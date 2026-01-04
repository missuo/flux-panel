package models

// User 用户模型
type User struct {
	BaseModel
	User          string `gorm:"column:user;type:varchar(100);not null;uniqueIndex" json:"user"`
	Pwd           string `gorm:"column:pwd;type:varchar(255);not null" json:"-"`
	RoleID        int    `gorm:"column:role_id;default:1" json:"roleId"`      // 0: 管理员, 1: 普通用户
	ExpTime       int64  `gorm:"column:exp_time" json:"expTime"`              // 到期时间
	Flow          int64  `gorm:"column:flow" json:"flow"`                     // 总流量
	InFlow        int64  `gorm:"column:in_flow;default:0" json:"inFlow"`      // 已用入流量
	OutFlow       int64  `gorm:"column:out_flow;default:0" json:"outFlow"`    // 已用出流量
	Num           int    `gorm:"column:num;default:0" json:"num"`             // 隧道数量限制
	FlowResetTime int64  `gorm:"column:flow_reset_time" json:"flowResetTime"` // 流量重置时间
	Status        int    `gorm:"column:status;default:1" json:"status"`       // -1: 删除, 0: 禁用, 1: 启用
}

// TableName 指定表名
func (User) TableName() string {
	return "user"
}
