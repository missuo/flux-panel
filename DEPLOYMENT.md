# Flux Panel 完整部署指南

## 🚀 快速部署（推荐）

### 前置要求

- Docker 20.10+
- Docker Compose 2.0+

### 一键启动

1. **克隆项目**
```bash
git clone <repository-url>
cd flux-panel
```

2. **配置环境变量**
```bash
# 复制环境变量模板
cp .env.example .env

# 编辑 .env 文件，修改以下关键配置：
# - DB_PASSWORD: 设置强密码
# - JWT_SECRET: 设置随机密钥（至少32位）
vim .env
```

3. **启动所有服务**
```bash
docker-compose up -d
```

4. **查看服务状态**
```bash
docker-compose ps
```

5. **访问系统**
- 前端：http://localhost
- 后端API：http://localhost:6365/health
- 数据库：localhost:3306

## 📦 服务说明

### MySQL 数据库
- **镜像**: mysql:8.0
- **端口**: 3306
- **默认数据库**: flux_panel
- **字符集**: utf8mb4
- **持久化**: mysql_data volume

### Go 后端 (Gin)
- **构建**: 从 `gin-backend/` 目录构建
- **端口**: 6365
- **健康检查**: /health
- **日志**: backend_logs volume

### 前端 (Vite + React)
- **构建**: 从 `vite-frontend/` 目录构建
- **端口**: 80
- **Nginx**: 反向代理后端 API
- **路由**: history 模式支持

## 🔧 详细配置

### 环境变量说明

| 变量 | 说明 | 默认值 | 必需 |
|------|------|--------|------|
| DB_HOST | 数据库地址 | mysql | ✅ |
| DB_PORT | 数据库端口 | 3306 | ✅ |
| DB_NAME | 数据库名 | flux_panel | ✅ |
| DB_USER | 数据库用户 | flux | ✅ |
| DB_PASSWORD | 数据库密码 | password | ✅ |
| JWT_SECRET | JWT密钥 | - | ✅ |
| BACKEND_PORT | 后端端口 | 6365 | ❌ |
| FRONTEND_PORT | 前端端口 | 80 | ❌ |

### 自定义端口

如果 80 端口被占用，可以修改端口：

```bash
# .env 文件
FRONTEND_PORT=8080
BACKEND_PORT=8365
```

然后重启服务：
```bash
docker-compose down
docker-compose up -d
```

## 🗄️ 数据库初始化

### 自动初始化

首次启动时，会自动执行 `gost.sql` 初始化脚本。

### 手动初始化

如果自动初始化失败，可以手动导入：

```bash
# 进入 MySQL 容器
docker-compose exec mysql mysql -u root -p

# 在 MySQL 中执行
USE flux_panel;
SOURCE /docker-entrypoint-initdb.d/init.sql;
```

### 创建管理员账户

```bash
# 进入 MySQL 容器
docker-compose exec mysql mysql -u root -p flux_panel

# 创建管理员（密码是 admin 的 MD5）
INSERT INTO user (user, pwd, role_id, exp_time, flow, num, created_time, updated_time, status)
VALUES ('admin', '21232f297a57a5a743894a0e4a801fc3', 1, 0, 0, 0, UNIX_TIMESTAMP() * 1000, UNIX_TIMESTAMP() * 1000, 0);
```

默认账户：
- 用户名：`admin`
- 密码：`admin`

## 📊 服务管理

### 查看日志

```bash
# 查看所有服务日志
docker-compose logs -f

# 查看特定服务日志
docker-compose logs -f backend
docker-compose logs -f frontend
docker-compose logs -f mysql
```

### 重启服务

```bash
# 重启所有服务
docker-compose restart

# 重启特定服务
docker-compose restart backend
```

### 停止服务

```bash
# 停止所有服务
docker-compose down

# 停止并删除数据卷（⚠️ 会删除数据库数据）
docker-compose down -v
```

### 更新服务

```bash
# 拉取最新代码
git pull

# 重新构建并启动
docker-compose up -d --build
```

## 🔐 生产环境部署

### 1. 修改默认密码

```bash
# 生成强密码
openssl rand -base64 32

# 生成 JWT Secret
openssl rand -hex 32
```

更新 `.env` 文件：
```bash
DB_PASSWORD=<生成的强密码>
JWT_SECRET=<生成的JWT密钥>
```

### 2. 使用 HTTPS（推荐 Nginx 反向代理）

创建 `nginx-proxy.conf`:

```nginx
server {
    listen 443 ssl http2;
    server_name your-domain.com;

    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;

    location / {
        proxy_pass http://localhost:80;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

server {
    listen 80;
    server_name your-domain.com;
    return 301 https://$server_name$request_uri;
}
```

### 3. 防火墙配置

```bash
# 只开放必要端口
ufw allow 80/tcp
ufw allow 443/tcp
ufw enable
```

### 4. 自动备份数据库

创建备份脚本 `backup.sh`:

```bash
#!/bin/bash
BACKUP_DIR="/backups/mysql"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="flux_panel_${TIMESTAMP}.sql"

mkdir -p $BACKUP_DIR

docker-compose exec -T mysql mysqldump \
  -u root \
  -p${DB_PASSWORD} \
  flux_panel > ${BACKUP_DIR}/${BACKUP_FILE}

# 压缩备份
gzip ${BACKUP_DIR}/${BACKUP_FILE}

# 保留最近7天的备份
find ${BACKUP_DIR} -name "flux_panel_*.sql.gz" -mtime +7 -delete

echo "Backup completed: ${BACKUP_FILE}.gz"
```

添加到 crontab：
```bash
# 每天凌晨2点自动备份
0 2 * * * /path/to/backup.sh >> /var/log/flux-panel-backup.log 2>&1
```

## 🩺 健康检查

### 检查服务状态

```bash
# 前端健康检查
curl http://localhost/

# 后端健康检查
curl http://localhost:6365/health

# 数据库健康检查
docker-compose exec mysql mysqladmin ping -h localhost
```

### 监控资源使用

```bash
# 查看容器资源使用
docker stats
```

## 🐛 故障排查

### 后端无法连接数据库

```bash
# 检查数据库是否已启动
docker-compose ps mysql

# 查看数据库日志
docker-compose logs mysql

# 进入后端容器测试连接
docker-compose exec backend sh
ping mysql
```

### 前端 502 错误

```bash
# 检查后端是否健康
docker-compose exec backend wget -O- http://localhost:6365/health

# 检查 Nginx 配置
docker-compose exec frontend nginx -t

# 查看前端日志
docker-compose logs frontend
```

### 数据库连接数过多

修改 `docker-compose.yml` 中的 MySQL 配置：
```yaml
command: >
  --max_connections=2000
```

## 📈 性能优化

### 1. 调整 MySQL 配置

```yaml
# docker-compose.yml
command: >
  --default-authentication-plugin=mysql_native_password
  --character-set-server=utf8mb4
  --collation-server=utf8mb4_unicode_ci
  --max_connections=2000
  --innodb_buffer_pool_size=512M
  --innodb_log_file_size=128M
  --query_cache_size=32M
```

### 2. 调整后端资源限制

```yaml
# docker-compose.yml
backend:
  deploy:
    resources:
      limits:
        cpus: '2'
        memory: 512M
      reservations:
        memory: 256M
```

### 3. 启用前端缓存

前端的 Nginx 已配置静态资源缓存（1年），无需额外配置。

## 🔄 数据迁移

### 从 SpringBoot 版本迁移

Go 版本完全兼容 SpringBoot 版本的数据库结构，只需：

1. 备份 SpringBoot 版本的数据库
2. 导入到新数据库
3. 启动 Go 版本服务

```bash
# 备份旧数据
docker-compose exec -T mysql-old mysqldump -u root -p flux_panel > backup.sql

# 导入新数据
docker-compose exec -T mysql mysql -u root -p flux_panel < backup.sql
```

## 📝 常用命令速查

```bash
# 启动服务
docker-compose up -d

# 停止服务
docker-compose down

# 查看日志
docker-compose logs -f [service]

# 重启服务
docker-compose restart [service]

# 重新构建
docker-compose up -d --build

# 进入容器
docker-compose exec [service] sh

# 查看状态
docker-compose ps

# 查看资源使用
docker stats

# 备份数据库
docker-compose exec -T mysql mysqldump -u root -p flux_panel > backup.sql

# 恢复数据库
docker-compose exec -T mysql mysql -u root -p flux_panel < backup.sql
```

## 🆘 获取帮助

- 查看后端文档：[gin-backend/README.md](gin-backend/README.md)
- 查看前端文档：[vite-frontend/README.md](vite-frontend/README.md)
- 提交 Issue：GitHub Issues

## 📄 License

MIT License
