package service

import (
	"flux-panel/models"
	"flux-panel/websocket"
	"fmt"
	"strings"
)

// GostResponse Gost 操作响应
type GostResponse struct {
	Success bool        `json:"success"`
	Message string      `json:"message"`
	Data    interface{} `json:"data"`
}

// AddLimiters 添加限流器
func AddLimiters(nodeID uint, name uint, speed string) *GostResponse {
	data := map[string]interface{}{
		"name":   fmt.Sprintf("%d", name),
		"limits": []string{fmt.Sprintf("$ %sMB %sMB", speed, speed)},
	}
	return sendGostMessage(nodeID, data, websocket.MessageTypeAddLimiters)
}

// UpdateLimiters 更新限流器
func UpdateLimiters(nodeID uint, name uint, speed string) *GostResponse {
	data := map[string]interface{}{
		"limiter": fmt.Sprintf("%d", name),
		"data": map[string]interface{}{
			"name":   fmt.Sprintf("%d", name),
			"limits": []string{fmt.Sprintf("$ %sMB %sMB", speed, speed)},
		},
	}
	return sendGostMessage(nodeID, data, websocket.MessageTypeUpdateLimiters)
}

// DeleteLimiters 删除限流器
func DeleteLimiters(nodeID uint, name uint) *GostResponse {
	data := map[string]interface{}{
		"limiter": fmt.Sprintf("%d", name),
	}
	return sendGostMessage(nodeID, data, websocket.MessageTypeDeleteLimiters)
}

// AddService 添加服务 (TCP/UDP)
func AddService(nodeID uint, name string, inPort int, limiter *int, remoteAddr string,
	forwardType int, tunnel *models.Tunnel, strategy, interfaceName string) *GostResponse {

	services := make([]map[string]interface{}, 0, 2)
	protocols := []string{"tcp", "udp"}

	for _, protocol := range protocols {
		service := createServiceConfig(name, inPort, limiter, remoteAddr, protocol, forwardType, tunnel, strategy, interfaceName)
		services = append(services, service)
	}

	return sendGostMessage(nodeID, services, websocket.MessageTypeAddService)
}

// UpdateService 更新服务
func UpdateService(nodeID uint, name string, inPort int, limiter *int, remoteAddr string,
	forwardType int, tunnel *models.Tunnel, strategy, interfaceName string) *GostResponse {

	services := make([]map[string]interface{}, 0, 2)
	protocols := []string{"tcp", "udp"}

	for _, protocol := range protocols {
		service := createServiceConfig(name, inPort, limiter, remoteAddr, protocol, forwardType, tunnel, strategy, interfaceName)
		services = append(services, service)
	}

	return sendGostMessage(nodeID, services, websocket.MessageTypeUpdateService)
}

// DeleteService 删除服务
func DeleteService(nodeID uint, name string) *GostResponse {
	data := map[string]interface{}{
		"services": []string{name + "_tcp", name + "_udp"},
	}
	return sendGostMessage(nodeID, data, websocket.MessageTypeDeleteService)
}

// PauseService 暂停服务
func PauseService(nodeID uint, name string) *GostResponse {
	data := map[string]interface{}{
		"services": []string{name + "_tcp", name + "_udp"},
	}
	return sendGostMessage(nodeID, data, websocket.MessageTypePauseService)
}

// ResumeService 恢复服务
func ResumeService(nodeID uint, name string) *GostResponse {
	data := map[string]interface{}{
		"services": []string{name + "_tcp", name + "_udp"},
	}
	return sendGostMessage(nodeID, data, websocket.MessageTypeResumeService)
}

// AddRemoteService 添加远程服务 (TLS)
func AddRemoteService(nodeID uint, name string, outPort int, remoteAddr, protocol, strategy, interfaceName string) *GostResponse {
	service := createRemoteServiceConfig(name, outPort, remoteAddr, protocol, strategy, interfaceName)
	return sendGostMessage(nodeID, []map[string]interface{}{service}, websocket.MessageTypeAddService)
}

// UpdateRemoteService 更新远程服务
func UpdateRemoteService(nodeID uint, name string, outPort int, remoteAddr, protocol, strategy, interfaceName string) *GostResponse {
	service := createRemoteServiceConfig(name, outPort, remoteAddr, protocol, strategy, interfaceName)
	return sendGostMessage(nodeID, []map[string]interface{}{service}, websocket.MessageTypeUpdateService)
}

// DeleteRemoteService 删除远程服务
func DeleteRemoteService(nodeID uint, name string) *GostResponse {
	data := map[string]interface{}{
		"services": []string{name + "_tls"},
	}
	return sendGostMessage(nodeID, data, websocket.MessageTypeDeleteService)
}

// PauseRemoteService 暂停远程服务
func PauseRemoteService(nodeID uint, name string) *GostResponse {
	data := map[string]interface{}{
		"services": []string{name + "_tls"},
	}
	return sendGostMessage(nodeID, data, websocket.MessageTypePauseService)
}

// ResumeRemoteService 恢复远程服务
func ResumeRemoteService(nodeID uint, name string) *GostResponse {
	data := map[string]interface{}{
		"services": []string{name + "_tls"},
	}
	return sendGostMessage(nodeID, data, websocket.MessageTypeResumeService)
}

// AddChains 添加链
func AddChains(nodeID uint, name, remoteAddr, protocol, interfaceName string) *GostResponse {
	dialer := map[string]interface{}{
		"type": protocol,
	}

	if protocol == "quic" {
		dialer["metadata"] = map[string]interface{}{
			"keepAlive": true,
			"ttl":       "10s",
		}
	}

	node := map[string]interface{}{
		"name": "node-" + name,
		"addr": remoteAddr,
		"connector": map[string]interface{}{
			"type": "relay",
		},
		"dialer": dialer,
	}

	if interfaceName != "" {
		node["interface"] = interfaceName
	}

	data := map[string]interface{}{
		"name": name + "_chains",
		"hops": []map[string]interface{}{
			{
				"name":  "hop-" + name,
				"nodes": []map[string]interface{}{node},
			},
		},
	}

	return sendGostMessage(nodeID, data, websocket.MessageTypeAddChains)
}

// UpdateChains 更新链
func UpdateChains(nodeID uint, name, remoteAddr, protocol, interfaceName string) *GostResponse {
	dialer := map[string]interface{}{
		"type": protocol,
	}

	if protocol == "quic" {
		dialer["metadata"] = map[string]interface{}{
			"keepAlive": true,
			"ttl":       "10s",
		}
	}

	node := map[string]interface{}{
		"name": "node-" + name,
		"addr": remoteAddr,
		"connector": map[string]interface{}{
			"type": "relay",
		},
		"dialer": dialer,
	}

	if interfaceName != "" {
		node["interface"] = interfaceName
	}

	chainData := map[string]interface{}{
		"name": name + "_chains",
		"hops": []map[string]interface{}{
			{
				"name":  "hop-" + name,
				"nodes": []map[string]interface{}{node},
			},
		},
	}

	data := map[string]interface{}{
		"chain": name + "_chains",
		"data":  chainData,
	}

	return sendGostMessage(nodeID, data, websocket.MessageTypeUpdateChains)
}

// DeleteChains 删除链
func DeleteChains(nodeID uint, name string) *GostResponse {
	data := map[string]interface{}{
		"chain": name + "_chains",
	}
	return sendGostMessage(nodeID, data, websocket.MessageTypeDeleteChains)
}

// 创建服务配置
func createServiceConfig(name string, inPort int, limiter *int, remoteAddr, protocol string,
	forwardType int, tunnel *models.Tunnel, strategy, interfaceName string) map[string]interface{} {

	service := map[string]interface{}{
		"name": name + "_" + protocol,
	}

	// 设置地址
	if protocol == "tcp" && tunnel != nil {
		service["addr"] = fmt.Sprintf("%s:%d", tunnel.TCPListenAddr, inPort)
	} else if protocol == "udp" && tunnel != nil {
		service["addr"] = fmt.Sprintf("%s:%d", tunnel.UDPListenAddr, inPort)
	} else {
		service["addr"] = fmt.Sprintf(":%d", inPort)
	}

	// 接口名称
	if interfaceName != "" {
		service["metadata"] = map[string]interface{}{
			"interface": interfaceName,
		}
	}

	// 限流器
	if limiter != nil {
		service["limiter"] = fmt.Sprintf("%d", *limiter)
	}

	// 处理器
	handler := map[string]interface{}{
		"type": protocol,
	}
	// 隧道转发需要添加链配置
	if forwardType != 1 { // 非端口转发
		handler["chain"] = name + "_chains"
	}
	service["handler"] = handler

	// 监听器
	listener := map[string]interface{}{
		"type": protocol,
	}
	if protocol == "udp" {
		listener["metadata"] = map[string]interface{}{
			"keepAlive": true,
		}
	}
	service["listener"] = listener

	// 端口转发需要配置转发器
	if forwardType == 1 && remoteAddr != "" {
		service["forwarder"] = createForwarder(remoteAddr, strategy)
	}

	return service
}

// 创建远程服务配置
func createRemoteServiceConfig(name string, outPort int, remoteAddr, protocol, strategy, interfaceName string) map[string]interface{} {
	service := map[string]interface{}{
		"name": name + "_tls",
		"addr": fmt.Sprintf(":%d", outPort),
	}

	if interfaceName != "" {
		service["metadata"] = map[string]interface{}{
			"interface": interfaceName,
		}
	}

	service["handler"] = map[string]interface{}{
		"type": "relay",
	}

	service["listener"] = map[string]interface{}{
		"type": protocol,
	}

	service["forwarder"] = createForwarder(remoteAddr, strategy)

	return service
}

// 创建转发器配置
func createForwarder(remoteAddr, strategy string) map[string]interface{} {
	nodes := make([]map[string]interface{}, 0)
	addrs := strings.Split(remoteAddr, ",")

	for i, addr := range addrs {
		nodes = append(nodes, map[string]interface{}{
			"name": fmt.Sprintf("node_%d", i+1),
			"addr": strings.TrimSpace(addr),
		})
	}

	if strategy == "" {
		strategy = "fifo"
	}

	return map[string]interface{}{
		"nodes": nodes,
		"selector": map[string]interface{}{
			"strategy":    strategy,
			"maxFails":    1,
			"failTimeout": "600s",
		},
	}
}

// 发送 Gost 消息
func sendGostMessage(nodeID uint, data interface{}, msgType string) *GostResponse {
	resp, err := websocket.GetServer().SendMessage(nodeID, data, msgType)
	if err != nil {
		return &GostResponse{
			Success: false,
			Message: err.Error(),
		}
	}

	return &GostResponse{
		Success: resp.Success,
		Message: resp.Message,
		Data:    resp.Data,
	}
}

// BuildServiceName 构建服务名称
func BuildServiceName(forwardID, userID, userTunnelID interface{}) string {
	return fmt.Sprintf("%v_%v_%v", forwardID, userID, userTunnelID)
}
