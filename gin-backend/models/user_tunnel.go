package models

// UserTunnel 用户隧道权限模型
type UserTunnel struct {
	BaseModel
	UserID        uint  `gorm:"column:user_id;not null;index:idx_user_tunnel" json:"user_id"`
	TunnelID      uint  `gorm:"column:tunnel_id;not null;index:idx_user_tunnel" json:"tunnel_id"`
	ExpTime       int64 `gorm:"column:exp_time" json:"exp_time"`       // 到期时间
	Flow          int64 `gorm:"column:flow" json:"flow"`               // 总流量
	InFlow        int64 `gorm:"column:in_flow;default:0" json:"in_flow"` // 已用入流量
	OutFlow       int64 `gorm:"column:out_flow;default:0" json:"out_flow"` // 已用出流量
	FlowResetTime int64 `gorm:"column:flow_reset_time" json:"flow_reset_time"` // 流量重置时间
}

// TableName 指定表名
func (UserTunnel) TableName() string {
	return "user_tunnel"
}
