package service

import (
	"errors"
	"flux-panel/dto"
	"flux-panel/models"
	"flux-panel/repository"
	"flux-panel/websocket"
	"time"

	"gorm.io/gorm"
)

type DiagnosisResult struct {
	NodeId      uint    `json:"nodeId"`
	NodeName    string  `json:"nodeName"`
	TargetIp    string  `json:"targetIp"`
	TargetPort  int     `json:"targetPort"`
	Description string  `json:"description"`
	Success     bool    `json:"success"`
	Message     string  `json:"message"`
	AverageTime float64 `json:"averageTime"`
	PacketLoss  float64 `json:"packetLoss"`
	Timestamp   int64   `json:"timestamp"`
}

type TunnelService struct {
	repo           *repository.TunnelRepository
	userTunnelRepo *repository.UserTunnelRepository
	nodeRepo       *repository.NodeRepository
	forwardRepo    *repository.ForwardRepository
}

func NewTunnelService(db *gorm.DB) *TunnelService {
	return &TunnelService{
		repo:           repository.NewTunnelRepository(db),
		userTunnelRepo: repository.NewUserTunnelRepository(db),
		nodeRepo:       repository.NewNodeRepository(db),
		forwardRepo:    repository.NewForwardRepository(db),
	}
}

// ...

// DiagnoseTunnel 诊断隧道
func (s *TunnelService) DiagnoseTunnel(id uint) (map[string]interface{}, error) {
	tunnel, err := s.repo.FindByID(id)
	if err != nil {
		return nil, errors.New("隧道不存在")
	}

	inNode, err := s.nodeRepo.FindByID(tunnel.InNodeID)
	if err != nil {
		return nil, errors.New("入口节点不存在")
	}

	var outNode *models.Node
	if tunnel.Type == 2 { // 隧道转发
		outNode, err = s.nodeRepo.FindByID(tunnel.OutNodeID)
		if err != nil {
			return nil, errors.New("出口节点不存在")
		}
	}

	var results []DiagnosisResult

	if tunnel.Type == 1 {
		// 端口转发
		inResult := s.performTcpPingDiagnosis(inNode, "www.google.com", 443, "入口->外网")
		results = append(results, inResult)
	} else {
		// 隧道转发
		outNodePort := s.getOutNodeTcpPort(tunnel.ID)
		if outNode != nil {
			inToOutResult := s.performTcpPingDiagnosis(inNode, outNode.ServerIP, outNodePort, "入口->出口")
			results = append(results, inToOutResult)
		}

		if outNode != nil {
			outToExternalResult := s.performTcpPingDiagnosis(outNode, "www.google.com", 443, "出口->外网")
			results = append(results, outToExternalResult)
		}
	}

	tunnelTypeStr := "隧道转发"
	if tunnel.Type == 1 {
		tunnelTypeStr = "端口转发"
	}

	result := map[string]interface{}{
		"tunnelId":   tunnel.ID,
		"tunnelName": tunnel.Name,
		"tunnelType": tunnelTypeStr,
		"results":    results,
		"timestamp":  time.Now().UnixMilli(),
	}

	return result, nil
}

// getOutNodeTcpPort 获取出口节点TCP端口
func (s *TunnelService) getOutNodeTcpPort(tunnelID uint) int {
	forwards, err := s.forwardRepo.FindByTunnelID(tunnelID)
	if err == nil {
		for _, f := range forwards {
			if f.Status == 1 {
				return f.OutPort
			}
		}
	}
	return 22
}

// performTcpPingDiagnosis 执行 TCP Ping 诊断
func (s *TunnelService) performTcpPingDiagnosis(node *models.Node, targetIp string, port int, description string) DiagnosisResult {
	result := DiagnosisResult{
		NodeId:      node.ID,
		NodeName:    node.Name,
		TargetIp:    targetIp,
		TargetPort:  port,
		Description: description,
		Timestamp:   time.Now().UnixMilli(),
	}

	tcpPingReq := map[string]interface{}{
		"ip":      targetIp,
		"port":    port,
		"count":   4,
		"timeout": 5000,
	}

	resp, err := websocket.GetServer().SendMessage(node.ID, tcpPingReq, "TcpPing")
	if err != nil {
		result.Success = false
		result.Message = err.Error()
		result.PacketLoss = 100.0
		result.AverageTime = -1.0
		return result
	}

	if !resp.Success {
		result.Success = false
		result.Message = resp.Message
		result.PacketLoss = 100.0
		result.AverageTime = -1.0
		return result
	}

	// 解析 Data
	// resp.Data 是 interface{}，可能是 map[string]interface{}
	// Agent 返回: {"ip": "...", "port": ..., "success": true, "averageTime": ..., "packetLoss": ...}

	if dataMap, ok := resp.Data.(map[string]interface{}); ok {
		if val, ok := dataMap["success"].(bool); ok {
			result.Success = val
		}
		if val, ok := dataMap["message"].(string); ok && val != "" {
			result.Message = val
		} else if result.Success {
			result.Message = "TCP连接成功"
		} else {
			// 尝试获取 errorMessage
			if errMsg, ok := dataMap["errorMessage"].(string); ok {
				result.Message = errMsg
			} else {
				result.Message = "TCP连接失败"
			}
		}

		if val, ok := dataMap["averageTime"].(float64); ok {
			result.AverageTime = val
		}
		if val, ok := dataMap["packetLoss"].(float64); ok {
			result.PacketLoss = val
		}
	} else {
		// 数据格式不对，但调用成功
		result.Success = true
		result.Message = "TCP连接成功 (数据解析失败)"
	}

	return result
}

// CreateTunnel 创建隧道
func (s *TunnelService) CreateTunnel(tunnelDto *dto.TunnelDto) error {
	tunnel := &models.Tunnel{
		Name:          tunnelDto.Name,
		InNodeID:      tunnelDto.InNodeID,
		OutNodeID:     tunnelDto.OutNodeID,
		Type:          tunnelDto.Type,
		Flow:          tunnelDto.Flow,
		Protocol:      tunnelDto.Protocol,
		TCPListenAddr: tunnelDto.TCPListenAddr,
		UDPListenAddr: tunnelDto.UDPListenAddr,
		InterfaceName: tunnelDto.InterfaceName,
	}

	if tunnelDto.TrafficRatio != nil {
		tunnel.TrafficRatio = *tunnelDto.TrafficRatio
	} else {
		tunnel.TrafficRatio = 1.0
	}
	tunnel.Status = 1 // 默认启用

	return s.repo.Create(tunnel)
}

// GetAllTunnels 获取所有隧道
func (s *TunnelService) GetAllTunnels() ([]models.Tunnel, error) {
	return s.repo.FindAll()
}

// UpdateTunnel 更新隧道
func (s *TunnelService) UpdateTunnel(updateDto *dto.TunnelUpdateDto) error {
	tunnel, err := s.repo.FindByID(updateDto.ID)
	if err != nil {
		return errors.New("隧道不存在")
	}

	// 更新字段
	if updateDto.Name != nil {
		tunnel.Name = *updateDto.Name
	}
	if updateDto.InNodeID != nil {
		tunnel.InNodeID = *updateDto.InNodeID
	}
	if updateDto.OutNodeID != nil {
		tunnel.OutNodeID = *updateDto.OutNodeID
	}
	if updateDto.Type != nil {
		tunnel.Type = *updateDto.Type
	}
	if updateDto.Flow != nil {
		tunnel.Flow = *updateDto.Flow
	}
	if updateDto.Protocol != nil {
		tunnel.Protocol = *updateDto.Protocol
	}
	if updateDto.TrafficRatio != nil {
		tunnel.TrafficRatio = *updateDto.TrafficRatio
	}
	if updateDto.TCPListenAddr != nil {
		tunnel.TCPListenAddr = *updateDto.TCPListenAddr
	}
	if updateDto.UDPListenAddr != nil {
		tunnel.UDPListenAddr = *updateDto.UDPListenAddr
	}
	if updateDto.InterfaceName != nil {
		tunnel.InterfaceName = *updateDto.InterfaceName
	}

	return s.repo.Update(tunnel)
}

// DeleteTunnel 删除隧道
func (s *TunnelService) DeleteTunnel(id uint) error {
	return s.repo.Delete(id)
}

// GetUserTunnels 获取用户可用的隧道
func (s *TunnelService) GetUserTunnels(userID uint) ([]models.Tunnel, error) {
	return s.repo.FindByUserID(userID)
}

// AssignUserTunnel 分配用户隧道权限
func (s *TunnelService) AssignUserTunnel(assignDto *dto.UserTunnelDto) error {
	// 检查是否已经分配
	_, err := s.userTunnelRepo.FindByUserAndTunnel(assignDto.UserID, assignDto.TunnelID)
	if err == nil {
		return errors.New("用户已拥有该隧道权限")
	}

	userTunnel := &models.UserTunnel{
		UserID:        assignDto.UserID,
		TunnelID:      assignDto.TunnelID,
		ExpTime:       assignDto.ExpTime,
		Flow:          assignDto.Flow,
		FlowResetTime: assignDto.FlowResetTime,
	}
	userTunnel.Status = 1 // 默认启用

	return s.userTunnelRepo.Create(userTunnel)
}

// GetUserTunnelList 获取用户隧道权限列表
func (s *TunnelService) GetUserTunnelList(queryDto *dto.UserTunnelQueryDto) ([]models.UserTunnel, error) {
	if queryDto.UserID != nil {
		return s.userTunnelRepo.FindByUserID(*queryDto.UserID)
	}
	if queryDto.TunnelID != nil {
		return s.userTunnelRepo.FindByTunnelID(*queryDto.TunnelID)
	}
	return s.userTunnelRepo.FindAll()
}

// RemoveUserTunnel 移除用户隧道权限
func (s *TunnelService) RemoveUserTunnel(id uint) error {
	return s.userTunnelRepo.Delete(id)
}

// UpdateUserTunnel 更新用户隧道权限
func (s *TunnelService) UpdateUserTunnel(updateDto *dto.UserTunnelUpdateDto) error {
	userTunnel, err := s.userTunnelRepo.FindByID(updateDto.ID)
	if err != nil {
		return errors.New("用户隧道权限不存在")
	}

	if updateDto.ExpTime != nil {
		userTunnel.ExpTime = *updateDto.ExpTime
	}
	if updateDto.Flow != nil {
		userTunnel.Flow = *updateDto.Flow
	}
	if updateDto.FlowResetTime != nil {
		userTunnel.FlowResetTime = *updateDto.FlowResetTime
	}

	return s.userTunnelRepo.Update(userTunnel)
}

// GetTunnelByID 根据ID获取隧道
func (s *TunnelService) GetTunnelByID(id uint) (*models.Tunnel, error) {
	tunnel, err := s.repo.FindByID(id)
	if err != nil {
		return nil, errors.New("隧道不存在")
	}
	return tunnel, nil
}

// DiagnoseTunnel 诊断隧道
