# SRE Health Checker with Prometheus & Grafana

A production-ready, concurrent health monitoring service written in Go with full observability stack including Prometheus metrics collection, Grafana dashboards, and AlertManager notifications.

![Go Version](https://img.shields.io/badge/Go-1.21%2B-blue)
![Docker](https://img.shields.io/badge/Docker-Ready-brightgreen)
![Prometheus](https://img.shields.io/badge/Prometheus-Enabled-orange)
![Grafana](https://img.shields.io/badge/Grafana-Dashboards-purple)

## 🚀 Features

### Core Health Monitoring
- **Multi-Service Monitoring** - Monitor multiple HTTP/HTTPS endpoints concurrently
- **Configurable Intervals** - Set custom check intervals and timeouts per service
- **Thread-Safe** - Concurrent-safe status updates using mutex locks
- **Detailed Logging** - Comprehensive logging of all health check events

### Observability Stack
- **Prometheus Metrics** - Automatic metrics collection and storage
- **Grafana Dashboards** - Pre-configured dashboards with real-time visualizations
- **AlertManager** - Intelligent alert routing for Slack, Email, and PagerDuty
- **Node Exporter** - System metrics (CPU, Memory, Disk usage)
- **Docker Compose** - One-command deployment of entire stack

## 📊 Screenshots

### Service Dashboard
- Real-time service status (UP/DOWN)
- Response time trends
- 24-hour uptime percentage
- Health check frequency

### Available Metrics
- `service_up` - Binary metric (1=up, 0=down)
- `service_response_time_ms` - Response latency
- System metrics via Node Exporter

## 🛠️ Quick Start

### Prerequisites
- Docker Desktop (Windows/Mac) or Docker Engine (Linux)
- Docker Compose
- Git

### Installation

1. **Clone the repository**
```bash
git clone https://github.com/b95702041/sre-health-checker.git
cd sre-health-checker
```

2. **Start the monitoring stack**

**Windows (PowerShell):**
```powershell
.\setup.ps1
```

**Windows (Command Prompt):**
```cmd
setup.bat
```

**Linux/Mac:**
```bash
chmod +x setup.sh
./setup.sh
```

**Using Make:**
```bash
make setup
make up
```

3. **Access the services**
- 📊 **Health Checker**: http://localhost:8080
- 📈 **Grafana**: http://localhost:3000 (admin/admin)
- 🔍 **Prometheus**: http://localhost:9090
- 🔔 **AlertManager**: http://localhost:9093

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         User Browser                         │
└────────────┬────────────────────────────────────┬───────────┘
             │                                    │
             ▼                                    ▼
    ┌────────────────┐                   ┌────────────────┐
    │  Health Checker│                   │    Grafana     │
    │   (Port 8080)  │                   │  (Port 3000)   │
    └────────┬───────┘                   └────────┬───────┘
             │                                    │
             ▼                                    ▼
    ┌────────────────────────────────────────────────────┐
    │                    Prometheus                       │
    │                    (Port 9090)                      │
    │                                                     │
    │  • Scrapes metrics from Health Checker             │
    │  • Stores time-series data                         │
    │  • Evaluates alert rules                           │
    └──────────────────┬──────────────────────────────┘
                       │
                       ▼
              ┌────────────────┐
              │  AlertManager  │
              │  (Port 9093)   │
              │                │
              │ • Slack        │
              │ • Email        │
              │ • PagerDuty    │
              └────────────────┘
```

## 📁 Project Structure

```
sre-health-checker/
├── main.go                          # Main application code
├── go.mod                           # Go module file
├── docker-compose.yml               # Docker Compose configuration
├── Dockerfile                       # Multi-stage Docker build
├── Makefile                         # Build and management commands
├── setup.ps1                        # Windows PowerShell setup
├── setup.bat                        # Windows batch setup
├── setup.sh                         # Linux/Mac setup script
├── prometheus/
│   ├── prometheus.yml               # Prometheus configuration
│   └── alerts.yml                   # Alert rules
├── grafana/
│   ├── provisioning/
│   │   ├── datasources/
│   │   │   └── prometheus.yml      # Datasource configuration
│   │   └── dashboards/
│   │       └── dashboard.yml        # Dashboard provisioning
│   └── dashboards/
│       └── sre-health-dashboard.json # Pre-built dashboard
└── alertmanager/
    └── alertmanager.yml             # Alert routing configuration
```

## 🔧 Configuration

### Adding Services to Monitor

Edit the `services` slice in `main.go`:

```go
services := []Service{
    {
        Name:     "my-api",
        URL:      "https://api.example.com/health",
        Interval: 30 * time.Second,
        Timeout:  5 * time.Second,
    },
    // Add more services here
}
```

Then rebuild:
```bash
docker-compose build
docker-compose up -d
```

### Configuring Alerts

Edit `prometheus/alerts.yml` to customize alert thresholds:

```yaml
- alert: ServiceDown
  expr: service_up == 0
  for: 2m  # Change duration here
  labels:
    severity: critical
```

### Setting Up Notifications

Edit `alertmanager/alertmanager.yml`:

```yaml
# Slack notifications
slack_api_url: 'YOUR_SLACK_WEBHOOK_URL'

# Email configuration
smtp_smarthost: 'smtp.gmail.com:587'
smtp_auth_username: 'your-email@gmail.com'
smtp_auth_password: 'your-app-password'
```

## 📊 API Endpoints

### Health Checker Service

| Endpoint | Description | Response |
|----------|-------------|----------|
| `GET /` | Web dashboard | HTML |
| `GET /health` | Service health check | `200 OK` |
| `GET /status` | JSON status of all services | JSON |
| `GET /metrics` | Prometheus metrics | Prometheus format |

### Example Status Response
```json
{
  "healthy": true,
  "services": {
    "google": {
      "name": "google",
      "url": "https://www.google.com",
      "healthy": true,
      "response_time_ms": 123,
      "last_checked": "2025-01-20T10:30:00Z",
      "error": ""
    }
  }
}
```

## 🐳 Docker Commands

### Basic Operations
```bash
# Start all services
docker-compose up -d

# Stop all services
docker-compose down

# View logs
docker-compose logs -f [service-name]

# Restart a service
docker-compose restart [service-name]

# View running containers
docker-compose ps
```

### Service-Specific Logs
```bash
# Health Checker logs
docker-compose logs -f health-checker

# Prometheus logs
docker-compose logs -f prometheus

# Grafana logs
docker-compose logs -f grafana
```

## 📈 Grafana Dashboard Features

The pre-configured dashboard includes:

- **Service Status Overview** - Real-time UP/DOWN status for all services
- **Response Time Trends** - Historical performance graphs
- **24-Hour Uptime Gauge** - Service availability percentage
- **Health Checks Per Hour** - Monitoring frequency visualization
- **Service Details Table** - Comprehensive service information
- **Auto-refresh** - Updates every 10 seconds

## 🔔 Alert Examples

Pre-configured alerts:

| Alert | Condition | Severity |
|-------|-----------|----------|
| ServiceDown | Service down for 2+ minutes | Critical |
| HighResponseTime | Response > 5 seconds for 5 minutes | Warning |
| CriticalResponseTime | Response > 10 seconds | Critical |
| HighCPUUsage | CPU > 80% for 5 minutes | Warning |
| HighMemoryUsage | Memory > 90% for 5 minutes | Warning |

## 🧪 Development

### Running Locally (without Docker)

```bash
# Run the health checker
go run main.go

# Run tests
go test -v ./...

# Format code
go fmt ./...
```

### Building Binary

```bash
# Windows
go build -o sre-health-checker.exe main.go

# Linux/Mac
go build -o sre-health-checker main.go
```

## 🚀 Production Deployment

### Environment Variables

Create a `.env` file for production:
```env
PROMETHEUS_RETENTION=30d
GRAFANA_ADMIN_PASSWORD=secure-password
ALERT_SLACK_WEBHOOK=https://hooks.slack.com/...
```

### Kubernetes Deployment

Helm charts and Kubernetes manifests coming soon!

### Cloud Deployment

- **AWS**: Use ECS or EKS with Application Load Balancer
- **Azure**: Deploy to AKS or Container Instances
- **GCP**: Use GKE or Cloud Run

## 📚 Advanced Configuration

### Custom Prometheus Queries

Access Prometheus at http://localhost:9090 and try:

```promql
# Average response time last 5 minutes
avg(rate(service_response_time_ms[5m]))

# Uptime percentage
avg_over_time(service_up[24h]) * 100

# Services with high response time
service_response_time_ms > 5000
```

### Grafana Dashboard Customization

1. Login to Grafana (admin/admin)
2. Navigate to Dashboards
3. Click "SRE Service Health Dashboard"
4. Click settings icon to edit
5. Add panels for custom metrics

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📋 Roadmap

- [ ] Support for TCP/UDP health checks
- [ ] SSL certificate expiration monitoring
- [ ] Custom health check scripts
- [ ] Webhook notifications
- [ ] Historical data analysis
- [ ] SLA/SLO tracking
- [ ] Multi-region monitoring
- [ ] Kubernetes operator
- [ ] Terraform modules

## 🐛 Troubleshooting

### Docker Desktop Not Starting (Windows)
```powershell
# Enable WSL 2
wsl --install
wsl --set-default-version 2

# Restart Docker service
Restart-Service docker
```

### Port Already in Use
```bash
# Find process using port (e.g., 8080)
# Windows
netstat -ano | findstr :8080

# Linux/Mac
lsof -i :8080
```

### Grafana Not Loading Dashboard
```bash
# Restart Grafana
docker-compose restart grafana

# Check logs
docker-compose logs grafana
```

## 📖 Documentation

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [AlertManager Documentation](https://prometheus.io/docs/alerting/latest/alertmanager/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)

## 📄 License

This project is licensed under the MIT License.

## 👤 Author

**b95702041**
- GitHub: [@b95702041](https://github.com/b95702041)

## 🙏 Acknowledgments

- Built with Go's excellent concurrency primitives
- Inspired by SRE best practices from Google
- Monitoring patterns from Prometheus community
- Dashboard inspiration from Grafana Labs

## 💬 Support

- Create an [Issue](https://github.com/b95702041/sre-health-checker/issues) for bug reports
- Start a [Discussion](https://github.com/b95702041/sre-health-checker/discussions) for questions
- Check [Wiki](https://github.com/b95702041/sre-health-checker/wiki) for detailed guides

---

Made with ❤️ for the SRE community