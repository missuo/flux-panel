package handler

import (
	"flux-panel/dto"
	"flux-panel/service"
	"flux-panel/utils"
	"strconv"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

type ForwardHandler struct {
	service *service.ForwardService
}

func NewForwardHandler(db *gorm.DB) *ForwardHandler {
	return &ForwardHandler{
		service: service.NewForwardService(db),
	}
}

// CreateForward 创建转发
func (h *ForwardHandler) CreateForward(c *gin.Context) {
	var forwardDto dto.ForwardDto
	if err := c.ShouldBindJSON(&forwardDto); err != nil {
		utils.Error(c, "参数错误")
		return
	}

	userID, _ := c.Get("user_id")
	userName, _ := c.Get("user")

	userIDInt := userID.(int)
	userNameStr := ""
	if userName != nil {
		userNameStr = userName.(string)
	}

	if err := h.service.CreateForward(userIDInt, userNameStr, &forwardDto); err != nil {
		utils.Error(c, err.Error())
		return
	}

	utils.Success(c, "转发创建成功")
}

// GetAllForwards 获取所有转发
func (h *ForwardHandler) GetAllForwards(c *gin.Context) {
	forwards, err := h.service.GetAllForwards()
	if err != nil {
		utils.Error(c, err.Error())
		return
	}
	utils.Success(c, forwards)
}

// UpdateForward 更新转发
func (h *ForwardHandler) UpdateForward(c *gin.Context) {
	var updateDto dto.ForwardUpdateDto
	if err := c.ShouldBindJSON(&updateDto); err != nil {
		utils.Error(c, "参数错误")
		return
	}

	if err := h.service.UpdateForward(&updateDto); err != nil {
		utils.Error(c, err.Error())
		return
	}

	utils.Success(c, "转发更新成功")
}

// DeleteForward 删除转发
func (h *ForwardHandler) DeleteForward(c *gin.Context) {
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

	if err := h.service.DeleteForward(id); err != nil {
		utils.Error(c, err.Error())
		return
	}

	utils.Success(c, "转发删除成功")
}

// ForceDeleteForward 强制删除转发
func (h *ForwardHandler) ForceDeleteForward(c *gin.Context) {
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

	if err := h.service.ForceDeleteForward(id); err != nil {
		utils.Error(c, err.Error())
		return
	}

	utils.Success(c, "转发强制删除成功")
}

// PauseForward 暂停转发
func (h *ForwardHandler) PauseForward(c *gin.Context) {
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

	if err := h.service.PauseForward(id); err != nil {
		utils.Error(c, err.Error())
		return
	}

	utils.Success(c, "转发已暂停")
}

// ResumeForward 恢复转发
func (h *ForwardHandler) ResumeForward(c *gin.Context) {
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

	if err := h.service.ResumeForward(id); err != nil {
		utils.Error(c, err.Error())
		return
	}

	utils.Success(c, "转发已恢复")
}

// DiagnoseForward 诊断转发
func (h *ForwardHandler) DiagnoseForward(c *gin.Context) {
	var req map[string]interface{}
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.Error(c, "参数错误")
		return
	}

	id := parseID(req["forwardId"])
	if id == 0 {
		utils.Error(c, "参数错误")
		return
	}

	result, err := h.service.DiagnoseForward(id)
	if err != nil {
		utils.Error(c, err.Error())
		return
	}

	utils.Success(c, result)
}

// UpdateForwardOrder 更新转发排序
func (h *ForwardHandler) UpdateForwardOrder(c *gin.Context) {
	var orderDto dto.ForwardOrderDto
	if err := c.ShouldBindJSON(&orderDto); err != nil {
		utils.Error(c, "参数错误")
		return
	}

	if err := h.service.UpdateForwardOrder(&orderDto); err != nil {
		utils.Error(c, err.Error())
		return
	}

	utils.Success(c, "排序更新成功")
}

// parseID 解析ID参数
func parseID(val interface{}) uint {
	if val == nil {
		return 0
	}
	switch v := val.(type) {
	case float64:
		return uint(v)
	case string:
		id, _ := strconv.ParseUint(v, 10, 32)
		return uint(id)
	case int:
		return uint(v)
	default:
		return 0
	}
}
