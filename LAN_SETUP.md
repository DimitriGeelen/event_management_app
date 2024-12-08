# LAN Setup Guide

## Prerequisites

Before installation, ensure your system has:
- Ubuntu 24.04 LTS
- At least 4GB RAM
- At least 50GB disk space
- Network interface configured
- Internet connection for package installation

## Quick Installation

1. Download the installation script:
```bash
curl -O https://raw.githubusercontent.com/DimitriGeelen/event_management_app/main/install_lan.sh
chmod +x install_lan.sh
```

2. Run the installation script:
```bash
sudo ./install_lan.sh
```

## Manual Installation

### 1. System Updates

```bash
sudo apt update
sudo apt upgrade -y
```

### 2. Node.js and npm Installation

```bash
# Add Node.js repository
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -

# Install Node.js
sudo apt install -y nodejs

# Verify npm installation
which npm || sudo apt install -y npm

# Update npm to latest version
sudo npm install -g npm@latest

# Install global npm packages
sudo npm install -g nodemon
sudo npm install -g pm2
sudo npm install -g typescript
sudo npm install -g @vue/cli
```

### 3. Snap Installation

```bash
# Install snap
sudo apt install -y snapd
sudo systemctl enable --now snapd.socket

# Install snap core
sudo snap install core

# Verify snap installation
snap version
```

[Rest of the documentation content...]

## Verification

After installation, verify that all components are installed correctly:

```bash
# Check Node.js version
node --version

# Check npm version
npm --version

# Check snap version
snap version

# Check installed npm packages
npm list -g --depth=0

# Check Docker
docker --version
docker-compose --version
```

## Troubleshooting

### npm Issues

If you encounter npm permission issues:
```bash
# Fix permissions
sudo chown -R $USER:$USER ~/.npm
sudo chown -R $USER:$USER /usr/lib/node_modules

# Clear npm cache
npm cache clean --force
```

### Snap Issues

If snap is not working properly:
```bash
# Ensure snapd is running
sudo systemctl status snapd

# Restart snap service
sudo systemctl restart snapd

# Clear snap cache
sudo rm -rf /var/cache/snapd/*
```

[Rest of the troubleshooting content...]
