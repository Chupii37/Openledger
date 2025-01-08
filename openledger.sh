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

# Step 7: Create a Dockerfile
echo -e "\033[33mCreating Dockerfile...\033[0m"
cat > Dockerfile <<EOL
# Use an official Ubuntu as a base image
FROM ubuntu:20.04

# Set environment variables to disable interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Update package list and install dependencies
RUN apt-get update && apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    unzip \
    sudo \
    lsb-release \
    && apt-get clean

# Set the working directory to /opt/ubuntu-node in the container
WORKDIR /opt/ubuntu-node

# Copy the openledger-node-1.0.0-linux.zip file from the host into the container
COPY openledger-node-1.0.0-linux.zip /opt/ubuntu-node/

# Unzip the downloaded zip file inside the container
RUN unzip openledger-node-1.0.0-linux.zip && rm openledger-node-1.0.0-linux.zip

# Install the node by running the install script
RUN chmod +x install.sh && ./install.sh

# Start the node (adjust this to your actual start command)
CMD ["./start-node.sh"]
EOL

# Step 8: Display success message for Dockerfile creation
echo -e "\033[32mDockerfile created successfully!\033[0m"

# Step 9: Build the Docker image from the Dockerfile
echo -e "\033[33mBuilding Docker image...\033[0m"
docker build -t openledger-node .

# Step 10: Run the OpenLedger Node container with auto-restart policy
echo -e "\033[33mStarting OpenLedger Node container with auto-restart...\033[0m"
docker run -d --name openledger-node --restart unless-stopped openledger-node

# Final success message
echo -e "\033[32mOpenLedger Node has been installed and is running with auto-restart!\033[0m"
