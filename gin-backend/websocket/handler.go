package websocket

import (
	"log"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/gorilla/websocket"
	"gorm.io/gorm"
)

// Handler WebSocket 处理器
type Handler struct {
	db       *gorm.DB
	upgrader websocket.Upgrader
}

// Node 节点模型（简化版，用于验证）
type Node struct {
	ID     uint   `gorm:"primaryKey"`
	Secret string `gorm:"column:secret"`
}

// NewHandler 创建新的 WebSocket 处理器
func NewHandler(db *gorm.DB) *Handler {
	return &Handler{
		db: db,
		upgrader: websocket.Upgrader{
			ReadBufferSize:  1024,
			WriteBufferSize: 1024,
			CheckOrigin: func(r *http.Request) bool {
				return true
			},
		},
	}
}

// HandleConnection 处理 WebSocket 连接
func (h *Handler) HandleConnection(c *gin.Context) {
	secret := c.Query("secret")
	if secret == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "缺少认证信息"})
		return
	}

	// 验证节点
	var node Node
	if err := h.db.Table("node").Where("secret = ?", secret).First(&node).Error; err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "节点认证失败"})
		return
	}

	// 升级为 WebSocket 连接
	conn, err := h.upgrader.Upgrade(c.Writer, c.Request, nil)
	if err != nil {
		log.Printf("WebSocket 升级失败: %v", err)
		return
	}

	// 添加到连接管理器
	GetServer().AddConnection(node.ID, conn)
}

// IsNodeConnected 检查节点是否已连接
func IsNodeConnected(nodeID uint) bool {
	return GetServer().GetConnection(nodeID) != nil
}
