package repository

import (
	"flux-panel/models"

	"gorm.io/gorm"
)

type TunnelRepository struct {
	db *gorm.DB
}

func NewTunnelRepository(db *gorm.DB) *TunnelRepository {
	return &TunnelRepository{db: db}
}

func (r *TunnelRepository) Create(tunnel *models.Tunnel) error {
	return r.db.Create(tunnel).Error
}

func (r *TunnelRepository) FindByID(id uint) (*models.Tunnel, error) {
	var tunnel models.Tunnel
	err := r.db.Where("id = ? AND status = 0", id).First(&tunnel).Error
	return &tunnel, err
}

func (r *TunnelRepository) FindAll() ([]models.Tunnel, error) {
	var tunnels []models.Tunnel
	err := r.db.Where("status = 0").Find(&tunnels).Error
	return tunnels, err
}

func (r *TunnelRepository) Update(tunnel *models.Tunnel) error {
	return r.db.Save(tunnel).Error
}

func (r *TunnelRepository) Delete(id uint) error {
	return r.db.Model(&models.Tunnel{}).Where("id = ?", id).Update("status", 1).Error
}

func (r *TunnelRepository) FindByUserID(userID uint) ([]models.Tunnel, error) {
	var tunnels []models.Tunnel
	err := r.db.Joins("JOIN user_tunnel ON user_tunnel.tunnel_id = tunnel.id").
		Where("user_tunnel.user_id = ? AND tunnel.status = 0", userID).
		Find(&tunnels).Error
	return tunnels, err
}
