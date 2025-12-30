package router

import (
	"flux-panel/handler"
	"flux-panel/middleware"
	"flux-panel/models"

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
		}

		// 验证码相关路由 (暂时禁用验证码)
		captcha := v1.Group("/captcha")
		{
			captcha.POST("/check", func(c *gin.Context) {
				c.JSON(200, gin.H{
					"code": 0,
					"msg":  "success",
					"data": 0,
				})
			})
		}
	}

	// 健康检查
	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"status": "ok",
		})
	})

	return r
}
