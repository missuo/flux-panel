package handler

import (
	"flux-panel/service"
	"flux-panel/utils"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

type ConfigHandler struct {
	service *service.ConfigService
}

func NewConfigHandler(db *gorm.DB) *ConfigHandler {
	return &ConfigHandler{
		service: service.NewConfigService(db),
	}
}

// GetConfigs 获取所有配置
func (h *ConfigHandler) GetConfigs(c *gin.Context) {
	configs, err := h.service.GetConfigs()
	if err != nil {
		utils.Error(c, err.Error())
		return
	}
	utils.Success(c, configs)
}

// GetConfigByName 根据名称获取配置
func (h *ConfigHandler) GetConfigByName(c *gin.Context) {
	var req map[string]string
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.Error(c, "参数错误")
		return
	}

	name := req["name"]
	config, err := h.service.GetConfigByName(name)
	if err != nil {
		utils.Error(c, "配置不存在")
		return
	}
	utils.Success(c, config)
}

// UpdateConfigs 批量更新配置
func (h *ConfigHandler) UpdateConfigs(c *gin.Context) {
	var configMap map[string]string
	if err := c.ShouldBindJSON(&configMap); err != nil {
		utils.Error(c, "参数错误")
		return
	}

	if err := h.service.UpdateConfigs(configMap); err != nil {
		utils.Error(c, err.Error())
		return
	}
	utils.Success(c, "配置更新成功")
}

// UpdateConfig 更新单个配置
func (h *ConfigHandler) UpdateConfig(c *gin.Context) {
	var req map[string]string
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.Error(c, "参数错误")
		return
	}

	name := req["name"]
	value := req["value"]

	if err := h.service.UpdateConfig(name, value); err != nil {
		utils.Error(c, err.Error())
		return
	}
	utils.Success(c, "配置更新成功")
}
