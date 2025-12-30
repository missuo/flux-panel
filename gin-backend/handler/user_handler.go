package handler

import (
	"flux-panel/dto"
	"flux-panel/service"
	"flux-panel/utils"
	"strconv"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

type UserHandler struct {
	service *service.UserService
}

func NewUserHandler(db *gorm.DB) *UserHandler {
	return &UserHandler{
		service: service.NewUserService(db),
	}
}

// Login 用户登录
func (h *UserHandler) Login(c *gin.Context) {
	var loginDto dto.LoginDto
	if err := c.ShouldBindJSON(&loginDto); err != nil {
		utils.Error(c, "参数错误")
		return
	}

	data, err := h.service.Login(&loginDto)
	if err != nil {
		utils.Error(c, err.Error())
		return
	}

	utils.Success(c, data)
}

// CreateUser 创建用户
func (h *UserHandler) CreateUser(c *gin.Context) {
	var userDto dto.UserDto
	if err := c.ShouldBindJSON(&userDto); err != nil {
		utils.Error(c, "参数错误")
		return
	}

	if err := h.service.CreateUser(&userDto); err != nil {
		utils.Error(c, err.Error())
		return
	}

	utils.Success(c, nil)
}

// GetAllUsers 获取所有用户
func (h *UserHandler) GetAllUsers(c *gin.Context) {
	users, err := h.service.GetAllUsers()
	if err != nil {
		utils.Error(c, err.Error())
		return
	}

	utils.Success(c, users)
}

// UpdateUser 更新用户
func (h *UserHandler) UpdateUser(c *gin.Context) {
	var updateDto dto.UserUpdateDto
	if err := c.ShouldBindJSON(&updateDto); err != nil {
		utils.Error(c, "参数错误")
		return
	}

	if err := h.service.UpdateUser(&updateDto); err != nil {
		utils.Error(c, err.Error())
		return
	}

	utils.Success(c, nil)
}

// DeleteUser 删除用户
func (h *UserHandler) DeleteUser(c *gin.Context) {
	var req map[string]interface{}
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.Error(c, "参数错误")
		return
	}

	idStr, ok := req["id"].(string)
	if !ok {
		idFloat, ok := req["id"].(float64)
		if !ok {
			utils.Error(c, "参数错误")
			return
		}
		idStr = strconv.Itoa(int(idFloat))
	}

	id, err := strconv.ParseUint(idStr, 10, 32)
	if err != nil {
		utils.Error(c, "参数错误")
		return
	}

	if err := h.service.DeleteUser(uint(id)); err != nil {
		utils.Error(c, err.Error())
		return
	}

	utils.Success(c, nil)
}

// GetUserPackage 获取用户套餐信息
func (h *UserHandler) GetUserPackage(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		utils.Error(c, "未登录")
		return
	}

	packageInfo, err := h.service.GetUserPackageInfo(uint(userID.(int)))
	if err != nil {
		utils.Error(c, err.Error())
		return
	}

	utils.Success(c, packageInfo)
}

// UpdatePassword 修改密码
func (h *UserHandler) UpdatePassword(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		utils.Error(c, "未登录")
		return
	}

	var changeDto dto.ChangePasswordDto
	if err := c.ShouldBindJSON(&changeDto); err != nil {
		utils.Error(c, "参数错误")
		return
	}

	if err := h.service.UpdatePassword(uint(userID.(int)), &changeDto); err != nil {
		utils.Error(c, err.Error())
		return
	}

	utils.Success(c, nil)
}

// ResetFlow 重置流量
func (h *UserHandler) ResetFlow(c *gin.Context) {
	var resetDto dto.ResetFlowDto
	if err := c.ShouldBindJSON(&resetDto); err != nil {
		utils.Error(c, "参数错误")
		return
	}

	if err := h.service.ResetFlow(&resetDto); err != nil {
		utils.Error(c, err.Error())
		return
	}

	utils.Success(c, nil)
}
