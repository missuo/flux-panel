package handler

import (
	"flux-panel/service"
	"flux-panel/utils"
	"image/color"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/mojocn/base64Captcha"
	"gorm.io/gorm"
)

type CaptchaHandler struct {
	configService *service.ConfigService
}

// 验证码存储
var (
	captchaStore  = base64Captcha.DefaultMemStore
	captchaDriver = newSliderDriver()
	captchaMutex  sync.RWMutex
	// 二次验证 token 存储 (用于登录验证)
	validTokens      = make(map[string]int64) // token -> expireTime
	tokenCleanupOnce sync.Once
)

const (
	tokenExpireSeconds = 120 // 验证码有效期 120 秒
)

func NewCaptchaHandler(db *gorm.DB) *CaptchaHandler {
	// 启动 token 清理协程
	tokenCleanupOnce.Do(func() {
		go cleanupExpiredTokens()
	})

	return &CaptchaHandler{
		configService: service.NewConfigService(db),
	}
}

// newSliderDriver 创建滑块验证码驱动
func newSliderDriver() *base64Captcha.DriverString {
	return &base64Captcha.DriverString{
		Height:          80,
		Width:           240,
		NoiseCount:      0,
		ShowLineOptions: base64Captcha.OptionShowHollowLine,
		Length:          4,
		Source:          "1234567890abcdefghijklmnopqrstuvwxyz",
		BgColor: &color.RGBA{
			R: 240,
			G: 240,
			B: 240,
			A: 255,
		},
		Fonts: []string{"wqy-microhei.ttc"},
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
	// 获取验证码类型配置
	captchaType := "STRING"
	config, err := h.configService.GetConfigByName("captcha_type")
	if err == nil && config.Value != "" && config.Value != "RANDOM" {
		captchaType = config.Value
	}

	var driver base64Captcha.Driver

	switch captchaType {
	case "SLIDER":
		// 使用数字验证码模拟滑块
		driver = base64Captcha.NewDriverDigit(80, 240, 4, 0.7, 80)
	case "MATH":
		// 数学运算验证码
		driver = base64Captcha.NewDriverMath(80, 240, 0, base64Captcha.OptionShowHollowLine, nil, nil, []string{"wqy-microhei.ttc"})
	default:
		// 默认字符验证码
		driver = captchaDriver
	}

	captcha := base64Captcha.NewCaptcha(driver, captchaStore)
	id, b64s, _, err := captcha.Generate()
	if err != nil {
		c.JSON(200, gin.H{
			"success": false,
			"message": "生成验证码失败",
		})
		return
	}

	c.JSON(200, gin.H{
		"success": true,
		"code":    0,
		"data": gin.H{
			"id":              id,
			"captchaType":     captchaType,
			"backgroundImage": b64s,
			"sliderImage":     "",
		},
	})
}

// VerifyRequest 验证请求
type VerifyRequest struct {
	ID   string `json:"id"`
	Data struct {
		Answer string `json:"answer"` // 用户输入的答案
	} `json:"data"`
}

// Verify 验证验证码
func (h *CaptchaHandler) Verify(c *gin.Context) {
	var req VerifyRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(200, gin.H{
			"success": false,
			"code":    1,
			"message": "参数错误",
		})
		return
	}

	// 验证验证码
	if !captchaStore.Verify(req.ID, req.Data.Answer, true) {
		c.JSON(200, gin.H{
			"success": false,
			"code":    1,
			"message": "验证码错误",
		})
		return
	}

	// 存储验证成功的 token，用于登录时二次验证
	storeValidToken(req.ID)

	c.JSON(200, gin.H{
		"success": true,
		"code":    0,
		"data": gin.H{
			"validToken": req.ID,
		},
	})
}

// ValidateCaptchaToken 验证 captcha token（供登录使用）
func ValidateCaptchaToken(captchaID string) bool {
	if captchaID == "" {
		return false
	}

	captchaMutex.RLock()
	expireTime, exists := validTokens[captchaID]
	captchaMutex.RUnlock()

	if !exists {
		return false
	}

	// 检查是否过期
	if time.Now().Unix() > expireTime {
		// 删除过期 token
		captchaMutex.Lock()
		delete(validTokens, captchaID)
		captchaMutex.Unlock()
		return false
	}

	// 验证成功后删除 token（一次性使用）
	captchaMutex.Lock()
	delete(validTokens, captchaID)
	captchaMutex.Unlock()

	return true
}

// storeValidToken 存储已验证的 token
func storeValidToken(captchaID string) {
	captchaMutex.Lock()
	defer captchaMutex.Unlock()

	expireTime := time.Now().Unix() + tokenExpireSeconds
	validTokens[captchaID] = expireTime
}

// cleanupExpiredTokens 清理过期的 token
func cleanupExpiredTokens() {
	ticker := time.NewTicker(time.Minute)
	for range ticker.C {
		now := time.Now().Unix()

		captchaMutex.Lock()
		for id, expireTime := range validTokens {
			if now > expireTime {
				delete(validTokens, id)
			}
		}
		captchaMutex.Unlock()
	}
}
