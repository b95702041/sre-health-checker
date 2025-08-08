@echo off
setlocal enabledelayedexpansion

echo ========================================
echo   SRE Health Checker Setup for Windows
echo ========================================
echo.

:: Check if Docker is installed
docker --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Docker is not installed or not in PATH.
    echo Please install Docker Desktop for Windows first.
    echo Download from: https://www.docker.com/products/docker-desktop
    pause
    exit /b 1
)
echo [OK] Docker detected

:: Check if Docker Compose is installed
docker-compose --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Docker Compose is not installed.
    echo Please ensure Docker Desktop is properly installed.
    pause
    exit /b 1
)
echo [OK] Docker Compose detected
echo.

:: Create directory structure
echo Creating directory structure...
if not exist "prometheus" mkdir prometheus
if not exist "grafana\provisioning\datasources" mkdir grafana\provisioning\datasources
if not exist "grafana\provisioning\dashboards" mkdir grafana\provisioning\dashboards  
if not exist "grafana\dashboards" mkdir grafana\dashboards
if not exist "alertmanager" mkdir alertmanager
echo [OK] Directories created
echo.

:: Check if configuration files exist
echo Checking configuration files...
if not exist "docker-compose.yml" (
    echo [ERROR] docker-compose.yml not found
    echo Please ensure all configuration files are in place
    pause
    exit /b 1
)

if not exist "Dockerfile" (
    echo [ERROR] Dockerfile not found
    echo Please ensure all configuration files are in place
    pause
    exit /b 1
)
echo [OK] Configuration files found
echo.

:: Check if Docker Desktop is running
docker info >nul 2>&1
if %errorlevel% neq 0 (
    echo [WARNING] Docker Desktop doesn't seem to be running.
    echo Starting Docker Desktop...
    start "" "C:\Program Files\Docker\Docker\Docker Desktop.exe"
    echo Waiting for Docker to start (this may take a minute)...
    timeout /t 30 /nobreak >nul
    
    :: Check again
    docker info >nul 2>&1
    if %errorlevel% neq 0 (
        echo [ERROR] Docker Desktop failed to start.
        echo Please start Docker Desktop manually and run this script again.
        pause
        exit /b 1
    )
)
echo [OK] Docker is running
echo.

:: Stop any existing containers
echo Stopping any existing containers...
docker-compose down >nul 2>&1

:: Build and start containers
echo Building Docker images (this may take a few minutes)...
docker-compose build --no-cache
if %errorlevel% neq 0 (
    echo [ERROR] Failed to build Docker images
    pause
    exit /b 1
)
echo [OK] Docker images built
echo.

echo Starting services...
docker-compose up -d
if %errorlevel% neq 0 (
    echo [ERROR] Failed to start services
    pause
    exit /b 1
)

:: Wait for services to start
echo Waiting for services to initialize...
timeout /t 15 /nobreak >nul

:: Check service health
echo.
echo Checking service status...
echo ========================

:: Check Health Checker
curl -s -o nul -w "%%{http_code}" http://localhost:8080/health >temp.txt 2>nul
set /p status=<temp.txt
del temp.txt
if "!status!"=="200" (
    echo [OK] Health Checker is running on port 8080
) else (
    echo [WARNING] Health Checker is not responding on port 8080
)

:: Check Prometheus
curl -s -o nul -w "%%{http_code}" http://localhost:9090/-/healthy >temp.txt 2>nul
set /p status=<temp.txt
del temp.txt
if "!status!"=="200" (
    echo [OK] Prometheus is running on port 9090
) else (
    echo [WARNING] Prometheus is not responding on port 9090
)

:: Check Grafana
curl -s -o nul -w "%%{http_code}" http://localhost:3000/api/health >temp.txt 2>nul
set /p status=<temp.txt
del temp.txt
if "!status!"=="200" (
    echo [OK] Grafana is running on port 3000
) else (
    echo [WARNING] Grafana is not responding on port 3000
)

:: Check AlertManager
curl -s -o nul -w "%%{http_code}" http://localhost:9093/-/healthy >temp.txt 2>nul
set /p status=<temp.txt
del temp.txt
if "!status!"=="200" (
    echo [OK] AlertManager is running on port 9093
) else (
    echo [WARNING] AlertManager is not responding on port 9093
)

echo.
echo ==========================================
echo    Setup Complete!
echo ==========================================
echo.
echo Access your services:
echo   Health Checker:  http://localhost:8080
echo   Grafana:         http://localhost:3000 (admin/admin)
echo   Prometheus:      http://localhost:9090
echo   AlertManager:    http://localhost:9093
echo.
echo API Endpoints:
echo   Health Status:   http://localhost:8080/status
echo   Metrics:         http://localhost:8080/metrics
echo.
echo Useful commands:
echo   View logs:       docker-compose logs -f [service-name]
echo   Stop all:        docker-compose down
echo   Restart:         docker-compose restart
echo   View status:     docker-compose ps
echo.
echo Press any key to exit...
pause >nul