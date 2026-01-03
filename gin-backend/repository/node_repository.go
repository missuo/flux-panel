package repository

import (
	"flux-panel/models"

	"gorm.io/gorm"
)

type NodeRepository struct {
	db *gorm.DB
}

func NewNodeRepository(db *gorm.DB) *NodeRepository {
	return &NodeRepository{db: db}
}

func (r *NodeRepository) Create(node *models.Node) error {
	return r.db.Create(node).Error
}

func (r *NodeRepository) FindByID(id uint) (*models.Node, error) {
	var node models.Node
	err := r.db.Where("id = ? AND status = 0", id).First(&node).Error
	return &node, err
}

// FindAll 获取所有节点
func (r *NodeRepository) FindAll() ([]models.Node, error) {
	var nodes []models.Node
	err := r.db.Find(&nodes).Error
	return nodes, err
}

// Update 更新节点
func (r *NodeRepository) Update(node *models.Node) error {
	return r.db.Save(node).Error
}

// Delete 删除节点
func (r *NodeRepository) Delete(id uint) error {
	return r.db.Delete(&models.Node{}, id).Error
}
