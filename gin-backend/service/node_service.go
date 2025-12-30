package service

import (
	"errors"
	"flux-panel/dto"
	"flux-panel/models"
	"flux-panel/repository"
	"fmt"

	"gorm.io/gorm"
)

type NodeService struct {
	repo *repository.NodeRepository
}

func NewNodeService(db *gorm.DB) *NodeService {
	return &NodeService{
		repo: repository.NewNodeRepository(db),
	}
}

// CreateNode 创建节点
func (s *NodeService) CreateNode(nodeDto *dto.NodeDto) error {
	node := &models.Node{
		Name:     nodeDto.Name,
		Secret:   nodeDto.Secret,
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

	// 生成安装命令
	command := fmt.Sprintf(
		"curl -fsSL https://raw.githubusercontent.com/your-repo/flux-panel/main/install.sh | bash -s -- --id=%d --secret=%s --server=%s",
		node.ID,
		node.Secret,
		node.ServerIP,
	)

	return command, nil
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
