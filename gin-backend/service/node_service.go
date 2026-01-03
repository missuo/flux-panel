package service

import (
	"errors"
	"flux-panel/dto"
	"flux-panel/models"
	"flux-panel/repository"
	"fmt"
	"strings"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type NodeService struct {
	repo          *repository.NodeRepository
	configService *ConfigService
}

func NewNodeService(db *gorm.DB) *NodeService {
	return &NodeService{
		repo:          repository.NewNodeRepository(db),
		configService: NewConfigService(db),
	}
}

// CreateNode 创建节点
func (s *NodeService) CreateNode(nodeDto *dto.NodeDto) error {
	// 自动生成 Secret（UUID 去掉横线）
	secret := strings.ReplaceAll(uuid.New().String(), "-", "")

	node := &models.Node{
		Name:     nodeDto.Name,
		Secret:   secret,
		IP:       nodeDto.IP,
		ServerIP: nodeDto.ServerIP,
		Version:  nodeDto.Version,
		PortSta:  nodeDto.PortSta,
		PortEnd:  nodeDto.PortEnd,
		HTTP:     nodeDto.HTTP,
		TLS:      nodeDto.TLS,
		Socks:    nodeDto.Socks,
	}

	return s.repo.Create(node)
}

// GetAllNodes 获取所有节点
func (s *NodeService) GetAllNodes() ([]models.Node, error) {
	return s.repo.FindAll()
}

// UpdateNode 更新节点
func (s *NodeService) UpdateNode(updateDto *dto.NodeUpdateDto) error {
	node, err := s.repo.FindByID(updateDto.ID)
	if err != nil {
		return errors.New("节点不存在")
	}

	// 更新字段
	if updateDto.Name != nil {
		node.Name = *updateDto.Name
	}
	if updateDto.Secret != nil {
		node.Secret = *updateDto.Secret
	}
	if updateDto.IP != nil {
		node.IP = *updateDto.IP
	}
	if updateDto.ServerIP != nil {
		node.ServerIP = *updateDto.ServerIP
	}
	if updateDto.Version != nil {
		node.Version = *updateDto.Version
	}
	if updateDto.PortSta != nil {
		node.PortSta = *updateDto.PortSta
	}
	if updateDto.PortEnd != nil {
		node.PortEnd = *updateDto.PortEnd
	}
	if updateDto.HTTP != nil {
		node.HTTP = *updateDto.HTTP
	}
	if updateDto.TLS != nil {
		node.TLS = *updateDto.TLS
	}
	if updateDto.Socks != nil {
		node.Socks = *updateDto.Socks
	}

	return s.repo.Update(node)
}

// DeleteNode 删除节点
func (s *NodeService) DeleteNode(id uint) error {
	return s.repo.Delete(id)
}

// GetInstallCommand 获取安装命令
func (s *NodeService) GetInstallCommand(id uint) (string, error) {
	node, err := s.repo.FindByID(id)
	if err != nil {
		return "", errors.New("节点不存在")
	}

	// 从配置表获取面板 IP
	config, err := s.configService.GetConfigByName("ip")
	if err != nil {
		return "", errors.New("请先前往网站配置中设置ip")
	}

	panelAddr := config.Value
	if panelAddr == "" {
		return "", errors.New("请先前往网站配置中设置ip")
	}

	// 处理 IPv6 地址
	processedAddr := processServerAddress(panelAddr)

	// 检查 Secret 是否为空，如果为空则生成并保存
	if node.Secret == "" {
		node.Secret = strings.ReplaceAll(uuid.New().String(), "-", "")
		if err := s.repo.Update(node); err != nil {
			return "", errors.New("更新节点密钥失败")
		}
	}

	// 生成安装命令（与 Spring Boot 保持一致）
	command := fmt.Sprintf(
		"curl -L https://github.com/missuo/flux-panel/releases/download/v1.5.0/install.sh -o ./install.sh && chmod +x ./install.sh && ./install.sh -a %s -s %s",
		processedAddr,
		node.Secret,
	)

	return command, nil
}

// processServerAddress 处理服务器地址，确保 IPv6 地址被方括号包裹
func processServerAddress(serverAddr string) string {
	if serverAddr == "" {
		return serverAddr
	}

	// 如果已经被方括号包裹，直接返回
	if strings.HasPrefix(serverAddr, "[") {
		return serverAddr
	}

	// 查找最后一个冒号，分离主机和端口
	lastColonIndex := strings.LastIndex(serverAddr, ":")
	if lastColonIndex == -1 {
		// 没有端口号，直接检查是否需要包裹
		if isIPv6Address(serverAddr) {
			return "[" + serverAddr + "]"
		}
		return serverAddr
	}

	host := serverAddr[:lastColonIndex]
	port := serverAddr[lastColonIndex:]

	// 检查主机部分是否为 IPv6 地址
	if isIPv6Address(host) {
		return "[" + host + "]" + port
	}

	return serverAddr
}

// isIPv6Address 判断是否为 IPv6 地址
func isIPv6Address(address string) bool {
	// IPv6 地址包含多个冒号，至少 2 个
	colonCount := strings.Count(address, ":")
	return colonCount >= 2
}

// CheckNodeStatus 检查节点状态
func (s *NodeService) CheckNodeStatus(nodeID *uint) ([]map[string]interface{}, error) {
	var nodes []models.Node
	var err error

	if nodeID != nil && *nodeID > 0 {
		node, err := s.repo.FindByID(*nodeID)
		if err != nil {
			return nil, errors.New("节点不存在")
		}
		nodes = []models.Node{*node}
	} else {
		nodes, err = s.repo.FindAll()
		if err != nil {
			return nil, err
		}
	}

	result := make([]map[string]interface{}, 0)
	for _, node := range nodes {
		// TODO: 实际检查节点状态的逻辑
		status := map[string]interface{}{
			"id":     node.ID,
			"name":   node.Name,
			"ip":     node.IP,
			"status": "online", // 暂时返回在线状态
		}
		result = append(result, status)
	}

	return result, nil
}
