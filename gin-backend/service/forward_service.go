package service

import (
	"errors"
	"flux-panel/dto"
	"flux-panel/models"
	"flux-panel/repository"

	"gorm.io/gorm"
)

type ForwardService struct {
	repo           *repository.ForwardRepository
	tunnelRepo     *repository.TunnelRepository
	userTunnelRepo *repository.UserTunnelRepository
	nodeRepo       *repository.NodeRepository
}

func NewForwardService(db *gorm.DB) *ForwardService {
	return &ForwardService{
		repo:           repository.NewForwardRepository(db),
		tunnelRepo:     repository.NewTunnelRepository(db),
		userTunnelRepo: repository.NewUserTunnelRepository(db),
		nodeRepo:       repository.NewNodeRepository(db),
	}
}

// CreateForward 创建转发
func (s *ForwardService) CreateForward(userID int, userName string, forwardDto *dto.ForwardDto) error {
	inPort := 0
	if forwardDto.InPort != nil {
		inPort = *forwardDto.InPort
	}

	forward := &models.Forward{
		UserID:        userID,
		UserName:      userName,
		Name:          forwardDto.Name,
		TunnelID:      forwardDto.TunnelID,
		RemoteAddr:    forwardDto.RemoteAddr,
		Strategy:      forwardDto.Strategy,
		InPort:        inPort,
		InterfaceName: forwardDto.InterfaceName,
	}

	return s.repo.Create(forward)
}

// GetAllForwards 获取所有转发
func (s *ForwardService) GetAllForwards() ([]models.Forward, error) {
	return s.repo.FindAll()
}

// GetForwardsByUserID 获取用户的转发
func (s *ForwardService) GetForwardsByUserID(userID int) ([]models.Forward, error) {
	return s.repo.FindByUserID(userID)
}

// UpdateForward 更新转发
func (s *ForwardService) UpdateForward(updateDto *dto.ForwardUpdateDto) error {
	forward, err := s.repo.FindByID(updateDto.ID)
	if err != nil {
		return errors.New("转发不存在")
	}

	forward.Name = updateDto.Name
	forward.TunnelID = updateDto.TunnelID
	forward.RemoteAddr = updateDto.RemoteAddr
	forward.Strategy = updateDto.Strategy
	forward.InterfaceName = updateDto.InterfaceName
	if updateDto.InPort != nil {
		forward.InPort = *updateDto.InPort
	}

	return s.repo.Update(forward)
}

// DeleteForward 删除转发
func (s *ForwardService) DeleteForward(id uint) error {
	_, err := s.repo.FindByID(id)
	if err != nil {
		return errors.New("转发不存在")
	}
	return s.repo.Delete(id)
}

// ForceDeleteForward 强制删除转发
func (s *ForwardService) ForceDeleteForward(id uint) error {
	return s.repo.Delete(id)
}

// PauseForward 暂停转发
func (s *ForwardService) PauseForward(id uint) error {
	forward, err := s.repo.FindByID(id)
	if err != nil {
		return errors.New("转发不存在")
	}

	// 更新数据库状态
	forward.Status = 0
	if err := s.repo.Update(forward); err != nil {
		return err
	}

	// 调用 Gost API 暂停服务
	userTunnel, err := s.userTunnelRepo.FindByUserAndTunnel(uint(forward.UserID), uint(forward.TunnelID))
	if err != nil {
		return nil // 如果找不到映射，可能已经被删除了，只需要暂停 DB 状态即可
	}

	tunnel, err := s.tunnelRepo.FindByID(uint(forward.TunnelID))
	if err != nil {
		return nil
	}

	serviceName := BuildServiceName(forward.ID, forward.UserID, userTunnel.ID)
	PauseService(tunnel.InNodeID, serviceName)
	if tunnel.Type == 2 {
		PauseRemoteService(tunnel.OutNodeID, serviceName)
	}

	return nil
}

// ResumeForward 恢复转发
func (s *ForwardService) ResumeForward(id uint) error {
	forward, err := s.repo.FindByID(id)
	if err != nil {
		return errors.New("转发不存在")
	}

	// 更新数据库状态
	forward.Status = 1
	if err := s.repo.Update(forward); err != nil {
		return err
	}

	// 调用 Gost API 恢复服务
	userTunnel, err := s.userTunnelRepo.FindByUserAndTunnel(uint(forward.UserID), uint(forward.TunnelID))
	if err != nil {
		return nil
	}

	tunnel, err := s.tunnelRepo.FindByID(uint(forward.TunnelID))
	if err != nil {
		return nil
	}

	serviceName := BuildServiceName(forward.ID, forward.UserID, userTunnel.ID)
	ResumeService(tunnel.InNodeID, serviceName)
	if tunnel.Type == 2 {
		ResumeRemoteService(tunnel.OutNodeID, serviceName)
	}

	return nil
}

// DiagnoseForward 诊断转发
func (s *ForwardService) DiagnoseForward(id uint) (map[string]interface{}, error) {
	forward, err := s.repo.FindByID(id)
	if err != nil {
		return nil, errors.New("转发不存在")
	}

	// TODO: 实现真正的诊断逻辑 (例如 TCP Ping RemoteAddr)
	// 目前返回 Mock 数据以防前端白屏
	result := map[string]interface{}{
		"forwardId": forward.ID,
		"status":    "ok",
		"message":   "诊断暂未实现",
		"timestamp": 0, // Fill with current time if needed
	}
	return result, nil
}

// UpdateForwardOrder 更新转发排序
func (s *ForwardService) UpdateForwardOrder(orderDto *dto.ForwardOrderDto) error {
	for _, item := range orderDto.Forwards {
		if err := s.repo.UpdateOrder(item.ID, item.Inx); err != nil {
			return err
		}
	}
	return nil
}
