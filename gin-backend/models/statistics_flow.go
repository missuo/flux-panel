package models

// StatisticsFlow 流量统计模型
type StatisticsFlow struct {
	BaseModel
	ForwardID int   `gorm:"column:forward_id;index" json:"forward_id"`
	UserID    int   `gorm:"column:user_id;index" json:"user_id"`
	InFlow    int64 `gorm:"column:in_flow;default:0" json:"in_flow"`
	OutFlow   int64 `gorm:"column:out_flow;default:0" json:"out_flow"`
	Date      int64 `gorm:"column:date;index" json:"date"` // 统计日期
}

// TableName 指定表名
func (StatisticsFlow) TableName() string {
	return "statistics_flow"
}
