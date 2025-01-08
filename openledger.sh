#!/bin/bash

# Display a message in cyan color
echo -e "\033[36mShowing ANIANI!!!\033[0m"

# Display the message and fetch the logo from the provided URL
echo -e "\033[32mMenampilkan logo...\033[0m"
wget -qO- https://raw.githubusercontent.com/Chupii37/Chupii-Node/refs/heads/main/Logo.sh | bash

# Step 1: Update the system and upgrade installed packages
echo -e "\033[33mUpdating system packages...\033[0m"
sudo apt update && sudo apt upgrade -y

# Step 2: Check if Docker is installed
echo -e "\033[33mChecking Docker installation...\033[0m"
if ! command -v docker &> /dev/null
then
    echo -e "\033[31mDocker is not installed. Installing Docker...\033[0m"
    # Install Docker if not present
    sudo apt install -y docker.io
    sudo systemctl start docker
    sudo systemctl enable docker
    echo -e "\033[32mDocker installed successfully!\033[0m"
else
    echo -e "\033[32mDocker is already installed.\033[0m"
fi

# Step 3: Check if unzip is installed, and install it if necessary
echo -e "\033[33mChecking unzip installation...\033[0m"
if ! command -v unzip &> /dev/null
then
    echo -e "\033[31mUnzip is not installed. Installing unzip...\033[0m"
    sudo apt install -y unzip
    echo -e "\033[32mUnzip installed successfully!\033[0m"
else
    echo -e "\033[32mUnzip is already installed.\033[0m"
fi

# Step 4: Create a folder for openledger-node and change into that directory
echo -e "\033[33mCreating the openledger-node directory...\033[0m"
mkdir -p openledger-node
cd openledger-node

# Step 5: Download the openledger-node-1.0.0-linux.zip file
echo -e "\033[33mDownloading openledger-node-1.0.0-linux.zip...\033[0m"
wget https://cdn.openledger.xyz/openledger-node-1.0.0-linux.zip

# Step 6: Unzip the downloaded file
echo -e "\033[33mUnzipping openledger-node-1.0.0-linux.zip...\033[0m"
unzip -o openledger-node-1.0.0-linux.zip

# Step 7: Install the .deb package
echo -e "\033[33mInstalling the openledger-node .deb package...\033[0m"
sudo dpkg -i openledger-node-1.0.0.deb

# Step 8: Fix any missing dependencies
echo -e "\033[33mFixing dependencies...\033[0m"
sudo apt-get install -f

# Step 9: Allow Docker to access X11 server (necessary for GUI applications)
echo -e "\033[33mAllowing Docker to access X11 server...\033[0m"
xhost +local:docker

# Step 10: Create Dockerfile
echo -e "\033[33mCreating Dockerfile...\033[0m"
cat > Dockerfile <<EOL
# Use an official Ubuntu as a base image
FROM ubuntu:20.04

# Set environment variables to disable interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install necessary dependencies
RUN apt-get update && apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    unzip \
    sudo \
    lsb-release \
    libgtk-3-0 \
    libnotify4 \
    libnss3 \
    libxss1 \
    libxtst6 \
    xdg-utils \
    libatspi2.0-0 \
    libsecret-1-0 \
    && apt-get clean

# Set working directory in Docker
WORKDIR /opt

# Step 1: Copy the zip file into the container
COPY openledger-node-1.0.0-linux.zip /opt/

# Step 2: Unzip the OpenLedger Node zip file
RUN unzip openledger-node-1.0.0-linux.zip && rm openledger-node-1.0.0-linux.zip

# Step 3: Install the OpenLedger Node .deb package
RUN dpkg -i /opt/openledger-node-1.0.0/openledger-node-1.0.0.deb && apt-get install -f

# Step 4: Check and confirm that the directory exists after installation
RUN ls -l /opt && echo "OpenLedger Node installed successfully!"

# Expose X11 socket to allow GUI applications to run
RUN apt-get update && apt-get install -y x11-apps

# Allow Docker to access X11 server
RUN echo "xhost +local:docker" > ~/.bashrc

# Command to start the OpenLedger Node
CMD ["/opt/openledger-node-1.0.0/openledger-node", "--no-sandbox"]
EOL

# Step 11: Build the Docker image
echo -e "\033[33mBuilding Docker image...\033[0m"
docker build -t openledger-node-x11 .

# Step 12: Allow Docker to access X11 server (ensure permissions for local connections)
echo -e "\033[33mAllowing Docker to access X11 server...\033[0m"
xhost +local:docker

# Step 13: Start the Docker container with X11 forwarding
echo -e "\033[33mStarting OpenLedger Node container with X11 forwarding...\033[0m"
docker run -e DISPLAY=$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix -d --name openledger-node-x11 --restart unless-stopped openledger-node-x11

echo -e "\033[32mOpenLedger Node has been installed and is running with X11 forwarding and auto-restart!\033[0m"
