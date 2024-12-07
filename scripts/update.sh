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

# Check if script is run as root
if [[ $EUID -ne 0 ]]; then
   error "This script must be run as root"
   exit 1
fi

# Update system packages
log "Updating system packages..."
apt update && apt upgrade -y

# Update Node.js packages
log "Updating Node.js packages..."
cd /opt/event_management_app
npm update
npm audit fix

cd frontend
npm update
npm audit fix

# Rebuild frontend
log "Rebuilding frontend..."
npm run build

# Restart services
log "Restarting services..."
pm2 restart all
systemctl restart nginx

# Run security audit
log "Running security audit..."

# Check for known vulnerabilities
npm audit
cd frontend && npm audit

# Update system security
apt install --only-upgrade fail2ban

# Update SSL certificates if they exist
if [ -x "$(command -v certbot)" ]; then
    certbot renew
fi

log "Update completed successfully!"