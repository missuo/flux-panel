package models

// Node 节点模型
type Node struct {
	BaseModel
	Name     string `gorm:"column:name;type:varchar(100);not null" json:"name"`
	Secret   string `gorm:"column:secret;type:varchar(255)" json:"secret"`
	IP       string `gorm:"column:ip;type:varchar(100)" json:"ip"`
	ServerIP string `gorm:"column:server_ip;type:varchar(100)" json:"server_ip"`
	Version  string `gorm:"column:version;type:varchar(50)" json:"version"`
	PortSta  int    `gorm:"column:port_sta" json:"port_sta"` // 端口起始
	PortEnd  int    `gorm:"column:port_end" json:"port_end"` // 端口结束
	HTTP     int    `gorm:"column:http;default:0" json:"http"` // HTTP端口
	TLS      int    `gorm:"column:tls;default:0" json:"tls"`   // TLS端口
	Socks    int    `gorm:"column:socks;default:0" json:"socks"` // Socks端口
}

// TableName 指定表名
func (Node) TableName() string {
	return "node"
}
