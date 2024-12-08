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
BACKUP_DIR="/backup/event_management"
DATETIME=$(date +"%Y%m%d_%H%M%S")
APP_DIR="/opt/event_management_app"

# Create backup directory structure
mkdir -p "${BACKUP_DIR}/${DATETIME}/{
    mongodb,
    uploads,
    configs,
    logs
}"

# Backup MongoDB
log "Backing up MongoDB..."
docker-compose exec -T mongodb mongodump --out=/dump
docker cp $(docker-compose ps -q mongodb):/dump "${BACKUP_DIR}/${DATETIME}/mongodb"

# Backup uploads directory
log "Backing up uploads..."
tar -czf "${BACKUP_DIR}/${DATETIME}/uploads/uploads.tar.gz" -C "${APP_DIR}" uploads

# Backup configuration files
log "Backing up configurations..."
cp "${APP_DIR}/.env" "${BACKUP_DIR}/${DATETIME}/configs/"
cp -r "${APP_DIR}/config" "${BACKUP_DIR}/${DATETIME}/configs/"
cp /etc/nginx/sites-available/event-management "${BACKUP_DIR}/${DATETIME}/configs/"

# Backup logs
log "Backing up logs..."
cp -r "${APP_DIR}/logs" "${BACKUP_DIR}/${DATETIME}/logs/"
cp /var/log/nginx/access.log "${BACKUP_DIR}/${DATETIME}/logs/nginx_access.log"
cp /var/log/nginx/error.log "${BACKUP_DIR}/${DATETIME}/logs/nginx_error.log"

# Create backup metadata
log "Creating backup metadata..."
cat > "${BACKUP_DIR}/${DATETIME}/backup_info.txt" << EOL
Backup created at: $(date)
Server IP: $(hostname -I | awk '{print $1}')
Docker containers:
$(docker ps --format '{{.Names}}\t{{.Status}}')

Disk usage:
$(df -h)

Included files:
$(find "${BACKUP_DIR}/${DATETIME}" -type f -exec ls -lh {} \;)
EOL

# Create single archive of all backups
log "Creating final archive..."
cd "${BACKUP_DIR}"
tar -czf "event_management_backup_${DATETIME}.tar.gz" "${DATETIME}"

# Clean up temporary files
rm -rf "${BACKUP_DIR}/${DATETIME}"

# Remove old backups (keep last 7 days)
find "${BACKUP_DIR}" -name "event_management_backup_*.tar.gz" -mtime +7 -exec rm {} \;

# Verify backup
if [ -f "${BACKUP_DIR}/event_management_backup_${DATETIME}.tar.gz" ]; then
    log "Backup completed successfully: ${BACKUP_DIR}/event_management_backup_${DATETIME}.tar.gz"
    log "Backup size: $(du -h "${BACKUP_DIR}/event_management_backup_${DATETIME}.tar.gz" | cut -f1)"
 else
    error "Backup failed!"
    exit 1
fi

# Optional: Copy to remote location if configured
if [ -n "$BACKUP_REMOTE_PATH" ]; then
    log "Copying backup to remote location..."
    rsync -av "${BACKUP_DIR}/event_management_backup_${DATETIME}.tar.gz" "$BACKUP_REMOTE_PATH"
fi