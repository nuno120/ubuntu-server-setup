# Ubuntu Server Setup Scripts
[![Build Status](https://travis-ci.org/jasonheecs/ubuntu-server-setup.svg?branch=master)](https://travis-ci.org/jasonheecs/ubuntu-server-setup)

A comprehensive collection of setup scripts to automate the provisioning of Ubuntu servers. The setup is divided into three main scripts, each building upon the previous one:

## 1. Basic Setup (setup.sh)
* User Management:
  * Create/update user account with sudo access
  * Add public SSH key for secure authentication
* SSH Security:
  * Disable password authentication
  * Deny root login
* System Configuration:
  * Setup Uncomplicated Firewall (UFW)
  * Create swap file based on machine's memory
  * Configure timezone (Default: "Asia/Singapore")
  * Install Network Time Protocol

## 2. Enhanced Security (second_setup.sh)
* SSH Hardening:
  * Configure custom SSH port
  * Key-based authentication only
* Advanced Firewall:
  * Allow custom SSH port
  * Allow HTTP (80) and HTTPS (443)
  * Deny all other incoming traffic
* Fail2ban Protection:
  * SSH brute force protection (max 3 retries)
  * HTTP/HTTPS protection
  * 10-minute ban time
  * Email notifications
* Security Updates:
  * Unattended-upgrades configuration
  * Automated security updates
  * Email notifications for updates

## 3. Docker & Traefik Setup (third_setup.sh)
* Docker Installation:
  * Docker Engine (latest stable)
  * Docker Compose v2
  * User added to docker group
* Directory Structure:
  ```
  /opt/docker/
  ├── traefik/
  │   ├── config/
  │   └── acme/
  ├── monitoring/
  │   ├── prometheus/
  │   └── grafana/
  └── apps/
  ```
* Traefik Configuration:
  * Automatic SSL certificates via Let's Encrypt
  * HTTP to HTTPS redirect
  * Secure dashboard access
  * Rate limiting (100 req/min per IP)
  * Security headers (HSTS, CSP, etc.)

# Installation

1. Install git if not present:
```bash
sudo apt-get update
sudo apt-get install git
```

2. Clone the repository:
```bash
cd ~
git clone https://github.com/nuno120/ubuntu-server-setup.git
```

3. Run the setup scripts in sequence:
```bash
cd ubuntu-server-setup
# Step 1: Basic setup
bash setup.sh
# Step 2: Enhanced security
bash second_setup.sh
# Step 3: Docker and Traefik
bash third_setup.sh
```

# Setup Requirements

## For First Setup (setup.sh):
1. New username (if creating new account)
2. Public SSH key
3. Preferred timezone

## For Second Setup (second_setup.sh):
1. Custom SSH port (default: 22)
2. Email for notifications (optional)

## For Third Setup (third_setup.sh):
1. Domain name for Traefik dashboard
2. Email for Let's Encrypt SSL certificates

To generate an SSH key:
```bash
ssh-keygen -t ed25519 -a 200 -C "user@server" -f ~/.ssh/user_server_ed25519
cat ~/.ssh/user_server_ed25519.pub
```

# Post-Installation Verification

After First Setup:
* Test SSH login with new user
* Verify UFW status: `sudo ufw status`
* Check system timezone: `timedatectl`

After Second Setup:
* Test SSH on new port before closing current session
* Check fail2ban status: `sudo fail2ban-client status`
* Verify security updates: `cat /etc/apt/apt.conf.d/50unattended-upgrades`

After Third Setup:
* Verify Docker installation: `docker --version`
* Check Traefik status: `docker ps`
* Access Traefik dashboard: `https://traefik.your-domain.com`
* Verify SSL certificates: `https://traefik.your-domain.com/api/rawdata`

# Supported Versions
* Ubuntu 22.04 LTS (Recommended)
* Ubuntu 20.04 LTS
* Ubuntu 18.04 LTS
* Ubuntu 16.04 LTS
* Ubuntu 14.04 LTS

# Testing
Tests are run against Vagrant VMs. To run tests:
```bash
./tests/tests.sh
```
