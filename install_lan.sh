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

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
    error "Please run as root (use sudo)"
    exit 1
fi

# Create log directory
NPM_LOG_DIR="/var/log/npm"
mkdir -p "$NPM_LOG_DIR"

# Get network interface
PRIMARY_INTERFACE=$(ip route | grep default | awk '{print $5}' | head -n1)
IP_ADDRESS=$(ip -4 addr show $PRIMARY_INTERFACE | grep -oP '(?<=inet\s)\d+(\.\d+){3}')

log "Installing on interface ${PRIMARY_INTERFACE} with IP ${IP_ADDRESS}"

# Update system
log "Updating system packages..."
apt update
apt upgrade -y

# Install build essentials first
log "Installing build essentials..."
apt install -y build-essential python3-pip

# Remove existing Node.js and npm
log "Removing existing Node.js and npm installations..."
apt remove -y nodejs npm
apt autoremove -y

# Install Node.js and npm
log "Installing Node.js and npm..."
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt install -y nodejs

# Set npm log level to verbose temporarily
export npm_config_loglevel=verbose

# Configure npm
log "Configuring npm..."
NPM_PREFIX="/usr/local"
npm config set prefix "$NPM_PREFIX"

# Fix permissions
log "Setting up npm permissions..."
if [ -n "$SUDO_USER" ]; then
    mkdir -p "$NPM_PREFIX/lib/node_modules"
    chown -R $SUDO_USER:$SUDO_USER "$NPM_PREFIX/lib/node_modules"
    chown -R $SUDO_USER:$SUDO_USER /usr/lib/node_modules
    mkdir -p "/home/$SUDO_USER/.npm"
    chown -R $SUDO_USER:$SUDO_USER "/home/$SUDO_USER/.npm"
fi

# Update npm
log "Updating npm..."
su - $SUDO_USER -c "npm install -g npm@latest" >> "$NPM_LOG_DIR/npm-install.log" 2>&1

# Install global packages with error handling
install_global_package() {
    local package=$1
    log "Installing $package..."
    if ! su - $SUDO_USER -c "npm install -g $package" >> "$NPM_LOG_DIR/npm-install.log" 2>&1; then
        warning "Failed to install $package. Retrying with --no-optional..."
        if ! su - $SUDO_USER -c "npm install -g $package --no-optional" >> "$NPM_LOG_DIR/npm-install.log" 2>&1; then
            error "Failed to install $package. Check $NPM_LOG_DIR/npm-install.log for details"
            return 1
        fi
    fi
    return 0
}

# Install required global packages
GLOBAL_PACKAGES=("nodemon" "pm2" "typescript" "@vue/cli")
for package in "${GLOBAL_PACKAGES[@]}"; do
    install_global_package "$package"
done

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
    htop

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
chown -R $SUDO_USER:$SUDO_USER "${APP_DIR}"

# Clone repository
log "Cloning repository..."
su - $SUDO_USER -c "git clone https://github.com/DimitriGeelen/event_management_app.git ${APP_DIR}"

# Install project dependencies
cd "${APP_DIR}"

# Install backend dependencies
log "Installing backend dependencies..."
su - $SUDO_USER -c "cd ${APP_DIR} && npm install" >> "$NPM_LOG_DIR/npm-install.log" 2>&1

# Install frontend dependencies
log "Installing frontend dependencies..."
su - $SUDO_USER -c "cd ${APP_DIR}/frontend && npm install" >> "$NPM_LOG_DIR/npm-install.log" 2>&1

# Check for npm errors
if grep -i "error" "$NPM_LOG_DIR/npm-install.log"; then
    warning "Some npm errors occurred during installation. Running npm fix script..."
    bash ./scripts/npm-fix.sh
fi

# Configure Nginx for LAN access
log "Configuring Nginx..."
cat > /etc/nginx/sites-available/event-management << EOL
server {
    listen 80;
    server_name $IP_ADDRESS;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }

    location /api {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }

    location /grafana/ {
        proxy_pass http://localhost:3000/;
    }

    location /kibana/ {
        proxy_pass http://localhost:5601/;
    }
}
EOL

# Enable Nginx site
ln -sf /etc/nginx/sites-available/event-management /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Configure firewall
log "Configuring firewall..."
ufw allow ssh
ufw allow http
ufw allow from 192.168.0.0/16 to any port 3000
ufw allow from 192.168.0.0/16 to any port 5000
ufw allow from 192.168.0.0/16 to any port 27017
ufw allow from 192.168.0.0/16 to any port 9090
ufw allow from 192.168.0.0/16 to any port 5601

# Enable firewall
echo "y" | ufw enable

# Start services
log "Starting services..."
systemctl restart nginx
docker-compose -f docker-compose.prod.yml up -d
docker-compose -f docker-compose.monitoring.yml up -d

# Set correct permissions
chown -R www-data:www-data "${APP_DIR}"
chmod -R 755 "${APP_DIR}"

# Create uploads directory with proper permissions
mkdir -p "${APP_DIR}/uploads"
chown -R www-data:www-data "${APP_DIR}/uploads"
chmod -R 755 "${APP_DIR}/uploads"

log "Installation completed!"
log "Application is available at: http://${IP_ADDRESS}"
log "Monitoring dashboard: http://${IP_ADDRESS}/grafana"
log "Logs dashboard: http://${IP_ADDRESS}/kibana"

# Print credentials
log "\nCredentials:"
log "MongoDB Root Username: admin"
log "MongoDB Root Password: $(grep MONGO_ROOT_PASSWORD .env | cut -d'=' -f2)"
log "Grafana Admin Password: $(grep GRAFANA_PASSWORD .env | cut -d'=' -f2)"

warning "\nPlease save these credentials in a secure location!"
warning "For security, consider changing the default passwords."