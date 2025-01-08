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

# Step 4: Install necessary libraries for X11 forwarding and GUI applications
echo -e "\033[33mInstalling required dependencies for GUI...\033[0m"
sudo apt install -y \
    libgtk-3-0 libnotify4 libnss3 libxss1 libxtst6 \
    xdg-utils libatspi2.0-0 libsecret-1-0 \
    xorg x11-apps

# Step 5: Create a folder for openledger-node and change into that directory
echo -e "\033[33mCreating the openledger-node directory...\033[0m"
mkdir -p openledger-node
cd openledger-node

# Step 6: Download the openledger-node-1.0.0-linux.zip file
echo -e "\033[33mDownloading openledger-node-1.0.0-linux.zip...\033[0m"
wget https://cdn.openledger.xyz/openledger-node-1.0.0-linux.zip

# Step 7: Unzip the downloaded file
echo -e "\033[33mUnzipping openledger-node-1.0.0-linux.zip...\033[0m"
unzip -o openledger-node-1.0.0-linux.zip

# Step 8: Install the .deb package
echo -e "\033[33mInstalling the openledger-node .deb package...\033[0m"
sudo dpkg -i openledger-node-1.0.0.deb

# Step 9: Fix any missing dependencies
echo -e "\033[33mFixing dependencies...\033[0m"
sudo apt-get install -f

# Step 10: Create a Dockerfile with X11 forwarding setup
echo -e "\033[33mCreating Dockerfile...\033[0m"
cat > Dockerfile <<EOL
# Use an official Ubuntu as a base image
FROM ubuntu:20.04

# Set environment variables to disable interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Update package list and install dependencies
RUN apt-get update && apt-get install -y \
    libgtk-3-0 libnotify4 libnss3 libxss1 libxtst6 \
    xdg-utils libatspi2.0-0 libsecret-1-0 \
    wget unzip x11-apps \
    && apt-get clean

# Set the working directory to /opt/ubuntu-node in the container
WORKDIR /opt/ubuntu-node

# Copy the openledger-node-1.0.0-linux.zip file from the host into the container
COPY openledger-node-1.0.0-linux.zip /opt/ubuntu-node/

# Unzip the downloaded zip file inside the container
RUN unzip openledger-node-1.0.0-linux.zip && rm openledger-node-1.0.0-linux.zip

# Install the node by installing the .deb package
RUN dpkg -i openledger-node-1.0.0.deb && apt-get install -f

# Set environment variable to allow X11 forwarding
ENV DISPLAY=:0

# Start the node (adjust the command if necessary, this assumes the node starts via systemctl or other command)
CMD ["openledger-node", "start"]
EOL

# Step 11: Display success message for Dockerfile creation
echo -e "\033[32mDockerfile created successfully!\033[0m"

# Step 12: Build the Docker image from the Dockerfile
echo -e "\033[33mBuilding Docker image...\033[0m"
docker build -t openledger-node-x11 .

# Step 13: Allow Docker containers to access the host's X11 server
echo -e "\033[33mAllowing Docker to access X11 server...\033[0m"
xhost +local:docker

# Step 14: Run the OpenLedger Node container with X11 forwarding enabled
echo -e "\033[33mStarting OpenLedger Node container with X11 forwarding...\033[0m"
docker run -d \
    --name openledger-node-x11 \
    -e DISPLAY=$DISPLAY \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    openledger-node-x11

# Final success message
echo -e "\033[32mOpenLedger Node is now running with X11 forwarding!\033[0m"
