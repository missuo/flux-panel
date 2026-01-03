package dto

// LoginDto 登录请求
type LoginDto struct {
	Username  string `json:"username" binding:"required"`
	Password  string `json:"password" binding:"required"`
	CaptchaId string `json:"captchaId"`
}

// UserDto 创建用户请求
type UserDto struct {
	User          string `json:"user" binding:"required"`
	Pwd           string `json:"pwd" binding:"required"`
	Flow          int64  `json:"flow" binding:"required"`
	Num           int    `json:"num" binding:"required"`
	ExpTime       int64  `json:"expTime" binding:"required"`
	FlowResetTime int64  `json:"flowResetTime" binding:"required"`
	Status        *int   `json:"status"`
}

// UserUpdateDto 更新用户请求
type UserUpdateDto struct {
	ID            uint   `json:"id" binding:"required"`
	User          string `json:"user" binding:"required"`
	Pwd           string `json:"pwd"`
	Flow          int64  `json:"flow" binding:"required"`
	Num           int    `json:"num" binding:"required"`
	ExpTime       int64  `json:"expTime" binding:"required"`
	FlowResetTime int64  `json:"flowResetTime" binding:"required"`
	Status        *int   `json:"status"`
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
