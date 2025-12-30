package models

// ViteConfig 前端配置模型
type ViteConfig struct {
	ID    uint   `gorm:"primaryKey;autoIncrement" json:"id"`
	Name  string `gorm:"column:name;type:varchar(100);uniqueIndex" json:"name"`
	Value string `gorm:"column:value;type:text" json:"value"`
	Time  int64  `gorm:"column:time" json:"time"`
}

// TableName 指定表名
func (ViteConfig) TableName() string {
	return "vite_config"
}
