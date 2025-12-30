package handler

import (
	"crypto/md5"
	"encoding/hex"
	"flux-panel/models"
	"fmt"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

type OpenApiHandler struct {
	db *gorm.DB
}

func NewOpenApiHandler(db *gorm.DB) *OpenApiHandler {
	return &OpenApiHandler{db: db}
}

// SubStore 订阅信息接口
func (h *OpenApiHandler) SubStore(c *gin.Context) {
	user := c.Query("user")
	pwd := c.Query("pwd")
	tunnel := c.DefaultQuery("tunnel", "-1")

	// 校验参数
	if user == "" {
		c.JSON(200, gin.H{"code": 1, "msg": "用户不能为空"})
		return
	}
	if pwd == "" {
		c.JSON(200, gin.H{"code": 1, "msg": "密码不能为空"})
		return
	}

	// 查询用户
	var userInfo models.User
	if err := h.db.Where("user = ?", user).First(&userInfo).Error; err != nil {
		c.JSON(200, gin.H{"code": 1, "msg": "鉴权失败"})
		return
	}

	// 验证密码
	pwdMd5 := md5Hash(pwd)
	if pwdMd5 != userInfo.Pwd {
		c.JSON(200, gin.H{"code": 1, "msg": "鉴权失败"})
		return
	}

	const GIGA int64 = 1024 * 1024 * 1024
	var headerValue string

	if tunnel == "-1" {
		// 返回用户总流量信息
		headerValue = buildSubscriptionHeader(
			userInfo.OutFlow,
			userInfo.InFlow,
			userInfo.Flow*GIGA,
			userInfo.ExpTime/1000,
		)
	} else {
		// 查询用户隧道信息
		var tunnelInfo models.UserTunnel
		if err := h.db.Where("id = ?", tunnel).First(&tunnelInfo).Error; err != nil {
			c.JSON(200, gin.H{"code": 1, "msg": "隧道不存在"})
			return
		}

		// 验证隧道所属
		if tunnelInfo.UserID != userInfo.ID {
			c.JSON(200, gin.H{"code": 1, "msg": "隧道不存在"})
			return
		}

		headerValue = buildSubscriptionHeader(
			tunnelInfo.OutFlow,
			tunnelInfo.InFlow,
			tunnelInfo.Flow*GIGA,
			tunnelInfo.ExpTime/1000,
		)
	}

	c.Header("subscription-userinfo", headerValue)
	c.String(200, headerValue)
}

func md5Hash(text string) string {
	hash := md5.Sum([]byte(text))
	return hex.EncodeToString(hash[:])
}

func buildSubscriptionHeader(upload, download, total, expire int64) string {
	return fmt.Sprintf("upload=%d; download=%d; total=%d; expire=%d", download, upload, total, expire)
}
