package handler

import (
	"encoding/json"
	"flux-panel/dto"
	"flux-panel/models"
	"flux-panel/service"
	"flux-panel/utils"
	"log"
	"strconv"
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

	// 异步清理孤立配置
	go h.cleanOrphanedConfigs(node.ID, &gostConfig)

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

	// 解密数据（如果加密）
	decryptedData, err := h.decryptIfNeeded(rawData, secret)
	if err != nil {
		log.Printf("解密数据失败: %v", err)
		c.String(200, successResponse)
		return
	}

	// 解析流量数据
	var flowData dto.FlowDto
	if err := json.Unmarshal(decryptedData, &flowData); err != nil {
		log.Printf("解析流量数据失败: %v", err)
		c.String(200, successResponse)
		return
	}

	// 跳过 web_api
	if flowData.N == "web_api" {
		c.String(200, successResponse)
		return
	}

	log.Printf("节点 %d 上报流量数据: %+v", node.ID, flowData)

	// 处理流量数据
	h.processFlowData(&flowData)

	c.String(200, successResponse)
}

// decryptIfNeeded 检测并解密加密消息
func (h *FlowHandler) decryptIfNeeded(rawData []byte, secret string) ([]byte, error) {
	// 尝试解析为加密消息
	var encMsg dto.EncryptedMessage
	if err := json.Unmarshal(rawData, &encMsg); err != nil {
		// 不是加密消息格式，直接返回原始数据
		return rawData, nil
	}

	// 检查是否标记为加密
	if !encMsg.Encrypted || encMsg.Data == "" {
		return rawData, nil
	}

	// 获取加密器并解密
	crypto, err := utils.GetOrCreateCrypto(secret)
	if err != nil {
		return nil, err
	}

	decrypted, err := crypto.DecryptString(encMsg.Data)
	if err != nil {
		return nil, err
	}

	return []byte(decrypted), nil
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
		h.checkUserLimits(userID, flowData.N)
		h.checkUserTunnelLimits(userTunnelID, userID, flowData.N)
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

func (h *FlowHandler) checkUserLimits(userID, serviceName string) {
	var user models.User
	if err := h.db.First(&user, userID).Error; err != nil {
		return
	}

	// 检查流量限制
	userFlowLimit := user.Flow * bytesToGB
	userCurrentFlow := user.InFlow + user.OutFlow
	if userFlowLimit < userCurrentFlow {
		h.pauseUserServices(userID, serviceName)
		return
	}

	// 检查到期时间
	if user.ExpTime > 0 && user.ExpTime <= time.Now().UnixMilli() {
		h.pauseUserServices(userID, serviceName)
		return
	}

	// 检查用户状态
	if user.Status != 1 {
		h.pauseUserServices(userID, serviceName)
	}
}

func (h *FlowHandler) checkUserTunnelLimits(userTunnelID, userID, serviceName string) {
	var userTunnel models.UserTunnel
	if err := h.db.First(&userTunnel, userTunnelID).Error; err != nil {
		return
	}

	// 检查流量限制
	flow := userTunnel.InFlow + userTunnel.OutFlow
	if flow >= userTunnel.Flow*bytesToGB {
		h.pauseTunnelServices(userTunnel.TunnelID, userID, serviceName)
		return
	}

	// 检查到期时间
	if userTunnel.ExpTime > 0 && userTunnel.ExpTime <= time.Now().UnixMilli() {
		h.pauseTunnelServices(userTunnel.TunnelID, userID, serviceName)
		return
	}

	// 检查隧道状态
	if userTunnel.Status != 1 {
		h.pauseTunnelServices(userTunnel.TunnelID, userID, serviceName)
	}
}

func (h *FlowHandler) pauseUserServices(userID, serviceName string) {
	var forwards []models.Forward
	h.db.Where("user_id = ?", userID).Find(&forwards)

	h.pauseForwards(forwards, serviceName)
}

func (h *FlowHandler) pauseTunnelServices(tunnelID uint, userID, serviceName string) {
	var forwards []models.Forward
	h.db.Where("tunnel_id = ? AND user_id = ?", tunnelID, userID).Find(&forwards)

	h.pauseForwards(forwards, serviceName)
}

func (h *FlowHandler) pauseForwards(forwards []models.Forward, serviceName string) {
	for _, forward := range forwards {
		var tunnel models.Tunnel
		if err := h.db.First(&tunnel, forward.TunnelID).Error; err != nil {
			continue
		}

		// ... (Inside pauseForwards)
		// 暂停入口节点服务
		service.PauseService(uint(tunnel.InNodeID), serviceName)

		// 隧道类型(2)也需要暂停出口节点
		if tunnel.Type == 2 {
			service.PauseRemoteService(uint(tunnel.OutNodeID), serviceName)
		}

		// 更新转发状态
		h.db.Model(&models.Forward{}).Where("id = ?", forward.ID).Update("status", 0)
	}
}

// cleanOrphanedConfigs 清理孤立的 Gost 配置
func (h *FlowHandler) cleanOrphanedConfigs(nodeID uint, gostConfig *dto.GostConfigDto) {
	// 清理孤立的服务
	for _, svc := range gostConfig.Services {
		if svc.Name == "web_api" {
			continue
		}

		parts := strings.Split(svc.Name, "_")
		if len(parts) < 4 {
			continue
		}

		forwardID := parts[0]
		userID := parts[1]
		userTunnelID := parts[2]
		serviceType := parts[3]

		var forward models.Forward
		if err := h.db.First(&forward, forwardID).Error; err != nil {
			// 转发不存在，删除服务
			serviceName := forwardID + "_" + userID + "_" + userTunnelID
			if serviceType == "tcp" || serviceType == "udp" {
				service.DeleteService(nodeID, serviceName)
			} else if serviceType == "tls" {
				service.DeleteRemoteService(nodeID, serviceName)
			}
			log.Printf("删除孤立的服务: %s (节点: %d)", svc.Name, nodeID)
		}
	}

	// 清理孤立的链
	for _, chain := range gostConfig.Chains {
		parts := strings.Split(chain.Name, "_")
		if len(parts) < 4 {
			continue
		}

		forwardID := parts[0]

		var forward models.Forward
		if err := h.db.First(&forward, forwardID).Error; err != nil {
			service.DeleteChains(nodeID, chain.Name)
			log.Printf("删除孤立的链: %s (节点: %d)", chain.Name, nodeID)
		}
	}

	// 清理孤立的限流器
	for _, limiter := range gostConfig.Limiters {
		limiterID, err := strconv.ParseUint(limiter.Name, 10, 64)
		if err != nil {
			continue
		}

		var speedLimit models.SpeedLimit
		if err := h.db.First(&speedLimit, limiterID).Error; err != nil {
			service.DeleteLimiters(nodeID, uint(limiterID))
			log.Printf("删除孤立的限流器: %s (节点: %d)", limiter.Name, nodeID)
		}
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
