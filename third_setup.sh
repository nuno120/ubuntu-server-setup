#!/bin/bash

# Source the library functions
source ./setupLibrary.sh

# Default values
DEFAULT_DOMAIN="notitiemaker.nl"
DEFAULT_EMAIL="beheer@notitiemaker.nl"

# Function to get user input with default value
get_user_input() {
    local prompt=$1
    local default=$2
    local value

    read -p "$prompt [$default]: " value
    echo ${value:-$default}
}

# Function to configure domain and email
configure_domain_email() {
    print_message "Domain and Email Configuration"
    echo "Default domain: $DEFAULT_DOMAIN"
    echo "Default email: $DEFAULT_EMAIL"
    
    read -p "Do you want to use default values? (y/N): " use_default
    if [[ ${use_default,,} == "y" ]]; then
        DOMAIN=$DEFAULT_DOMAIN
        EMAIL=$DEFAULT_EMAIL
    else
        DOMAIN=$(get_user_input "Enter your domain" "$DEFAULT_DOMAIN")
        EMAIL=$(get_user_input "Enter your email" "$DEFAULT_EMAIL")
    fi
    
    print_success "Domain set to: $DOMAIN"
    print_success "Email set to: $EMAIL"
}

# Function to install Docker
install_docker() {
    print_message "Installing Docker..."
    
    # Add Docker's official GPG key
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    # Add Docker repository
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Install Docker
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io
    
    # Add current user to docker group
    sudo usermod -aG docker $USER
    
    # Start and enable Docker service
    sudo systemctl start docker
    sudo systemctl enable docker
    
    print_success "Docker installed successfully!"
}

# Function to install Docker Compose
install_docker_compose() {
    print_message "Installing Docker Compose..."
    
    # Install Docker Compose from package manager
    sudo apt-get update
    sudo apt-get install -y docker-compose-plugin
    
    print_success "Docker Compose installed successfully!"
}

# Function to create Docker directory structure
create_docker_structure() {
    print_message "Creating Docker directory structure..."
    
    # Create main Docker directory
    sudo mkdir -p /opt/docker/{traefik/{config,acme},monitoring/{prometheus,grafana},apps}
    
    print_success "Docker directory structure created!"
}

# Function to configure Traefik
configure_traefik() {
    print_message "Configuring Traefik..."
    
    # Create Traefik network
    docker network create traefik-net || true
    
    # Create acme.json for SSL certificates
    sudo touch /opt/docker/traefik/acme/acme.json
    sudo chmod 600 /opt/docker/traefik/acme/acme.json
    
    # Create Traefik configuration
    cat << EOF | sudo tee /opt/docker/traefik/config/traefik.yml
global:
  checkNewVersion: true
  sendAnonymousUsage: false

api:
  dashboard: true
  insecure: false

entryPoints:
  web:
    address: ":80"
    http:
      redirections:
        entryPoint:
          to: websecure
          scheme: https
  websecure:
    address: ":443"
    http:
      tls:
        certResolver: letsencrypt
      middlewares:
        - securityHeaders@file
        - rateLimit@file

certificatesResolvers:
  letsencrypt:
    acme:
      email: "${EMAIL}"
      storage: /acme/acme.json
      httpChallenge:
        entryPoint: web

providers:
  docker:
    endpoint: "unix:///var/run/docker.sock"
    exposedByDefault: false
    network: traefik-net
  file:
    directory: /config
    watch: true

log:
  level: INFO
  format: json

accessLog:
  format: json
EOF

    # Create dynamic configuration for middlewares
    cat << 'EOF' | sudo tee /opt/docker/traefik/config/dynamic.yml
http:
  middlewares:
    securityHeaders:
      headers:
        sslRedirect: true
        forceSTSHeader: true
        stsIncludeSubdomains: true
        stsPreload: true
        stsSeconds: 31536000
        customFrameOptionsValue: "SAMEORIGIN"
        contentTypeNosniff: true
        browserXssFilter: true
        contentSecurityPolicy: "default-src 'self'"
        referrerPolicy: "strict-origin-when-cross-origin"
        permissionsPolicy: "camera=(), microphone=(), geolocation=(), payment=()"
    
    rateLimit:
      rateLimit:
        average: 100
        period: 1m
        burst: 50
EOF

    # Create docker-compose.yml for Traefik
    cat << EOF | sudo tee /opt/docker/docker-compose.yml
version: '3'

services:
  traefik:
    image: traefik:v2.10
    container_name: traefik
    restart: unless-stopped
    security_opt:
      - no-new-privileges:true
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./traefik/config/traefik.yml:/traefik.yml:ro
      - ./traefik/config/dynamic.yml:/config/dynamic.yml:ro
      - ./traefik/acme/acme.json:/acme/acme.json
    networks:
      - traefik-net
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.traefik.entrypoints=websecure"
      - "traefik.http.routers.traefik.rule=Host(\`traefik.${DOMAIN}\`)"
      - "traefik.http.routers.traefik.service=api@internal"
      - "traefik.http.routers.traefik.middlewares=securityHeaders@file"
      - "traefik.http.routers.traefik.tls.certresolver=letsencrypt"

networks:
  traefik-net:
    external: true
EOF

    print_success "Traefik configured successfully!"
}

# Function to start Traefik
start_traefik() {
    print_message "Starting Traefik..."
    cd /opt/docker
    sudo docker-compose up -d
    print_success "Traefik started successfully!"
}

# Main execution
print_message "Starting third setup script..."

# Check if script is run as root
check_root

# Get domain and email configuration
configure_domain_email

# Install and configure components
install_docker
install_docker_compose
create_docker_structure
configure_traefik
start_traefik

print_success "Third setup completed successfully!"
print_message "Traefik dashboard will be available at: https://traefik.$DOMAIN" 