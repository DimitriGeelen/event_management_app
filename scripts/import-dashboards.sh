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
GRAFANA_URL="http://localhost:3000"
GRAFANA_API_KEY="${GRAFANA_API_KEY}"
DASHBOARDS_DIR="./config/grafana/dashboards"

# Check if API key is set
if [ -z "$GRAFANA_API_KEY" ]; then
    error "GRAFANA_API_KEY environment variable is not set"
    exit 1
fi

# Function to import dashboard
import_dashboard() {
    local file=$1
    local filename=$(basename "$file")
    
    log "Importing dashboard: $filename"
    
    # Read dashboard JSON and wrap it in the required format
    local dashboard_json=$(cat "$file")
    local import_json=$(cat <<EOF
{
  "dashboard": $dashboard_json,
  "overwrite": true
}
EOF
)
    
    # Import dashboard via API
    response=$(curl -s -X POST \
        -H "Authorization: Bearer $GRAFANA_API_KEY" \
        -H "Content-Type: application/json" \
        -d "$import_json" \
        "$GRAFANA_URL/api/dashboards/db")
    
    if echo "$response" | grep -q '"status":"success"'; then
        log "Successfully imported $filename"
    else
        error "Failed to import $filename: $response"
        return 1
    fi
}

# Import all dashboards
for dashboard in "$DASHBOARDS_DIR"/*.json; do
    if [ -f "$dashboard" ]; then
        import_dashboard "$dashboard"
    fi
done

log "Dashboard import completed"