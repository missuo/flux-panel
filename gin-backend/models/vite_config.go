package models

// ViteConfig 前端配置模型
type ViteConfig struct {
	BaseModel
	ConfigKey   string `gorm:"column:config_key;type:varchar(100);uniqueIndex" json:"config_key"`
	ConfigValue string `gorm:"column:config_value;type:text" json:"config_value"`
	Description string `gorm:"column:description;type:varchar(255)" json:"description"`
}

// TableName 指定表名
func (ViteConfig) TableName() string {
	return "vite_config"
}
