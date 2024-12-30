#!/bin/bash

set -e

function getCurrentDir() {
    local current_dir="${BASH_SOURCE%/*}"
    if [[ ! -d "${current_dir}" ]]; then current_dir="$PWD"; fi
    echo "${current_dir}"
}

current_dir=$(getCurrentDir)
output_file="output.log"

# Redirect output to both console and log file
exec 3>&1 >>"${output_file}" 2>&1

echo "Starting additional security configurations..." >&3

# Configure custom SSH port
echo "Enter custom SSH port (default: 22):" >&3
read -rp $'' ssh_port
ssh_port=${ssh_port:-22}

# Update SSH port in sshd_config
sudo sed -i "s/^#*Port .*/Port ${ssh_port}/" /etc/ssh/sshd_config

# Configure UFW for the requirements
echo "Configuring firewall..." >&3
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Update SSH port in UFW
sudo ufw delete allow OpenSSH >/dev/null 2>&1 || true
sudo ufw allow "${ssh_port}"/tcp comment 'SSH custom port'
sudo ufw allow 80/tcp comment 'HTTP'
sudo ufw allow 443/tcp comment 'HTTPS'

# Install and configure fail2ban
echo "Installing and configuring fail2ban..." >&3
sudo apt-get update
sudo apt-get install -y fail2ban

# Configure fail2ban
cat << EOF | sudo tee /etc/fail2ban/jail.local
[DEFAULT]
bantime = 60
findtime = 60
maxretry = 25
action = %(action_)s

[sshd] # This is activated when a ssh connection is made
enabled = true
port = ${ssh_port}
filter = sshd
logpath = /var/log/auth.log

# This is activated when a api request returns a 401 or 403, so we can block the ip address
[http-auth]
enabled = true
filter = apache-auth
ports = http,https
logpath = /var/log/apache2/error.log
maxretry = 50
findtime = 60
bantime = 60


# This is always activated
[http-get-dos]
enabled = true
port = http,https
filter = http-get-dos
logpath = /var/log/apache2/access.log
maxretry = 300
findtime = 60
bantime = 60
EOF

# Create custom filter for HTTP DOS protection
cat << EOF | sudo tee /etc/fail2ban/filter.d/http-get-dos.conf
[Definition]
failregex = ^<HOST> -.*"(GET|POST).*
ignoreregex =
EOF

# Configure unattended upgrades
echo "Configuring automatic security updates..." >&3
sudo apt-get install -y unattended-upgrades apt-listchanges

cat << EOF | sudo tee /etc/apt/apt.conf.d/50unattended-upgrades
Unattended-Upgrade::Allowed-Origins {
    "\${distro_id}:\${distro_codename}-security";
    "\${distro_id}ESMApps:\${distro_codename}-apps-security";
    "\${distro_id}ESM:\${distro_codename}-infra-security";
};
Unattended-Upgrade::Package-Blacklist {
};
Unattended-Upgrade::AutoFixInterruptedDpkg "true";
Unattended-Upgrade::MinimalSteps "true";
Unattended-Upgrade::InstallOnShutdown "false";
Unattended-Upgrade::Mail "root";
Unattended-Upgrade::MailOnlyOnError "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "true";
Unattended-Upgrade::Automatic-Reboot-Time "02:00";
EOF

# Enable unattended upgrades
sudo dpkg-reconfigure -f noninteractive unattended-upgrades

# Restart services
echo "Restarting services..." >&3
sudo systemctl restart fail2ban
sudo service ssh restart

echo "Security setup completed!" >&3
echo "Please make sure to:" >&3
echo "1. Test SSH connection on new port before closing this session" >&3
echo "2. Configure email settings in fail2ban if needed" >&3
echo "3. Check /var/log/fail2ban.log for fail2ban status" >&3
