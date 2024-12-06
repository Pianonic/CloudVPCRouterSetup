#!/bin/bash

# Best script to setup Docker infrastructure for NetBird and Nginx Proxy Manager on Debian

set -e

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

echo "Starting installation... This might take a few minutes."

# Prompt for NetBird Setup Key
read -p "Enter your NetBird WT_SETUP_KEY: " WT_SETUP_KEY
while [ -z "$WT_SETUP_KEY" ]; then
  echo "NetBird setup key is required. Please enter it."
  read -p "Enter your NetBird WT_SETUP_KEY: " WT_SETUP_KEY
done

# Step 1: Update System and Install Required Packages
echo "Updating system..." > /dev/null
(sudo apt update -y && sudo apt upgrade -y && sudo apt install -y curl git apt-transport-https ca-certificates software-properties-common) & spinner

# Step 2: Install Docker
echo "Installing Docker..." > /dev/null
if ! [ -x "$(command -v docker)" ]; then
  (curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg &&
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null &&
    sudo apt update -y && sudo apt install -y docker-ce docker-ce-cli containerd.io) & spinner
else
  echo "Docker is already installed." > /dev/null
fi

# Step 3: Install Docker Compose
echo "Installing Docker Compose..." > /dev/null
if ! [ -x "$(command -v docker-compose)" ]; then
  (sudo curl -L "https://github.com/docker/compose/releases/download/v2.26.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose &&
    sudo chmod +x /usr/local/bin/docker-compose) & spinner
else
  echo "Docker Compose is already installed." > /dev/null
fi

# Step 4: Create Directory Structure
echo "Creating directory structure..." > /dev/null
(mkdir -p ~/infra/netbird ~/infra/npm-plus/data ~/infra/npm-plus/letsencrypt &&
  chmod -R 755 ~/infra) & spinner

# Step 5: Generate docker-compose.yml
echo "Generating docker-compose.yml..." > /dev/null
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

# Step 6: Deploy Docker Services
echo "Deploying services..." > /dev/null
(cd ~/infra && sudo docker-compose up -d) & spinner

echo "Installation complete!"
