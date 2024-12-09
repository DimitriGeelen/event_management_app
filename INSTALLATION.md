# Installation Guide

## Quick Installation (Ubuntu 24.04)

### Automatic Installation

1. Download the installation script:
```bash
curl -O https://raw.githubusercontent.com/DimitriGeelen/event_management_app/main/install_lan.sh
chmod +x install_lan.sh
sudo ./install_lan.sh
```

### Manual Installation

1. Update system:
```bash
sudo apt update
sudo apt upgrade -y
```

2. Install required packages:
```bash
sudo apt install -y build-essential python3-pip apt-transport-https ca-certificates curl software-properties-common git nginx ufw fail2ban net-tools htop snapd
```

3. Install Node.js and npm:
```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
```

4. Install Docker:
```bash
curl -fsSL https://get.docker.com | sudo bash
sudo apt install -y docker-compose
```

5. Create application directory:
```bash
sudo mkdir -p /opt/event_management_app
sudo chown $USER:$USER /opt/event_management_app
```

6. Clone repository:
```bash
git clone https://github.com/DimitriGeelen/event_management_app.git /opt/event_management_app
```

7. Set up frontend:
```bash
cd /opt/event_management_app/frontend
npm install
npm install -D tailwindcss@latest postcss@latest autoprefixer@latest @tailwindcss/forms@latest
npm run build
```

8. Start services:
```bash
cd /opt/event_management_app
docker-compose -f docker-compose.prod.yml up -d
```

## System Requirements

- Ubuntu 24.04 LTS
- Minimum 4GB RAM
- 20GB disk space
- Internet connection
- Ports 80, 443, 3000, 5000 available

## Configuration

### Environment Variables

Create a `.env` file in the root directory:
```env
MONGODB_URI=mongodb://mongodb:27017/event_management
JWT_SECRET=your_secret_key
PORT=5000
HOST=0.0.0.0
NODE_ENV=production
GRAFANA_PASSWORD=your_grafana_password
MONGO_ROOT_USERNAME=admin
MONGO_ROOT_PASSWORD=your_mongo_password
```

### Nginx Configuration

Nginx configuration is automatically set up at `/etc/nginx/sites-available/event-management`

### Firewall Configuration

The installation script configures UFW with the following rules:
- SSH (22)
- HTTP (80)
- HTTPS (443)
- Frontend (3000)
- Backend API (5000)

## Post-Installation

### Access Points

- Frontend: `http://your-server-ip/`
- API: `http://your-server-ip/api`
- Grafana: `http://your-server-ip/grafana`
- Kibana: `http://your-server-ip/kibana`

### Default Credentials

- MongoDB Root User: admin
- MongoDB Password: (generated during installation)
- Grafana Admin Password: (generated during installation)

### Security Recommendations

1. Change default passwords
2. Enable SSL/TLS
3. Set up regular backups
4. Configure fail2ban
5. Keep system updated

## Troubleshooting

### Common Issues

1. Port conflicts:
```bash
sudo netstat -tulpn | grep -E '80|443|3000|5000'
sudo fuser -k 80/tcp  # To kill process using port 80
```

2. Docker issues:
```bash
sudo docker ps  # Check running containers
sudo docker-compose logs  # Check container logs
```

3. Permission issues:
```bash
sudo chown -R www-data:www-data /opt/event_management_app
sudo chmod -R 755 /opt/event_management_app
```

### Logs

- Application logs: `/opt/event_management_app/logs/`
- Nginx logs: `/var/log/nginx/`
- Docker logs: `sudo docker-compose logs`

## Maintenance

### Updates

```bash
cd /opt/event_management_app
git pull
docker-compose -f docker-compose.prod.yml up -d --build
```

### Backups

```bash
# Database backup
sudo docker exec mongodb mongodump --out /data/backup

# Application backup
sudo tar -czf /backup/app_$(date +%Y%m%d).tar.gz /opt/event_management_app
```

### Monitoring

- System resources: `htop`
- Docker stats: `docker stats`
- Disk usage: `df -h`

## Support

- GitHub Issues: [Report Issues](https://github.com/DimitriGeelen/event_management_app/issues)
- Documentation: Check the `/docs` directory
- Log files: Check `/var/log/` directory