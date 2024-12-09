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

# Set up build directory
APP_DIR="/opt/event_management_app"
BUILD_DIR="/tmp/event_management_build"

# Clean up function
cleanup() {
    log "Cleaning up build directory..."
    rm -rf "$BUILD_DIR"
}

# Set up trap to clean up on exit
trap cleanup EXIT

# Create build directory
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Copy application files to build directory
cp -r "$APP_DIR"/* "$BUILD_DIR"/

# Navigate to build directory
cd "$BUILD_DIR"

# Ensure node_modules is clean
log "Cleaning node_modules..."
rm -rf frontend/node_modules
rm -rf node_modules

# Install dependencies for frontend
log "Installing frontend dependencies..."
cd frontend
npm install --production=false || {
    error "Failed to install frontend dependencies"
    exit 1
}

# Build frontend
log "Building frontend..."
npm run build || {
    error "Failed to build frontend"
    exit 1
}

# Go back to root directory
cd ..

# Build Docker images
log "Building Docker images..."

# Build with error handling
if ! docker-compose -f docker-compose.prod.yml build --no-cache; then
    error "Failed to build Docker images"
    exit 1
}

# Stop existing containers
log "Stopping existing containers..."
docker-compose -f docker-compose.prod.yml down || true

# Start new containers
log "Starting containers..."
if ! docker-compose -f docker-compose.prod.yml up -d; then
    error "Failed to start containers"
    exit 1
fi

# Wait for services to be ready
log "Waiting for services to be ready..."
sleep 10

# Check if services are running
log "Verifying services..."

# Function to check if a service is running
check_service() {
    local service=$1
    local container_name="event_management_app_${service}_1"
    if ! docker ps | grep -q "$container_name"; then
        error "Service $service is not running"
        docker logs "$container_name"
        return 1
    fi
    return 0
}

# Check main services
check_service frontend
check_service backend
check_service mongodb

log "Docker build and deployment completed successfully!"
