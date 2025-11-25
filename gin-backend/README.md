# Flux Panel - Go Backend (Gin Framework)

这是 Flux Panel 的 Go 语言版本后端，使用 Gin 框架重写自原有的 SpringBoot 版本。

## 特性

- ✅ 用户管理（登录、CRUD、密码管理、流量管理）
- ✅ 节点管理（节点CRUD、安装命令生成）
- ✅ 隧道管理（隧道CRUD、用户隧道权限分配）
- ✅ JWT 认证
- ✅ 角色权限控制
- ✅ CORS 支持
- ✅ 定时任务（流量统计、流量重置）
- ✅ RESTful API 设计

## 技术栈

- **框架**: Gin
- **ORM**: GORM
- **数据库**: MySQL
- **认证**: JWT
- **配置**: Viper
- **定时任务**: Cron
- **日志**: Gin Logger

## 项目结构

```
gin-backend/
├── config/          # 配置管理
├── models/          # 数据模型
├── repository/      # 数据访问层
├── service/         # 业务逻辑层
├── handler/         # API 处理器（控制器）
├── middleware/      # 中间件
├── utils/           # 工具类
├── router/          # 路由配置
├── task/            # 定时任务
├── dto/             # 数据传输对象
├── config.yaml      # 配置文件
├── main.go          # 主入口
├── Dockerfile       # Docker 构建文件
└── README.md        # 项目说明
```

## 环境要求

- Go 1.21+
- MySQL 5.7+

## 快速开始

### 1. 安装依赖

```bash
cd gin-backend
go mod download
```

### 2. 配置数据库

编辑 `config.yaml` 文件，配置数据库连接信息：

```yaml
database:
  host: "localhost"
  port: 3306
  user: "root"
  password: "your_password"
  dbname: "flux_panel"
```

或者使用环境变量：

```bash
export DB_HOST=localhost
export DB_USER=root
export DB_PASSWORD=your_password
export DB_NAME=flux_panel
export JWT_SECRET=your-jwt-secret
```

### 3. 运行项目

```bash
go run main.go
```

服务将在 `http://localhost:6365` 启动。

### 4. 构建项目

```bash
go build -o flux-panel-backend
./flux-panel-backend
```

## Docker 部署

### 构建镜像

```bash
docker build -t flux-panel-backend:latest .
```

### 运行容器

```bash
docker run -d \
  --name flux-panel-backend \
  -p 6365:6365 \
  -e DB_HOST=mysql \
  -e DB_USER=root \
  -e DB_PASSWORD=password \
  -e DB_NAME=flux_panel \
  -e JWT_SECRET=your-secret-key \
  flux-panel-backend:latest
```

### 使用 Docker Compose

创建 `docker-compose.yml`:

```yaml
version: '3.8'

services:
  mysql:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: password
      MYSQL_DATABASE: flux_panel
    volumes:
      - mysql_data:/var/lib/mysql
    ports:
      - "3306:3306"

  backend:
    build: .
    ports:
      - "6365:6365"
    environment:
      DB_HOST: mysql
      DB_USER: root
      DB_PASSWORD: password
      DB_NAME: flux_panel
      JWT_SECRET: your-secret-key
    depends_on:
      - mysql

volumes:
  mysql_data:
```

运行：

```bash
docker-compose up -d
```

## API 接口

### 用户相关

- `POST /api/v1/user/login` - 用户登录
- `POST /api/v1/user/package` - 获取用户套餐信息（需认证）
- `POST /api/v1/user/updatePassword` - 修改密码（需认证）
- `POST /api/v1/user/create` - 创建用户（管理员）
- `POST /api/v1/user/list` - 用户列表（管理员）
- `POST /api/v1/user/update` - 更新用户（管理员）
- `POST /api/v1/user/delete` - 删除用户（管理员）
- `POST /api/v1/user/reset` - 重置流量（管理员）

### 节点相关

- `POST /api/v1/node/create` - 创建节点（管理员）
- `POST /api/v1/node/list` - 节点列表（管理员）
- `POST /api/v1/node/update` - 更新节点（管理员）
- `POST /api/v1/node/delete` - 删除节点（管理员）
- `POST /api/v1/node/install` - 获取安装命令（管理员）

### 隧道相关

- `POST /api/v1/tunnel/create` - 创建隧道（管理员）
- `POST /api/v1/tunnel/list` - 隧道列表（管理员）
- `POST /api/v1/tunnel/update` - 更新隧道（管理员）
- `POST /api/v1/tunnel/delete` - 删除隧道（管理员）
- `POST /api/v1/tunnel/user/assign` - 分配用户隧道权限（管理员）
- `POST /api/v1/tunnel/user/list` - 用户隧道权限列表（管理员）
- `POST /api/v1/tunnel/user/remove` - 移除用户隧道权限（管理员）
- `POST /api/v1/tunnel/user/update` - 更新用户隧道权限（管理员）
- `POST /api/v1/tunnel/user/tunnel` - 获取用户可用隧道（需认证）

### 健康检查

- `GET /health` - 健康检查

## 配置说明

### config.yaml

```yaml
server:
  port: "6365"              # 服务端口
  mode: "debug"             # 运行模式: debug/release
  max_connections: 2000     # 最大连接数
  shutdown_timeout: 30      # 优雅关闭超时时间（秒）

database:
  host: "localhost"         # 数据库地址
  port: 3306                # 数据库端口
  user: "root"              # 数据库用户
  password: ""              # 数据库密码
  dbname: "flux_panel"      # 数据库名
  max_open_conns: 20        # 最大打开连接数
  max_idle_conns: 5         # 最大空闲连接数
  conn_max_lifetime: 500    # 连接最大生命周期（秒）

jwt:
  secret: "your-secret"     # JWT密钥
  expire_time: 2160         # Token过期时间（小时，默认90天）

captcha:
  enabled: true             # 是否启用验证码
  expire: 120               # 验证码过期时间（秒）

log:
  dir: "./logs"             # 日志目录
  level: "info"             # 日志级别
```

## 与 SpringBoot 版本的对比

| 特性 | SpringBoot | Go + Gin |
|------|------------|----------|
| 启动时间 | ~5-10秒 | <1秒 |
| 内存占用 | ~200-500MB | ~20-50MB |
| 性能 | 良好 | 优秀 |
| 部署大小 | ~50-100MB | ~10-20MB |
| 并发处理 | 线程池 | Goroutine |

## 定时任务

- **流量统计**: 每小时统计一次流量数据
- **流量重置**: 每天凌晨检查并重置到期的流量

## 开发指南

### 添加新的API接口

1. 在 `dto/` 目录下定义请求和响应结构
2. 在 `repository/` 目录下添加数据访问方法
3. 在 `service/` 目录下实现业务逻辑
4. 在 `handler/` 目录下创建处理器
5. 在 `router/router.go` 中注册路由

### 添加新的中间件

在 `middleware/` 目录下创建中间件文件，并在 `router/router.go` 中使用。

### 添加定时任务

在 `task/scheduler.go` 中使用 cron 表达式添加新的定时任务。

## 注意事项

1. 请务必修改生产环境的 JWT Secret
2. 建议使用反向代理（如 Nginx）进行生产部署
3. 定期备份数据库
4. 监控服务器资源使用情况

## License

MIT License

## 贡献

欢迎提交 Issue 和 Pull Request！

## 联系方式

如有问题，请提交 Issue。
