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

    # Monitoring endpoints
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
ufw allow from 192.168.0.0/16 to any port 3000 # React dev server
ufw allow from 192.168.0.0/16 to any port 5000 # Backend API
ufw allow from 192.168.0.0/16 to any port 27017 # MongoDB
ufw allow from 192.168.0.0/16 to any port 9090 # Prometheus
ufw allow from 192.168.0.0/16 to any port 3000 # Grafana
ufw allow from 192.168.0.0/16 to any port 5601 # Kibana

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
log "\nCredentials (saved in ${APP_DIR}/.env):"
log "MongoDB Root Username: admin"
log "MongoDB Root Password: $(grep MONGO_ROOT_PASSWORD .env | cut -d'=' -f2)"
log "Grafana Admin Password: $(grep GRAFANA_PASSWORD .env | cut -d'=' -f2)"

warning "\nPlease save these credentials in a secure location!"
warning "For security, consider changing the default passwords."
