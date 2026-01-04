package dto

// TunnelDto 创建隧道请求
type TunnelDto struct {
	Name          string   `json:"name" binding:"required"`
	InNodeID      uint     `json:"inNodeId"`
	OutNodeID     uint     `json:"outNodeId"`
	Type          int      `json:"type"`
	Flow          int      `json:"flow"`
	Protocol      string   `json:"protocol"`
	TrafficRatio  *float64 `json:"trafficRatio"`
	TCPListenAddr string   `json:"tcpListenAddr"`
	UDPListenAddr string   `json:"udpListenAddr"`
	InterfaceName string   `json:"interfaceName"`
}

// TunnelUpdateDto 更新隧道请求
type TunnelUpdateDto struct {
	ID            uint     `json:"id" binding:"required"`
	Name          *string  `json:"name"`
	InNodeID      *uint    `json:"inNodeId"`
	OutNodeID     *uint    `json:"outNodeId"`
	Type          *int     `json:"type"`
	Flow          *int     `json:"flow"`
	Protocol      *string  `json:"protocol"`
	TrafficRatio  *float64 `json:"trafficRatio"`
	TCPListenAddr *string  `json:"tcpListenAddr"`
	UDPListenAddr *string  `json:"udpListenAddr"`
	InterfaceName *string  `json:"interfaceName"`
}

// UserTunnelDto 分配用户隧道请求
type UserTunnelDto struct {
	UserID        uint  `json:"userId" binding:"required"`
	TunnelID      uint  `json:"tunnelId" binding:"required"`
	ExpTime       int64 `json:"expTime"`
	Flow          int64 `json:"flow"`
	FlowResetTime int64 `json:"flowResetTime"` // 0表示不重置
	Num           int   `json:"num"`
}

// UserTunnelQueryDto 查询用户隧道请求
type UserTunnelQueryDto struct {
	UserID   *uint `json:"userId"`
	TunnelID *uint `json:"tunnelId"`
}

// UserTunnelUpdateDto 更新用户隧道请求
type UserTunnelUpdateDto struct {
	ID            uint   `json:"id" binding:"required"`
	ExpTime       *int64 `json:"expTime"`
	Flow          *int64 `json:"flow"`
	FlowResetTime *int64 `json:"flowResetTime"`
	Num           *int   `json:"num"`
}

// UserTunnelResponseDto 用户隧道权限响应
type UserTunnelResponseDto struct {
	ID            uint   `json:"id"`
	UserID        uint   `json:"userId"`
	TunnelID      uint   `json:"tunnelId"`
	TunnelName    string `json:"tunnelName"`
	ExpTime       int64  `json:"expTime"`
	Flow          int64  `json:"flow"`
	InFlow        int64  `json:"inFlow"`
	OutFlow       int64  `json:"outFlow"`
	FlowResetTime int64  `json:"flowResetTime"`
	Num           int    `json:"num"`
	SpeedID       int    `json:"speedId"`
}
