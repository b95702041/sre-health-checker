#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Setting up SRE Health Checker with Prometheus & Grafana${NC}"
echo "=================================================="

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker is not installed. Please install Docker first.${NC}"
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}❌ Docker Compose is not installed. Please install Docker Compose first.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Docker and Docker Compose detected${NC}"

# Create directory structure
echo -e "\n${YELLOW}Creating directory structure...${NC}"
mkdir -p prometheus
mkdir -p grafana/provisioning/datasources
mkdir -p grafana/provisioning/dashboards
mkdir -p grafana/dashboards
mkdir -p alertmanager

echo -e "${GREEN}✓ Directories created${NC}"

# Check if configuration files exist
echo -e "\n${YELLOW}Checking configuration files...${NC}"

if [ ! -f "docker-compose.yml" ]; then
    echo -e "${RED}❌ docker-compose.yml not found${NC}"
    echo "Please ensure all configuration files are in place"
    exit 1
fi

if [ ! -f "Dockerfile" ]; then
    echo -e "${RED}❌ Dockerfile not found${NC}"
    echo "Please ensure all configuration files are in place"
    exit 1
fi

echo -e "${GREEN}✓ Configuration files found${NC}"

# Build and start containers
echo -e "\n${YELLOW}Building and starting containers...${NC}"
docker-compose down 2>/dev/null
docker-compose build --no-cache
docker-compose up -d

# Wait for services to start
echo -e "\n${YELLOW}Waiting for services to start...${NC}"
sleep 10

# Check service health
echo -e "\n${YELLOW}Checking service status...${NC}"

# Function to check if service is running
check_service() {
    local service=$1
    local port=$2
    local url=$3
    
    if curl -s -o /dev/null -w "%{http_code}" "http://localhost:${port}${url}" | grep -q "200\|302"; then
        echo -e "${GREEN}✓ ${service} is running on port ${port}${NC}"
        return 0
    else
        echo -e "${RED}❌ ${service} is not responding on port ${port}${NC}"
        return 1
    fi
}

# Check each service
check_service "Health Checker" 8080 "/health"
check_service "Prometheus" 9090 "/-/healthy"
check_service "Grafana" 3000 "/api/health"
check_service "AlertManager" 9093 "/-/healthy"

echo -e "\n${GREEN}=================================================="
echo -e "🎉 Setup Complete!${NC}"
echo -e "${GREEN}==================================================${NC}"
echo ""
echo -e "${YELLOW}Access your services:${NC}"
echo -e "  📊 Health Checker Dashboard: ${GREEN}http://localhost:8080${NC}"
echo -e "  📈 Grafana: ${GREEN}http://localhost:3000${NC} (admin/admin)"
echo -e "  🔍 Prometheus: ${GREEN}http://localhost:9090${NC}"
echo -e "  🔔 AlertManager: ${GREEN}http://localhost:9093${NC}"
echo ""
echo -e "${YELLOW}API Endpoints:${NC}"
echo -e "  • Health Status: ${GREEN}http://localhost:8080/status${NC}"
echo -e "  • Metrics: ${GREEN}http://localhost:8080/metrics${NC}"
echo ""
echo -e "${YELLOW}Useful commands:${NC}"
echo -e "  • View logs: ${GREEN}docker-compose logs -f [service-name]${NC}"
echo -e "  • Stop all: ${GREEN}docker-compose down${NC}"
echo -e "  • Restart: ${GREEN}docker-compose restart${NC}"
echo -e "  • View metrics: ${GREEN}curl http://localhost:8080/metrics${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo -e "  1. Open Grafana at http://localhost:3000"
echo -e "  2. Login with admin/admin"
echo -e "  3. View the pre-configured dashboard"
echo -e "  4. Configure AlertManager for notifications (optional)"