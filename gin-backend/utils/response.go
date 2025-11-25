package utils

import (
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
)

// Response 统一响应结构
type Response struct {
	Code int         `json:"code"`
	Msg  string      `json:"msg"`
	Ts   int64       `json:"ts"`
	Data interface{} `json:"data,omitempty"`
}

// Success 成功响应
func Success(c *gin.Context, data interface{}) {
	c.JSON(http.StatusOK, Response{
		Code: 0,
		Msg:  "操作成功",
		Ts:   time.Now().UnixMilli(),
		Data: data,
	})
}

// SuccessWithMsg 成功响应（自定义消息）
func SuccessWithMsg(c *gin.Context, msg string, data interface{}) {
	c.JSON(http.StatusOK, Response{
		Code: 0,
		Msg:  msg,
		Ts:   time.Now().UnixMilli(),
		Data: data,
	})
}

// Error 错误响应
func Error(c *gin.Context, msg string) {
	c.JSON(http.StatusOK, Response{
		Code: -1,
		Msg:  msg,
		Ts:   time.Now().UnixMilli(),
	})
}

// ErrorWithCode 错误响应（自定义错误码）
func ErrorWithCode(c *gin.Context, code int, msg string) {
	c.JSON(http.StatusOK, Response{
		Code: code,
		Msg:  msg,
		Ts:   time.Now().UnixMilli(),
	})
}

// Unauthorized 未授权响应
func Unauthorized(c *gin.Context, msg string) {
	c.JSON(http.StatusUnauthorized, Response{
		Code: 401,
		Msg:  msg,
		Ts:   time.Now().UnixMilli(),
	})
	c.Abort()
}
