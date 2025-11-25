.PHONY: help build run dev clean docker-build docker-run test

help: ## 显示帮助信息
	@echo "可用的命令:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

build: ## 构建项目
	@echo "Building..."
	@go build -o flux-panel-backend main.go
	@echo "Build completed!"

run: ## 运行项目
	@echo "Running..."
	@go run main.go

dev: ## 开发模式运行（使用 air 热重载）
	@if command -v air > /dev/null; then \
		air; \
	else \
		echo "air not found. Installing..."; \
		go install github.com/cosmtrek/air@latest; \
		air; \
	fi

clean: ## 清理构建文件
	@echo "Cleaning..."
	@rm -f flux-panel-backend
	@rm -rf logs/
	@echo "Clean completed!"

docker-build: ## 构建 Docker 镜像
	@echo "Building Docker image..."
	@docker build -t flux-panel-backend:latest .
	@echo "Docker image built!"

docker-run: ## 运行 Docker 容器
	@echo "Running Docker container..."
	@docker run -d \
		--name flux-panel-backend \
		-p 6365:6365 \
		-e DB_HOST=host.docker.internal \
		-e DB_USER=root \
		-e DB_PASSWORD=password \
		-e DB_NAME=flux_panel \
		-e JWT_SECRET=your-secret-key \
		flux-panel-backend:latest
	@echo "Docker container started!"

docker-stop: ## 停止 Docker 容器
	@echo "Stopping Docker container..."
	@docker stop flux-panel-backend
	@docker rm flux-panel-backend
	@echo "Docker container stopped!"

test: ## 运行测试
	@echo "Running tests..."
	@go test -v ./...

deps: ## 下载依赖
	@echo "Downloading dependencies..."
	@go mod download
	@go mod tidy
	@echo "Dependencies downloaded!"

fmt: ## 格式化代码
	@echo "Formatting code..."
	@go fmt ./...
	@echo "Code formatted!"

lint: ## 运行代码检查
	@echo "Running linter..."
	@if command -v golangci-lint > /dev/null; then \
		golangci-lint run; \
	else \
		echo "golangci-lint not found. Please install it first."; \
		echo "go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest"; \
	fi
