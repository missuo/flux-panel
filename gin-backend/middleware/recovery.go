package middleware

import (
	"flux-panel/utils"
	"fmt"
	"runtime/debug"

	"github.com/gin-gonic/gin"
)

// Recovery 错误恢复中间件
func Recovery() gin.HandlerFunc {
	return func(c *gin.Context) {
		defer func() {
			if err := recover(); err != nil {
				// 打印错误堆栈
				fmt.Printf("[Recovery] panic recovered:\n%s\n%s\n", err, debug.Stack())

				// 返回错误响应
				utils.ErrorWithCode(c, 500, "服务器内部错误")
			}
		}()
		c.Next()
	}
}
