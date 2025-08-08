# SRE Health Checker Setup Script for Windows (PowerShell)
# Run with: powershell -ExecutionPolicy Bypass -File setup.ps1

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  SRE Health Checker Setup for Windows" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Function to check command availability
function Test-Command {
    param($Command)
    try {
        if (Get-Command $Command -ErrorAction Stop) {
            return $true
        }
    }
    catch {
        return $false
    }
}

# Check if Docker is installed
Write-Host "Checking prerequisites..." -ForegroundColor Yellow
if (-not (Test-Command "docker")) {
    Write-Host "[ERROR] Docker is not installed or not in PATH." -ForegroundColor Red
    Write-Host "Please install Docker Desktop for Windows first." -ForegroundColor Red
    Write-Host "Download from: https://www.docker.com/products/docker-desktop" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}
Write-Host "[OK] Docker detected" -ForegroundColor Green

# Check if Docker Compose is installed
if (-not (Test-Command "docker-compose")) {
    Write-Host "[ERROR] Docker Compose is not installed." -ForegroundColor Red
    Write-Host "Please ensure Docker Desktop is properly installed." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}
Write-Host "[OK] Docker Compose detected" -ForegroundColor Green
Write-Host ""

# Create directory structure
Write-Host "Creating directory structure..." -ForegroundColor Yellow
$directories = @(
    "prometheus",
    "grafana\provisioning\datasources",
    "grafana\provisioning\dashboards",
    "grafana\dashboards",
    "alertmanager"
)

foreach ($dir in $directories) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}
Write-Host "[OK] Directories created" -ForegroundColor Green
Write-Host ""

# Check if configuration files exist
Write-Host "Checking configuration files..." -ForegroundColor Yellow
$requiredFiles = @("docker-compose.yml", "Dockerfile")

foreach ($file in $requiredFiles) {
    if (-not (Test-Path $file)) {
        Write-Host "[ERROR] $file not found" -ForegroundColor Red
        Write-Host "Please ensure all configuration files are in place" -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }
}
Write-Host "[OK] Configuration files found" -ForegroundColor Green
Write-Host ""

# Check if Docker Desktop is running
Write-Host "Checking Docker status..." -ForegroundColor Yellow
$dockerRunning = $false
try {
    docker info 2>&1 | Out-Null
    $dockerRunning = $?
}
catch {
    $dockerRunning = $false
}

if (-not $dockerRunning) {
    Write-Host "[WARNING] Docker Desktop doesn't seem to be running." -ForegroundColor Yellow
    Write-Host "Attempting to start Docker Desktop..." -ForegroundColor Yellow
    
    # Try to find and start Docker Desktop
    $dockerPaths = @(
        "$env:ProgramFiles\Docker\Docker\Docker Desktop.exe",
        "$env:ProgramFiles(x86)\Docker\Docker\Docker Desktop.exe",
        "$env:LOCALAPPDATA\Docker\Docker Desktop.exe"
    )
    
    $dockerFound = $false
    foreach ($path in $dockerPaths) {
        if (Test-Path $path) {
            Start-Process $path
            $dockerFound = $true
            break
        }
    }
    
    if ($dockerFound) {
        Write-Host "Waiting for Docker to start (this may take a minute)..." -ForegroundColor Yellow
        $attempts = 0
        $maxAttempts = 30
        
        while ($attempts -lt $maxAttempts) {
            Start-Sleep -Seconds 2
            try {
                docker info 2>&1 | Out-Null
                if ($?) {
                    $dockerRunning = $true
                    break
                }
            }
            catch {}
            $attempts++
            Write-Host "." -NoNewline
        }
        Write-Host ""
    }
    
    if (-not $dockerRunning) {
        Write-Host "[ERROR] Docker Desktop failed to start." -ForegroundColor Red
        Write-Host "Please start Docker Desktop manually and run this script again." -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }
}
Write-Host "[OK] Docker is running" -ForegroundColor Green
Write-Host ""

# Stop any existing containers
Write-Host "Stopping any existing containers..." -ForegroundColor Yellow
docker-compose down 2>&1 | Out-Null

# Build and start containers
Write-Host "Building Docker images (this may take a few minutes)..." -ForegroundColor Yellow
$buildResult = docker-compose build --no-cache 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Failed to build Docker images" -ForegroundColor Red
    Write-Host $buildResult
    Read-Host "Press Enter to exit"
    exit 1
}
Write-Host "[OK] Docker images built" -ForegroundColor Green
Write-Host ""

Write-Host "Starting services..." -ForegroundColor Yellow
$startResult = docker-compose up -d 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Failed to start services" -ForegroundColor Red
    Write-Host $startResult
    Read-Host "Press Enter to exit"
    exit 1
}

# Wait for services to start
Write-Host "Waiting for services to initialize..." -ForegroundColor Yellow
Start-Sleep -Seconds 15

# Function to check service health
function Test-ServiceHealth {
    param(
        [string]$ServiceName,
        [string]$Port,
        [string]$HealthPath
    )
    
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:$Port$HealthPath" -UseBasicParsing -TimeoutSec 5 -ErrorAction SilentlyContinue
        if ($response.StatusCode -eq 200 -or $response.StatusCode -eq 302) {
            Write-Host "[OK] $ServiceName is running on port $Port" -ForegroundColor Green
            return $true
        }
    }
    catch {}
    
    Write-Host "[WARNING] $ServiceName is not responding on port $Port" -ForegroundColor Yellow
    return $false
}

# Check service health
Write-Host ""
Write-Host "Checking service status..." -ForegroundColor Yellow
Write-Host "========================" -ForegroundColor Yellow

Test-ServiceHealth -ServiceName "Health Checker" -Port 8080 -HealthPath "/health" | Out-Null
Test-ServiceHealth -ServiceName "Prometheus" -Port 9090 -HealthPath "/-/healthy" | Out-Null
Test-ServiceHealth -ServiceName "Grafana" -Port 3000 -HealthPath "/api/health" | Out-Null
Test-ServiceHealth -ServiceName "AlertManager" -Port 9093 -HealthPath "/-/healthy" | Out-Null

Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host "    Setup Complete!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Access your services:" -ForegroundColor Cyan
Write-Host "  Health Checker:  " -NoNewline; Write-Host "http://localhost:8080" -ForegroundColor Yellow
Write-Host "  Grafana:         " -NoNewline; Write-Host "http://localhost:3000" -ForegroundColor Yellow -NoNewline; Write-Host " (admin/admin)" -ForegroundColor Gray
Write-Host "  Prometheus:      " -NoNewline; Write-Host "http://localhost:9090" -ForegroundColor Yellow
Write-Host "  AlertManager:    " -NoNewline; Write-Host "http://localhost:9093" -ForegroundColor Yellow
Write-Host ""
Write-Host "API Endpoints:" -ForegroundColor Cyan
Write-Host "  Health Status:   " -NoNewline; Write-Host "http://localhost:8080/status" -ForegroundColor Yellow
Write-Host "  Metrics:         " -NoNewline; Write-Host "http://localhost:8080/metrics" -ForegroundColor Yellow
Write-Host ""
Write-Host "Useful commands:" -ForegroundColor Cyan
Write-Host "  View logs:       " -NoNewline; Write-Host "docker-compose logs -f [service-name]" -ForegroundColor Gray
Write-Host "  Stop all:        " -NoNewline; Write-Host "docker-compose down" -ForegroundColor Gray
Write-Host "  Restart:         " -NoNewline; Write-Host "docker-compose restart" -ForegroundColor Gray
Write-Host "  View status:     " -NoNewline; Write-Host "docker-compose ps" -ForegroundColor Gray
Write-Host ""

# Open browser
$openBrowser = Read-Host "Would you like to open Grafana in your browser? (Y/N)"
if ($openBrowser -eq 'Y' -or $openBrowser -eq 'y') {
    Start-Process "http://localhost:3000"
}

Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")