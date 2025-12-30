package repository

import (
	"flux-panel/models"

	"gorm.io/gorm"
)

type ConfigRepository struct {
	db *gorm.DB
}

func NewConfigRepository(db *gorm.DB) *ConfigRepository {
	return &ConfigRepository{db: db}
}

func (r *ConfigRepository) FindAll() ([]models.ViteConfig, error) {
	var configs []models.ViteConfig
	err := r.db.Find(&configs).Error
	return configs, err
}

func (r *ConfigRepository) FindByName(name string) (*models.ViteConfig, error) {
	var config models.ViteConfig
	err := r.db.Where("name = ?", name).First(&config).Error
	return &config, err
}

func (r *ConfigRepository) Create(config *models.ViteConfig) error {
	return r.db.Create(config).Error
}

func (r *ConfigRepository) Update(config *models.ViteConfig) error {
	return r.db.Save(config).Error
}
