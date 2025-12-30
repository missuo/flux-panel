package handler

import (
	"encoding/json"
	"flux-panel/dto"
	"flux-panel/models"
	"log"
	"strings"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

type FlowHandler struct {
	db *gorm.DB
}

// 用于同步相同用户和隧道的流量更新操作
var (
	userLocks    = make(map[string]*sync.Mutex)
	tunnelLocks  = make(map[string]*sync.Mutex)
	forwardLocks = make(map[string]*sync.Mutex)
	locksMutex   sync.Mutex
)

const (
	successResponse     = "ok"
	defaultUserTunnelID = "0"
	bytesToGB           = 1024 * 1024 * 1024
)

func NewFlowHandler(db *gorm.DB) *FlowHandler {
	return &FlowHandler{db: db}
}

// Config 接收节点配置数据
func (h *FlowHandler) Config(c *gin.Context) {
	secret := c.Query("secret")

	// 验证节点
	var node models.Node
	if err := h.db.Where("secret = ?", secret).First(&node).Error; err != nil {
		c.String(200, successResponse)
		return
	}

	// 读取原始数据
	rawData, err := c.GetRawData()
	if err != nil {
		c.String(200, successResponse)
		return
	}

	// 解析配置数据
	var gostConfig dto.GostConfigDto
	if err := json.Unmarshal(rawData, &gostConfig); err != nil {
		log.Printf("解析节点 %d 配置数据失败: %v", node.ID, err)
		c.String(200, successResponse)
		return
	}

	// TODO: 实际的配置清理逻辑
	log.Printf("节点 %d 配置数据接收成功", node.ID)

	c.String(200, successResponse)
}

// Test 测试接口
func (h *FlowHandler) Test(c *gin.Context) {
	c.String(200, "test")
}

// Upload 处理流量数据上报
func (h *FlowHandler) Upload(c *gin.Context) {
	secret := c.Query("secret")

	// 验证节点
	var nodeCount int64
	h.db.Model(&models.Node{}).Where("secret = ?", secret).Count(&nodeCount)
	if nodeCount == 0 {
		c.String(200, successResponse)
		return
	}

	// 读取原始数据
	rawData, err := c.GetRawData()
	if err != nil {
		c.String(200, successResponse)
		return
	}

	// 解析流量数据
	var flowData dto.FlowDto
	if err := json.Unmarshal(rawData, &flowData); err != nil {
		log.Printf("解析流量数据失败: %v", err)
		c.String(200, successResponse)
		return
	}

	// 跳过web_api
	if flowData.N == "web_api" {
		c.String(200, successResponse)
		return
	}

	log.Printf("节点上报流量数据: %+v", flowData)

	// 处理流量数据
	h.processFlowData(&flowData)

	c.String(200, successResponse)
}

func (h *FlowHandler) processFlowData(flowData *dto.FlowDto) {
	// 解析服务名称
	parts := strings.Split(flowData.N, "_")
	if len(parts) < 3 {
		return
	}

	forwardID := parts[0]
	userID := parts[1]
	userTunnelID := parts[2]

	// 获取转发信息
	var forward models.Forward
	if err := h.db.First(&forward, forwardID).Error; err != nil {
		return
	}

	// 获取流量计费类型
	flowType := h.getFlowType(&forward)

	// 获取流量倍率
	var tunnel models.Tunnel
	trafficRatio := 1.0
	if err := h.db.First(&tunnel, forward.TunnelID).Error; err == nil {
		trafficRatio = tunnel.TrafficRatio
	}

	// 计算流量
	inFlow := int64(float64(flowData.D) * trafficRatio * float64(flowType))
	outFlow := int64(float64(flowData.U) * trafficRatio * float64(flowType))

	// 更新转发流量
	h.updateForwardFlow(forwardID, inFlow, outFlow)

	// 更新用户流量
	h.updateUserFlow(userID, inFlow, outFlow)

	// 更新用户隧道流量
	h.updateUserTunnelFlow(userTunnelID, inFlow, outFlow)

	// 非管理员转发检查限制
	if userTunnelID != defaultUserTunnelID {
		h.checkUserLimits(userID)
		h.checkUserTunnelLimits(userTunnelID, userID)
	}
}

func (h *FlowHandler) getFlowType(forward *models.Forward) int {
	defaultFlowType := 2
	var tunnel models.Tunnel
	if err := h.db.First(&tunnel, forward.TunnelID).Error; err != nil {
		return defaultFlowType
	}
	return tunnel.Flow
}

func (h *FlowHandler) updateForwardFlow(forwardID string, inFlow, outFlow int64) {
	lock := getLock(forwardLocks, forwardID)
	lock.Lock()
	defer lock.Unlock()

	h.db.Model(&models.Forward{}).Where("id = ?", forwardID).
		UpdateColumns(map[string]interface{}{
			"in_flow":  gorm.Expr("in_flow + ?", inFlow),
			"out_flow": gorm.Expr("out_flow + ?", outFlow),
		})
}

func (h *FlowHandler) updateUserFlow(userID string, inFlow, outFlow int64) {
	lock := getLock(userLocks, userID)
	lock.Lock()
	defer lock.Unlock()

	h.db.Model(&models.User{}).Where("id = ?", userID).
		UpdateColumns(map[string]interface{}{
			"in_flow":  gorm.Expr("in_flow + ?", inFlow),
			"out_flow": gorm.Expr("out_flow + ?", outFlow),
		})
}

func (h *FlowHandler) updateUserTunnelFlow(userTunnelID string, inFlow, outFlow int64) {
	if userTunnelID == defaultUserTunnelID {
		return
	}

	lock := getLock(tunnelLocks, userTunnelID)
	lock.Lock()
	defer lock.Unlock()

	h.db.Model(&models.UserTunnel{}).Where("id = ?", userTunnelID).
		UpdateColumns(map[string]interface{}{
			"in_flow":  gorm.Expr("in_flow + ?", inFlow),
			"out_flow": gorm.Expr("out_flow + ?", outFlow),
		})
}

func (h *FlowHandler) checkUserLimits(userID string) {
	var user models.User
	if err := h.db.First(&user, userID).Error; err != nil {
		return
	}

	// 检查流量限制
	userFlowLimit := user.Flow * bytesToGB
	userCurrentFlow := user.InFlow + user.OutFlow
	if userFlowLimit < userCurrentFlow {
		h.pauseUserServices(userID)
		return
	}

	// 检查到期时间
	if user.ExpTime > 0 && user.ExpTime <= time.Now().UnixMilli() {
		h.pauseUserServices(userID)
		return
	}

	// 检查用户状态
	if user.Status != 1 {
		h.pauseUserServices(userID)
	}
}

func (h *FlowHandler) checkUserTunnelLimits(userTunnelID, userID string) {
	var userTunnel models.UserTunnel
	if err := h.db.First(&userTunnel, userTunnelID).Error; err != nil {
		return
	}

	// 检查流量限制
	flow := userTunnel.InFlow + userTunnel.OutFlow
	if flow >= userTunnel.Flow*bytesToGB {
		h.pauseTunnelServices(userTunnel.TunnelID, userID)
		return
	}

	// 检查到期时间
	if userTunnel.ExpTime > 0 && userTunnel.ExpTime <= time.Now().UnixMilli() {
		h.pauseTunnelServices(userTunnel.TunnelID, userID)
	}
}

func (h *FlowHandler) pauseUserServices(userID string) {
	// TODO: 实际的暂停服务逻辑，需要与Gost交互
	var forwards []models.Forward
	h.db.Where("user_id = ?", userID).Find(&forwards)

	for _, forward := range forwards {
		h.db.Model(&models.Forward{}).Where("id = ?", forward.ID).Update("status", 0)
	}
}

func (h *FlowHandler) pauseTunnelServices(tunnelID uint, userID string) {
	// TODO: 实际的暂停服务逻辑，需要与Gost交互
	var forwards []models.Forward
	h.db.Where("tunnel_id = ? AND user_id = ?", tunnelID, userID).Find(&forwards)

	for _, forward := range forwards {
		h.db.Model(&models.Forward{}).Where("id = ?", forward.ID).Update("status", 0)
	}
}

func getLock(locks map[string]*sync.Mutex, key string) *sync.Mutex {
	locksMutex.Lock()
	defer locksMutex.Unlock()

	if lock, exists := locks[key]; exists {
		return lock
	}

	lock := &sync.Mutex{}
	locks[key] = lock
	return lock
}
