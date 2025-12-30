package service

import (
	"errors"
	"flux-panel/models"
	"flux-panel/repository"
	"time"

	"gorm.io/gorm"
)

type ConfigService struct {
	repo *repository.ConfigRepository
}

func NewConfigService(db *gorm.DB) *ConfigService {
	return &ConfigService{
		repo: repository.NewConfigRepository(db),
	}
}

// GetConfigs 获取所有配置
func (s *ConfigService) GetConfigs() (map[string]string, error) {
	configs, err := s.repo.FindAll()
	if err != nil {
		return nil, err
	}

	configMap := make(map[string]string)
	for _, config := range configs {
		configMap[config.Name] = config.Value
	}
	return configMap, nil
}

// GetConfigByName 根据名称获取配置
func (s *ConfigService) GetConfigByName(name string) (*models.ViteConfig, error) {
	if name == "" {
		return nil, errors.New("配置名称不能为空")
	}
	return s.repo.FindByName(name)
}

// UpdateConfigs 批量更新配置
func (s *ConfigService) UpdateConfigs(configMap map[string]string) error {
	for name, value := range configMap {
		if name == "" {
			continue
		}
		if err := s.updateOrCreateConfig(name, value); err != nil {
			return err
		}
	}
	return nil
}

// UpdateConfig 更新单个配置
func (s *ConfigService) UpdateConfig(name, value string) error {
	if name == "" {
		return errors.New("配置名称不能为空")
	}
	return s.updateOrCreateConfig(name, value)
}

func (s *ConfigService) updateOrCreateConfig(name, value string) error {
	config, err := s.repo.FindByName(name)
	if err != nil {
		// 不存在则创建
		newConfig := &models.ViteConfig{
			Name:  name,
			Value: value,
			Time:  time.Now().UnixMilli(),
		}
		return s.repo.Create(newConfig)
	}

	// 存在则更新
	config.Value = value
	config.Time = time.Now().UnixMilli()
	return s.repo.Update(config)
}
