#!/bin/bash

# Enable error handling
set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Function to print colored output
log() { echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"; }
warning() { echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"; }
error() { echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"; }

# Error handler
handle_error() {
    local line_number=$1
    local error_code=$2
    error "An error occurred in line ${line_number}, exit code: ${error_code}"
    exit ${error_code}
}

# Set up error handling
trap 'handle_error ${LINENO} $?' ERR

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
    error "Please run as root (use sudo)"
    exit 1
fi

# Create log directory
NPM_LOG_DIR="/var/log/npm"
mkdir -p "$NPM_LOG_DIR"
chmod 755 "$NPM_LOG_DIR"

# Function to retry commands
retry_command() {
    local retries=$1
    shift
    local count=0
    until "$@"; do
        exit=$?
        count=$((count + 1))
        if [ $count -lt $retries ]; then
            warning "Retry $count/$retries: Command failed, retrying in 5 seconds..."
            sleep 5
        else
            error "Command failed after $retries attempts"
            return $exit
        fi
    done
    return 0
}

# Update system
log "Updating system..."
retry_command 3 apt update
retry_command 3 apt upgrade -y

# Install required packages
log "Installing required packages..."
PACKAGES=(
    build-essential
    python3-pip
    apt-transport-https
    ca-certificates
    curl
    software-properties-common
    git
    nginx
    ufw
    fail2ban
    net-tools
    htop
    snapd
)

for package in "${PACKAGES[@]}"; do
    retry_command 3 apt install -y "$package" || { error "Failed to install $package"; exit 1; }
done

# Install Node.js and npm
log "Installing Node.js and npm..."
if ! curl -fsSL https://deb.nodesource.com/setup_20.x -o nodesource_setup.sh; then
    error "Failed to download Node.js setup script"
    exit 1
fi

chmod +x nodesource_setup.sh
if ! ./nodesource_setup.sh; then
    error "Failed to run Node.js setup script"
    exit 1
fi
rm nodesource_setup.sh

retry_command 3 apt install -y nodejs

# Verify Node.js installation
if ! command -v node >/dev/null 2>&1 || ! command -v npm >/dev/null 2>&1; then
    error "Node.js or npm installation failed"
    exit 1
fi

# Install Docker
log "Installing Docker..."
if ! curl -fsSL https://get.docker.com -o get-docker.sh; then
    error "Failed to download Docker installation script"
    exit 1
fi

chmod +x get-docker.sh
if ! ./get-docker.sh; then
    error "Failed to install Docker"
    exit 1
fi
rm get-docker.sh

# Install Docker Compose
log "Installing Docker Compose..."
retry_command 3 apt install -y docker-compose

# Start and enable Docker service
systemctl start docker
systemctl enable docker

# Create app directory
APP_DIR="/opt/event_management_app"
log "Creating application directory at ${APP_DIR}"
mkdir -p "$APP_DIR"

# Clone repository
log "Cloning repository..."
git clone https://github.com/DimitriGeelen/event_management_app.git "$APP_DIR"

# Set up frontend
cd "$APP_DIR/frontend"
log "Setting up frontend..."

# Install frontend dependencies
log "Installing frontend dependencies..."
if ! npm install; then
    error "Failed to install main frontend dependencies"
    exit 1
fi

# Install Tailwind CSS and its dependencies
log "Installing Tailwind CSS dependencies..."
if ! npm install -D tailwindcss@latest postcss@latest autoprefixer@latest @tailwindcss/forms@latest; then
    error "Failed to install Tailwind CSS dependencies"
    exit 1
fi

# Initialize Tailwind CSS if not already initialized
if [ ! -f "tailwind.config.js" ] || [ ! -f "postcss.config.js" ]; then
    log "Initializing Tailwind CSS..."
    npx tailwindcss init -p
fi

# Test frontend build
log "Testing frontend build..."
if ! npm run build; then
    error "Frontend build failed"
    exit 1
fi

# Clean up frontend build
rm -rf build

# Go back to app directory
cd "$APP_DIR"

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

# Stop existing containers
log "Stopping any existing containers..."
docker-compose -f docker-compose.prod.yml down || true

# Clean Docker system
log "Cleaning Docker system..."
docker system prune -af

# Build and start containers
log "Building and starting containers..."
if ! docker-compose -f docker-compose.prod.yml up -d --build; then
    error "Failed to build and start containers"
    docker-compose -f docker-compose.prod.yml logs
    exit 1
fi

# Configure Nginx
log "Configuring Nginx..."
cat > /etc/nginx/sites-available/event-management << EOL
server {
    listen 80;
    server_name _;

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
}
EOL

# Enable site and restart Nginx
ln -sf /etc/nginx/sites-available/event-management /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
systemctl restart nginx

# Configure firewall
log "Configuring firewall..."
ufw allow ssh
ufw allow http
ufw allow https
ufw allow from 192.168.0.0/16 to any port 3000
ufw allow from 192.168.0.0/16 to any port 5000

# Enable firewall
echo "y" | ufw enable

# Set permissions
log "Setting permissions..."
chown -R www-data:www-data "$APP_DIR"
chmod -R 755 "$APP_DIR"

# Final verification
log "Verifying services..."
sleep 10

# Check if containers are running
if ! docker ps | grep -q event_management; then
    error "Containers failed to start"
    docker-compose -f docker-compose.prod.yml logs
    exit 1
fi

log "Installation completed successfully!"
log "Services are available at:"
log "Application: http://localhost"
log "API: http://localhost/api"

log "\nCredentials:"
log "MongoDB Root Username: admin"
log "MongoDB Root Password: $(grep MONGO_ROOT_PASSWORD .env | cut -d'=' -f2)"
log "Grafana Admin Password: $(grep GRAFANA_PASSWORD .env | cut -d'=' -f2)"

warning "\nPlease save these credentials in a secure location!"
warning "For security, consider changing the default passwords."