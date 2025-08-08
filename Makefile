.PHONY: help build up down restart logs status clean setup metrics

# Default target
help:
	@echo "SRE Health Checker - Makefile Commands"
	@echo "======================================"
	@echo "  make setup     - Initial setup (creates directories and config files)"
	@echo "  make build     - Build Docker images"
	@echo "  make up        - Start all services"
	@echo "  make down      - Stop all services"
	@echo "  make restart   - Restart all services"
	@echo "  make logs      - View logs (all services)"
	@echo "  make status    - Check service status"
	@echo "  make clean     - Remove containers and volumes"
	@echo "  make metrics   - Display current metrics"
	@echo "  make dev       - Run health checker locally (no Docker)"
	@echo ""
	@echo "Service-specific logs:"
	@echo "  make logs-app  - Health checker logs"
	@echo "  make logs-prom - Prometheus logs"
	@echo "  make logs-graf - Grafana logs"

# Setup project structure
setup:
	@echo "Setting up project structure..."
	@mkdir -p prometheus grafana/provisioning/datasources grafana/provisioning/dashboards grafana/dashboards alertmanager
	@chmod +x setup.sh
	@echo "✓ Setup complete"

# Build Docker images
build:
	@echo "Building Docker images..."
	@docker-compose build --no-cache

# Start all services
up:
	@echo "Starting all services..."
	@docker-compose up -d
	@sleep 5
	@make status

# Stop all services
down:
	@echo "Stopping all services..."
	@docker-compose down

# Restart all services
restart:
	@echo "Restarting all services..."
	@docker-compose restart
	@sleep 5
	@make status

# View logs for all services
logs:
	@docker-compose logs -f --tail=100

# Service-specific logs
logs-app:
	@docker-compose logs -f --tail=100 health-checker

logs-prom:
	@docker-compose logs -f --tail=100 prometheus

logs-graf:
	@docker-compose logs -f --tail=100 grafana

logs-alert:
	@docker-compose logs -f --tail=100 alertmanager

# Check service status
status:
	@echo "Checking service status..."
	@echo "========================"
	@docker-compose ps
	@echo ""
	@echo "Service URLs:"
	@echo "  Health Checker: http://localhost:8080"
	@echo "  Grafana:        http://localhost:3000 (admin/admin)"
	@echo "  Prometheus:     http://localhost:9090"
	@echo "  AlertManager:   http://localhost:9093"

# Clean up containers and volumes
clean:
	@echo "Cleaning up containers and volumes..."
	@docker-compose down -v
	@docker system prune -f
	@echo "✓ Cleanup complete"

# Display current metrics
metrics:
	@echo "Current Metrics:"
	@echo "==============="
	@curl -s http://localhost:8080/metrics | grep -E "^service_" | head -20

# Run locally for development
dev:
	@echo "Running health checker locally..."
	@go run main.go

# Quick health check
health:
	@echo "Health Check Status:"
	@curl -s http://localhost:8080/status | jq '.'

# Run tests
test:
	@echo "Running tests..."
	@go test -v ./...

# Format Go code
fmt:
	@echo "Formatting Go code..."
	@go fmt ./...
	@echo "✓ Code formatted"

# Run linter
lint:
	@echo "Running linter..."
	@golangci-lint run
	@echo "✓ Linting complete"