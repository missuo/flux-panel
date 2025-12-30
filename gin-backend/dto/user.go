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
	Password      string `json:"password" binding:"required"`
	RoleID        int    `json:"role_id"`
	ExpTime       int64  `json:"exp_time"`
	Flow          int64  `json:"flow"`
	Num           int    `json:"num"`
	FlowResetTime int64  `json:"flow_reset_time"`
}

// UserUpdateDto 更新用户请求
type UserUpdateDto struct {
	ID            uint   `json:"id" binding:"required"`
	User          string `json:"user"`
	Password      string `json:"password"`
	RoleID        *int   `json:"role_id"`
	ExpTime       *int64 `json:"exp_time"`
	Flow          *int64 `json:"flow"`
	Num           *int   `json:"num"`
	FlowResetTime *int64 `json:"flow_reset_time"`
}

// ChangePasswordDto 修改密码请求
type ChangePasswordDto struct {
	OldPassword string `json:"old_password" binding:"required"`
	NewPassword string `json:"new_password" binding:"required"`
}

// ResetFlowDto 重置流量请求
type ResetFlowDto struct {
	ID   uint `json:"id" binding:"required"`
	Type int  `json:"type" binding:"required"`
}

// UserPackageDto 用户套餐信息响应
type UserPackageDto struct {
	User          string `json:"user"`
	ExpTime       int64  `json:"exp_time"`
	Flow          int64  `json:"flow"`
	UsedFlow      int64  `json:"used_flow"`
	InFlow        int64  `json:"in_flow"`
	OutFlow       int64  `json:"out_flow"`
	Num           int    `json:"num"`
	UsedNum       int    `json:"used_num"`
	FlowResetTime int64  `json:"flow_reset_time"`
}
