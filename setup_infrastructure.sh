#!/bin/bash

# Script to setup Docker infrastructure for NetBird and Nginx Proxy Manager on Debian

set -e

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

spinner() {
  local pid=$!
  local delay=0.1
  local spinstr='|/-\' 
  while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
    local temp=${spinstr#?}
    printf " [%c]  " "$spinstr"
    local spinstr=$temp${spinstr%"$temp"}
    sleep $delay
    printf "\b\b\b\b\b\b"
  done
  printf "    \b\b\b\b"
}

# Function to clear the terminal reliably
clear_terminal() {
  # Using `tput reset` to reliably clear the screen
  tput reset
}

echo -e "${YELLOW}Starting installation... This might take a few minutes.${NC}"

# Prompt for NetBird Setup Key
echo -e "\n${YELLOW}Please enter the NetBird WT_SETUP_KEY:${NC}"
read -p "" WT_SETUP_KEY
echo -e "${GREEN}WT_SETUP_KEY received: $WT_SETUP_KEY${NC}\n"

# Install Docker and Docker Compose
echo -e "${YELLOW}Installing Docker and Docker Compose...${NC}" 
# [Install commands for Docker and Docker Compose would go here, similar to the original script.]

# Create directory structure
echo -e "${YELLOW}Creating directory structure...${NC}"
# [Directory creation commands go here]

# Generate docker-compose.yml
echo -e "${YELLOW}Generating docker-compose.yml...${NC}"
cat <<EOF > ~/infra/docker-compose.yml
version: '3.8'

services:
  netbird:
    image: netbirdio/netbird:latest
    container_name: netbird
    restart: always
    environment:
      - LOG_LEVEL=info
      - WT_SETUP_KEY=${WT_SETUP_KEY}
    volumes:
      - ./netbird:/etc/wiretrustee
    network_mode: host
    cap_add:
      - NET_ADMIN
      - SYS_MODULE
    privileged: true

  npm-plus:
    image: zoeyvid/npmplus:latest
    container_name: npm_plus
    restart: always
    ports:
      - "80:80"
      - "443:443"
      - "81:81"
    environment:
      - DB_SQLITE_FILE="/data/database.sqlite"
      - TZ=$(cat /etc/timezone || echo "UTC")
    volumes:
      - ./npm-plus/data:/data
      - ./npm-plus/letsencrypt:/etc/letsencrypt
    networks:
      - custom_network

networks:
  custom_network:
    driver: bridge
EOF

# Deploy Docker services
echo -e "${YELLOW}Deploying services...${NC}"
(cd ~/infra && sudo docker-compose up -d) & spinner
wait

# Fetch local NetBird container IP address
NETBIRD_IP=$(sudo docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' netbird)

# Clear the terminal
clear_terminal

echo -e "\n${GREEN}Installation complete!${NC}\n"

# Informative message about accessing services
echo -e "${YELLOW}You can now access the following services:${NC}\n"
echo -e "1. ${GREEN}NetBird${NC}: NetBird is running and connected to your VPC."
echo -e "2. ${GREEN}Nginx Proxy Manager (NPM-Plus)${NC}: Access NPM-Plus to manage your proxy settings."
echo -e "   - HTTP: ${GREEN}http://$NETBIRD_IP:80${NC}"
echo -e "   - HTTPS: ${GREEN}https://$NETBIRD_IP:443${NC}"
echo -e "   - NPM-Plus UI: ${GREEN}http://$NETBIRD_IP:81${NC}\n"
echo -e "${YELLOW}You need to connect via NetBird to access these services.${NC}"
echo -e "${YELLOW}Ensure your firewall rules are configured to allow traffic to these ports.${NC}"
