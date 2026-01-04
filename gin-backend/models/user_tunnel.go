package models

// UserTunnel 用户隧道权限模型
type UserTunnel struct {
	BaseModel
	UserID        uint  `gorm:"column:user_id;not null;index:idx_user_tunnel" json:"userId"`
	TunnelID      uint  `gorm:"column:tunnel_id;not null;index:idx_user_tunnel" json:"tunnelId"`
	ExpTime       int64 `gorm:"column:exp_time" json:"expTime"`              // 到期时间
	Flow          int64 `gorm:"column:flow" json:"flow"`                     // 总流量
	InFlow        int64 `gorm:"column:in_flow;default:0" json:"inFlow"`      // 已用入流量
	OutFlow       int64 `gorm:"column:out_flow;default:0" json:"outFlow"`    // 已用出流量
	FlowResetTime int64 `gorm:"column:flow_reset_time" json:"flowResetTime"` // 流量重置时间
	Num           int   `gorm:"column:num;default:0" json:"num"`             // 转发数量限制
	SpeedID       int   `gorm:"column:speed_id" json:"speedId"`              // 限速ID
}

// TableName 指定表名
func (UserTunnel) TableName() string {
	return "user_tunnel"
}
