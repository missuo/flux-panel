package models

// StatisticsFlow 流量统计模型
type StatisticsFlow struct {
	ID          uint   `gorm:"primaryKey" json:"id"`
	UserID      int    `gorm:"column:user_id;index" json:"user_id"`
	Flow        int64  `gorm:"column:flow;default:0" json:"flow"`               // 增量流量
	TotalFlow   int64  `gorm:"column:total_flow;default:0" json:"total_flow"`   // 累计流量
	Time        string `gorm:"column:time;size:10" json:"time"`                 // HH:mm 格式
	CreatedTime int64  `gorm:"column:created_time;index" json:"created_time"`   // 创建时间戳
}

// TableName 指定表名
func (StatisticsFlow) TableName() string {
	return "statistics_flow"
}
