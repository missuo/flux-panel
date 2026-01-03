package repository

import (
	"flux-panel/models"

	"gorm.io/gorm"
)

type UserTunnelRepository struct {
	db *gorm.DB
}

func NewUserTunnelRepository(db *gorm.DB) *UserTunnelRepository {
	return &UserTunnelRepository{db: db}
}

func (r *UserTunnelRepository) Create(userTunnel *models.UserTunnel) error {
	return r.db.Create(userTunnel).Error
}

func (r *UserTunnelRepository) FindByID(id uint) (*models.UserTunnel, error) {
	var userTunnel models.UserTunnel
	err := r.db.Where("id = ?", id).First(&userTunnel).Error
	return &userTunnel, err
}

func (r *UserTunnelRepository) FindByUserAndTunnel(userID, tunnelID uint) (*models.UserTunnel, error) {
	var userTunnel models.UserTunnel
	err := r.db.Where("user_id = ? AND tunnel_id = ?", userID, tunnelID).First(&userTunnel).Error
	return &userTunnel, err
}

func (r *UserTunnelRepository) FindByUserID(userID uint) ([]models.UserTunnel, error) {
	var userTunnels []models.UserTunnel
	err := r.db.Where("user_id = ?", userID).Find(&userTunnels).Error
	return userTunnels, err
}

func (r *UserTunnelRepository) FindByTunnelID(tunnelID uint) ([]models.UserTunnel, error) {
	var userTunnels []models.UserTunnel
	err := r.db.Where("tunnel_id = ?", tunnelID).Find(&userTunnels).Error
	return userTunnels, err
}

func (r *UserTunnelRepository) FindAll() ([]models.UserTunnel, error) {
	var userTunnels []models.UserTunnel
	err := r.db.Find(&userTunnels).Error
	return userTunnels, err
}

func (r *UserTunnelRepository) Update(userTunnel *models.UserTunnel) error {
	return r.db.Save(userTunnel).Error
}

func (r *UserTunnelRepository) Delete(id uint) error {
	return r.db.Delete(&models.UserTunnel{}, id).Error
}
