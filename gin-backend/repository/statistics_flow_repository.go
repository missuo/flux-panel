package repository

import (
	"flux-panel/models"

	"gorm.io/gorm"
)

type StatisticsFlowRepository struct {
	db *gorm.DB
}

func NewStatisticsFlowRepository(db *gorm.DB) *StatisticsFlowRepository {
	return &StatisticsFlowRepository{db: db}
}

func (r *StatisticsFlowRepository) FindByUserID(userID uint) ([]models.StatisticsFlow, error) {
	var stats []models.StatisticsFlow
	// 获取最近24条记录（假设每小时一条）
	err := r.db.Where("user_id = ?", userID).Order("created_time DESC").Limit(24).Find(&stats).Error
	return stats, err
}
