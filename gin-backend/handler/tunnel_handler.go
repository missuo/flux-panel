package handler

import (
	"flux-panel/dto"
	"flux-panel/service"
	"flux-panel/utils"
	"strconv"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

type TunnelHandler struct {
	service *service.TunnelService
}

func NewTunnelHandler(db *gorm.DB) *TunnelHandler {
	return &TunnelHandler{
		service: service.NewTunnelService(db),
	}
}

// CreateTunnel 创建隧道
func (h *TunnelHandler) CreateTunnel(c *gin.Context) {
	var tunnelDto dto.TunnelDto
	if err := c.ShouldBindJSON(&tunnelDto); err != nil {
		utils.Error(c, "参数错误")
		return
	}

	if err := h.service.CreateTunnel(&tunnelDto); err != nil {
		utils.Error(c, err.Error())
		return
	}

	utils.Success(c, nil)
}

// GetAllTunnels 获取所有隧道
func (h *TunnelHandler) GetAllTunnels(c *gin.Context) {
	tunnels, err := h.service.GetAllTunnels()
	if err != nil {
		utils.Error(c, err.Error())
		return
	}

	utils.Success(c, tunnels)
}

// UpdateTunnel 更新隧道
func (h *TunnelHandler) UpdateTunnel(c *gin.Context) {
	var updateDto dto.TunnelUpdateDto
	if err := c.ShouldBindJSON(&updateDto); err != nil {
		utils.Error(c, "参数错误")
		return
	}

	if err := h.service.UpdateTunnel(&updateDto); err != nil {
		utils.Error(c, err.Error())
		return
	}

	utils.Success(c, nil)
}

// DeleteTunnel 删除隧道
func (h *TunnelHandler) DeleteTunnel(c *gin.Context) {
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

	if err := h.service.DeleteTunnel(uint(id)); err != nil {
		utils.Error(c, err.Error())
		return
	}

	utils.Success(c, nil)
}

// AssignUserTunnel 分配用户隧道权限
func (h *TunnelHandler) AssignUserTunnel(c *gin.Context) {
	var assignDto dto.UserTunnelDto
	if err := c.ShouldBindJSON(&assignDto); err != nil {
		utils.Error(c, "参数错误")
		return
	}

	if err := h.service.AssignUserTunnel(&assignDto); err != nil {
		utils.Error(c, err.Error())
		return
	}

	utils.Success(c, nil)
}

// GetUserTunnelList 获取用户隧道权限列表
func (h *TunnelHandler) GetUserTunnelList(c *gin.Context) {
	var queryDto dto.UserTunnelQueryDto
	if err := c.ShouldBindJSON(&queryDto); err != nil {
		utils.Error(c, "参数错误")
		return
	}

	userTunnels, err := h.service.GetUserTunnelList(&queryDto)
	if err != nil {
		utils.Error(c, err.Error())
		return
	}

	utils.Success(c, userTunnels)
}

// RemoveUserTunnel 移除用户隧道权限
func (h *TunnelHandler) RemoveUserTunnel(c *gin.Context) {
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

	if err := h.service.RemoveUserTunnel(uint(id)); err != nil {
		utils.Error(c, err.Error())
		return
	}

	utils.Success(c, nil)
}

// UpdateUserTunnel 更新用户隧道权限
func (h *TunnelHandler) UpdateUserTunnel(c *gin.Context) {
	var updateDto dto.UserTunnelUpdateDto
	if err := c.ShouldBindJSON(&updateDto); err != nil {
		utils.Error(c, "参数错误")
		return
	}

	if err := h.service.UpdateUserTunnel(&updateDto); err != nil {
		utils.Error(c, err.Error())
		return
	}

	utils.Success(c, nil)
}

// GetUserTunnels 获取用户可用的隧道
func (h *TunnelHandler) GetUserTunnels(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		utils.Error(c, "未登录")
		return
	}

	roleID, roleExists := c.Get("role_id")
	if roleExists && roleID.(int) == 0 {
		tunnels, err := h.service.GetAllTunnels()
		if err != nil {
			utils.Error(c, err.Error())
			return
		}
		utils.Success(c, tunnels)
		return
	}

	tunnels, err := h.service.GetUserTunnels(uint(userID.(int)))
	if err != nil {
		utils.Error(c, err.Error())
		return
	}

	utils.Success(c, tunnels)
}

// GetTunnelByID 根据ID获取隧道
func (h *TunnelHandler) GetTunnelByID(c *gin.Context) {
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

	tunnel, err := h.service.GetTunnelByID(id)
	if err != nil {
		utils.Error(c, err.Error())
		return
	}

	utils.Success(c, tunnel)
}

// DiagnoseTunnel 诊断隧道
func (h *TunnelHandler) DiagnoseTunnel(c *gin.Context) {
	var req map[string]interface{}
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.Error(c, "参数错误")
		return
	}

	var id uint
	var val interface{}
	var ok bool

	if val, ok = req["tunnelId"]; ok {
		// Found tunnelId
	} else if val, ok = req["id"]; ok {
		// Found id
	} else {
		utils.Error(c, "参数错误")
		return
	}

	// Parse ID
	if v, ok := val.(float64); ok {
		id = uint(v)
	} else if v, ok := val.(string); ok {
		if idUint, err := strconv.ParseUint(v, 10, 32); err == nil {
			id = uint(idUint)
		}
	}

	if id == 0 {
		utils.Error(c, "参数错误")
		return
	}

	result, err := h.service.DiagnoseTunnel(id)
	if err != nil {
		utils.Error(c, err.Error())
		return
	}

	utils.Success(c, result)
}
