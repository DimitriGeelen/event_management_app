# Installing Event Management App on Ubuntu 24.04

## Prerequisites Installation

### 1. Update System
```bash
sudo apt update
sudo apt upgrade -y
```

### 2. Install Node.js and npm
```bash
# Add NodeSource repository
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -

# Install Node.js
sudo apt install -y nodejs

# Verify installation
node --version
npm --version
```

### 3. Install MongoDB
```bash
# Import MongoDB public key
curl -fsSL https://pgp.mongodb.com/server-7.0.asc | \
   sudo gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg \
   --dearmor

# Add MongoDB repository
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | \
   sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list

# Update package list
sudo apt update

# Install MongoDB
sudo apt install -y mongodb-org

# Start MongoDB service
sudo systemctl start mongod

# Enable MongoDB to start on boot
sudo systemctl enable mongod

# Verify MongoDB status
sudo systemctl status mongod
```

### 4. Install Git
```bash
sudo apt install -y git
```

## Application Installation

### 1. Clone the Repository
```bash
git clone https://github.com/DimitriGeelen/event_management_app.git
cd event_management_app
```

### 2. Set Up Environment Variables
```bash
# Create .env file
cat > .env << EOL
MONGODB_URI=mongodb://localhost:27017/event_management
JWT_SECRET=your_secure_jwt_secret_here
PORT=5000
EOL
```

### 3. Install Dependencies
```bash
# Install backend dependencies
npm install

# Install frontend dependencies
cd frontend
npm install
```

### 4. Build the Frontend
```bash
# Still in the frontend directory
npm run build
```

### 5. Set Up PM2 Process Manager (for production)
```bash
# Install PM2 globally
sudo npm install -g pm2

# Start the backend server with PM2
cd ..
pm2 start server.js --name event-management-backend

# Save PM2 configuration
pm2 save

# Configure PM2 to start on boot
pm2 startup systemd
```

### 6. Set Up Nginx (for production)
```bash
# Install Nginx
sudo apt install -y nginx

# Create Nginx configuration
sudo nano /etc/nginx/sites-available/event-management
```

Add the following configuration:
```nginx
server {
    listen 80;
    server_name your_domain.com;  # Replace with your domain

    # Frontend
    location / {
        root /path/to/event_management_app/frontend/build;
        try_files $uri $uri/ /index.html;
    }

    # Backend API
    location /api {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

```bash
# Create symbolic link
sudo ln -s /etc/nginx/sites-available/event-management /etc/nginx/sites-enabled/

# Test Nginx configuration
sudo nginx -t

# Restart Nginx
sudo systemctl restart nginx
```

### 7. Set Up UFW Firewall
```bash
# Allow Nginx
sudo ufw allow 'Nginx Full'

# Allow SSH (if needed)
sudo ufw allow ssh

# Enable firewall
sudo ufw enable
```

## Development Setup

For development, you can run the application without Nginx:

### 1. Start the Backend
```bash
# In the root directory
npm run server
```

### 2. Start the Frontend Development Server
```bash
# In the frontend directory
npm start
```

## Troubleshooting

### MongoDB Issues
```bash
# Check MongoDB logs
sudo journalctl -u mongod.service

# Check MongoDB status
sudo systemctl status mongod

# Restart MongoDB
sudo systemctl restart mongod
```

### Application Issues
```bash
# Check PM2 logs
pm2 logs event-management-backend

# Check Nginx logs
sudo tail -f /var/log/nginx/error.log
```

### Permission Issues
```bash
# Set correct ownership for the application directory
sudo chown -R $USER:$USER /path/to/event_management_app

# Set correct permissions for the uploads directory
chmod -R 755 /path/to/event_management_app/uploads
```

## Security Recommendations

1. Enable SSL/TLS using Let's Encrypt:
```bash
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d your_domain.com
```

2. Secure MongoDB:
- Create admin user
- Enable authentication
- Configure firewall rules

3. Regular Updates:
```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Update npm packages
npm audit fix
```