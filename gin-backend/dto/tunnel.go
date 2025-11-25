package dto

// TunnelDto 创建隧道请求
type TunnelDto struct {
	Name          string   `json:"name" binding:"required"`
	InNodeID      uint     `json:"in_node_id"`
	OutNodeID     uint     `json:"out_node_id"`
	Type          int      `json:"type"`
	Flow          int      `json:"flow"`
	Protocol      string   `json:"protocol"`
	TrafficRatio  *float64 `json:"traffic_ratio"`
	TCPListenAddr string   `json:"tcp_listen_addr"`
	UDPListenAddr string   `json:"udp_listen_addr"`
	InterfaceName string   `json:"interface_name"`
}

// TunnelUpdateDto 更新隧道请求
type TunnelUpdateDto struct {
	ID            uint     `json:"id" binding:"required"`
	Name          *string  `json:"name"`
	InNodeID      *uint    `json:"in_node_id"`
	OutNodeID     *uint    `json:"out_node_id"`
	Type          *int     `json:"type"`
	Flow          *int     `json:"flow"`
	Protocol      *string  `json:"protocol"`
	TrafficRatio  *float64 `json:"traffic_ratio"`
	TCPListenAddr *string  `json:"tcp_listen_addr"`
	UDPListenAddr *string  `json:"udp_listen_addr"`
	InterfaceName *string  `json:"interface_name"`
}

// UserTunnelDto 分配用户隧道请求
type UserTunnelDto struct {
	UserID        uint  `json:"user_id" binding:"required"`
	TunnelID      uint  `json:"tunnel_id" binding:"required"`
	ExpTime       int64 `json:"exp_time"`
	Flow          int64 `json:"flow"`
	FlowResetTime int64 `json:"flow_reset_time"`
}

// UserTunnelQueryDto 查询用户隧道请求
type UserTunnelQueryDto struct {
	UserID   *uint `json:"user_id"`
	TunnelID *uint `json:"tunnel_id"`
}

// UserTunnelUpdateDto 更新用户隧道请求
type UserTunnelUpdateDto struct {
	ID            uint   `json:"id" binding:"required"`
	ExpTime       *int64 `json:"exp_time"`
	Flow          *int64 `json:"flow"`
	FlowResetTime *int64 `json:"flow_reset_time"`
}
