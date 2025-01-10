#!/bin/bash

# Display messages with different colors
CYAN='\033[36m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
MAGENTA='\033[35m'
RESET='\033[0m'

# Display a message in cyan color
echo -e "${CYAN}Starting openledger setup script...${RESET}"

# Display the message and fetch the logo from the provided URL
echo -e "${GREEN}Menampilkan logo...${RESET}"
wget -qO- https://raw.githubusercontent.com/Chupii37/Chupii-Node/refs/heads/main/Logo.sh | bash

# Check for system updates and upgrade
echo -e "${YELLOW}Checking system updates and upgrading...${RESET}"
sudo apt update && sudo apt upgrade -y

# Check if Docker is installed
echo -e "${YELLOW}Checking if Docker is installed...${RESET}"
if ! command -v docker &> /dev/null
then
    echo -e "${RED}Docker not found, installing...${RESET}"
    sudo apt install docker.io -y
else
    echo -e "${GREEN}Docker is already installed.${RESET}"
fi

# Check if Docker Compose is installed
echo -e "${YELLOW}Checking if Docker Compose is installed...${RESET}"
if ! command -v docker-compose &> /dev/null
then
    echo -e "${RED}Docker Compose not found, installing...${RESET}"
    sudo apt-get install -y curl
    curl -L "https://github.com/docker/compose/releases/download/$(curl -s https://api.github.com/repos/docker/compose/releases/latest | jq -r .tag_name)/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
else
    echo -e "${GREEN}Docker Compose is already installed.${RESET}"
fi

# Check if unzip is installed
echo -e "${YELLOW}Checking if unzip is installed...${RESET}"
if ! command -v unzip &> /dev/null
then
    echo -e "${RED}Unzip not found, installing...${RESET}"
    sudo apt install unzip -y
else
    echo -e "${GREEN}Unzip is already installed.${RESET}"
fi

# Install additional dependencies for desktop applications
echo -e "${YELLOW}Installing additional dependencies for desktop applications...${RESET}"
sudo apt install -y \
    wget \
    curl \
    unzip \
    xorg \
    xvfb \
    sudo \
    docker.io \
    lxde \
    ffmpeg \
    libasound2t64 \
    libxss1 \
    libappindicator3-1 \
    libnss3 \
    libgtk-3-0 \
    libx11-xcb1 \
    libxtst6 \
    libgnome2-0 \
    libva2 \
    libjsoncpp-dev \
    libssl-dev \
    libcurl4-openssl-dev \
    libgl1-mesa-glx \
    libvpx-dev \
    mesa-utils

# Run the docker setup
echo -e "${GREEN}Running Docker setup...${RESET}"

# Create Dockerfile
cat <<EOF > Dockerfile
# Use Ubuntu as the base image
FROM ubuntu:20.04

# Set the environment variable to non-interactive mode for installing packages
ENV DEBIAN_FRONTEND=noninteractive

# Install required dependencies
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
    libgnome2-0 \\
    libva2 \\
    libjsoncpp-dev \\
    libssl-dev \\
    libcurl4-openssl-dev \\
    libgl1-mesa-glx \\
    libvpx-dev \\
    mesa-utils \\
    && rm -rf /var/lib/apt/lists/*

# Create directory to store downloaded files (file-dock)
RUN mkdir -p /file-dock

# Download the openledger-node package directly in the container
RUN wget -P /file-dock https://cdn.openledger.xyz/openledger-node-1.0.0-linux.zip

# Unpack the downloaded zip file inside the container
RUN unzip /file-dock/openledger-node-1.0.0-linux.zip -d /file-dock

# Install the .deb package inside the container
RUN dpkg -i /file-dock/openledger-node-1.0.0-linux.deb && apt --fix-broken install -y

# Set the working directory to /file-dock
WORKDIR /file-dock

# Set the entrypoint with flags
ENTRYPOINT ["openledger-node", "--no-sandbox", "--disable-gpu"]

# Run the openledger node
CMD ["./openledger-node"]
EOF

# Create Docker Compose file
cat <<EOF > docker-compose.yml
version: '3.8'

services:
  app:
    build: .
    container_name: openledger-docker
    environment:
      - DISPLAY=${DISPLAY}  # Pass the display variable to the container
    volumes:
      - /tmp/.X11-unix:/tmp/.X11-unix  # Mount X11 socket to forward the display
    network_mode: host  # Ensure we can forward to the host's X11 server
    privileged: true  # Needed for Docker to work inside Docker if required
    shm_size: '2gb'  # Shared memory size for GUI apps
    stdin_open: true
    tty: true
EOF

# Success message
echo -e "${GREEN}Dockerfile and Docker Compose file have been created.${RESET}"
echo -e "${GREEN}You can now build the Docker container using 'docker-compose up --build'.${RESET}"
