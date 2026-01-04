package router

import (
	"flux-panel/handler"
	"flux-panel/middleware"
	"flux-panel/models"
	"flux-panel/websocket"

	"github.com/gin-gonic/gin"
)

// SetupRouter 设置路由
func SetupRouter() *gin.Engine {
	r := gin.New()

	// 使用中间件
	r.Use(middleware.Recovery())
	r.Use(middleware.Logger())
	r.Use(middleware.CORS())

	// 创建handlers
	userHandler := handler.NewUserHandler(models.DB)
	nodeHandler := handler.NewNodeHandler(models.DB)
	tunnelHandler := handler.NewTunnelHandler(models.DB)
	configHandler := handler.NewConfigHandler(models.DB)
	forwardHandler := handler.NewForwardHandler(models.DB)
	speedLimitHandler := handler.NewSpeedLimitHandler(models.DB)
	captchaHandler := handler.NewCaptchaHandler(models.DB)
	openApiHandler := handler.NewOpenApiHandler(models.DB)
	flowHandler := handler.NewFlowHandler(models.DB)

	// API v1路由组
	v1 := r.Group("/api/v1")
	{
		// 用户相关路由
		user := v1.Group("/user")
		{
			// 不需要认证的路由
			user.POST("/login", userHandler.Login)

			// 需要认证的路由
			authUser := user.Group("")
			authUser.Use(middleware.JWTAuth())
			{
				authUser.POST("/package", userHandler.GetUserPackage)
				authUser.POST("/updatePassword", userHandler.UpdatePassword)

				// 管理员路由
				adminUser := authUser.Group("")
				adminUser.Use(middleware.RequireRole())
				{
					adminUser.POST("/create", userHandler.CreateUser)
					adminUser.POST("/list", userHandler.GetAllUsers)
					adminUser.POST("/update", userHandler.UpdateUser)
					adminUser.POST("/delete", userHandler.DeleteUser)
					adminUser.POST("/reset", userHandler.ResetFlow)
					adminUser.POST("/toggle-status", userHandler.ToggleUserStatus)
				}
			}
		}

		// 节点相关路由
		node := v1.Group("/node")
		node.Use(middleware.JWTAuth())
		node.Use(middleware.RequireRole())
		{
			node.POST("/create", nodeHandler.CreateNode)
			node.POST("/list", nodeHandler.GetAllNodes)
			node.POST("/update", nodeHandler.UpdateNode)
			node.POST("/delete", nodeHandler.DeleteNode)
			node.POST("/install", nodeHandler.GetInstallCommand)
			node.POST("/check-status", nodeHandler.CheckNodeStatus)
		}

		// 隧道相关路由
		tunnel := v1.Group("/tunnel")
		{
			// 管理员路由
			adminTunnel := tunnel.Group("")
			adminTunnel.Use(middleware.JWTAuth())
			adminTunnel.Use(middleware.RequireRole())
			{
				adminTunnel.POST("/create", tunnelHandler.CreateTunnel)
				adminTunnel.POST("/list", tunnelHandler.GetAllTunnels)
				adminTunnel.POST("/get", tunnelHandler.GetTunnelByID)
				adminTunnel.POST("/update", tunnelHandler.UpdateTunnel)
				adminTunnel.POST("/delete", tunnelHandler.DeleteTunnel)
				adminTunnel.POST("/diagnose", tunnelHandler.DiagnoseTunnel)

				// 用户隧道权限管理
				adminTunnel.POST("/user/assign", tunnelHandler.AssignUserTunnel)
				adminTunnel.POST("/user/list", tunnelHandler.GetUserTunnelList)
				adminTunnel.POST("/user/remove", tunnelHandler.RemoveUserTunnel)
				adminTunnel.POST("/user/update", tunnelHandler.UpdateUserTunnel)
			}

			// 用户路由
			userTunnel := tunnel.Group("")
			userTunnel.Use(middleware.JWTAuth())
			{
				userTunnel.POST("/user/tunnel", tunnelHandler.GetUserTunnels)
			}
		}

		// 配置相关路由
		config := v1.Group("/config")
		{
			// 无需认证即可访问
			config.POST("/list", configHandler.GetConfigs)
			config.POST("/get", configHandler.GetConfigByName)

			// 需要管理员权限
			adminConfig := config.Group("")
			adminConfig.Use(middleware.JWTAuth())
			adminConfig.Use(middleware.RequireRole())
			{
				adminConfig.POST("/update", configHandler.UpdateConfigs)
				adminConfig.POST("/update-single", configHandler.UpdateConfig)
			}
		}

		// 转发相关路由
		forward := v1.Group("/forward")
		forward.Use(middleware.JWTAuth())
		{
			forward.POST("/create", forwardHandler.CreateForward)
			forward.POST("/list", forwardHandler.GetAllForwards)
			forward.POST("/update", forwardHandler.UpdateForward)
			forward.POST("/delete", forwardHandler.DeleteForward)
			forward.POST("/force-delete", forwardHandler.ForceDeleteForward)
			forward.POST("/pause", forwardHandler.PauseForward)
			forward.POST("/resume", forwardHandler.ResumeForward)
			forward.POST("/diagnose", forwardHandler.DiagnoseForward)
			forward.POST("/update-order", forwardHandler.UpdateForwardOrder)
		}

		// 限速规则相关路由
		speedLimit := v1.Group("/speed-limit")
		speedLimit.Use(middleware.JWTAuth())
		speedLimit.Use(middleware.RequireRole())
		{
			speedLimit.POST("/create", speedLimitHandler.CreateSpeedLimit)
			speedLimit.POST("/list", speedLimitHandler.GetAllSpeedLimits)
			speedLimit.POST("/update", speedLimitHandler.UpdateSpeedLimit)
			speedLimit.POST("/delete", speedLimitHandler.DeleteSpeedLimit)
			speedLimit.POST("/tunnels", speedLimitHandler.GetTunnels)
		}

		// 验证码相关路由
		captcha := v1.Group("/captcha")
		{
			captcha.POST("/check", captchaHandler.Check)
			captcha.POST("/generate", captchaHandler.Generate)
			captcha.POST("/verify", captchaHandler.Verify)
			captcha.POST("/verify-turnstile", captchaHandler.VerifyTurnstile)
		}

		// OpenAPI相关路由
		openApi := v1.Group("/open_api")
		{
			openApi.GET("/sub_store", openApiHandler.SubStore)
		}
	}

	// 流量上报相关路由 (无需认证，节点使用secret验证)
	flow := r.Group("/flow")
	{
		flow.POST("/config", flowHandler.Config)
		flow.Any("/test", flowHandler.Test)
		flow.Any("/upload", flowHandler.Upload)
	}

	// WebSocket 节点连接 (路径匹配 Spring Boot 后端)
	wsHandler := websocket.NewHandler(models.DB)
	r.GET("/system-info", wsHandler.HandleConnection)

	// 健康检查
	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"status": "ok",
		})
	})

	return r
}
