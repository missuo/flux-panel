package models

// BaseModel 基础模型
type BaseModel struct {
	ID          uint  `gorm:"primaryKey;autoIncrement" json:"id"`
	CreatedTime int64 `gorm:"column:created_time;autoCreateTime:milli" json:"created_time"`
	UpdatedTime int64 `gorm:"column:updated_time;autoUpdateTime:milli" json:"updated_time"`
	Status      int   `gorm:"column:status;default:0" json:"status"` // 0: 正常, 1: 删除
}
