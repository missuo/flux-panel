package dto

// SpeedLimitDto 创建限速规则请求
type SpeedLimitDto struct {
	Name       string `json:"name" binding:"required"`
	Speed      int    `json:"speed" binding:"required"`
	TunnelID   int64  `json:"tunnelId" binding:"required"`
	TunnelName string `json:"tunnelName" binding:"required"`
}

// SpeedLimitUpdateDto 更新限速规则请求
type SpeedLimitUpdateDto struct {
	ID         uint   `json:"id" binding:"required"`
	Name       string `json:"name" binding:"required"`
	Speed      int    `json:"speed" binding:"required"`
	TunnelID   int64  `json:"tunnelId" binding:"required"`
	TunnelName string `json:"tunnelName" binding:"required"`
}
