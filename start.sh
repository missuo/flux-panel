#!/bin/bash

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印彩色信息
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查 Docker
check_docker() {
    print_info "检查 Docker..."
    if ! command -v docker &> /dev/null; then
        print_error "Docker 未安装，请先安装 Docker"
        exit 1
    fi
    print_success "Docker 已安装"
}

# 检查 Docker Compose
check_docker_compose() {
    print_info "检查 Docker Compose..."
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        print_error "Docker Compose 未安装，请先安装 Docker Compose"
        exit 1
    fi
    print_success "Docker Compose 已安装"
}

# 检查环境变量文件
check_env_file() {
    print_info "检查环境变量文件..."
    if [ ! -f .env ]; then
        print_warning ".env 文件不存在，正在从 .env.example 创建..."
        cp .env.example .env
        print_warning "请编辑 .env 文件，设置数据库密码和 JWT Secret"
        print_warning "特别是以下配置："
        echo ""
        echo "  DB_PASSWORD=your_secure_password_here"
        echo "  JWT_SECRET=your_jwt_secret_key_change_in_production"
        echo ""
        read -p "按回车键继续（使用默认配置）或 Ctrl+C 退出编辑配置... " -r
    else
        print_success ".env 文件已存在"
    fi
}

# 生成随机密码
generate_password() {
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-32
}

# 配置向导
config_wizard() {
    print_info "开始配置向导..."

    # 询问是否使用默认配置
    read -p "是否使用默认配置？(y/n) [默认: n]: " use_default
    use_default=${use_default:-n}

    if [ "$use_default" == "y" ]; then
        print_info "使用默认配置..."
        return
    fi

    # 生成随机密码
    db_password=$(generate_password)
    jwt_secret=$(generate_password)

    print_info "已生成随机密码"

    # 询问端口配置
    read -p "前端端口 [默认: 80]: " frontend_port
    frontend_port=${frontend_port:-80}

    read -p "后端端口 [默认: 6365]: " backend_port
    backend_port=${backend_port:-6365}

    # 写入配置文件
    cat > .env << EOF
# 数据库配置
DB_HOST=mysql
DB_PORT=3306
DB_NAME=flux_panel
DB_USER=flux
DB_PASSWORD=${db_password}

# JWT 配置
JWT_SECRET=${jwt_secret}

# 端口配置
BACKEND_PORT=${backend_port}
FRONTEND_PORT=${frontend_port}

# 日志配置
LOG_DIR=/app/logs
EOF

    print_success "配置文件已生成"
    print_warning "重要信息已保存到 .env 文件中，请妥善保管！"
}

# 启动服务
start_services() {
    print_info "启动服务..."

    # 使用 docker compose 或 docker-compose
    if docker compose version &> /dev/null; then
        docker compose up -d
    else
        docker-compose up -d
    fi

    print_success "服务启动成功！"
}

# 等待服务健康
wait_for_services() {
    print_info "等待服务启动..."

    local max_wait=120
    local waited=0

    while [ $waited -lt $max_wait ]; do
        if docker compose ps | grep -q "healthy"; then
            break
        fi
        sleep 2
        waited=$((waited + 2))
        echo -n "."
    done
    echo ""

    if [ $waited -ge $max_wait ]; then
        print_warning "服务启动超时，请检查日志"
    else
        print_success "服务已就绪"
    fi
}

# 显示访问信息
show_access_info() {
    # 读取端口配置
    source .env

    echo ""
    print_success "============================================"
    print_success "  Flux Panel 启动成功！"
    print_success "============================================"
    echo ""
    print_info "访问信息："
    echo "  前端：http://localhost:${FRONTEND_PORT:-80}"
    echo "  后端：http://localhost:${BACKEND_PORT:-6365}"
    echo "  健康检查：http://localhost:${BACKEND_PORT:-6365}/health"
    echo ""
    print_info "默认管理员账户："
    echo "  用户名：admin"
    echo "  密码：admin"
    echo ""
    print_warning "⚠️  重要提醒："
    echo "  1. 首次使用需要初始化数据库并创建管理员账户"
    echo "  2. 请及时修改默认密码"
    echo "  3. 生产环境请修改 .env 中的 JWT_SECRET"
    echo ""
    print_info "常用命令："
    echo "  查看日志：docker compose logs -f"
    echo "  停止服务：docker compose down"
    echo "  重启服务：docker compose restart"
    echo "  查看状态：docker compose ps"
    echo ""
    print_info "详细文档请查看："
    echo "  - DEPLOYMENT.md（部署文档）"
    echo "  - gin-backend/README.md（后端文档）"
    echo "  - vite-frontend/README.md（前端文档）"
    echo ""
}

# 创建管理员账户提示
show_admin_setup() {
    echo ""
    print_warning "============================================"
    print_warning "  创建管理员账户"
    print_warning "============================================"
    echo ""
    print_info "如果这是首次启动，请执行以下命令创建管理员账户："
    echo ""
    echo "docker compose exec mysql mysql -u root -p\${DB_PASSWORD} flux_panel -e \\"
    echo "\"INSERT INTO user (user, pwd, role_id, exp_time, flow, num, created_time, updated_time, status) \\"
    echo "VALUES ('admin', '21232f297a57a5a743894a0e4a801fc3', 1, 0, 0, 0, UNIX_TIMESTAMP() * 1000, UNIX_TIMESTAMP() * 1000, 0);\""
    echo ""
    print_info "默认密码是 'admin'（MD5值）"
    echo ""
}

# 主函数
main() {
    echo ""
    echo "╔═══════════════════════════════════════════╗"
    echo "║     Flux Panel - 快速启动脚本            ║"
    echo "║     Go + Gin + Vite + MySQL              ║"
    echo "╚═══════════════════════════════════════════╝"
    echo ""

    # 检查依赖
    check_docker
    check_docker_compose

    # 检查并配置环境变量
    check_env_file

    # 如果 .env 是新创建的，运行配置向导
    if [ ! -s .env ] || grep -q "your_secure_password_here" .env; then
        config_wizard
    fi

    # 启动服务
    start_services

    # 等待服务健康
    wait_for_services

    # 显示访问信息
    show_access_info

    # 显示管理员账户创建提示
    show_admin_setup
}

# 运行主函数
main
