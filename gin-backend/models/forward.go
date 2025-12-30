package models

// Forward 转发模型
type Forward struct {
	BaseModel
	UserID        int    `gorm:"column:user_id" json:"userId"`
	UserName      string `gorm:"column:user_name;type:varchar(100)" json:"userName"`
	Name          string `gorm:"column:name;type:varchar(100)" json:"name"`
	TunnelID      int    `gorm:"column:tunnel_id" json:"tunnelId"`
	InPort        int    `gorm:"column:in_port" json:"inPort"`
	OutPort       int    `gorm:"column:out_port" json:"outPort"`
	RemoteAddr    string `gorm:"column:remote_addr;type:varchar(255)" json:"remoteAddr"`
	InterfaceName string `gorm:"column:interface_name;type:varchar(100)" json:"interfaceName"`
	Strategy      string `gorm:"column:strategy;type:varchar(50)" json:"strategy"`
	InFlow        int64  `gorm:"column:in_flow;default:0" json:"inFlow"`
	OutFlow       int64  `gorm:"column:out_flow;default:0" json:"outFlow"`
	Inx           int    `gorm:"column:inx" json:"inx"`
}

// TableName 指定表名
func (Forward) TableName() string {
	return "forward"
}
