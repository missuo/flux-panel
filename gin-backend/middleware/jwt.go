package middleware

import (
	"flux-panel/utils"
	"strings"

	"github.com/gin-gonic/gin"
)

// JWTAuth JWT认证中间件
func JWTAuth() gin.HandlerFunc {
	return func(c *gin.Context) {
		token := c.GetHeader("Authorization")

		if token == "" {
			utils.Unauthorized(c, "未登录或token已过期")
			return
		}

		// 移除Bearer前缀（如果有）
		token = strings.TrimPrefix(token, "Bearer ")

		// 验证token
		claims, err := utils.ParseToken(token)
		if err != nil {
			utils.Unauthorized(c, "无效的token或token已过期")
			return
		}

		// 将用户信息存入上下文
		c.Set("user_id", claims.UserID)
		c.Set("user", claims.User)
		c.Set("role_id", claims.RoleID)

		c.Next()
	}
}

// RequireRole 角色验证中间件（仅管理员可访问）
func RequireRole() gin.HandlerFunc {
	return func(c *gin.Context) {
		roleID, exists := c.Get("role_id")
		if !exists {
			utils.Unauthorized(c, "无权限访问")
			return
		}

		// 检查是否为管理员 (roleId == 1)
		if roleID.(int) != 1 {
			utils.Unauthorized(c, "无权限访问")
			return
		}

		c.Next()
	}
}
