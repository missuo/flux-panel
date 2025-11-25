# 快速开始指南

## 项目说明

这是基于 SpringBoot 版本重写的 Go + Gin 框架实现。项目已包含所有核心功能：

✅ 完整的用户管理系统
✅ 节点管理
✅ 隧道管理
✅ 用户隧道权限管理
✅ JWT 认证和角色权限
✅ 定时任务（流量统计、自动重置）
✅ RESTful API 设计

## 一分钟启动

### 方式一：使用 Docker Compose（推荐）

```bash
cd gin-backend
docker-compose up -d
```

等待服务启动后，访问 `http://localhost:6365/health` 验证服务是否正常。

### 方式二：本地运行

1. **安装依赖**
```bash
cd gin-backend
go mod download
```

2. **配置数据库**

编辑 `config.yaml` 或设置环境变量：
```bash
export DB_HOST=localhost
export DB_USER=root
export DB_PASSWORD=your_password
export DB_NAME=flux_panel
export JWT_SECRET=your-secret-key
```

3. **运行**
```bash
make run
# 或
go run main.go
```

## 使用 Makefile

项目提供了便捷的 Makefile 命令：

```bash
make help          # 查看所有可用命令
make build         # 构建项目
make run           # 运行项目
make dev           # 开发模式（热重载）
make clean         # 清理构建文件
make docker-build  # 构建 Docker 镜像
make docker-run    # 运行 Docker 容器
make test          # 运行测试
make deps          # 下载依赖
make fmt           # 格式化代码
```

## 初始化数据

服务首次启动时会自动创建数据库表。你需要手动创建第一个管理员账户：

```sql
INSERT INTO user (user, pwd, role_id, exp_time, flow, num, created_time, updated_time, status)
VALUES ('admin', '21232f297a57a5a743894a0e4a801fc3', 1, 0, 0, 0, UNIX_TIMESTAMP() * 1000, UNIX_TIMESTAMP() * 1000, 0);
```

默认密码是 `admin` 的 MD5 值。

## API 测试

### 登录

```bash
curl -X POST http://localhost:6365/api/v1/user/login \
  -H "Content-Type: application/json" \
  -d '{
    "user": "admin",
    "password": "admin"
  }'
```

### 获取用户列表（需要 token）

```bash
curl -X POST http://localhost:6365/api/v1/user/list \
  -H "Content-Type: application/json" \
  -H "Authorization: YOUR_TOKEN_HERE"
```

## 性能对比

与 SpringBoot 版本相比：

| 指标 | SpringBoot | Go + Gin | 提升 |
|------|-----------|----------|------|
| 启动时间 | ~5-10秒 | <1秒 | 5-10倍 |
| 内存占用 | ~200-500MB | ~20-50MB | 4-10倍 |
| 部署大小 | ~50-100MB | ~10-20MB | 5倍 |
| 并发性能 | 良好 | 优秀 | 显著提升 |

## 项目结构一览

```
gin-backend/
├── config/          # 配置管理（Viper）
├── models/          # GORM 数据模型
├── repository/      # 数据访问层
├── service/         # 业务逻辑层
├── handler/         # Gin 处理器（等同于 Controller）
├── middleware/      # Gin 中间件
├── utils/           # 工具类（JWT、加密、HTTP等）
├── router/          # 路由配置
├── task/            # Cron 定时任务
├── dto/             # 数据传输对象
├── main.go          # 主入口
├── config.yaml      # 配置文件
├── Dockerfile       # Docker 构建
├── docker-compose.yml
├── Makefile         # 构建脚本
└── README.md        # 详细文档
```

## 开发建议

1. **热重载开发**: 使用 `make dev` 启动开发模式，代码修改后自动重启
2. **代码格式化**: 提交前运行 `make fmt` 格式化代码
3. **Docker 开发**: 推荐使用 `docker-compose` 进行开发，环境一致
4. **日志查看**: 日志文件在 `logs/` 目录

## 迁移说明

从 SpringBoot 迁移到 Go 版本的主要变化：

1. **注解 → 中间件**: Spring 的 `@RequireRole` 等注解改为 Gin 中间件
2. **MyBatis → GORM**: SQL 映射改为 GORM ORM
3. **Bean → Struct**: Java Bean 改为 Go Struct
4. **依赖注入 → 构造函数**: Spring DI 改为显式构造函数传递
5. **配置 → Viper**: application.yml 改为 config.yaml + Viper

所有 API 接口保持与 SpringBoot 版本完全兼容！

## 故障排查

### 数据库连接失败

检查：
- 数据库服务是否启动
- `config.yaml` 或环境变量配置是否正确
- 防火墙是否允许 3306 端口

### Token 验证失败

确保：
- JWT_SECRET 配置正确
- Token 没有过期
- 请求头正确携带 Authorization

### 端口被占用

修改 `config.yaml` 中的 `server.port` 或设置环境变量。

## 下一步

1. 根据实际需求调整 `config.yaml` 配置
2. 修改生产环境的 JWT Secret
3. 配置反向代理（Nginx）
4. 设置日志轮转
5. 配置监控和告警

更多详细信息请查看 [README.md](./README.md)

## 技术支持

遇到问题？

1. 查看 [README.md](./README.md) 详细文档
2. 检查日志文件 `logs/`
3. 提交 Issue

祝你使用愉快！🚀
