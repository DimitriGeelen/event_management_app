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

# Create log directory with proper permissions
NPM_LOG_DIR="/var/log/npm"
mkdir -p "$NPM_LOG_DIR"
chmod 755 "$NPM_LOG_DIR"

# Detect network interface with fallback
PRIMARY_INTERFACE=$(ip route | grep default | awk '{print $5}' | head -n1)
if [ -z "$PRIMARY_INTERFACE" ]; then
    warning "No default route found, trying to find first non-loopback interface"
    PRIMARY_INTERFACE=$(ip -o link show | awk '$2 != "lo:" {print $2}' | cut -d: -f1 | head -n1)
    if [ -z "$PRIMARY_INTERFACE" ]; then
        error "No network interface found"
        exit 1
    fi
fi

# Get IP address with validation
IP_ADDRESS=$(ip -4 addr show $PRIMARY_INTERFACE | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
if [ -z "$IP_ADDRESS" ]; then
    error "Could not detect IP address for interface ${PRIMARY_INTERFACE}"
    exit 1
fi

log "Installing on interface ${PRIMARY_INTERFACE} with IP ${IP_ADDRESS}"

# Update system with retry
log "Updating system packages..."
for i in {1..3}; do
    if apt update && apt upgrade -y; then
        break
    elif [ $i -eq 3 ]; then
        error "Failed to update system after 3 attempts"
        exit 1
    else
        warning "Retry $i/3: System update failed, retrying..."
        sleep 5
    fi
done

# Install build essentials with verification
log "Installing build essentials..."
if ! apt install -y build-essential python3-pip; then
    error "Failed to install build essentials"
    exit 1
fi

# Determine user for installations
if [ -n "$SUDO_USER" ]; then
    INSTALL_USER="$SUDO_USER"
else
    INSTALL_USER=$(who am i | awk '{print $1}')
    if [ -z "$INSTALL_USER" ]; then
        INSTALL_USER="root"
        warning "Could not determine non-root user, using root"
    fi
fi

# Remove existing Node.js and npm
log "Removing existing Node.js and npm installations..."
apt remove -y nodejs npm || true
apt autoremove -y || true

# Install Node.js and npm with verification
log "Installing Node.js and npm..."
if ! curl -fsSL https://deb.nodesource.com/setup_20.x -o nodesource_setup.sh; then
    error "Failed to download Node.js setup script"
    exit 1
fi

if ! bash nodesource_setup.sh; then
    error "Failed to run Node.js setup script"
    exit 1
fi
rm nodesource_setup.sh

if ! apt install -y nodejs; then
    error "Failed to install Node.js"
    exit 1
fi

# Verify Node.js and npm installation
if ! command -v node >/dev/null 2>&1 || ! command -v npm >/dev/null 2>&1; then
    error "Node.js or npm installation failed"
    exit 1
fi

# Set npm log level to verbose temporarily
export npm_config_loglevel=verbose

[Rest of the script with similar error handling and verification...]
