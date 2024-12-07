# Ubuntu 24.04 Installation Guide

This guide provides step-by-step instructions for installing and running the Event Management Application on Ubuntu 24.04.

## Prerequisites Installation

1. Update system packages:
```bash
sudo apt update
sudo apt upgrade -y
```

2. Install curl:
```bash
sudo apt install -y curl
```

3. Install Node.js:
```bash
# Add NodeSource repository
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -

# Install Node.js
sudo apt install -y nodejs

# Verify installation
node --version
npm --version
```

4. Install MongoDB:
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

5. Install git:
```bash
sudo apt install -y git
```

## Application Installation

1. Clone the repository:
```bash
git clone https://github.com/DimitriGeelen/event_management_app.git
cd event_management_app
```

2. Create environment file:
```bash
cat > .env << EOL
MONGODB_URI=mongodb://localhost:27017/event_management
JWT_SECRET=your_secret_key_here
PORT=5000
EOL
```

3. Install backend dependencies:
```bash
npm install
```

4. Install frontend dependencies:
```bash
cd frontend
npm install
```

## Running the Application

1. Start the backend server (from the root directory):
```bash
npm run server
```

2. In a new terminal, start the frontend development server:
```bash
cd frontend
npm start
```

## Setting Up PM2 for Production (Optional)

1. Install PM2:
```bash
sudo npm install -g pm2
```

2. Start the backend with PM2:
```bash
pm2 start npm --name "event-management-backend" -- run server
```

3. Start the frontend with PM2:
```bash
cd frontend
pm2 start npm --name "event-management-frontend" -- start
```

4. Enable PM2 startup:
```bash
pm2 startup systemd
```

5. Save the PM2 process list:
```bash
pm2 save
```

## Troubleshooting

1. If MongoDB fails to start:
```bash
# Check MongoDB logs
sudo journalctl -u mongod.service -f

# Repair MongoDB database
sudo mongod --repair
```

2. If ports are already in use:
```bash
# Check what's using port 5000 (backend)
sudo lsof -i :5000

# Check what's using port 3000 (frontend)
sudo lsof -i :3000

# Kill process using a port
sudo kill -9 <PID>
```

3. If you can't connect to MongoDB:
```bash
# Check MongoDB status
sudo systemctl status mongod

# Restart MongoDB
sudo systemctl restart mongod
```

4. If npm install fails:
```bash
# Clear npm cache
npm cache clean --force

# Try installation with legacy peer deps
npm install --legacy-peer-deps
```

## Security Considerations

1. Generate a strong JWT secret:
```bash
# Generate a random secret and save it
openssl rand -hex 32 > jwt_secret.txt
```

2. Configure MongoDB security:
```bash
# Create admin user
mongosh