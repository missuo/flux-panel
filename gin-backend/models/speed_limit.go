package models

// SpeedLimit 限速模型
type SpeedLimit struct {
	BaseModel
	Name       string `gorm:"column:name;type:varchar(100)" json:"name"`
	Speed      int    `gorm:"column:speed" json:"speed"`
	TunnelID   int64  `gorm:"column:tunnel_id" json:"tunnelId"`
	TunnelName string `gorm:"column:tunnel_name;type:varchar(100)" json:"tunnelName"`
	Status     int    `gorm:"column:status;default:0" json:"status"` // 0: 正常, 1: 删除
}

// TableName 指定表名
func (SpeedLimit) TableName() string {
	return "speed_limit"
}
