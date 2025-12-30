package handler

import (
	"flux-panel/dto"
	"flux-panel/service"
	"flux-panel/utils"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

type SpeedLimitHandler struct {
	service *service.SpeedLimitService
}

func NewSpeedLimitHandler(db *gorm.DB) *SpeedLimitHandler {
	return &SpeedLimitHandler{
		service: service.NewSpeedLimitService(db),
	}
}

// CreateSpeedLimit 创建限速规则
func (h *SpeedLimitHandler) CreateSpeedLimit(c *gin.Context) {
	var limitDto dto.SpeedLimitDto
	if err := c.ShouldBindJSON(&limitDto); err != nil {
		utils.Error(c, "参数错误")
		return
	}

	if err := h.service.CreateSpeedLimit(&limitDto); err != nil {
		utils.Error(c, err.Error())
		return
	}

	utils.Success(c, "限速规则创建成功")
}

// GetAllSpeedLimits 获取所有限速规则
func (h *SpeedLimitHandler) GetAllSpeedLimits(c *gin.Context) {
	speedLimits, err := h.service.GetAllSpeedLimits()
	if err != nil {
		utils.Error(c, err.Error())
		return
	}
	utils.Success(c, speedLimits)
}

// UpdateSpeedLimit 更新限速规则
func (h *SpeedLimitHandler) UpdateSpeedLimit(c *gin.Context) {
	var updateDto dto.SpeedLimitUpdateDto
	if err := c.ShouldBindJSON(&updateDto); err != nil {
		utils.Error(c, "参数错误")
		return
	}

	if err := h.service.UpdateSpeedLimit(&updateDto); err != nil {
		utils.Error(c, err.Error())
		return
	}

	utils.Success(c, "限速规则更新成功")
}

// DeleteSpeedLimit 删除限速规则
func (h *SpeedLimitHandler) DeleteSpeedLimit(c *gin.Context) {
	var req map[string]interface{}
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.Error(c, "参数错误")
		return
	}

	id := parseID(req["id"])
	if id == 0 {
		utils.Error(c, "参数错误")
		return
	}

	if err := h.service.DeleteSpeedLimit(id); err != nil {
		utils.Error(c, err.Error())
		return
	}

	utils.Success(c, "限速规则删除成功")
}
