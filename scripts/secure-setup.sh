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

# Check if script is run as root
if [[ $EUID -ne 0 ]]; then
   error "This script must be run as root"
   exit 1
}

# Function to generate secure passwords
generate_password() {
    openssl rand -base64 32
}

# Secure MongoDB
log "Configuring MongoDB security..."

# Create MongoDB admin user
MONGO_ADMIN_PASSWORD=$(generate_password)
MONGO_APP_PASSWORD=$(generate_password)

mongosh admin --eval "
  db.createUser({
    user: 'admin',
    pwd: '$MONGO_ADMIN_PASSWORD',
    roles: [ { role: 'userAdminAnyDatabase', db: 'admin' } ]
  });
  db.createUser({
    user: 'eventapp',
    pwd: '$MONGO_APP_PASSWORD',
    roles: [ { role: 'readWrite', db: 'event_management' } ]
  });
"

# Enable MongoDB authentication
sed -i 's/#security:/security:\n  authorization: enabled/' /etc/mongod.conf

# Restart MongoDB
systemctl restart mongod

# Update application's MongoDB URI
sed -i "s|mongodb://localhost:27017/event_management|mongodb://eventapp:${MONGO_APP_PASSWORD}@localhost:27017/event_management?authSource=admin|" /opt/event_management_app/.env

# Set up fail2ban
log "Installing and configuring fail2ban..."
apt install -y fail2ban

cat > /etc/fail2ban/jail.local << EOL
[DEFAULT]
bantime = 1h
findtime = 10m
maxretry = 5

[sshd]
enabled = true

[mongodb]
enabled = true
port = 27017
filter = mongodb
logpath = /var/log/mongodb/mongod.log
maxretry = 3
findtime = 5m
bantime = 1h

[nginx-http-auth]
enabled = true

[nginx-botsearch]
enabled = true
EOL

# Create MongoDB filter for fail2ban
cat > /etc/fail2ban/filter.d/mongodb.conf << EOL
[Definition]
failregex = ^.*authenticating.*failed.*remote:\s+<HOST>.*$
ignoreregex =
EOL

# Restart fail2ban
systemctl restart fail2ban

# Configure SSL/TLS with Let's Encrypt
log "Would you like to configure SSL/TLS with Let's Encrypt? (y/n)"
read -r setup_ssl

if [[ $setup_ssl =~ ^[Yy]$ ]]; then
    read -p "Enter your domain name: " domain_name
    apt install -y certbot python3-certbot-nginx
    certbot --nginx -d "$domain_name" --non-interactive --agree-tos --email "admin@${domain_name}" --redirect
fi

# Secure Nginx configuration
log "Securing Nginx configuration..."

cat > /etc/nginx/conf.d/security.conf << EOL
# Security headers
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header X-Content-Type-Options "nosniff" always;
add_header Referrer-Policy "no-referrer-when-downgrade" always;
add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

# SSL configuration
ssl_protocols TLSv1.2 TLSv1.3;
ssl_prefer_server_ciphers on;
ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;

# SSL session configuration
ssl_session_timeout 1d;
ssl_session_cache shared:SSL:50m;
ssl_session_tickets off;

# Enable OCSP stapling
ssl_stapling on;
ssl_stapling_verify on;
resolver 8.8.8.8 8.8.4.4 valid=300s;
resolver_timeout 5s;

# Disable potentially dangerous protocols and methods
proxy_hide_header X-Powered-By;
proxy_hide_header Server;
server_tokens off;
client_max_body_size 10M;
EOL

# Configure logrotate for application logs
log "Configuring log rotation..."

cat > /etc/logrotate.d/event-management << EOL
/opt/event_management_app/logs/*.log {
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    create 0640 www-data adm
    sharedscripts
    postrotate
        /usr/bin/pm2 reloadLogs
    endscript
}
EOL

# Create backup script
log "Setting up backup script..."

cat > /opt/event_management_app/scripts/backup.sh << EOL
#!/bin/bash

BACKUP_DIR=/opt/event_management_app/backups
TIMESTAMP=\$(date +%Y%m%d_%H%M%S)

# Create backup directory if it doesn't exist
mkdir -p \$BACKUP_DIR

# Backup MongoDB
mongodump --uri="mongodb://eventapp:${MONGO_APP_PASSWORD}@localhost:27017/event_management?authSource=admin" --out="\$BACKUP_DIR/mongo_\$TIMESTAMP"

# Backup uploads directory
tar -czf "\$BACKUP_DIR/uploads_\$TIMESTAMP.tar.gz" -C /opt/event_management_app uploads

# Backup configuration files
tar -czf "\$BACKUP_DIR/config_\$TIMESTAMP.tar.gz" /opt/event_management_app/.env /etc/nginx/sites-available/event-management

# Remove backups older than 30 days
find \$BACKUP_DIR -type f -mtime +30 -exec rm {} \;
EOL

chmod +x /opt/event_management_app/scripts/backup.sh

# Set up daily backup cron job
(crontab -l 2>/dev/null; echo "0 2 * * * /opt/event_management_app/scripts/backup.sh") | crontab -

# Set up system monitoring
log "Setting up system monitoring..."

# Install monitoring tools
apt install -y htop iotop nethogs

# Install and configure node_exporter for Prometheus metrics
wget https://github.com/prometheus/node_exporter/releases/download/v1.7.0/node_exporter-1.7.0.linux-amd64.tar.gz
tar xvfz node_exporter-1.7.0.linux-amd64.tar.gz
cp node_exporter-1.7.0.linux-amd64/node_exporter /usr/local/bin/
rm -rf node_exporter-1.7.0.linux-amd64*

# Create node_exporter service
cat > /etc/systemd/system/node_exporter.service << EOL
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOL

# Create node_exporter user
useradd -rs /bin/false node_exporter

# Start and enable node_exporter
systemctl daemon-reload
systemctl start node_exporter
systemctl enable node_exporter

# Save MongoDB credentials
log "Saving credentials..."

cat > /root/.event_management_credentials << EOL
MongoDB Admin Password: ${MONGO_ADMIN_PASSWORD}
MongoDB Application Password: ${MONGO_APP_PASSWORD}
EOL

chmod 600 /root/.event_management_credentials

log "Security setup completed!"
log "MongoDB credentials have been saved to /root/.event_management_credentials"
warning "Make sure to save these credentials in a secure location!"
