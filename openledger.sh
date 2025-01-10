#!/bin/bash

# Define colors for output
CYAN='\033[36m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
RESET='\033[0m'

# Function to handle errors
handle_error() {
    echo -e "${RED}Error: $1${RESET}"
    exit 1
}

# Display the message and fetch the logo
echo -e "${GREEN}Displaying logo...${RESET}"
wget -qO- https://raw.githubusercontent.com/Chupii37/Chupii-Node/refs/heads/main/Logo.sh | bash || handle_error "Failed to fetch the logo script."

# Update system and install necessary dependencies
echo -e "${GREEN}Updating system and installing dependencies...${RESET}"
sudo apt update || handle_error "Failed to update system."
sudo apt upgrade -y || handle_error "Failed to upgrade system."
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common || handle_error "Failed to install basic dependencies."

# Install Docker
echo -e "${GREEN}Installing Docker...${RESET}"
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg || handle_error "Failed to add Docker GPG key."
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null || handle_error "Failed to add Docker repository."
sudo apt update || handle_error "Failed to update package list after adding Docker repo."
sudo apt install -y docker-ce docker-ce-cli containerd.io || handle_error "Failed to install Docker."
sudo systemctl start docker || handle_error "Failed to start Docker."
sudo systemctl enable docker || handle_error "Failed to enable Docker to start on boot."

# Display Docker version
docker --version || handle_error "Failed to display Docker version."

# Install Docker Compose if not installed
echo -e "${YELLOW}Checking if Docker Compose is installed...${RESET}"
if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}Docker Compose not found, installing...${RESET}"
    sudo apt-get install -y curl || handle_error "Failed to install curl."
    curl -L "https://github.com/docker/compose/releases/download/$(curl -s https://api.github.com/repos/docker/compose/releases/latest | jq -r .tag_name)/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose || handle_error "Failed to download Docker Compose."
    sudo chmod +x /usr/local/bin/docker-compose || handle_error "Failed to set executable permission for Docker Compose."
else
    echo -e "${GREEN}Docker Compose is already installed.${RESET}"
fi

# Check and install unzip
echo -e "${YELLOW}Checking if unzip is installed...${RESET}"
if ! command -v unzip &> /dev/null; then
    echo -e "${RED}Unzip not found, installing...${RESET}"
    sudo apt install unzip -y || handle_error "Failed to install unzip."
else
    echo -e "${GREEN}Unzip is already installed.${RESET}"
fi

# Install additional dependencies for desktop applications
echo -e "${YELLOW}Installing additional dependencies...${RESET}"
sudo apt install -y \
    wget curl unzip xorg xvfb sudo docker.io lxde ffmpeg \
    libasound2t64 libxss1 libappindicator3-1 libnss3 \
    libgtk-3-0 libx11-xcb1 libxtst6 libvpx-dev \
    mesa-utils libjsoncpp-dev libssl-dev \
    libcurl4-openssl-dev libva2 || handle_error "Failed to install dependencies."

# Clean up package lists to save space
sudo rm -rf /var/lib/apt/lists/*

# Create Dockerfile
echo -e "${GREEN}Creating Dockerfile...${RESET}"
cat <<EOF > Dockerfile
FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \\
    wget \\
    curl \\
    unzip \\
    xorg \\
    xvfb \\
    sudo \\
    docker.io \\
    lxde \\
    ffmpeg \\
    libasound2t64 \\
    libxss1 \\
    libappindicator3-1 \\
    libnss3 \\
    libgtk-3-0 \\
    libx11-xcb1 \\
    libxtst6 \\
    libvpx-dev \\
    mesa-utils \\
    libjsoncpp-dev \\
    libssl-dev \\
    libcurl4-openssl-dev \\
    libva2 \\
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /file-dock
RUN wget -P /file-dock https://cdn.openledger.xyz/openledger-node-1.0.0-linux.zip && \\
    unzip /file-dock/openledger-node-1.0.0-linux.zip -d /file-dock

RUN dpkg -i /file-dock/openledger-node-1.0.0-linux.deb && apt --fix-broken install -y

WORKDIR /file-dock
ENTRYPOINT ["openledger-node", "--no-sandbox", "--disable-gpu"]
CMD ["./openledger-node"]
EOF

# Create Docker Compose file with volume and user customization
echo -e "${GREEN}Creating Docker Compose file...${RESET}"
cat <<EOF > docker-compose.yml
version: '3.8'

services:
  app:
    build: .
    container_name: openledger-docker
    environment:
      - DISPLAY=${DISPLAY}
      - OPENLEDGER_VERSION=\${OPENLEDGER_VERSION:-1.0.0}
    volumes:
      - openledger_data:/file-dock/data
      - /tmp/.X11-unix:/tmp/.X11-unix
    network_mode: host
    privileged: true
    shm_size: '2gb'
    stdin_open: true
    tty: true

volumes:
  openledger_data:
EOF

# Create .env file for user customization
echo -e "${GREEN}Creating .env file for user customization...${RESET}"
cat <<EOF > .env
OPENLEDGER_VERSION=1.0.0
EOF

# Final success message
echo -e "${GREEN}Dockerfile, Docker Compose file, and .env file have been created.${RESET}"
echo -e "${GREEN}You can now build the Docker container using 'docker-compose up --build'.${RESET}"
