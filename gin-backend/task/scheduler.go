package task

import (
	"flux-panel/models"
	"flux-panel/service"
	"log"
	"time"

	"github.com/robfig/cron/v3"
	"gorm.io/gorm"
)

var scheduler *cron.Cron
var db *gorm.DB

const bytesToGB = 1024 * 1024 * 1024

// InitScheduler 初始化定时任务
func InitScheduler(database *gorm.DB) {
	db = database
	scheduler = cron.New(cron.WithSeconds())

	// 每小时统计一次流量 (0 0 * * * *)
	_, err := scheduler.AddFunc("0 0 * * * *", StatisticsFlow)
	if err != nil {
		log.Printf("Failed to add statistics flow task: %v", err)
	}

	// 每天凌晨00:00:05检查并重置流量 (5 0 0 * * *)
	_, err = scheduler.AddFunc("5 0 0 * * *", ResetFlowTask)
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

// StatisticsFlow 统计流量 (每小时执行)
func StatisticsFlow() {
	log.Println("Running statistics flow task...")

	now := time.Now()
	currentHour := now.Format("15:04")
	currentTime := now.UnixMilli()

	// 1. 删除48小时前的统计记录
	cutoffTime := currentTime - 48*60*60*1000
	if err := db.Where("created_time < ?", cutoffTime).Delete(&models.StatisticsFlow{}).Error; err != nil {
		log.Printf("Failed to delete old statistics: %v", err)
	}

	// 2. 获取所有用户
	var users []models.User
	if err := db.Find(&users).Error; err != nil {
		log.Printf("Failed to get users: %v", err)
		return
	}

	// 3. 为每个用户计算流量增量并记录
	var stats []models.StatisticsFlow
	for _, user := range users {
		currentTotalFlow := user.InFlow + user.OutFlow

		// 获取上一条记录
		var lastRecord models.StatisticsFlow
		err := db.Where("user_id = ?", user.ID).
			Order("id DESC").
			Limit(1).
			First(&lastRecord).Error

		var incrementFlow int64 = currentTotalFlow
		if err == nil {
			// 有上一条记录，计算增量
			incrementFlow = currentTotalFlow - lastRecord.TotalFlow
			// 如果增量为负（可能是流量重置），则使用当前值
			if incrementFlow < 0 {
				incrementFlow = currentTotalFlow
			}
		}

		stat := models.StatisticsFlow{
			UserID:      int(user.ID),
			Flow:        incrementFlow,
			TotalFlow:   currentTotalFlow,
			Time:        currentHour,
			CreatedTime: currentTime,
		}
		stats = append(stats, stat)
	}

	// 批量保存
	if len(stats) > 0 {
		if err := db.CreateInBatches(stats, 100).Error; err != nil {
			log.Printf("Failed to save statistics: %v", err)
		}
	}

	log.Printf("Statistics flow task completed, processed %d users", len(users))
}

// ResetFlowTask 重置流量任务 (每天00:00:05执行)
func ResetFlowTask() {
	log.Println("Running reset flow task...")

	now := time.Now()
	currentDay := now.Day()
	lastDayOfMonth := time.Date(now.Year(), now.Month()+1, 0, 0, 0, 0, 0, now.Location()).Day()

	log.Printf("当前日期: %v, 当月第%d天, 当月最后一天: %d", now.Format("2006-01-02"), currentDay, lastDayOfMonth)

	// 重置用户流量
	resetUserFlow(currentDay, lastDayOfMonth)

	// 重置用户隧道流量
	resetUserTunnelFlow(currentDay, lastDayOfMonth)

	// 处理过期用户
	handleExpiredUsers()

	// 处理过期隧道
	handleExpiredUserTunnels()

	log.Println("Reset flow task completed")
}

// resetUserFlow 重置用户流量
func resetUserFlow(currentDay, lastDayOfMonth int) {
	var users []models.User

	// 查询需要重置的用户
	// flow_reset_time: 每月第几天重置 (1-31)
	query := db.Where("flow_reset_time != 0")

	if currentDay == lastDayOfMonth {
		// 月末特殊处理：如果用户设置的是31号，但当月只有30天
		query = query.Where("flow_reset_time = ? OR flow_reset_time > ?", currentDay, lastDayOfMonth)
	} else {
		query = query.Where("flow_reset_time = ?", currentDay)
	}

	if err := query.Find(&users).Error; err != nil {
		log.Printf("Failed to get users for reset: %v", err)
		return
	}

	if len(users) == 0 {
		log.Println("没有需要重置流量的用户")
		return
	}

	log.Printf("找到 %d 个需要重置流量的用户", len(users))

	// 使用原子SQL更新避免并发冲突
	for _, user := range users {
		if err := db.Model(&models.User{}).
			Where("id = ?", user.ID).
			Updates(map[string]interface{}{
				"in_flow":  0,
				"out_flow": 0,
			}).Error; err != nil {
			log.Printf("Failed to reset user %d flow: %v", user.ID, err)
		} else {
			log.Printf("用户[ID: %d, 用户名: %s]流量重置成功，重置日期: 每月%d号",
				user.ID, user.User, user.FlowResetTime)
		}
	}
}

// resetUserTunnelFlow 重置用户隧道流量
func resetUserTunnelFlow(currentDay, lastDayOfMonth int) {
	var userTunnels []models.UserTunnel

	query := db.Where("flow_reset_time != 0")

	if currentDay == lastDayOfMonth {
		query = query.Where("flow_reset_time = ? OR flow_reset_time > ?", currentDay, lastDayOfMonth)
	} else {
		query = query.Where("flow_reset_time = ?", currentDay)
	}

	if err := query.Find(&userTunnels).Error; err != nil {
		log.Printf("Failed to get user tunnels for reset: %v", err)
		return
	}

	if len(userTunnels) == 0 {
		return
	}

	log.Printf("找到 %d 个需要重置流量的用户隧道", len(userTunnels))

	for _, ut := range userTunnels {
		if err := db.Model(&models.UserTunnel{}).
			Where("id = ?", ut.ID).
			Updates(map[string]interface{}{
				"in_flow":  0,
				"out_flow": 0,
			}).Error; err != nil {
			log.Printf("Failed to reset user tunnel %d flow: %v", ut.ID, err)
		}
	}
}

// handleExpiredUsers 处理过期用户
func handleExpiredUsers() {
	now := time.Now().UnixMilli()

	var users []models.User
	if err := db.Where("role_id != 0 AND status = 1 AND exp_time IS NOT NULL AND exp_time < ?", now).
		Find(&users).Error; err != nil {
		log.Printf("Failed to get expired users: %v", err)
		return
	}

	for _, user := range users {
		// 查找用户的活跃转发
		var forwards []models.Forward
		db.Where("user_id = ? AND status = 1", user.ID).Find(&forwards)

		for _, forward := range forwards {
			// 获取用户隧道
			var userTunnel models.UserTunnel
			if err := db.Where("user_id = ? AND tunnel_id = ?", forward.UserID, forward.TunnelID).
				First(&userTunnel).Error; err != nil {
				continue
			}

			// 暂停转发服务
			pauseForwardService(&forward, userTunnel.ID)

			// 更新转发状态
			db.Model(&models.Forward{}).Where("id = ?", forward.ID).Update("status", 0)
		}

		// 更新用户状态
		db.Model(&models.User{}).Where("id = ?", user.ID).Update("status", 0)
		log.Printf("用户 %s 已过期并被禁用", user.User)
	}
}

// handleExpiredUserTunnels 处理过期用户隧道
func handleExpiredUserTunnels() {
	now := time.Now().UnixMilli()

	var userTunnels []models.UserTunnel
	if err := db.Where("status = 1 AND exp_time IS NOT NULL AND exp_time < ?", now).
		Find(&userTunnels).Error; err != nil {
		log.Printf("Failed to get expired user tunnels: %v", err)
		return
	}

	for _, ut := range userTunnels {
		// 查找相关的活跃转发
		var forwards []models.Forward
		db.Where("tunnel_id = ? AND user_id = ? AND status = 1", ut.TunnelID, ut.UserID).Find(&forwards)

		for _, forward := range forwards {
			// 暂停转发服务
			pauseForwardService(&forward, ut.ID)

			// 更新转发状态
			db.Model(&models.Forward{}).Where("id = ?", forward.ID).Update("status", 0)
		}

		// 更新隧道状态
		db.Model(&models.UserTunnel{}).Where("id = ?", ut.ID).Update("status", 0)
		log.Printf("用户隧道 %d 已过期并被禁用", ut.ID)
	}
}

// pauseForwardService 暂停转发服务
func pauseForwardService(forward *models.Forward, userTunnelID uint) {
	var tunnel models.Tunnel
	if err := db.First(&tunnel, forward.TunnelID).Error; err != nil {
		return
	}

	serviceName := service.BuildServiceName(forward.ID, forward.UserID, userTunnelID)
	log.Printf("Setting %s to disabled due to traffic limit exceeded", serviceName)

	if tunnel.Type == 1 {
		service.PauseService(tunnel.OutNodeID, serviceName)
	} else if tunnel.Type == 2 {
		service.PauseRemoteService(tunnel.OutNodeID, serviceName)
	}
}
