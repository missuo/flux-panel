package handler

import (
	"flux-panel/dto"
	"flux-panel/service"
	"flux-panel/utils"
	"strconv"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

type NodeHandler struct {
	service *service.NodeService
}

func NewNodeHandler(db *gorm.DB) *NodeHandler {
	return &NodeHandler{
		service: service.NewNodeService(db),
	}
}

// CreateNode 创建节点
func (h *NodeHandler) CreateNode(c *gin.Context) {
	var nodeDto dto.NodeDto
	if err := c.ShouldBindJSON(&nodeDto); err != nil {
		utils.Error(c, "参数错误")
		return
	}

	if err := h.service.CreateNode(&nodeDto); err != nil {
		utils.Error(c, err.Error())
		return
	}

	utils.Success(c, nil)
}

// GetAllNodes 获取所有节点
func (h *NodeHandler) GetAllNodes(c *gin.Context) {
	nodes, err := h.service.GetAllNodes()
	if err != nil {
		utils.Error(c, err.Error())
		return
	}

	utils.Success(c, nodes)
}

// UpdateNode 更新节点
func (h *NodeHandler) UpdateNode(c *gin.Context) {
	var updateDto dto.NodeUpdateDto
	if err := c.ShouldBindJSON(&updateDto); err != nil {
		utils.Error(c, "参数错误")
		return
	}

	if err := h.service.UpdateNode(&updateDto); err != nil {
		utils.Error(c, err.Error())
		return
	}

	utils.Success(c, nil)
}

// DeleteNode 删除节点
func (h *NodeHandler) DeleteNode(c *gin.Context) {
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

	if err := h.service.DeleteNode(uint(id)); err != nil {
		utils.Error(c, err.Error())
		return
	}

	utils.Success(c, nil)
}

// GetInstallCommand 获取安装命令
func (h *NodeHandler) GetInstallCommand(c *gin.Context) {
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

	command, err := h.service.GetInstallCommand(uint(id))
	if err != nil {
		utils.Error(c, err.Error())
		return
	}

	utils.Success(c, command)
}

// CheckNodeStatus 检查节点状态
func (h *NodeHandler) CheckNodeStatus(c *gin.Context) {
	var req map[string]interface{}
	c.ShouldBindJSON(&req)

	var nodeID *uint
	if id, ok := req["nodeId"]; ok {
		idVal := parseNodeID(id)
		nodeID = &idVal
	}

	result, err := h.service.CheckNodeStatus(nodeID)
	if err != nil {
		utils.Error(c, err.Error())
		return
	}

	utils.Success(c, result)
}

func parseNodeID(val interface{}) uint {
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
