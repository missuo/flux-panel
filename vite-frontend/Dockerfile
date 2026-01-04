# 多阶段构建 - 构建阶段
FROM node:20-alpine AS builder

WORKDIR /app

# 只复制 package 文件用于缓存依赖
COPY package*.json ./

# 安装依赖并清理缓存
RUN npm install && npm cache clean --force

# 复制源代码并构建
COPY . .
RUN npm run build

# 生产阶段 - 使用最小化的 nginx alpine 镜像
FROM nginx:alpine-slim AS production-stage

# 复制 nginx 配置
COPY nginx.conf /etc/nginx/nginx.conf

# 复制构建产物
COPY --from=builder /app/dist /usr/share/nginx/html

# 暴露端口
EXPOSE 80

# 启动 nginx
CMD ["nginx", "-g", "daemon off;"] 