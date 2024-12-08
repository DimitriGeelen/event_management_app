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

# Configuration
APP_DIR="/opt/event_management_app"
BACKUP_DIR="/backup/event_management"

# Function to check system health
check_health() {
    log "Checking system health..."

    # Check disk space
    DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
    if [ "$DISK_USAGE" -gt 80 ]; then
        warning "Disk usage is high: ${DISK_USAGE}%"
    fi

    # Check memory
    FREE_MEM=$(free -m | awk 'NR==2 {print $4}')
    if [ "$FREE_MEM" -lt 1000 ]; then
        warning "Low memory available: ${FREE_MEM}MB"
    fi

    # Check Docker services
    if ! docker ps > /dev/null 2>&1; then
        error "Docker is not running"
    else
        log "Docker is running"
        docker ps -a --format "{{.Names}}\t{{.Status}}" | while read container; do
            if [[ $container != *"Up"* ]]; then
                warning "Container issues: $container"
            fi
        done
    fi

    # Check Nginx
    if ! systemctl is-active --quiet nginx; then
        error "Nginx is not running"
    else
        log "Nginx is running"
    fi

    # Check network connectivity
    IP_ADDRESS=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | head -n1)
    log "Server IP: ${IP_ADDRESS}"

    # Check application endpoints
    if curl -s http://localhost:5000/health > /dev/null; then
        log "Backend API is responding"
    else
        error "Backend API is not responding"
    fi
}

# Function to update application
update_app() {
    log "Updating application..."
    cd "$APP_DIR"

    # Backup before update
    ./scripts/backup-all.sh

    # Pull latest changes
    git pull

    # Update dependencies
    docker-compose -f docker-compose.prod.yml down
    docker-compose -f docker-compose.prod.yml pull
    docker-compose -f docker-compose.prod.yml up -d --build

    log "Application updated successfully"
}

# Function to manage backups
manage_backups() {
    log "Managing backups..."

    # Create backup directory if it doesn't exist
    mkdir -p "$BACKUP_DIR"

    # Run backup scripts
    cd "$APP_DIR"
    ./scripts/backup-all.sh

    # Clean old backups (keep last 7 days)
    find "$BACKUP_DIR" -type f -mtime +7 -exec rm {} \;

    log "Backup management completed"
}

# Function to manage network
manage_network() {
    log "Managing network configuration..."

    # Show current network status
    IP_ADDRESS=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | head -n1)
    log "Current IP: ${IP_ADDRESS}"

    # Show active ports
    log "Active ports:"
    netstat -tulpn | grep LISTEN

    # Show firewall rules
    log "Firewall rules:"
    ufw status numbered

    # Option to modify firewall
    read -p "Do you want to modify firewall rules? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log "Current allowed IPs:"
        ufw status | grep ALLOW

        read -p "Enter IP range to allow (e.g., 192.168.1.0/24): " IP_RANGE
        ufw allow from "$IP_RANGE" to any port 80
        ufw allow from "$IP_RANGE" to any port 3000
        ufw allow from "$IP_RANGE" to any port 5000

        log "Updated firewall rules"
        ufw status
    fi
}

# Main menu
while true; do
    echo -e "\n${GREEN}=== Event Management App LAN Manager ===${NC}\n"
    echo "1. Check System Health"
    echo "2. Update Application"
    echo "3. Manage Backups"
    echo "4. Manage Network"
    echo "5. View Logs"
    echo "6. Exit"
    
    read -p "Select an option (1-6): " choice

    case $choice in
        1) check_health ;;
        2) update_app ;;
        3) manage_backups ;;
        4) manage_network ;;
        5)
            echo "1. Application Logs"
            echo "2. Nginx Logs"
            echo "3. Docker Logs"
            read -p "Select log type (1-3): " log_choice
            case $log_choice in
                1) docker-compose -f docker-compose.prod.yml logs --tail=100 -f ;;
                2) tail -f /var/log/nginx/*.log ;;
                3) docker ps -q | xargs docker logs --tail=100 -f ;;
                *) error "Invalid option" ;;
            esac
            ;;
        6) exit 0 ;;
        *) error "Invalid option" ;;
    esac

    read -p "Press enter to continue"
done