package repository

import (
	"flux-panel/models"

	"gorm.io/gorm"
)

type UserRepository struct {
	db *gorm.DB
}

func NewUserRepository(db *gorm.DB) *UserRepository {
	return &UserRepository{db: db}
}

func (r *UserRepository) Create(user *models.User) error {
	return r.db.Create(user).Error
}

// FindByID 根据ID查找用户（不包含已删除的用户，status >= 0）
func (r *UserRepository) FindByID(id uint) (*models.User, error) {
	var user models.User
	err := r.db.Where("id = ? AND status >= 0", id).First(&user).Error
	return &user, err
}

// FindByUsername 根据用户名查找用户（不包含已删除的，用于登录验证时只允许启用用户）
func (r *UserRepository) FindByUsername(username string) (*models.User, error) {
	var user models.User
	// 登录时只允许启用状态的用户
	err := r.db.Where("user = ? AND status = 1", username).First(&user).Error
	return &user, err
}

// FindAll 获取所有用户（不包含已删除的用户和管理员）
func (r *UserRepository) FindAll() ([]models.User, error) {
	var users []models.User
	// status >= 0 表示未删除（0=禁用, 1=启用）
	err := r.db.Where("status >= 0 AND role_id != 0").Find(&users).Error
	return users, err
}

func (r *UserRepository) Update(user *models.User) error {
	return r.db.Save(user).Error
}

// Delete 软删除用户（将status设为-1）
func (r *UserRepository) Delete(id uint) error {
	return r.db.Model(&models.User{}).Where("id = ?", id).Update("status", -1).Error
}

func (r *UserRepository) ResetFlow(id uint) error {
	return r.db.Model(&models.User{}).Where("id = ?", id).Updates(map[string]interface{}{
		"in_flow":  0,
		"out_flow": 0,
	}).Error
}
