#!/bin/bash

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Function to print colored output
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warning() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
}

# Configuration
API_URL="http://localhost:5000"
PROM_URL="http://localhost:9090"
ES_URL="http://localhost:9200"
KIBANA_URL="http://localhost:5601"
GRAFANA_URL="http://localhost:3000"

# Function to check service health
check_service() {
    local service=$1
    local url=$2
    
    log "Checking $service..."
    response=$(curl -s -o /dev/null -w "%{http_code}" "$url")
    
    if [ "$response" = "200" ]; then
        log "✓ $service is healthy"
        return 0
    else
        error "✗ $service is not responding (HTTP $response)"
        return 1
    fi
}

# Check all services
check_service "API" "$API_URL/health"
check_service "Prometheus" "$PROM_URL/-/healthy"
check_service "Elasticsearch" "$ES_URL/_cluster/health"
check_service "Kibana" "$KIBANA_URL/api/status"
check_service "Grafana" "$GRAFANA_URL/api/health"

# Check disk space
log "Checking disk space..."
disk_usage=$(df -h | grep '/dev/sda1')
disk_used_percent=$(echo "$disk_usage" | awk '{ print $5 }' | sed 's/%//')

if [ "$disk_used_percent" -gt 90 ]; then
    error "Disk usage is critical: ${disk_used_percent}%"
fi

# Check memory usage
log "Checking memory usage..."
mem_free=$(free -m | grep Mem | awk '{ print $4 }')

if [ "$mem_free" -lt 1024 ]; then
    warning "Low memory available: ${mem_free}MB"
fi

# Check Docker containers
log "Checking Docker containers..."
docker ps -a --format "{{.Names}}\t{{.Status}}" | while read container_status; do
    container_name=$(echo "$container_status" | cut -f1)
    status=$(echo "$container_status" | cut -f2)
    
    if [[ $status != *"Up"* ]]; then
        error "Container $container_name is not running: $status"
    else
        log "✓ Container $container_name is running"
    fi
done

# Output summary
log "\nHealth check completed"
