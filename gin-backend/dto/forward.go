package dto

// ForwardDto 创建转发请求
type ForwardDto struct {
	Name          string `json:"name" binding:"required"`
	TunnelID      int    `json:"tunnelId" binding:"required"`
	RemoteAddr    string `json:"remoteAddr" binding:"required"`
	Strategy      string `json:"strategy"`
	InPort        *int   `json:"inPort"`
	InterfaceName string `json:"interfaceName"`
}

// ForwardUpdateDto 更新转发请求
type ForwardUpdateDto struct {
	ID            uint   `json:"id" binding:"required"`
	Name          string `json:"name" binding:"required"`
	TunnelID      int    `json:"tunnelId" binding:"required"`
	RemoteAddr    string `json:"remoteAddr" binding:"required"`
	Strategy      string `json:"strategy"`
	InPort        *int   `json:"inPort"`
	InterfaceName string `json:"interfaceName"`
}

// ForwardOrderItem 转发排序项
type ForwardOrderItem struct {
	ID  uint `json:"id"`
	Inx int  `json:"inx"`
}

// ForwardOrderDto 转发排序请求
type ForwardOrderDto struct {
	Forwards []ForwardOrderItem `json:"forwards"`
}
