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
    # Save logs for debugging
    if [ -d "$NPM_LOG_DIR" ]; then
        cp -r "$NPM_LOG_DIR" "/tmp/npm_logs_$(date +%F_%H%M%S)"
    fi
    exit ${error_code}
}

# Set up error handling
trap 'handle_error ${LINENO} $?' ERR

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

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
    error "Please run as root (use sudo)"
    exit 1
fi

# Create log directory with proper permissions
NPM_LOG_DIR="/var/log/npm"
mkdir -p "$NPM_LOG_DIR"
chmod 755 "$NPM_LOG_DIR"

# Function to check and create directory
check_create_dir() {
    local dir=$1
    local owner=$2
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir" || { error "Failed to create directory: $dir"; exit 1; }
    fi
    chown -R "$owner:$owner" "$dir" || { error "Failed to set ownership for: $dir"; exit 1; }
    chmod 755 "$dir" || { error "Failed to set permissions for: $dir"; exit 1; }
}

# Function to check command availability
check_command() {
    if ! command -v "$1" >/dev/null 2>&1; then
        error "Required command not found: $1"
        exit 1
    fi
}

# Function to verify service is running
verify_service() {
    local service=$1
    local port=$2
    if ! nc -z localhost "$port"; then
        error "Service $service is not running on port $port"
        return 1
    fi
    return 0
}

# Main installation process with improved error handling

# 1. System Updates
log "Updating system..."
retry_command 3 apt update
retry_command 3 apt upgrade -y

# 2. Install required packages
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

# 3. Node.js and npm installation
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
check_command node
check_command npm

[... Continue with Docker, application setup, and service configuration with similar error handling ...]
