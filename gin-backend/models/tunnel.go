package models

// Tunnel 隧道模型
type Tunnel struct {
	BaseModel
	Name          string  `gorm:"column:name;type:varchar(100);not null" json:"name"`
	InNodeID      uint    `gorm:"column:in_node_id" json:"inNodeId"`            // 入口节点ID
	InIP          string  `gorm:"column:in_ip;type:varchar(100)" json:"inIp"`   // 入口IP (兼容)
	OutNodeID     uint    `gorm:"column:out_node_id" json:"outNodeId"`          // 出口节点ID
	OutIP         string  `gorm:"column:out_ip;type:varchar(100)" json:"outIp"` // 出口IP (兼容)
	Type          int     `gorm:"column:type;default:1" json:"type"`            // 1: 端口转发, 2: 隧道转发
	Flow          int     `gorm:"column:flow;default:2" json:"flow"`            // 1: 单向上传, 2: 双向
	Protocol      string  `gorm:"column:protocol;type:varchar(50)" json:"protocol"`
	TrafficRatio  float64 `gorm:"column:traffic_ratio;type:decimal(10,2);default:1.0" json:"trafficRatio"` // 流量倍率
	TCPListenAddr string  `gorm:"column:tcp_listen_addr;type:varchar(255)" json:"tcpListenAddr"`
	UDPListenAddr string  `gorm:"column:udp_listen_addr;type:varchar(255)" json:"udpListenAddr"`
	InterfaceName string  `gorm:"column:interface_name;type:varchar(100)" json:"interfaceName"`
}

// TableName 指定表名
func (Tunnel) TableName() string {
	return "tunnel"
}
