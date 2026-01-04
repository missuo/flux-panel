package dto

// LoginDto 登录请求
type LoginDto struct {
	Username  string `json:"username" binding:"required"`
	Password  string `json:"password" binding:"required"`
	CaptchaId string `json:"captchaId"`
}

// TunnelAssignDto 隧道分配信息
type TunnelAssignDto struct {
	TunnelID      uint  `json:"tunnelId" binding:"required"`
	Flow          int64 `json:"flow"`
	ExpTime       int64 `json:"expTime"`
	FlowResetTime int64 `json:"flowResetTime"`
}

// UserDto 创建用户请求
type UserDto struct {
	User          string            `json:"user" binding:"required"`
	Pwd           string            `json:"pwd" binding:"required"`
	Flow          int64             `json:"flow"`
	Num           int               `json:"num"`
	ExpTime       int64             `json:"expTime"`
	FlowResetTime int64             `json:"flowResetTime"`
	Status        *int              `json:"status"`
	TunnelAssigns []TunnelAssignDto `json:"tunnelAssigns"` // 创建用户时分配的隧道
}

// UserUpdateDto 更新用户请求
type UserUpdateDto struct {
	ID            uint              `json:"id" binding:"required"`
	User          string            `json:"user" binding:"required"`
	Pwd           string            `json:"pwd"`
	Flow          int64             `json:"flow"`
	Num           int               `json:"num"`
	ExpTime       int64             `json:"expTime"`
	FlowResetTime int64             `json:"flowResetTime"`
	Status        *int              `json:"status"`
	TunnelAssigns []TunnelAssignDto `json:"tunnelAssigns"` // 更新用户时分配的隧道
}

// ChangePasswordDto 修改密码请求
type ChangePasswordDto struct {
	NewUsername     string `json:"newUsername" binding:"required"`
	CurrentPassword string `json:"currentPassword" binding:"required"`
	NewPassword     string `json:"newPassword" binding:"required"`
	ConfirmPassword string `json:"confirmPassword" binding:"required"`
}

// ResetFlowDto 重置流量请求
type ResetFlowDto struct {
	ID   uint `json:"id" binding:"required"`
	Type int  `json:"type" binding:"required"`
}

// ToggleUserStatusDto 切换用户状态请求
type ToggleUserStatusDto struct {
	ID uint `json:"id" binding:"required"`
}

// UserPackageDto 用户套餐信息响应
type UserPackageDto struct {
	User          string `json:"user"`
	ExpTime       int64  `json:"expTime"`
	Flow          int64  `json:"flow"`
	UsedFlow      int64  `json:"usedFlow"`
	InFlow        int64  `json:"inFlow"`
	OutFlow       int64  `json:"outFlow"`
	Num           int    `json:"num"`
	UsedNum       int    `json:"usedNum"`
	FlowResetTime int64  `json:"flowResetTime"`
}

// UserDashboardResponse 仪表盘聚合数据
type UserDashboardResponse struct {
	UserInfo          UserPackageDto               `json:"userInfo"`
	TunnelPermissions []DashboardUserTunnelDto     `json:"tunnelPermissions"`
	Forwards          []DashboardForwardDto        `json:"forwards"`
	StatisticsFlows   []DashboardStatisticsFlowDto `json:"statisticsFlows"`
}

// DashboardUserTunnelDto 仪表盘用户隧道信息
type DashboardUserTunnelDto struct {
	ID            uint   `json:"id"`
	TunnelID      uint   `json:"tunnelId"`
	TunnelName    string `json:"tunnelName"`
	Flow          int64  `json:"flow"`
	InFlow        int64  `json:"inFlow"`
	OutFlow       int64  `json:"outFlow"`
	Num           int    `json:"num"`
	ExpTime       int64  `json:"expTime"`
	FlowResetTime int64  `json:"flowResetTime"`
	TunnelFlow    int    `json:"tunnelFlow"`
}

// DashboardForwardDto 仪表盘转发信息
type DashboardForwardDto struct {
	ID         uint   `json:"id"`
	Name       string `json:"name"`
	TunnelID   uint   `json:"tunnelId"`
	TunnelName string `json:"tunnelName"`
	InIP       string `json:"inIp"`
	InPort     int    `json:"inPort"`
	RemoteAddr string `json:"remoteAddr"`
	InFlow     int64  `json:"inFlow"`
	OutFlow    int64  `json:"outFlow"`
}

// DashboardStatisticsFlowDto 仪表盘流量统计
type DashboardStatisticsFlowDto struct {
	ID        uint   `json:"id"`
	UserID    uint   `json:"userId"`
	Flow      int64  `json:"flow"`
	TotalFlow int64  `json:"totalFlow"`
	Time      string `json:"time"`
}
