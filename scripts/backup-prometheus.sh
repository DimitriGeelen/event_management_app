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
BACKUP_DIR="/backup/prometheus"
DATETIME=$(date +"%Y%m%d_%H%M%S")
PROM_DATA_DIR="/var/lib/prometheus/data"

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Stop Prometheus container
log "Stopping Prometheus container..."
docker-compose stop prometheus

# Create snapshot
log "Creating snapshot..."
tar -czf "${BACKUP_DIR}/prometheus_${DATETIME}.tar.gz" -C "$PROM_DATA_DIR" .

# Start Prometheus container
log "Starting Prometheus container..."
docker-compose start prometheus

# Verify backup
if [ $? -eq 0 ]; then
    log "Backup completed successfully"
    
    # Clean up old backups (keep last 7 days)
    find "$BACKUP_DIR" -type f -mtime +7 -exec rm {} \;
    log "Cleaned up old backups"
    
    # Create backup metadata
    echo "Backup created at: $(date)" > "${BACKUP_DIR}/backup_${DATETIME}.meta"
    echo "Size: $(du -h "${BACKUP_DIR}/prometheus_${DATETIME}.tar.gz" | cut -f1)" >> "${BACKUP_DIR}/backup_${DATETIME}.meta"
    
    log "Backup metadata saved"
else
    error "Backup failed"
    exit 1
fi