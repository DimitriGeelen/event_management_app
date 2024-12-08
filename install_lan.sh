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
if [ "$EUID" -ne 0 ]; then
    error "Please run as root (use sudo)"
    exit 1
fi

# Get network interface
PRIMARY_INTERFACE=$(ip route | grep default | awk '{print $5}' | head -n1)
IP_ADDRESS=$(ip -4 addr show $PRIMARY_INTERFACE | grep -oP '(?<=inet\s)\d+(\.\d+){3}')

log "Installing on interface ${PRIMARY_INTERFACE} with IP ${IP_ADDRESS}"

# Update system
log "Updating system packages..."
apt update
apt upgrade -y

# Install Node.js and npm
log "Installing Node.js and npm..."
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
apt install -y nodejs

# Verify npm installation
if ! command -v npm &> /dev/null; then
    log "Installing npm separately..."
    apt install -y npm
fi

# Install npm latest version
log "Updating npm to latest version..."
npm install -g npm@latest

# Install snap
log "Installing snap..."
apt install -y snapd
systemctl enable --now snapd.socket

# Install snap core
log "Installing snap core..."
snap install core

# Install required packages
log "Installing required packages..."
apt install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common \
    git \
    nginx \
    ufw \
    fail2ban \
    net-tools \
    htop \
    build-essential \
    python3-pip

# Install Docker
log "Installing Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
rm get-docker.sh

# Install Docker Compose
log "Installing Docker Compose..."
apt install -y docker-compose

# Add current user to docker group
if [ -n "$SUDO_USER" ]; then
    usermod -aG docker $SUDO_USER
    log "Added user $SUDO_USER to docker group"
fi

# Create app directory
APP_DIR="/opt/event_management_app"
log "Creating application directory at ${APP_DIR}"
mkdir -p "${APP_DIR}"
cd "${APP_DIR}"

# Clone repository
log "Cloning repository..."
git clone https://github.com/DimitriGeelen/event_management_app.git .

# Install global npm packages
log "Installing global npm packages..."
npm install -g nodemon
npm install -g pm2
npm install -g typescript
npm install -g @vue/cli

# Create environment file
log "Creating environment file..."
cat > .env << EOL
MONGODB_URI=mongodb://mongodb:27017/event_management
JWT_SECRET=$(openssl rand -base64 32)
PORT=5000
HOST=0.0.0.0
NODE_ENV=production
GRAFANA_PASSWORD=$(openssl rand -base64 12)
MONGO_ROOT_USERNAME=admin
MONGO_ROOT_PASSWORD=$(openssl rand -base64 12)
EOL

[[ Rest of the installation script content... ]]
