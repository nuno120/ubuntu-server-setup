# Bash setup script for Ubuntu servers
[![Build Status](https://travis-ci.org/jasonheecs/ubuntu-server-setup.svg?branch=master)](https://travis-ci.org/jasonheecs/ubuntu-server-setup)

This is a setup script to automate the setup and provisioning of Ubuntu servers. It does the following:

## Basic Setup (setup.sh)
* Adds or updates a user account with sudo access
* Adds a public ssh key for the new user account
* Disables password authentication to the server
* Deny root login to the server
* Setup Uncomplicated Firewall
* Create Swap file based on machine's installed memory
* Setup the timezone for the server (Default to "Asia/Singapore")
* Install Network Time Protocol

## Enhanced Security Setup (total_setup.sh)
* All features from basic setup
* Configures custom SSH port
* Enhanced UFW configuration:
  * Allow custom SSH port
  * Allow HTTP (80)
  * Allow HTTPS (443)
  * Deny all other incoming traffic
* Fail2ban installation and configuration:
  * SSH protection (max 3 retries)
  * HTTP/HTTPS protection
  * 10-minute ban time for failed attempts
  * Email notifications for bans
* Automatic security updates:
  * Unattended-upgrades configuration
  * Security updates automation
  * Email notifications for important updates

# Installation
SSH into your server and install git if it is not installed:
```bash
sudo apt-get update
sudo apt-get install git
```

Clone this repository into your home directory:
```bash
cd ~
git clone https://github.com/nuno120/ubuntu-server-setup.git
```

Run either the basic or enhanced setup script:
```bash
cd ubuntu-server-setup
# For basic setup:
bash setup.sh
# For enhanced security setup:
bash total_setup.sh
```

# Setup prompts
When the setup script is run, you will be prompted for:

1. Whether to create a new non-root user account
2. The username for the new account (if creating one)
3. The public SSH key for the new account
4. The timezone for the server (Default: "Asia/Singapore")

Additional prompts for enhanced setup:
5. Custom SSH port (Default: 22)

To generate an SSH key from your local machine:
```bash
ssh-keygen -t ed25519 -a 200 -C "user@server" -f ~/.ssh/user_server_ed25519
cat ~/.ssh/user_server_ed25519.pub
```

# Post-Installation
After running the enhanced setup script:
1. Test SSH connection on the new port before closing the current session
2. Configure email settings in fail2ban if needed
3. Check /var/log/fail2ban.log for fail2ban status
4. Verify firewall rules with `sudo ufw status`

# Supported versions
This setup script has been tested against Ubuntu 14.04, Ubuntu 16.04, Ubuntu 18.04, Ubuntu 20.04 and Ubuntu 22.04.

# Running tests
Tests are run against a set of Vagrant VMs. To run the tests, run the following in the project's directory:  
`./tests/tests.sh`

# Security Features
## SSH Hardening
* Custom port (configurable)
* Key-based authentication only
* Root login disabled
* Password authentication disabled

## Firewall (UFW)
* Deny incoming by default
* Allow outgoing by default
* Custom SSH port allowed
* HTTP/HTTPS ports allowed
* All other ports blocked

## Fail2ban Protection
* SSH brute force protection
* HTTP/HTTPS authentication protection
* DOS attack protection
* Email notifications for security events

## Automatic Updates
* Security updates automated
* Configurable email notifications
* Unattended upgrade support
* System update automation
