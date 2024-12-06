# Infrastructure Setup for NetBird and Nginx Proxy Manager

This script automates the installation and configuration of Docker-based infrastructure on a Debian-based machine to deploy **NetBird** (a WireGuard-based VPN solution) and **Nginx Proxy Manager (NPM+)**.

---

## Features
- Installs **Docker** and **Docker Compose** on a fresh Debian system.
- Configures **NetBird** for secure VPN setup.
- Sets up **Nginx Proxy Manager (NPM+)** for HTTP/S proxy and SSL management.
- Creates necessary directory structure for persistent storage.
- Displays a minimalist spinner for progress with no verbose console output.

---

## Prerequisites

- A **Debian-based** system (e.g., Debian 12, Ubuntu 22.04).
- Root or sudo privileges on the machine.
- An active internet connection to download required packages and containers.

---

## Setup Instructions

### 1. Download and Execute the Script

To download and execute the script, run the following command:

```bash
curl -fsSL https://raw.githubusercontent.com/Pianonic/CloudVPCRouterSetup/refs/heads/main/setup_infrastructure.sh -o /tmp/setup_infrastructure.sh && chmod +x /tmp/setup_infrastructure.sh && sudo /tmp/setup_infrastructure.sh && rm /tmp/setup_infrastructure.sh
```

This command will:
1. Download the `setup_infrastructure.sh` script from the GitHub repository.
2. Execute the script with **bash**.

### 2. Enter the NetBird Setup Key

When prompted, input your **NetBird WT_SETUP_KEY**. This key is required to set up the NetBird VPN service.

---

## Directory Structure

The script creates the following folder structure under the `~/infra` directory:

```
infra/
├── netbird/              # Persistent storage for NetBird configuration
├── npm-plus/             # Data for Nginx Proxy Manager
│   ├── data/             # Database and application data
│   └── letsencrypt/      # SSL certificates
└── docker-compose.yml    # Docker Compose configuration file
```

This structure ensures that the configuration and data are persisted across service restarts.

---

## Accessing Services

After the script has finished executing, the following services will be available:

1. **NetBird VPN**:  
   - NetBird will run in the background, enabling secure VPN access to your network.
   - Use the **WT_SETUP_KEY** to connect devices to the VPN.

2. **Nginx Proxy Manager (NPM+)**:  
   - The NPM+ UI is available at `http://<your-server-ip>:81` for management.
   - You can configure reverse proxies, SSL certificates, and much more.

---

By following the instructions, you will have a working infrastructure with **NetBird** and **Nginx Proxy Manager** running on your Debian system, ready for secure VPN and reverse proxy management.

