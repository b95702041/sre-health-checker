// main.go
package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"sync"
	"time"
)

// Service represents a service to monitor
type Service struct {
	Name     string        `json:"name"`
	URL      string        `json:"url"`
	Interval time.Duration `json:"interval"`
	Timeout  time.Duration `json:"timeout"`
}

// HealthStatus represents the health status of a service
type HealthStatus struct {
	Name         string    `json:"name"`
	URL          string    `json:"url"`
	Healthy      bool      `json:"healthy"`
	ResponseTime int64     `json:"response_time_ms"`
	LastChecked  time.Time `json:"last_checked"`
	Error        string    `json:"error,omitempty"`
}

// HealthChecker manages health checks for multiple services
type HealthChecker struct {
	services []Service
	statuses map[string]*HealthStatus
	mu       sync.RWMutex
}

// NewHealthChecker creates a new health checker instance
func NewHealthChecker(services []Service) *HealthChecker {
	hc := &HealthChecker{
		services: services,
		statuses: make(map[string]*HealthStatus),
	}
	
	// Initialize status for each service
	for _, svc := range services {
		hc.statuses[svc.Name] = &HealthStatus{
			Name:    svc.Name,
			URL:     svc.URL,
			Healthy: false,
		}
	}
	
	return hc
}

// Start begins monitoring all services
func (hc *HealthChecker) Start() {
	for _, svc := range hc.services {
		go hc.monitorService(svc)
	}
}

// monitorService continuously checks a single service
func (hc *HealthChecker) monitorService(svc Service) {
	ticker := time.NewTicker(svc.Interval)
	defer ticker.Stop()
	
	// Check immediately
	hc.checkService(svc)
	
	for range ticker.C {
		hc.checkService(svc)
	}
}

// checkService performs a single health check
func (hc *HealthChecker) checkService(svc Service) {
	start := time.Now()
	
	ctx, cancel := context.WithTimeout(context.Background(), svc.Timeout)
	defer cancel()
	
	req, err := http.NewRequestWithContext(ctx, "GET", svc.URL, nil)
	if err != nil {
		hc.updateStatus(svc.Name, false, 0, err.Error())
		return
	}
	
	client := &http.Client{}
	resp, err := client.Do(req)
	responseTime := time.Since(start).Milliseconds()
	
	if err != nil {
		hc.updateStatus(svc.Name, false, responseTime, err.Error())
		return
	}
	defer resp.Body.Close()
	
	healthy := resp.StatusCode >= 200 && resp.StatusCode < 300
	errorMsg := ""
	if !healthy {
		errorMsg = fmt.Sprintf("HTTP %d", resp.StatusCode)
	}
	
	hc.updateStatus(svc.Name, healthy, responseTime, errorMsg)
}

// updateStatus updates the status of a service
func (hc *HealthChecker) updateStatus(name string, healthy bool, responseTime int64, errorMsg string) {
	hc.mu.Lock()
	defer hc.mu.Unlock()
	
	if status, exists := hc.statuses[name]; exists {
		status.Healthy = healthy
		status.ResponseTime = responseTime
		status.LastChecked = time.Now()
		status.Error = errorMsg
		
		// Log status changes
		if healthy {
			log.Printf("[OK] %s - %dms", name, responseTime)
		} else {
			log.Printf("[FAIL] %s - %s", name, errorMsg)
		}
	}
}

// GetStatuses returns current status of all services
func (hc *HealthChecker) GetStatuses() map[string]*HealthStatus {
	hc.mu.RLock()
	defer hc.mu.RUnlock()
	
	// Create a copy to avoid race conditions
	result := make(map[string]*HealthStatus)
	for k, v := range hc.statuses {
		status := *v
		result[k] = &status
	}
	return result
}

// MetricsHandler provides Prometheus-style metrics
func (hc *HealthChecker) MetricsHandler(w http.ResponseWriter, r *http.Request) {
	statuses := hc.GetStatuses()
	
	w.Header().Set("Content-Type", "text/plain")
	
	// Write metrics in Prometheus format
	fmt.Fprintf(w, "# HELP service_up Whether the service is up (1) or down (0)\n")
	fmt.Fprintf(w, "# TYPE service_up gauge\n")
	
	for name, status := range statuses {
		up := 0
		if status.Healthy {
			up = 1
		}
		fmt.Fprintf(w, "service_up{service=\"%s\",url=\"%s\"} %d\n", name, status.URL, up)
	}
	
	fmt.Fprintf(w, "\n# HELP service_response_time_ms Response time in milliseconds\n")
	fmt.Fprintf(w, "# TYPE service_response_time_ms gauge\n")
	
	for name, status := range statuses {
		fmt.Fprintf(w, "service_response_time_ms{service=\"%s\",url=\"%s\"} %d\n", 
			name, status.URL, status.ResponseTime)
	}
}

// StatusHandler provides JSON status endpoint
func (hc *HealthChecker) StatusHandler(w http.ResponseWriter, r *http.Request) {
	statuses := hc.GetStatuses()
	
	// Calculate overall health
	allHealthy := true
	for _, status := range statuses {
		if !status.Healthy {
			allHealthy = false
			break
		}
	}
	
	response := map[string]interface{}{
		"healthy":  allHealthy,
		"services": statuses,
	}
	
	w.Header().Set("Content-Type", "application/json")
	if !allHealthy {
		w.WriteHeader(http.StatusServiceUnavailable)
	}
	
	json.NewEncoder(w).Encode(response)
}

// HealthHandler provides a simple health check for the monitoring service itself
func HealthHandler(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	w.Write([]byte("OK"))
}

func main() {
	// Define services to monitor
	services := []Service{
		{
			Name:     "google",
			URL:      "https://www.google.com",
			Interval: 30 * time.Second,
			Timeout:  5 * time.Second,
		},
		{
			Name:     "github",
			URL:      "https://api.github.com",
			Interval: 30 * time.Second,
			Timeout:  5 * time.Second,
		},
		{
			Name:     "cloudflare-dns",
			URL:      "https://1.1.1.1/dns-query",
			Interval: 60 * time.Second,
			Timeout:  3 * time.Second,
		},
	}
	
	// Create and start health checker
	checker := NewHealthChecker(services)
	checker.Start()
	
	// Setup HTTP routes
	http.HandleFunc("/health", HealthHandler)
	http.HandleFunc("/status", checker.StatusHandler)
	http.HandleFunc("/metrics", checker.MetricsHandler)
	
	// Simple dashboard
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		html := `
<!DOCTYPE html>
<html>
<head>
    <title>Service Health Dashboard</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
        h1 { color: #333; }
        .service { background: white; padding: 15px; margin: 10px 0; border-radius: 5px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .healthy { border-left: 5px solid #4CAF50; }
        .unhealthy { border-left: 5px solid #f44336; }
        .name { font-weight: bold; font-size: 18px; }
        .url { color: #666; font-size: 14px; }
        .status { margin-top: 10px; }
        .response-time { color: #2196F3; }
        .error { color: #f44336; margin-top: 5px; }
        .refresh { margin: 20px 0; }
    </style>
    <script>
        function refreshStatus() {
            fetch('/status')
                .then(response => response.json())
                .then(data => {
                    const container = document.getElementById('services');
                    container.innerHTML = '';
                    
                    for (const [name, status] of Object.entries(data.services)) {
                        const div = document.createElement('div');
                        div.className = 'service ' + (status.healthy ? 'healthy' : 'unhealthy');
                        
                        let html = '<div class="name">' + status.name + '</div>';
                        html += '<div class="url">' + status.url + '</div>';
                        html += '<div class="status">Status: ' + (status.healthy ? '[OK] Healthy' : '[FAIL] Unhealthy') + '</div>';
                        html += '<div class="response-time">Response Time: ' + status.response_time_ms + 'ms</div>';
                        html += '<div>Last Checked: ' + new Date(status.last_checked).toLocaleString() + '</div>';
                        
                        if (status.error) {
                            html += '<div class="error">Error: ' + status.error + '</div>';
                        }
                        
                        div.innerHTML = html;
                        container.appendChild(div);
                    }
                    
                    document.getElementById('overall').textContent = data.healthy ? '[OK] All Services Healthy' : '[WARNING] Some Services Down';
                });
        }
        
        // Refresh every 5 seconds
        setInterval(refreshStatus, 5000);
        
        // Initial load
        window.onload = refreshStatus;
    </script>
</head>
<body>
    <h1>Service Health Dashboard</h1>
    <div class="refresh">
        <button onclick="refreshStatus()">Refresh Now</button>
        <span id="overall"></span>
    </div>
    <div id="services"></div>
    <div style="margin-top: 30px; padding-top: 20px; border-top: 1px solid #ddd;">
        <h3>API Endpoints:</h3>
        <ul>
            <li><a href="/status">/status</a> - JSON status of all services</li>
            <li><a href="/metrics">/metrics</a> - Prometheus metrics</li>
            <li><a href="/health">/health</a> - Health check for this service</li>
        </ul>
    </div>
</body>
</html>
`
		w.Header().Set("Content-Type", "text/html")
		w.Write([]byte(html))
	})
	
	log.Println("Starting health checker on :8080")
	log.Println("Dashboard: http://localhost:8080")
	log.Println("Status API: http://localhost:8080/status")
	log.Println("Metrics: http://localhost:8080/metrics")
	
	if err := http.ListenAndServe(":8080", nil); err != nil {
		log.Fatal(err)
	}
}