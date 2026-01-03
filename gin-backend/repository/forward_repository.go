package repository

import (
	"flux-panel/models"

	"gorm.io/gorm"
)

type ForwardRepository struct {
	db *gorm.DB
}

func NewForwardRepository(db *gorm.DB) *ForwardRepository {
	return &ForwardRepository{db: db}
}

func (r *ForwardRepository) Create(forward *models.Forward) error {
	return r.db.Create(forward).Error
}

func (r *ForwardRepository) FindByID(id uint) (*models.Forward, error) {
	var forward models.Forward
	err := r.db.Where("id = ?", id).First(&forward).Error
	return &forward, err
}

func (r *ForwardRepository) FindByUserID(userID int) ([]models.Forward, error) {
	var forwards []models.Forward
	err := r.db.Where("user_id = ?", userID).Order("inx ASC").Find(&forwards).Error
	return forwards, err
}

func (r *ForwardRepository) FindAll() ([]models.Forward, error) {
	var forwards []models.Forward
	err := r.db.Order("inx ASC").Find(&forwards).Error
	return forwards, err
}

func (r *ForwardRepository) Update(forward *models.Forward) error {
	return r.db.Save(forward).Error
}

func (r *ForwardRepository) Delete(id uint) error {
	return r.db.Delete(&models.Forward{}, id).Error
}

func (r *ForwardRepository) FindByTunnelID(tunnelID uint) ([]models.Forward, error) {
	var forwards []models.Forward
	err := r.db.Where("tunnel_id = ?", tunnelID).Order("inx ASC").Find(&forwards).Error
	return forwards, err
}

func (r *ForwardRepository) UpdateOrder(id uint, inx int) error {
	return r.db.Model(&models.Forward{}).Where("id = ?", id).Update("inx", inx).Error
}
