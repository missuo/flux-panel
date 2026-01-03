package service

import (
	"errors"
	"flux-panel/dto"
	"flux-panel/models"
	"flux-panel/repository"
	"flux-panel/websocket"
	"fmt"
	"net"
	"strconv"
	"strings"
	"time"

	"gorm.io/gorm"
)

type ForwardService struct {
	repo           *repository.ForwardRepository
	tunnelRepo     *repository.TunnelRepository
	userTunnelRepo *repository.UserTunnelRepository
	nodeRepo       *repository.NodeRepository
}

func NewForwardService(db *gorm.DB) *ForwardService {
	return &ForwardService{
		repo:           repository.NewForwardRepository(db),
		tunnelRepo:     repository.NewTunnelRepository(db),
		userTunnelRepo: repository.NewUserTunnelRepository(db),
		nodeRepo:       repository.NewNodeRepository(db),
	}
}

// CreateForward 创建转发
func (s *ForwardService) CreateForward(userID int, userName string, forwardDto *dto.ForwardDto) error {
	inPort := 0
	if forwardDto.InPort != nil {
		inPort = *forwardDto.InPort
	}

	tunnel, err := s.tunnelRepo.FindByID(uint(forwardDto.TunnelID))
	if err != nil {
		return errors.New("隧道不存在")
	}
	if tunnel.Status != 1 {
		return errors.New("隧道被禁用")
	}

	userTunnel, _ := s.userTunnelRepo.FindByUserAndTunnel(uint(userID), tunnel.ID)

	forward := &models.Forward{
		UserID:        userID,
		UserName:      userName,
		Name:          forwardDto.Name,
		TunnelID:      forwardDto.TunnelID,
		RemoteAddr:    forwardDto.RemoteAddr,
		Strategy:      forwardDto.Strategy,
		InPort:        inPort,
		InterfaceName: forwardDto.InterfaceName,
	}
	forward.Status = 1

	if err := s.repo.Create(forward); err != nil {
		return err
	}

	var limiter *int
	var userTunnelID uint
	if userTunnel != nil {
		if userTunnel.SpeedID > 0 {
			limiter = &userTunnel.SpeedID
		}
		userTunnelID = userTunnel.ID
	}

	inNode, err := s.nodeRepo.FindByID(tunnel.InNodeID)
	if err != nil {
		s.repo.Delete(forward.ID)
		return errors.New("入口节点不存在")
	}

	var outNode *models.Node
	if tunnel.Type == 2 {
		outNode, err = s.nodeRepo.FindByID(tunnel.OutNodeID)
		if err != nil {
			s.repo.Delete(forward.ID)
			return errors.New("出口节点不存在")
		}
	}

	if err := s.createGostServices(forward, tunnel, limiter, inNode, outNode, userTunnelID); err != nil {
		s.repo.Delete(forward.ID)
		return err
	}

	return nil
}

func (s *ForwardService) createGostServices(forward *models.Forward, tunnel *models.Tunnel, limiter *int, inNode, outNode *models.Node, userTunnelID uint) error {
	serviceName := BuildServiceName(forward.ID, forward.UserID, userTunnelID)

	if tunnel.Type == 2 {
		// Tunnel Forward
		// 1. Add Chain
		remoteAddr := fmt.Sprintf("%s:%d", tunnel.OutIP, forward.OutPort)
		if strings.Contains(tunnel.OutIP, ":") {
			remoteAddr = fmt.Sprintf("[%s]:%d", tunnel.OutIP, forward.OutPort)
		}

		chainResp := AddChains(inNode.ID, serviceName, remoteAddr, tunnel.Protocol, tunnel.InterfaceName)
		if !chainResp.Success {
			DeleteChains(inNode.ID, serviceName)
			return errors.New(chainResp.Message)
		}

		// 2. Remote Service
		remoteResp := AddRemoteService(outNode.ID, serviceName, forward.OutPort, forward.RemoteAddr, tunnel.Protocol, forward.Strategy, forward.InterfaceName)
		if !remoteResp.Success {
			DeleteChains(inNode.ID, serviceName)
			DeleteRemoteService(outNode.ID, serviceName)
			return errors.New(remoteResp.Message)
		}
	}

	interfaceName := ""
	if tunnel.Type != 2 {
		interfaceName = forward.InterfaceName
	}

	resp := AddService(inNode.ID, serviceName, forward.InPort, limiter, forward.RemoteAddr, tunnel.Type, tunnel, forward.Strategy, interfaceName)
	if !resp.Success {
		DeleteChains(inNode.ID, serviceName)
		if outNode != nil {
			DeleteRemoteService(outNode.ID, serviceName)
		}
		return errors.New(resp.Message)
	}

	return nil
}

// GetAllForwards 获取所有转发
func (s *ForwardService) GetAllForwards() ([]models.Forward, error) {
	return s.repo.FindAll()
}

// GetForwardsByUserID 获取用户的转发
func (s *ForwardService) GetForwardsByUserID(userID int) ([]models.Forward, error) {
	return s.repo.FindByUserID(userID)
}

// UpdateForward 更新转发
func (s *ForwardService) UpdateForward(updateDto *dto.ForwardUpdateDto) error {
	forward, err := s.repo.FindByID(updateDto.ID)
	if err != nil {
		return errors.New("转发不存在")
	}

	forward.Name = updateDto.Name
	forward.TunnelID = updateDto.TunnelID
	forward.RemoteAddr = updateDto.RemoteAddr
	forward.Strategy = updateDto.Strategy
	forward.InterfaceName = updateDto.InterfaceName
	if updateDto.InPort != nil {
		forward.InPort = *updateDto.InPort
	}

	return s.repo.Update(forward)
}

// DeleteForward 删除转发
func (s *ForwardService) DeleteForward(id uint) error {
	_, err := s.repo.FindByID(id)
	if err != nil {
		return errors.New("转发不存在")
	}
	return s.repo.Delete(id)
}

// ForceDeleteForward 强制删除转发
func (s *ForwardService) ForceDeleteForward(id uint) error {
	return s.repo.Delete(id)
}

// PauseForward 暂停转发
func (s *ForwardService) PauseForward(id uint) error {
	forward, err := s.repo.FindByID(id)
	if err != nil {
		return errors.New("转发不存在")
	}

	// 更新数据库状态
	forward.Status = 0
	if err := s.repo.Update(forward); err != nil {
		return err
	}

	// 调用 Gost API 暂停服务
	userTunnel, err := s.userTunnelRepo.FindByUserAndTunnel(uint(forward.UserID), uint(forward.TunnelID))
	if err != nil {
		return nil // 如果找不到映射，可能已经被删除了，只需要暂停 DB 状态即可
	}

	tunnel, err := s.tunnelRepo.FindByID(uint(forward.TunnelID))
	if err != nil {
		return nil
	}

	serviceName := BuildServiceName(forward.ID, forward.UserID, userTunnel.ID)
	PauseService(tunnel.InNodeID, serviceName)
	if tunnel.Type == 2 {
		PauseRemoteService(tunnel.OutNodeID, serviceName)
	}

	return nil
}

// ResumeForward 恢复转发
func (s *ForwardService) ResumeForward(id uint) error {
	forward, err := s.repo.FindByID(id)
	if err != nil {
		return errors.New("转发不存在")
	}

	// 更新数据库状态
	forward.Status = 1
	if err := s.repo.Update(forward); err != nil {
		return err
	}

	// 调用 Gost API 恢复服务
	userTunnel, err := s.userTunnelRepo.FindByUserAndTunnel(uint(forward.UserID), uint(forward.TunnelID))
	if err != nil {
		return nil
	}

	tunnel, err := s.tunnelRepo.FindByID(uint(forward.TunnelID))
	if err != nil {
		return nil
	}

	serviceName := BuildServiceName(forward.ID, forward.UserID, userTunnel.ID)
	ResumeService(tunnel.InNodeID, serviceName)
	if tunnel.Type == 2 {
		ResumeRemoteService(tunnel.OutNodeID, serviceName)
	}

	return nil
}

// DiagnoseForward 诊断转发
func (s *ForwardService) DiagnoseForward(id uint) (map[string]interface{}, error) {
	forward, err := s.repo.FindByID(id)
	if err != nil {
		return nil, errors.New("转发不存在")
	}

	tunnel, err := s.tunnelRepo.FindByID(uint(forward.TunnelID))
	if err != nil {
		return nil, errors.New("隧道不存在")
	}

	inNode, err := s.nodeRepo.FindByID(tunnel.InNodeID)
	if err != nil {
		return nil, errors.New("入口节点不存在")
	}

	var results []DiagnosisResult
	addrs := strings.Split(forward.RemoteAddr, ",")

	if tunnel.Type == 1 { // 端口转发
		for _, addr := range addrs {
			host, port := parseTarget(addr)
			if host == "" || port == 0 {
				continue
			}
			results = append(results, s.performTcpPingDiagnosis(inNode, host, port, "转发->目标"))
		}
	} else { // 隧道转发
		outNode, err := s.nodeRepo.FindByID(tunnel.OutNodeID)
		if err != nil {
			return nil, errors.New("出口节点不存在")
		}

		// 入口->出口
		results = append(results, s.performTcpPingDiagnosis(inNode, outNode.ServerIP, forward.OutPort, "入口->出口"))

		// 出口->目标
		for _, addr := range addrs {
			host, port := parseTarget(addr)
			if host == "" || port == 0 {
				continue
			}
			results = append(results, s.performTcpPingDiagnosis(outNode, host, port, "出口->目标"))
		}
	}

	tunnelTypeStr := "隧道转发"
	if tunnel.Type == 1 {
		tunnelTypeStr = "端口转发"
	}

	result := map[string]interface{}{
		"forwardId":   forward.ID,
		"forwardName": forward.Name,
		"tunnelType":  tunnelTypeStr,
		"results":     results,
		"timestamp":   time.Now().UnixMilli(),
	}

	return result, nil
}

func (s *ForwardService) performTcpPingDiagnosis(node *models.Node, targetIp string, port int, description string) DiagnosisResult {
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

	if dataMap, ok := resp.Data.(map[string]interface{}); ok {
		if val, ok := dataMap["success"].(bool); ok {
			result.Success = val
		}
		if val, ok := dataMap["message"].(string); ok && val != "" {
			result.Message = val
		} else if result.Success {
			result.Message = "TCP连接成功"
		} else {
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
		result.Success = true
		result.Message = "TCP连接成功 (数据解析失败)"
	}

	return result
}

func parseTarget(addr string) (string, int) {
	host, portStr, err := net.SplitHostPort(strings.TrimSpace(addr))
	if err != nil {
		return "", 0
	}
	port, _ := strconv.Atoi(portStr)
	return host, port
}

// UpdateForwardOrder 更新转发排序
func (s *ForwardService) UpdateForwardOrder(orderDto *dto.ForwardOrderDto) error {
	for _, item := range orderDto.Forwards {
		if err := s.repo.UpdateOrder(item.ID, item.Inx); err != nil {
			return err
		}
	}
	return nil
}
