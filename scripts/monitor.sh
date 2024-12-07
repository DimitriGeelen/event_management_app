#!/bin/bash

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Function to print section headers
print_header() {
    echo -e "\n${BLUE}=== $1 ===${NC}\n"
}

# Function to print status with color
print_status() {
    if [ $2 -eq 0 ]; then
        echo -e "$1: ${GREEN}OK${NC}"
    else
        echo -e "$1: ${RED}FAILED${NC}"
    fi
}

# Check system resources
print_header "System Resources"

# CPU usage
echo "CPU Usage:"
top -bn1 | head -n 3

# Memory usage
echo -e "\nMemory Usage:"
free -h

# Disk usage
echo -e "\nDisk Usage:"
df -h /

# Check services status
print_header "Service Status"

# MongoDB
systemctl is-active --quiet mongod
print_status "MongoDB" $?

# Nginx
systemctl is-active --quiet nginx
print_status "Nginx" $?

# PM2
pm2 ping > /dev/null 2>&1
print_status "PM2" $?

# Node Exporter
systemctl is-active --quiet node_exporter
print_status "Node Exporter" $?

# Generate summary
print_header "Summary"

# Count failed services
failed_services=0
systemctl is-active --quiet mongod || ((failed_services++))
systemctl is-active --quiet nginx || ((failed_services++))
pm2 ping > /dev/null 2>&1 || ((failed_services++))
systemctl is-active --quiet node_exporter || ((failed_services++))

# Check resource usage
disk_usage=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
mem_usage=$(free | awk '/Mem:/ {printf("%.0f", $3/$2 * 100)}')
cpu_usage=$(top -bn1 | awk '/%Cpu/ {print $2}')

# Print summary
echo -e "${BLUE}System Status Summary:${NC}"
echo -e "Failed Services: ${failed_services}"
echo -e "Disk Usage: ${disk_usage}%"
echo -e "Memory Usage: ${mem_usage}%"
echo -e "CPU Usage: ${cpu_usage}%"

# Print recommendations
if [ $failed_services -gt 0 ]; then
    echo -e "\n${RED}Action Required: Some services are not running!${NC}"
fi

if [ $disk_usage -gt 80 ]; then
    echo -e "${YELLOW}Warning: Disk usage is high!${NC}"
fi

if [ $mem_usage -gt 80 ]; then
    echo -e "${YELLOW}Warning: Memory usage is high!${NC}"
fi

if [ $cpu_usage -gt 80 ]; then
    echo -e "${YELLOW}Warning: CPU usage is high!${NC}"
fi