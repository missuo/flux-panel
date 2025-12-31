package main

import (
	"flux-panel/config"
	"flux-panel/models"
	"flux-panel/router"
	"flux-panel/task"
	"fmt"
	"log"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/gin-gonic/gin"
)

func main() {
	// 加载配置
	if err := config.InitConfig(); err != nil {
		log.Fatalf("Failed to initialize config: %v", err)
	}

	// 初始化数据库
	if err := models.InitDB(); err != nil {
		log.Fatalf("Failed to initialize database: %v", err)
	}

	// 自动迁移数据库表
	if err := models.AutoMigrate(); err != nil {
		log.Fatalf("Failed to auto migrate database: %v", err)
	}

	// 初始化定时任务
	task.InitScheduler(models.DB)

	// 设置 Gin 模式
	if config.AppConfig.Server.Mode == "release" {
		gin.SetMode(gin.ReleaseMode)
	}

	// 创建路由
	r := router.SetupRouter()

	// 启动服务器
	port := config.AppConfig.Server.Port
	if port == "" {
		port = "6365"
	}

	log.Printf("Starting server on port %s...", port)

	// 优雅关闭
	go func() {
		if err := r.Run(":" + port); err != nil {
			log.Fatalf("Failed to start server: %v", err)
		}
	}()

	// 等待中断信号
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	log.Println("Shutting down server...")

	// 停止定时任务
	task.StopScheduler()

	// 关闭数据库连接
	if err := models.CloseDB(); err != nil {
		log.Printf("Error closing database: %v", err)
	}

	// 给一些时间完成清理
	time.Sleep(time.Second * 2)
	fmt.Println("Server exited")
}
