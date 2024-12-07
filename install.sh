#!/bin/bash

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

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

# Function to check if a command was successful
check_status() {
    if [ $? -eq 0 ]; then
        log "$1 successful"
    else
        error "$1 failed"
        exit 1
    fi
}

# Check if script is run as root
if [[ $EUID -ne 0 ]]; then
   error "This script must be run as root"
   exit 1
}

# Update system
log "Updating system packages..."
sudo apt update
sudo apt upgrade -y
check_status "System update"

# Install Node.js
log "Installing Node.js..."
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
check_status "Node.js installation"

# Verify Node.js installation
node_version=$(node --version)
log "Node.js version: $node_version"

# Install MongoDB
log "Installing MongoDB..."
curl -fsSL https://pgp.mongodb.com/server-7.0.asc | \
   sudo gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg \
   --dearmor

echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | \
   sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list

sudo apt update
sudo apt install -y mongodb-org
check_status "MongoDB installation"

# Start and enable MongoDB
log "Starting MongoDB service..."
sudo systemctl start mongod
sudo systemctl enable mongod
check_status "MongoDB service start"

# Install Git
log "Installing Git..."
sudo apt install -y git
check_status "Git installation"

# Clone repository
log "Cloning repository..."
git clone https://github.com/DimitriGeelen/event_management_app.git /opt/event_management_app
check_status "Repository clone"

# Create uploads directory
log "Creating uploads directory..."
mkdir -p /opt/event_management_app/uploads
chmod 755 /opt/event_management_app/uploads

# Set up environment variables
log "Setting up environment variables..."
cat > /opt/event_management_app/.env << EOL
MONGODB_URI=mongodb://localhost:27017/event_management
JWT_SECRET=$(openssl rand -base64 32)
PORT=5000
EOL
check_status "Environment setup"

# Install dependencies
log "Installing backend dependencies..."
cd /opt/event_management_app
npm install
check_status "Backend dependencies installation"

log "Installing frontend dependencies..."
cd frontend
npm install
check_status "Frontend dependencies installation"

# Build frontend
log "Building frontend..."
npm run build
check_status "Frontend build"

# Install and configure PM2
log "Setting up PM2..."
sudo npm install -g pm2
cd ..
pm2 start server.js --name event-management-backend
pm2 save
pm2 startup systemd
check_status "PM2 setup"

# Install and configure Nginx
log "Setting up Nginx..."
sudo apt install -y nginx

# Create Nginx configuration
cat > /etc/nginx/sites-available/event-management << EOL
server {
    listen 80;
    server_name _;

    location / {
        root /opt/event_management_app/frontend/build;
        try_files \$uri \$uri/ /index.html;
    }

    location /api {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOL

# Enable site configuration
sudo ln -s /etc/nginx/sites-available/event-management /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default

# Test and restart Nginx
sudo nginx -t
check_status "Nginx configuration test"

sudo systemctl restart nginx
check_status "Nginx restart"

# Configure firewall
log "Configuring firewall..."
sudo ufw allow 'Nginx Full'
sudo ufw allow ssh
echo "y" | sudo ufw enable
check_status "Firewall configuration"

# Final message
log "Installation completed successfully!"
log "You can access the application at: http://$(curl -s ifconfig.me)"
warning "Make sure to secure your MongoDB installation and configure SSL/TLS for production use."
