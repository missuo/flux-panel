package websocket

import (
	"log"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/gorilla/websocket"
	"gorm.io/gorm"
)

// Handler WebSocket 处理器
type Handler struct {
	db       *gorm.DB
	upgrader websocket.Upgrader
}

// Node 节点模型（完整版，用于更新状态）
type Node struct {
	ID      uint    `gorm:"primaryKey"`
	Secret  string  `gorm:"column:secret"`
	Status  int     `gorm:"column:status"`
	Version *string `gorm:"column:version"`
	HTTP    *int    `gorm:"column:http"`
	TLS     *int    `gorm:"column:tls"`
	Socks   *int    `gorm:"column:socks"`
}

// TableName 指定表名
func (Node) TableName() string {
	return "node"
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

	// 获取额外参数
	version := c.Query("version")
	httpStr := c.Query("http")
	tlsStr := c.Query("tls")
	socksStr := c.Query("socks")

	// 验证节点
	var node Node
	if err := h.db.Where("secret = ?", secret).First(&node).Error; err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "节点认证失败"})
		return
	}

	log.Printf("节点 %d 尝试连接，版本: %s", node.ID, version)

	// 升级为 WebSocket 连接
	conn, err := h.upgrader.Upgrade(c.Writer, c.Request, nil)
	if err != nil {
		log.Printf("WebSocket 升级失败: %v", err)
		return
	}

	// 更新节点状态和参数
	updates := map[string]interface{}{}

	if version != "" {
		updates["version"] = version
	}
	if httpStr != "" {
		if httpVal, err := strconv.Atoi(httpStr); err == nil {
			updates["http"] = httpVal
		}
	}
	if tlsStr != "" {
		if tlsVal, err := strconv.Atoi(tlsStr); err == nil {
			updates["tls"] = tlsVal
		}
	}
	if socksStr != "" {
		if socksVal, err := strconv.Atoi(socksStr); err == nil {
			updates["socks"] = socksVal
		}
	}

	if err := h.db.Model(&Node{}).Where("id = ?", node.ID).Updates(updates).Error; err != nil {
		log.Printf("更新节点 %d 状态失败: %v", node.ID, err)
	} else {
		log.Printf("节点 %d 连接建立成功，状态更新为在线", node.ID)
	}

	// 添加到连接管理器，并设置断开回调
	nc := GetServer().AddConnection(node.ID, conn)

	// 设置连接断开时的回调
	go h.handleDisconnect(nc, node.ID)
}

// handleDisconnect 处理连接断开
func (h *Handler) handleDisconnect(nc *NodeConnection, nodeID uint) {
	// 等待连接关闭
	<-nc.Done

	// 检查是否还有其他连接
	if GetServer().GetConnection(nodeID) == nil {
		// 不再更新节点状态为离线
		log.Printf("节点 %d 已断开所有连接", nodeID)
	}
}

// IsNodeConnected 检查节点是否已连接
func IsNodeConnected(nodeID uint) bool {
	return GetServer().GetConnection(nodeID) != nil
}
