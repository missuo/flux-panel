package models

// Forward 转发模型
type Forward struct {
	BaseModel
	UserID        int    `gorm:"column:user_id" json:"user_id"`
	UserName      string `gorm:"column:user_name;type:varchar(100)" json:"user_name"`
	Name          string `gorm:"column:name;type:varchar(100)" json:"name"`
	TunnelID      int    `gorm:"column:tunnel_id" json:"tunnel_id"`
	InPort        int    `gorm:"column:in_port" json:"in_port"`
	OutPort       int    `gorm:"column:out_port" json:"out_port"`
	RemoteAddr    string `gorm:"column:remote_addr;type:varchar(255)" json:"remote_addr"`
	InterfaceName string `gorm:"column:interface_name;type:varchar(100)" json:"interface_name"`
	Strategy      string `gorm:"column:strategy;type:varchar(50)" json:"strategy"`
	InFlow        int64  `gorm:"column:in_flow;default:0" json:"in_flow"`
	OutFlow       int64  `gorm:"column:out_flow;default:0" json:"out_flow"`
	Inx           int    `gorm:"column:inx" json:"inx"` // 索引
}

// TableName 指定表名
func (Forward) TableName() string {
	return "forward"
}
