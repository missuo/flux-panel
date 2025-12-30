package repository

import (
	"flux-panel/models"

	"gorm.io/gorm"
)

type SpeedLimitRepository struct {
	db *gorm.DB
}

func NewSpeedLimitRepository(db *gorm.DB) *SpeedLimitRepository {
	return &SpeedLimitRepository{db: db}
}

func (r *SpeedLimitRepository) Create(speedLimit *models.SpeedLimit) error {
	return r.db.Create(speedLimit).Error
}

func (r *SpeedLimitRepository) FindByID(id uint) (*models.SpeedLimit, error) {
	var speedLimit models.SpeedLimit
	err := r.db.Where("id = ? AND status = 0", id).First(&speedLimit).Error
	return &speedLimit, err
}

func (r *SpeedLimitRepository) FindAll() ([]models.SpeedLimit, error) {
	var speedLimits []models.SpeedLimit
	err := r.db.Where("status = 0").Find(&speedLimits).Error
	return speedLimits, err
}

func (r *SpeedLimitRepository) Update(speedLimit *models.SpeedLimit) error {
	return r.db.Save(speedLimit).Error
}

func (r *SpeedLimitRepository) Delete(id uint) error {
	return r.db.Model(&models.SpeedLimit{}).Where("id = ?", id).Update("status", 1).Error
}
