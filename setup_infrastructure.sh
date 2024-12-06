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

echo -e "${YELLOW}Starting installation... This might take a few minutes.${NC}"

# Prompt for NetBird Setup Key
echo -e "\n${YELLOW}Please enter the NetBird WT_SETUP_KEY:${NC}"
read -p "" WT_SETUP_KEY
echo -e "${GREEN}WT_SETUP_KEY received: $WT_SETUP_KEY${NC}\n"

# Update System and Install Required Packages
echo -e "${YELLOW}Updating system...${NC}" > /dev/null
(sudo apt update -y && sudo apt upgrade -y && sudo apt install -y curl git apt-transport-https ca-certificates software-properties-common) & spinner
wait

# Install Docker
echo -e "\n${YELLOW}Installing Docker...${NC}" > /dev/null
if ! [ -x "$(command -v docker)" ]; then
  (curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg &&
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null &&
    sudo apt update -y && sudo apt install -y docker-ce docker-ce-cli containerd.io) & spinner
  wait
else
  echo -e "${GREEN}Docker is already installed.${NC}" > /dev/null
fi

# Install Docker Compose
echo -e "\n${YELLOW}Installing Docker Compose...${NC}" > /dev/null
if ! [ -x "$(command -v docker-compose)" ]; then
  (sudo curl -L "https://github.com/docker/compose/releases/download/v2.26.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose &&
    sudo chmod +x /usr/local/bin/docker-compose) & spinner
  wait
else
  echo -e "${GREEN}Docker Compose is already installed.${NC}" > /dev/null
fi

# Create Directory Structure
echo -e "\n${YELLOW}Creating directory structure...${NC}" > /dev/null
(mkdir -p ~/infra/npm-plus/data && chmod -R 755 ~/infra) & spinner
wait

# Generate docker-compose.yml
echo -e "\n${YELLOW}Generating docker-compose.yml...${NC}" > /dev/null
cat <<EOF > ~/infra/docker-compose.yml
version: '3.8'

services:
  npmplus:
    container_name: npmplus
    image: zoeyvid/npmplus
    restart: always
    ports:
      - 80:80
      - 443:443
      - 81:81
    volumes:
      - ./data:/data
    environment:
      - TZ=$(cat /etc/timezone || echo "Europe/Zurich")
      - ACME_EMAIL=ssl@pianonic.ch
EOF

# Deploy Docker Services
echo -e "\n${YELLOW}Deploying services...${NC}" > /dev/null
(cd ~/infra && sudo docker-compose up -d) & spinner
wait

# Fetch local NetBird container IP address dynamically from the `wt0` interface
NETBIRD_IP=$(sudo docker exec netbird ip a show wt0 | grep inet | awk '{ print $2 }' | cut -d/ -f1)

# Clear the console reliably
# You can use `tput` for clearing the screen in a terminal
tput reset

# Or you can use escape sequences to clear the screen
# echo -e "\033c"  # ANSI escape code to reset terminal

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
