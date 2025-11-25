package utils

import (
	"net"
	"strings"

	"github.com/gin-gonic/gin"
)

// GetClientIP 获取客户端IP
func GetClientIP(c *gin.Context) string {
	// 尝试从各种头部获取真实IP
	ip := c.GetHeader("X-Real-IP")
	if ip != "" {
		return ip
	}

	ip = c.GetHeader("X-Forwarded-For")
	if ip != "" {
		// X-Forwarded-For 可能包含多个IP，取第一个
		ips := strings.Split(ip, ",")
		if len(ips) > 0 {
			return strings.TrimSpace(ips[0])
		}
	}

	// 如果都没有，使用RemoteAddr
	ip = c.ClientIP()
	return ip
}

// IsValidIP 验证IP是否有效
func IsValidIP(ip string) bool {
	return net.ParseIP(ip) != nil
}

// IsPrivateIP 判断是否为私有IP
func IsPrivateIP(ip string) bool {
	parsedIP := net.ParseIP(ip)
	if parsedIP == nil {
		return false
	}

	// 检查是否为私有IP段
	privateBlocks := []string{
		"10.0.0.0/8",
		"172.16.0.0/12",
		"192.168.0.0/16",
		"127.0.0.0/8",
	}

	for _, block := range privateBlocks {
		_, subnet, _ := net.ParseCIDR(block)
		if subnet.Contains(parsedIP) {
			return true
		}
	}

	return false
}
