# 构建阶段
FROM golang:1.23-alpine AS builder

WORKDIR /app

# 安装 upx 用于压缩二进制文件
RUN apk add --no-cache upx

# 复制 go.mod 和 go.sum
COPY go.mod go.sum ./

# 下载依赖
RUN go mod download

# 复制源代码
COPY . .

# 构建应用 - 使用 ldflags 去除调试信息减小体积
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o main . && \
    upx --best --lzma main

# 运行阶段 - 使用 scratch 最小化镜像
FROM scratch

# 从 builder 复制 CA 证书（用于 HTTPS 请求）
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

# 从 builder 复制时区信息
COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo

# 从构建阶段复制二进制文件
COPY --from=builder /app/main /main
COPY --from=builder /app/config.yaml /config.yaml

# 设置时区
ENV TZ=Asia/Shanghai

# 暴露端口
EXPOSE 6365

# 运行应用
ENTRYPOINT ["/main"]
