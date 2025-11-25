package dto

// NodeDto 创建节点请求
type NodeDto struct {
	Name     string `json:"name" binding:"required"`
	Secret   string `json:"secret"`
	IP       string `json:"ip"`
	ServerIP string `json:"server_ip"`
	Version  string `json:"version"`
	PortSta  int    `json:"port_sta"`
	PortEnd  int    `json:"port_end"`
	HTTP     int    `json:"http"`
	TLS      int    `json:"tls"`
	Socks    int    `json:"socks"`
}

// NodeUpdateDto 更新节点请求
type NodeUpdateDto struct {
	ID       uint    `json:"id" binding:"required"`
	Name     *string `json:"name"`
	Secret   *string `json:"secret"`
	IP       *string `json:"ip"`
	ServerIP *string `json:"server_ip"`
	Version  *string `json:"version"`
	PortSta  *int    `json:"port_sta"`
	PortEnd  *int    `json:"port_end"`
	HTTP     *int    `json:"http"`
	TLS      *int    `json:"tls"`
	Socks    *int    `json:"socks"`
}
