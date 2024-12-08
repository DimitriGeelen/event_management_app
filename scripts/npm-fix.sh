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

APP_DIR="/opt/event_management_app"
NPM_LOG_DIR="/var/log/npm"

# Create npm log directory
mkdir -p "$NPM_LOG_DIR"

log "Starting npm troubleshooting..."

# Check npm installation
if ! command -v npm &> /dev/null; then
    error "npm not found. Reinstalling..."
    apt remove -y nodejs npm
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    apt install -y nodejs
fi

# Fix npm permissions
log "Fixing npm permissions..."
chown -R $SUDO_USER:$SUDO_USER ~/.npm
chown -R $SUDO_USER:$SUDO_USER /usr/lib/node_modules
mkdir -p /usr/local/lib/node_modules
chown -R $SUDO_USER:$SUDO_USER /usr/local/lib/node_modules
chmod -R 775 ~/.npm

# Clear npm cache
log "Clearing npm cache..."
su - $SUDO_USER -c "npm cache clean --force"

# Check for global package conflicts
log "Checking global packages..."
NPM_DEBUG=true npm ls -g --depth=0 2> "$NPM_LOG_DIR/npm-debug.log"

# Remove problematic packages
if grep -q "missing: " "$NPM_LOG_DIR/npm-debug.log"; then
    warning "Found missing dependencies. Removing problematic packages..."
    PROBLEM_PACKAGES=$(grep "missing: " "$NPM_LOG_DIR/npm-debug.log" | awk '{print $4}')
    for package in $PROBLEM_PACKAGES; do
        npm uninstall -g "$package"
    done
fi

# Reinstall required global packages
log "Reinstalling required global packages..."
su - $SUDO_USER -c "npm install -g npm@latest"
su - $SUDO_USER -c "npm install -g nodemon pm2 typescript @vue/cli"

# Check project dependencies
if [ -d "$APP_DIR" ]; then
    cd "$APP_DIR"
    log "Checking project dependencies..."
    
    # Backend dependencies
    if [ -f "package.json" ]; then
        log "Fixing backend dependencies..."
        rm -rf node_modules package-lock.json
        su - $SUDO_USER -c "cd $APP_DIR && npm install"
    fi

    # Frontend dependencies
    if [ -d "frontend" ] && [ -f "frontend/package.json" ]; then
        log "Fixing frontend dependencies..."
        cd frontend
        rm -rf node_modules package-lock.json
        su - $SUDO_USER -c "cd $APP_DIR/frontend && npm install"
    fi
fi

# Verify installations
log "Verifying installations..."
node --version
npm --version
npm list -g --depth=0

# Check for remaining errors
if [ -f "$NPM_LOG_DIR/npm-debug.log" ]; then
    if grep -i "error" "$NPM_LOG_DIR/npm-debug.log"; then
        warning "Some npm errors were found. Check $NPM_LOG_DIR/npm-debug.log for details"
    else
        log "No npm errors found"
    fi
fi

# Set up log rotation
cat > /etc/logrotate.d/npm << EOL
$NPM_LOG_DIR/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 644 root root
}
EOL

log "npm troubleshooting completed."
