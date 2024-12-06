#!/bin/bash

# Script to setup Docker infrastructure for NetBird and Nginx Proxy Manager on Debian

set -e

echo "==============================="
echo " Docker Infrastructure Setup for Debian"
echo "==============================="

# Step 1: Update System and Install Required Packages
echo "Updating system and installing prerequisites..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl git apt-transport-https ca-certificates software-properties-common

# Step 2: Install Docker
echo "Installing Docker..."
if ! [ -x "$(command -v docker)" ]; then
  curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt update && sudo apt install -y docker-ce docker-ce-cli containerd.io
else
  echo "Docker is already installed!"
fi

# Step 3: Install Docker Compose
echo "Installing Docker Compose..."
if ! [ -x "$(command -v docker-compose)" ]; then
  sudo curl -L "https://github.com/docker/compose/releases/download/v2.26.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose
else
  echo "Docker Compose is already installed!"
fi

# Step 4: Create Directory Structure
echo "Creating directory structure for services..."
mkdir -p ~/infra/netbird ~/infra/npm-plus/data ~/infra/npm-plus/letsencrypt

# Step 5: Set Permissions for Created Folders
echo "Setting permissions for created folders..."
chmod -R 755 ~/infra

# Step 6: Prompt for NetBird Setup Key
read -p "Enter your NetBird WT_SETUP_KEY: " WT_SETUP_KEY
if [ -z "$WT_SETUP_KEY" ]; then
  echo "NetBird setup key is required. Exiting."
  exit 1
fi

# Step 7: Generate docker-compose.yml
echo "Generating docker-compose.yml..."
cat <<EOF > ~/infra/docker-compose.yml
version: '3.8'

services:
  # NetBird Service
  netbird:
    image: netbirdio/netbird:latest
    container_name: netbird
    restart: always
    environment:
      - LOG_LEVEL=info
      - WT_SETUP_KEY=${WT_SETUP_KEY} # Replace with your NetBird client setup key
    volumes:
      - ./netbird:/etc/wiretrustee # Persistent storage for NetBird configuration
    network_mode: host # Required for direct access to network interfaces
    cap_add:
      - NET_ADMIN
      - SYS_MODULE
    privileged: true # Necessary for managing network settings

  # Nginx Proxy Manager Service (using NPM+)
  npm-plus:
    image: zoeyvid/npmplus:latest
    container_name: npm_plus
    restart: always
    ports:
      - "80:80"  # HTTP
      - "443:443" # HTTPS
      - "81:81"  # Management UI
    environment:
      - DB_SQLITE_FILE="/data/database.sqlite"
      - TZ=$(cat /etc/timezone || echo "UTC") # Set timezone
    volumes:
      - ./npm-plus/data:/data # Data storage for Nginx Proxy Manager
      - ./npm-plus/letsencrypt:/etc/letsencrypt # SSL certificate storage
    networks:
      - custom_network

networks:
  custom_network:
    driver: bridge
EOF

# Step 8: Deploy Docker Services
echo "Deploying Docker services..."
cd ~/infra
sudo docker-compose up -d

echo "==============================="
echo " Infrastructure Setup Complete"
echo "==============================="
echo " - NetBird and Nginx Proxy Manager are up and running."
echo " - Access Nginx Proxy Manager at http://<your-server-ip>:81"
echo "==============================="
