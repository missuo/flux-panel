package service

import (
	"errors"
	"flux-panel/dto"
	"flux-panel/models"
	"flux-panel/repository"
	"flux-panel/utils"

	"gorm.io/gorm"
)

type UserService struct {
	repo           *repository.UserRepository
	configService  *ConfigService
	userTunnelRepo *repository.UserTunnelRepository
	forwardRepo    *repository.ForwardRepository
	statsRepo      *repository.StatisticsFlowRepository
	tunnelRepo     *repository.TunnelRepository
	nodeRepo       *repository.NodeRepository
}

func NewUserService(db *gorm.DB) *UserService {
	return &UserService{
		repo:           repository.NewUserRepository(db),
		configService:  NewConfigService(db),
		userTunnelRepo: repository.NewUserTunnelRepository(db),
		forwardRepo:    repository.NewForwardRepository(db),
		statsRepo:      repository.NewStatisticsFlowRepository(db),
		tunnelRepo:     repository.NewTunnelRepository(db),
		nodeRepo:       repository.NewNodeRepository(db),
	}
}

// Login 用户登录
func (s *UserService) Login(loginDto *dto.LoginDto, validateCaptcha func(string) bool) (map[string]interface{}, error) {
	// 检查是否启用验证码
	captchaEnabled := false
	config, err := s.configService.GetConfigByName("captcha_enabled")
	if err == nil && config.Value == "true" {
		captchaEnabled = true
	}

	// 如果启用验证码，验证 captchaId
	if captchaEnabled {
		if loginDto.CaptchaId == "" {
			return nil, errors.New("验证码校验失败")
		}
		if validateCaptcha != nil && !validateCaptcha(loginDto.CaptchaId) {
			return nil, errors.New("验证码校验失败")
		}
	}

	user, err := s.repo.FindByUsername(loginDto.Username)
	if err != nil {
		return nil, errors.New("用户名或密码错误")
	}

	// 验证密码
	if !utils.ComparePassword(user.Pwd, loginDto.Password) {
		return nil, errors.New("用户名或密码错误")
	}

	// 生成token
	token, err := utils.GenerateToken(user)
	if err != nil {
		return nil, errors.New("生成token失败")
	}

	// 检查是否使用默认密码
	requirePasswordChange := loginDto.Username == "admin_user" && loginDto.Password == "admin_user"

	// 如果是管理员，确保有无限套餐
	if user.RoleID == 0 {
		needUpdate := false
		if user.Flow != 99999 {
			user.Flow = 99999
			needUpdate = true
		}
		if user.Num != 99999 {
			user.Num = 99999
			needUpdate = true
		}
		if user.Status != 1 {
			user.Status = 1
			needUpdate = true
		}

		if needUpdate {
			s.repo.Update(user)
		}
	}

	return map[string]interface{}{
		"token":                 token,
		"role_id":               user.RoleID,
		"name":                  user.User,
		"requirePasswordChange": requirePasswordChange,
	}, nil
}

// CreateUser 创建用户
func (s *UserService) CreateUser(userDto *dto.UserDto) error {
	// 检查用户是否存在
	_, err := s.repo.FindByUsername(userDto.User)
	if err == nil {
		return errors.New("用户已存在")
	}

	status := 1 // 默认启用
	if userDto.Status != nil {
		status = *userDto.Status
	}

	user := &models.User{
		User:          userDto.User,
		Pwd:           utils.HashPassword(userDto.Pwd),
		RoleID:        1, // 普通用户
		ExpTime:       userDto.ExpTime,
		Flow:          userDto.Flow,
		Num:           userDto.Num,
		FlowResetTime: userDto.FlowResetTime,
		Status:        status,
	}

	return s.repo.Create(user)
}

// GetAllUsers 获取所有用户
func (s *UserService) GetAllUsers() ([]models.User, error) {
	users, err := s.repo.FindAll()
	if err != nil {
		return nil, err
	}

	// 不返回密码
	for i := range users {
		users[i].Pwd = ""
	}

	return users, nil
}

// UpdateUser 更新用户
func (s *UserService) UpdateUser(updateDto *dto.UserUpdateDto) error {
	user, err := s.repo.FindByID(updateDto.ID)
	if err != nil {
		return errors.New("用户不存在")
	}

	// 不能修改管理员
	if user.RoleID == 0 {
		return errors.New("不能修改管理员用户信息")
	}

	// 检查用户名是否被占用
	if updateDto.User != user.User {
		existingUser, err := s.repo.FindByUsername(updateDto.User)
		if err == nil && existingUser.ID != user.ID {
			return errors.New("用户名已被其他用户使用")
		}
	}

	// 更新字段
	user.User = updateDto.User
	user.ExpTime = updateDto.ExpTime
	user.Flow = updateDto.Flow
	user.Num = updateDto.Num
	user.FlowResetTime = updateDto.FlowResetTime

	if updateDto.Pwd != "" {
		user.Pwd = utils.HashPassword(updateDto.Pwd)
	}
	if updateDto.Status != nil {
		user.Status = *updateDto.Status
	}

	return s.repo.Update(user)
}

// DeleteUser 删除用户
func (s *UserService) DeleteUser(id uint) error {
	user, err := s.repo.FindByID(id)
	if err != nil {
		return errors.New("用户不存在")
	}

	// 不能删除管理员
	if user.RoleID == 0 {
		return errors.New("不能删除管理员用户")
	}

	return s.repo.Delete(id)
}

// GetUserPackageInfo 获取用户套餐信息
func (s *UserService) GetUserPackageInfo(userID uint) (*dto.UserDashboardResponse, error) {
	user, err := s.repo.FindByID(userID)
	if err != nil {
		return nil, errors.New("用户不存在")
	}

	// 构造基础用户信息
	usedFlow := user.InFlow + user.OutFlow
	userInfo := dto.UserPackageDto{
		User:          user.User,
		ExpTime:       user.ExpTime,
		Flow:          user.Flow,
		UsedFlow:      usedFlow,
		InFlow:        user.InFlow,
		OutFlow:       user.OutFlow,
		Num:           user.Num,
		UsedNum:       0, // 需要计算
		FlowResetTime: user.FlowResetTime,
	}

	// 获取用户隧道权限
	userTunnels, _ := s.userTunnelRepo.FindByUserID(userID)

	// 获取用户转发
	forwards, _ := s.forwardRepo.FindByUserID(int(userID))
	userInfo.UsedNum = len(forwards)

	// 获取流量统计
	stats, _ := s.statsRepo.FindByUserID(userID)

	// 获取所有隧道信息建立缓存
	allTunnels, _ := s.tunnelRepo.FindAll()
	tunnelMap := make(map[uint]models.Tunnel)
	for _, t := range allTunnels {
		tunnelMap[t.ID] = t
	}

	// 组装 TunnelPermissions
	tunnelPermissions := make([]dto.DashboardUserTunnelDto, 0)
	for _, ut := range userTunnels {
		tunnelName := "未知隧道"
		tunnelFlow := 2 // 默认双向
		if t, ok := tunnelMap[ut.TunnelID]; ok {
			tunnelName = t.Name
			tunnelFlow = t.Flow
		}
		tunnelPermissions = append(tunnelPermissions, dto.DashboardUserTunnelDto{
			ID:            ut.ID,
			TunnelID:      ut.TunnelID,
			TunnelName:    tunnelName,
			Flow:          ut.Flow,
			InFlow:        ut.InFlow,
			OutFlow:       ut.OutFlow,
			Num:           0,
			ExpTime:       ut.ExpTime,
			FlowResetTime: ut.FlowResetTime,
			TunnelFlow:    tunnelFlow,
		})
	}

	// 组装 Forwards
	dashboardForwards := make([]dto.DashboardForwardDto, 0)
	for _, f := range forwards {
		tunnelName := "未知隧道"
		inIP := ""
		inPort := f.InPort
		if t, ok := tunnelMap[uint(f.TunnelID)]; ok {
			tunnelName = t.Name
			inIP = t.InIP
		}
		dashboardForwards = append(dashboardForwards, dto.DashboardForwardDto{
			ID:         f.ID,
			Name:       f.Name,
			TunnelID:   uint(f.TunnelID),
			TunnelName: tunnelName,
			InIP:       inIP,
			InPort:     inPort,
			RemoteAddr: f.RemoteAddr,
			InFlow:     f.InFlow,
			OutFlow:    f.OutFlow,
		})
	}

	// 组装 StatisticsFlows
	dashboardStats := make([]dto.DashboardStatisticsFlowDto, 0)
	for _, s := range stats {
		dashboardStats = append(dashboardStats, dto.DashboardStatisticsFlowDto{
			ID:        s.ID,
			UserID:    uint(s.UserID),
			Flow:      s.Flow,
			TotalFlow: s.TotalFlow,
			Time:      s.Time,
		})
	}

	return &dto.UserDashboardResponse{
		UserInfo:          userInfo,
		TunnelPermissions: tunnelPermissions,
		Forwards:          dashboardForwards,
		StatisticsFlows:   dashboardStats,
	}, nil
}

// UpdatePassword 修改密码
func (s *UserService) UpdatePassword(userID uint, changeDto *dto.ChangePasswordDto) error {
	user, err := s.repo.FindByID(userID)
	if err != nil {
		return errors.New("用户不存在")
	}

	// 验证新密码和确认密码是否匹配
	if changeDto.NewPassword != changeDto.ConfirmPassword {
		return errors.New("新密码和确认密码不匹配")
	}

	// 验证当前密码
	if !utils.ComparePassword(user.Pwd, changeDto.CurrentPassword) {
		return errors.New("当前密码错误")
	}

	// 检查新用户名是否被占用（如果用户名有变化）
	if changeDto.NewUsername != user.User {
		existingUser, err := s.repo.FindByUsername(changeDto.NewUsername)
		if err == nil && existingUser.ID != user.ID {
			return errors.New("用户名已被其他用户使用")
		}
		user.User = changeDto.NewUsername
	}

	// 更新密码
	user.Pwd = utils.HashPassword(changeDto.NewPassword)
	return s.repo.Update(user)
}

// ResetFlow 重置流量
func (s *UserService) ResetFlow(resetDto *dto.ResetFlowDto) error {
	if resetDto.Type == 1 {
		// 清零账号流量
		return s.repo.ResetFlow(resetDto.ID)
	}
	// Type == 2: 清零隧道流量 - 暂不实现
	return nil
}
