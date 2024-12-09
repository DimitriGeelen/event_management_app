#!/bin/bash

[Previous content remains the same...]

# Install Tailwind CSS and its dependencies
log "Installing Tailwind CSS dependencies..."
if ! npm install -D tailwindcss@latest postcss@latest autoprefixer@latest @tailwindcss/forms@latest; then
    error "Failed to install Tailwind CSS dependencies"
    exit 1
fi

# Test frontend build
log "Testing frontend build..."
if ! npm run build; then
    error "Frontend build failed"
    # Show build error logs
    cat build-error.log || true
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

    location /grafana/ {
        proxy_pass http://localhost:3000/;
    }

    location /kibana/ {
        proxy_pass http://localhost:5601/;
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