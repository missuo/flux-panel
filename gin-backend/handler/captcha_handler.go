package handler

import (
	"flux-panel/service"
	"flux-panel/utils"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

type CaptchaHandler struct {
	configService *service.ConfigService
}

func NewCaptchaHandler(db *gorm.DB) *CaptchaHandler {
	return &CaptchaHandler{
		configService: service.NewConfigService(db),
	}
}

// Check 检查是否启用验证码
func (h *CaptchaHandler) Check(c *gin.Context) {
	config, err := h.configService.GetConfigByName("captcha_enabled")
	if err != nil || config.Value != "true" {
		utils.Success(c, 0)
		return
	}
	utils.Success(c, 1)
}

// Generate 生成验证码
func (h *CaptchaHandler) Generate(c *gin.Context) {
	// TODO: 实际的验证码生成逻辑
	// 暂时返回一个模拟的验证码响应
	c.JSON(200, gin.H{
		"success": true,
		"data": gin.H{
			"id":            "mock-captcha-id",
			"captchaType":   "SLIDER",
			"backgroundImage": "",
			"sliderImage":   "",
		},
	})
}

// Verify 验证验证码
func (h *CaptchaHandler) Verify(c *gin.Context) {
	var req map[string]interface{}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(200, gin.H{
			"success": false,
			"message": "参数错误",
		})
		return
	}

	// TODO: 实际的验证码验证逻辑
	// 暂时返回验证成功
	id, _ := req["id"].(string)
	c.JSON(200, gin.H{
		"success": true,
		"data": gin.H{
			"validToken": id,
		},
	})
}
