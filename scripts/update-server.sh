#!/bin/bash

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Function to print colored output
log() { echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"; }
warning() { echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"; }
error() { echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"; }

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    error "Please run as root (use sudo)"
    exit 1
fi

# Configuration
APP_DIR="/opt/event_management_app"
BACKUP_DIR="/backup/event_management"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Function to check if service is running
check_service() {
    if systemctl is-active --quiet $1; then
        return 0
    else
        return 1
    fi
}

# Function to stop services
stop_services() {
    log "Stopping services..."
    docker-compose -f docker-compose.prod.yml down
    docker-compose -f docker-compose.monitoring.yml down
}

# Function to start services
start_services() {
    log "Starting services..."
    docker-compose -f docker-compose.prod.yml up -d
    docker-compose -f docker-compose.monitoring.yml up -d
    systemctl restart nginx
}

# Create backup
log "Creating backup..."
mkdir -p "$BACKUP_DIR/$TIMESTAMP"
cp -r "$APP_DIR" "$BACKUP_DIR/$TIMESTAMP/"

# Change to app directory
cd "$APP_DIR"

# Store current git hash
OLD_HASH=$(git rev-parse HEAD)

# Fetch latest changes
log "Fetching latest changes from GitHub..."
if ! git fetch origin main; then
    error "Failed to fetch from GitHub"
    exit 1
fi

# Check if updates are available
if git diff --quiet main origin/main; then
    log "Already up to date"
    exit 0
fi

# Stop services before update
stop_services

# Attempt to update
log "Updating from GitHub..."
if ! git pull origin main; then
    error "Failed to pull changes"
    log "Rolling back to previous version..."
    git reset --hard "$OLD_HASH"
    start_services
    exit 1
fi

# Update dependencies
log "Updating backend dependencies..."
if ! npm install; then
    error "Failed to update backend dependencies"
    log "Rolling back to previous version..."
    git reset --hard "$OLD_HASH"
    npm install
    start_services
    exit 1
fi

# Update frontend dependencies and rebuild
log "Updating frontend dependencies..."
cd frontend
if ! npm install; then
    error "Failed to update frontend dependencies"
    log "Rolling back to previous version..."
    cd ..
    git reset --hard "$OLD_HASH"
    npm install
    cd frontend
    npm install
    start_services
    exit 1
fi

# Build frontend
log "Building frontend..."
if ! npm run build; then
    error "Failed to build frontend"
    log "Rolling back to previous version..."
    cd ..
    git reset --hard "$OLD_HASH"
    npm install
    cd frontend
    npm install
    npm run build
    start_services
    exit 1
fi

cd ..

# Update docker images
log "Updating Docker images..."
if ! docker-compose -f docker-compose.prod.yml pull; then
    error "Failed to pull Docker images"
    log "Rolling back to previous version..."
    git reset --hard "$OLD_HASH"
    start_services
    exit 1
fi

# Start services
start_services

# Verify services are running
log "Verifying services..."
sleep 10

# Check if main services are responding
if ! curl -s http://localhost:5000/health > /dev/null; then
    error "Backend service is not responding"
    warning "Rolling back to previous version..."
    git reset --hard "$OLD_HASH"
    start_services
    exit 1
fi

# Clean up old backups (keep last 7 days)
log "Cleaning up old backups..."
find "$BACKUP_DIR" -maxdepth 1 -type d -mtime +7 -exec rm -rf {} \;

# Update npm packages that might need updating
log "Checking for npm updates..."
npm audit fix
cd frontend && npm audit fix
cd ..

# Clear npm cache
npm cache clean --force

# Restart PM2 processes if any
if command -v pm2 &> /dev/null; then
    log "Restarting PM2 processes..."
    pm2 reload all
fi

# Run database migrations if they exist
if [ -d "$APP_DIR/backend/migrations" ]; then
    log "Running database migrations..."
    node backend/migrations/migrate.js
fi

log "Update completed successfully!"
log "Current version: $(git rev-parse HEAD)"

# Print service status
log "\nService Status:"
docker-compose -f docker-compose.prod.yml ps
docker-compose -f docker-compose.monitoring.yml ps
systemctl status nginx | grep Active

log "\nBackup created at: $BACKUP_DIR/$TIMESTAMP"
