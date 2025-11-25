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
				adminTunnel.POST("/update", tunnelHandler.UpdateTunnel)
				adminTunnel.POST("/delete", tunnelHandler.DeleteTunnel)

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
	}

	// 健康检查
	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"status": "ok",
		})
	})

	return r
}
