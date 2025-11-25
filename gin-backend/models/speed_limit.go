package models

// SpeedLimit 限速模型
type SpeedLimit struct {
	BaseModel
	ForwardID int `gorm:"column:forward_id;uniqueIndex" json:"forward_id"`
	InLimit   int `gorm:"column:in_limit;default:0" json:"in_limit"`   // 入站限速 KB/s
	OutLimit  int `gorm:"column:out_limit;default:0" json:"out_limit"` // 出站限速 KB/s
}

// TableName 指定表名
func (SpeedLimit) TableName() string {
	return "speed_limit"
}
