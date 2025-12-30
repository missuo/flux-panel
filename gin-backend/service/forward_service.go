package service

import (
	"errors"
	"flux-panel/dto"
	"flux-panel/models"
	"flux-panel/repository"

	"gorm.io/gorm"
)

type ForwardService struct {
	repo *repository.ForwardRepository
}

func NewForwardService(db *gorm.DB) *ForwardService {
	return &ForwardService{
		repo: repository.NewForwardRepository(db),
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

// PauseForward 暂停转发 (TODO: 实现Gost集成)
func (s *ForwardService) PauseForward(id uint) error {
	_, err := s.repo.FindByID(id)
	if err != nil {
		return errors.New("转发不存在")
	}
	// TODO: 调用Gost API暂停服务
	return nil
}

// ResumeForward 恢复转发 (TODO: 实现Gost集成)
func (s *ForwardService) ResumeForward(id uint) error {
	_, err := s.repo.FindByID(id)
	if err != nil {
		return errors.New("转发不存在")
	}
	// TODO: 调用Gost API恢复服务
	return nil
}

// DiagnoseForward 诊断转发 (TODO: 实现诊断逻辑)
func (s *ForwardService) DiagnoseForward(id uint) (map[string]interface{}, error) {
	forward, err := s.repo.FindByID(id)
	if err != nil {
		return nil, errors.New("转发不存在")
	}

	// TODO: 实现真正的诊断逻辑
	result := map[string]interface{}{
		"forwardId": forward.ID,
		"status":    "ok",
		"message":   "诊断功能开发中",
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
