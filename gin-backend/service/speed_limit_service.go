package service

import (
	"errors"
	"flux-panel/dto"
	"flux-panel/models"
	"flux-panel/repository"

	"gorm.io/gorm"
)

type SpeedLimitService struct {
	repo *repository.SpeedLimitRepository
}

func NewSpeedLimitService(db *gorm.DB) *SpeedLimitService {
	return &SpeedLimitService{
		repo: repository.NewSpeedLimitRepository(db),
	}
}

// CreateSpeedLimit 创建限速规则
func (s *SpeedLimitService) CreateSpeedLimit(limitDto *dto.SpeedLimitDto) error {
	speedLimit := &models.SpeedLimit{
		Name:       limitDto.Name,
		Speed:      limitDto.Speed,
		TunnelID:   limitDto.TunnelID,
		TunnelName: limitDto.TunnelName,
		Status:     0,
	}
	return s.repo.Create(speedLimit)
}

// GetAllSpeedLimits 获取所有限速规则
func (s *SpeedLimitService) GetAllSpeedLimits() ([]models.SpeedLimit, error) {
	return s.repo.FindAll()
}

// UpdateSpeedLimit 更新限速规则
func (s *SpeedLimitService) UpdateSpeedLimit(updateDto *dto.SpeedLimitUpdateDto) error {
	speedLimit, err := s.repo.FindByID(updateDto.ID)
	if err != nil {
		return errors.New("限速规则不存在")
	}

	speedLimit.Name = updateDto.Name
	speedLimit.Speed = updateDto.Speed
	speedLimit.TunnelID = updateDto.TunnelID
	speedLimit.TunnelName = updateDto.TunnelName

	return s.repo.Update(speedLimit)
}

// DeleteSpeedLimit 删除限速规则
func (s *SpeedLimitService) DeleteSpeedLimit(id uint) error {
	_, err := s.repo.FindByID(id)
	if err != nil {
		return errors.New("限速规则不存在")
	}
	return s.repo.Delete(id)
}
