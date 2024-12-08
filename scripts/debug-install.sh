#!/bin/bash

# Enable debug mode
set -x

# Save output to log file
exec 1> >(tee "/tmp/install_debug_$(date +%F_%H%M%S).log") 2>&1

# Source the installation script
source /opt/event_management_app/install_lan.sh
