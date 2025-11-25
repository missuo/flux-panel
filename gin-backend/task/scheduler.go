package task

import (
	"flux-panel/models"
	"log"
	"time"

	"github.com/robfig/cron/v3"
)

var scheduler *cron.Cron

// InitScheduler 初始化定时任务
func InitScheduler() {
	scheduler = cron.New(cron.WithSeconds())

	// 每小时统计一次流量
	_, err := scheduler.AddFunc("0 0 * * * *", StatisticsFlow)
	if err != nil {
		log.Printf("Failed to add statistics flow task: %v", err)
	}

	// 每天凌晨检查并重置流量
	_, err = scheduler.AddFunc("0 0 0 * * *", CheckAndResetFlow)
	if err != nil {
		log.Printf("Failed to add reset flow task: %v", err)
	}

	// 启动调度器
	scheduler.Start()
	log.Println("Scheduler started")
}

// StopScheduler 停止定时任务
func StopScheduler() {
	if scheduler != nil {
		scheduler.Stop()
		log.Println("Scheduler stopped")
	}
}

// StatisticsFlow 统计流量
func StatisticsFlow() {
	log.Println("Running statistics flow task...")

	// 获取所有转发记录
	var forwards []models.Forward
	if err := models.DB.Where("status = 0").Find(&forwards).Error; err != nil {
		log.Printf("Failed to get forwards: %v", err)
		return
	}

	// 统计每个转发的流量
	now := time.Now().Unix()
	for _, forward := range forwards {
		stat := &models.StatisticsFlow{
			ForwardID: int(forward.ID),
			UserID:    forward.UserID,
			InFlow:    forward.InFlow,
			OutFlow:   forward.OutFlow,
			Date:      now,
		}

		if err := models.DB.Create(stat).Error; err != nil {
			log.Printf("Failed to create statistics: %v", err)
		}
	}

	log.Println("Statistics flow task completed")
}

// CheckAndResetFlow 检查并重置流量
func CheckAndResetFlow() {
	log.Println("Running check and reset flow task...")

	now := time.Now().Unix()

	// 重置用户流量
	var users []models.User
	if err := models.DB.Where("status = 0 AND flow_reset_time > 0 AND flow_reset_time <= ?", now).Find(&users).Error; err != nil {
		log.Printf("Failed to get users: %v", err)
		return
	}

	for _, user := range users {
		// 重置流量
		user.InFlow = 0
		user.OutFlow = 0

		// 计算下次重置时间（30天后）
		user.FlowResetTime = time.Now().AddDate(0, 0, 30).Unix()

		if err := models.DB.Save(&user).Error; err != nil {
			log.Printf("Failed to reset user flow: %v", err)
		} else {
			log.Printf("Reset flow for user: %s", user.User)
		}
	}

	// 重置用户隧道流量
	var userTunnels []models.UserTunnel
	if err := models.DB.Where("status = 0 AND flow_reset_time > 0 AND flow_reset_time <= ?", now).Find(&userTunnels).Error; err != nil {
		log.Printf("Failed to get user tunnels: %v", err)
		return
	}

	for _, ut := range userTunnels {
		// 重置流量
		ut.InFlow = 0
		ut.OutFlow = 0

		// 计算下次重置时间（30天后）
		ut.FlowResetTime = time.Now().AddDate(0, 0, 30).Unix()

		if err := models.DB.Save(&ut).Error; err != nil {
			log.Printf("Failed to reset user tunnel flow: %v", err)
		}
	}

	log.Println("Check and reset flow task completed")
}
