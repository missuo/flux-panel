package dto

// ForwardDto 创建转发请求
type ForwardDto struct {
	UserID        int    `json:"user_id"`
	UserName      string `json:"user_name"`
	Name          string `json:"name" binding:"required"`
	TunnelID      int    `json:"tunnel_id" binding:"required"`
	InPort        int    `json:"in_port" binding:"required"`
	OutPort       int    `json:"out_port" binding:"required"`
	RemoteAddr    string `json:"remote_addr" binding:"required"`
	InterfaceName string `json:"interface_name"`
	Strategy      string `json:"strategy"`
}

// ForwardUpdateDto 更新转发请求
type ForwardUpdateDto struct {
	ID            uint    `json:"id" binding:"required"`
	Name          *string `json:"name"`
	InPort        *int    `json:"in_port"`
	OutPort       *int    `json:"out_port"`
	RemoteAddr    *string `json:"remote_addr"`
	InterfaceName *string `json:"interface_name"`
	Strategy      *string `json:"strategy"`
}
