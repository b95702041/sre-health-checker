# SRE Health Checker

A lightweight, concurrent health monitoring service written in Go that checks multiple endpoints and exposes metrics for observability.

## Features

- **Multi-Service Monitoring** - Monitor multiple HTTP/HTTPS endpoints concurrently
- **Configurable Intervals** - Set custom check intervals and timeouts per service
- **Prometheus Metrics** - Export metrics in Prometheus format for integration with monitoring stacks
- **REST API** - JSON API for programmatic access to health status
- **Web Dashboard** - Built-in dashboard with auto-refresh for real-time monitoring
- **Thread-Safe** - Concurrent-safe status updates using mutex locks
- **Detailed Logging** - Comprehensive logging of all health check events

## Quick Start

### Prerequisites

- Go 1.19 or higher
- Git

### Installation

1. Clone the repository:
```bash
git clone https://github.com/b95702041/sre-health-checker.git
cd sre-health-checker
```

2. Run the service:
```bash
go run main.go
```

The service will start on port 8080 by default.

### Building

To build a binary:
```bash
# Windows
go build -o sre-health-checker.exe main.go

# Linux/Mac
go build -o sre-health-checker main.go
```

## Usage

### Accessing the Service

Once running, you can access:

- **Dashboard**: http://localhost:8080
- **JSON Status**: http://localhost:8080/status
- **Prometheus Metrics**: http://localhost:8080/metrics
- **Health Check**: http://localhost:8080/health

### API Endpoints

#### GET /status
Returns JSON with the current status of all monitored services.

**Response Example:**
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

#### GET /metrics
Returns Prometheus-formatted metrics.

**Response Example:**
```
# HELP service_up Whether the service is up (1) or down (0)
# TYPE service_up gauge
service_up{service="google",url="https://www.google.com"} 1

# HELP service_response_time_ms Response time in milliseconds
# TYPE service_response_time_ms gauge
service_response_time_ms{service="google",url="https://www.google.com"} 123
```

#### GET /health
Simple health check endpoint for the monitoring service itself.

**Response:** `200 OK`

## Configuration

Currently, services are configured in the `main()` function. To add or modify services, edit the `services` slice:

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

### Service Configuration Options

- `Name`: Unique identifier for the service
- `URL`: Full URL to check (must include protocol)
- `Interval`: How often to check the service
- `Timeout`: Maximum time to wait for a response

## Default Monitored Services

The application comes pre-configured to monitor:
- **Google** - https://www.google.com (30s interval)
- **GitHub API** - https://api.github.com (30s interval)  
- **Cloudflare DNS** - https://1.1.1.1/dns-query (60s interval)

## Docker Support

### Building Docker Image

Create a `Dockerfile`:
```dockerfile
FROM golang:1.21-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN go build -o health-checker main.go

FROM alpine:latest
RUN apk --no-cache add ca-certificates
WORKDIR /root/
COPY --from=builder /app/health-checker .
EXPOSE 8080
CMD ["./health-checker"]
```

Build and run:
```bash
docker build -t sre-health-checker .
docker run -p 8080:8080 sre-health-checker
```

## Integration with Monitoring Stack

### Prometheus Configuration

Add to your `prometheus.yml`:
```yaml
scrape_configs:
  - job_name: 'health-checker'
    static_configs:
      - targets: ['localhost:8080']
    metrics_path: '/metrics'
    scrape_interval: 30s
```

### Grafana Dashboard

You can create alerts and dashboards using the exported metrics:
- `service_up`: Binary metric (0/1) for service availability
- `service_response_time_ms`: Response time for performance monitoring

## Project Structure
```
sre-health-checker/
├── main.go           # Main application code
├── README.md         # This file
├── go.mod           # Go module file
├── go.sum           # Go dependencies checksum (if any)
└── .gitignore       # Git ignore file
```

## Running Tests

```bash
go test -v ./...
```

## Extending the Project

### Potential Enhancements

1. **Configuration File Support**
   - Add YAML/JSON config file support
   - Environment variable configuration

2. **Alert Notifications**
   - Slack integration
   - Email notifications
   - PagerDuty integration

3. **Advanced Health Checks**
   - Custom health check logic per service
   - TCP/UDP port checks
   - Certificate expiration monitoring

4. **Data Persistence**
   - Store historical data
   - Trend analysis
   - SLA calculations

5. **Authentication**
   - Basic auth for endpoints
   - API key authentication

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Author

**b95702041**
- GitHub: [@b95702041](https://github.com/b95702041)

## License

This project is licensed under the MIT License.

## Acknowledgments

- Built with Go's excellent concurrency primitives
- Inspired by SRE best practices
- Designed for cloud-native environments