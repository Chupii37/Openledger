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

# Step 4: Create the Dockerfile
echo -e "\033[33mCreating Dockerfile...\033[0m"
cat > Dockerfile <<EOL
# Use an official Ubuntu as a base image
FROM ubuntu:20.04

# Set environment variables to disable interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install necessary dependencies
RUN apt-get update && apt-get install -y \\
    apt-transport-https \\
    ca-certificates \\
    curl \\
    unzip \\
    wget \\
    sudo \\
    lsb-release \\
    libgtk-3-0 \\
    libnotify4 \\
    libnss3 \\
    libxss1 \\
    libxtst6 \\
    xdg-utils \\
    libatspi2.0-0 \\
    libsecret-1-0 \\
    && apt-get clean

# Set working directory in Docker
WORKDIR /opt

# Step 1: Download the OpenLedger Node zip file inside the container
RUN wget https://cdn.openledger.xyz/openledger-node-1.0.0-linux.zip

# Step 2: Unzip the OpenLedger Node zip file
RUN unzip openledger-node-1.0.0-linux.zip && rm openledger-node-1.0.0-linux.zip

# Step 3: Install the OpenLedger Node .deb package
RUN dpkg -i /opt/openledger-node-1.0.0/openledger-node-1.0.0.deb && apt-get install -f

# Step 4: Install any additional dependencies or confirm directory structure
RUN ls -l /opt/openledger-node-1.0.0/

# Step 5: Expose X11 socket to allow GUI applications to run
RUN apt-get update && apt-get install -y x11-apps

# Allow Docker to access X11 server
RUN echo "xhost +local:docker" > ~/.bashrc

# Command to start the OpenLedger Node
CMD ["/opt/openledger-node-1.0.0/openledger-node", "--no-sandbox"]
EOL

echo -e "\033[32mDockerfile created successfully!\033[0m"

# Step 5: Build the Docker image
echo -e "\033[33mBuilding Docker image...\033[0m"
docker build -t openledger-node-x11 .

# Step 6: Allow Docker to access X11 server (necessary for GUI applications)
echo -e "\033[33mAllowing Docker to access X11 server...\033[0m"
xhost +local:docker

# Step 7: Run the OpenLedger Node container with X11 forwarding
echo -e "\033[33mStarting OpenLedger Node container with X11 forwarding...\033[0m"
docker run -d --name openledger-node-x11 --restart always --network host -e DISPLAY=$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix openledger-node-x11

echo -e "\033[32mOpenLedger Node is now running with X11 forwarding and auto-restart!\033[0m"
