package service

import (
	"errors"
	"flux-panel/dto"
	"flux-panel/models"
	"flux-panel/repository"

	"gorm.io/gorm"
)

type TunnelService struct {
	repo           *repository.TunnelRepository
	userTunnelRepo *repository.UserTunnelRepository
}

func NewTunnelService(db *gorm.DB) *TunnelService {
	return &TunnelService{
		repo:           repository.NewTunnelRepository(db),
		userTunnelRepo: repository.NewUserTunnelRepository(db),
	}
}

// CreateTunnel 创建隧道
func (s *TunnelService) CreateTunnel(tunnelDto *dto.TunnelDto) error {
	tunnel := &models.Tunnel{
		Name:          tunnelDto.Name,
		InNodeID:      tunnelDto.InNodeID,
		OutNodeID:     tunnelDto.OutNodeID,
		Type:          tunnelDto.Type,
		Flow:          tunnelDto.Flow,
		Protocol:      tunnelDto.Protocol,
		TCPListenAddr: tunnelDto.TCPListenAddr,
		UDPListenAddr: tunnelDto.UDPListenAddr,
		InterfaceName: tunnelDto.InterfaceName,
	}

	if tunnelDto.TrafficRatio != nil {
		tunnel.TrafficRatio = *tunnelDto.TrafficRatio
	} else {
		tunnel.TrafficRatio = 1.0
	}

	return s.repo.Create(tunnel)
}

// GetAllTunnels 获取所有隧道
func (s *TunnelService) GetAllTunnels() ([]models.Tunnel, error) {
	return s.repo.FindAll()
}

// UpdateTunnel 更新隧道
func (s *TunnelService) UpdateTunnel(updateDto *dto.TunnelUpdateDto) error {
	tunnel, err := s.repo.FindByID(updateDto.ID)
	if err != nil {
		return errors.New("隧道不存在")
	}

	// 更新字段
	if updateDto.Name != nil {
		tunnel.Name = *updateDto.Name
	}
	if updateDto.InNodeID != nil {
		tunnel.InNodeID = *updateDto.InNodeID
	}
	if updateDto.OutNodeID != nil {
		tunnel.OutNodeID = *updateDto.OutNodeID
	}
	if updateDto.Type != nil {
		tunnel.Type = *updateDto.Type
	}
	if updateDto.Flow != nil {
		tunnel.Flow = *updateDto.Flow
	}
	if updateDto.Protocol != nil {
		tunnel.Protocol = *updateDto.Protocol
	}
	if updateDto.TrafficRatio != nil {
		tunnel.TrafficRatio = *updateDto.TrafficRatio
	}
	if updateDto.TCPListenAddr != nil {
		tunnel.TCPListenAddr = *updateDto.TCPListenAddr
	}
	if updateDto.UDPListenAddr != nil {
		tunnel.UDPListenAddr = *updateDto.UDPListenAddr
	}
	if updateDto.InterfaceName != nil {
		tunnel.InterfaceName = *updateDto.InterfaceName
	}

	return s.repo.Update(tunnel)
}

// DeleteTunnel 删除隧道
func (s *TunnelService) DeleteTunnel(id uint) error {
	return s.repo.Delete(id)
}

// GetUserTunnels 获取用户可用的隧道
func (s *TunnelService) GetUserTunnels(userID uint) ([]models.Tunnel, error) {
	return s.repo.FindByUserID(userID)
}

// AssignUserTunnel 分配用户隧道权限
func (s *TunnelService) AssignUserTunnel(assignDto *dto.UserTunnelDto) error {
	// 检查是否已经分配
	_, err := s.userTunnelRepo.FindByUserAndTunnel(assignDto.UserID, assignDto.TunnelID)
	if err == nil {
		return errors.New("用户已拥有该隧道权限")
	}

	userTunnel := &models.UserTunnel{
		UserID:        assignDto.UserID,
		TunnelID:      assignDto.TunnelID,
		ExpTime:       assignDto.ExpTime,
		Flow:          assignDto.Flow,
		FlowResetTime: assignDto.FlowResetTime,
	}

	return s.userTunnelRepo.Create(userTunnel)
}

// GetUserTunnelList 获取用户隧道权限列表
func (s *TunnelService) GetUserTunnelList(queryDto *dto.UserTunnelQueryDto) ([]models.UserTunnel, error) {
	if queryDto.UserID != nil {
		return s.userTunnelRepo.FindByUserID(*queryDto.UserID)
	}
	if queryDto.TunnelID != nil {
		return s.userTunnelRepo.FindByTunnelID(*queryDto.TunnelID)
	}
	return s.userTunnelRepo.FindAll()
}

// RemoveUserTunnel 移除用户隧道权限
func (s *TunnelService) RemoveUserTunnel(id uint) error {
	return s.userTunnelRepo.Delete(id)
}

// UpdateUserTunnel 更新用户隧道权限
func (s *TunnelService) UpdateUserTunnel(updateDto *dto.UserTunnelUpdateDto) error {
	userTunnel, err := s.userTunnelRepo.FindByID(updateDto.ID)
	if err != nil {
		return errors.New("用户隧道权限不存在")
	}

	if updateDto.ExpTime != nil {
		userTunnel.ExpTime = *updateDto.ExpTime
	}
	if updateDto.Flow != nil {
		userTunnel.Flow = *updateDto.Flow
	}
	if updateDto.FlowResetTime != nil {
		userTunnel.FlowResetTime = *updateDto.FlowResetTime
	}

	return s.userTunnelRepo.Update(userTunnel)
}

// GetTunnelByID 根据ID获取隧道
func (s *TunnelService) GetTunnelByID(id uint) (*models.Tunnel, error) {
	tunnel, err := s.repo.FindByID(id)
	if err != nil {
		return nil, errors.New("隧道不存在")
	}
	return tunnel, nil
}

// DiagnoseTunnel 诊断隧道
func (s *TunnelService) DiagnoseTunnel(id uint) (map[string]interface{}, error) {
	tunnel, err := s.repo.FindByID(id)
	if err != nil {
		return nil, errors.New("隧道不存在")
	}

	// TODO: 实际的隧道诊断逻辑，需要与Gost交互
	result := map[string]interface{}{
		"id":        tunnel.ID,
		"name":      tunnel.Name,
		"status":    "online",
		"latency":   0,
		"message":   "隧道诊断功能待实现",
	}

	return result, nil
}
