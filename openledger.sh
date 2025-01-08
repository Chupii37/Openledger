#!/bin/bash

# Display a message in cyan color
echo -e "\033[36mShowing ANIANI!!!\033[0m"

# Display the message and fetch the logo from the provided URL
echo -e "\033[32mMenampilkan logo...\033[0m"
wget -qO- https://raw.githubusercontent.com/Chupii37/Chupii-Node/refs/heads/main/Logo.sh | bash

# Step 1: Update system and install dependencies
echo -e "\033[33mUpdating system packages...\033[0m"
sudo apt update && sudo apt upgrade -y
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common unzip x11-apps

# Step 2: Check if `unzip` is installed and install if necessary
echo -e "\033[33mChecking if 'unzip' is installed...\033[0m"
if ! command -v unzip &> /dev/null
then
    echo -e "\033[31m'unzip' not found. Installing 'unzip'...\033[0m"
    sudo apt install -y unzip
    echo -e "\033[32m'unzip' installed successfully!\033[0m"
else
    echo -e "\033[32m'unzip' is already installed.\033[0m"
fi

# Step 3: Install Docker if not installed
echo -e "\033[33mChecking Docker installation...\033[0m"
if ! command -v docker &> /dev/null
then
    echo -e "\033[31mDocker not found. Installing Docker...\033[0m"
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt update
    sudo apt install -y docker-ce
    sudo systemctl start docker
    sudo systemctl enable docker
    echo -e "\033[32mDocker installed successfully!\033[0m"
else
    echo -e "\033[32mDocker is already installed.\033[0m"
fi

# Step 4: Check and install OpenLedger Node .deb package
echo -e "\033[33mDownloading and installing OpenLedger Node...\033[0m"
wget https://cdn.openledger.xyz/openledger-node-1.0.0-linux.zip -P /tmp/
unzip /tmp/openledger-node-1.0.0-linux.zip -d /tmp/

# Find the .deb file after extraction and install it
DEB_FILE=$(find /tmp -name "openledger-node-*.deb" | head -n 1)

if [ -z "$DEB_FILE" ]; then
    echo -e "\033[31mNo .deb file found. Exiting...\033[0m"
    exit 1
else
    echo -e "\033[32mFound .deb file: $DEB_FILE\033[0m"
    sudo dpkg -i "$DEB_FILE"
    sudo apt-get install -f
fi

# Step 5: Allow Docker to access X11 server for GUI applications
echo -e "\033[33mAllowing Docker to access the X11 server...\033[0m"
# Ensuring MobaXterm X11 server is listening and accessible (if using Windows)
xhost +localhost

# Step 6: Check if the OpenLedger Node Docker image exists
echo -e "\033[33mChecking for the OpenLedger Node Docker image...\033[0m"
if ! docker image inspect openledger-node-x11:latest &> /dev/null; then
    echo -e "\033[31mDocker image 'openledger-node-x11:latest' not found.\033[0m"
    echo -e "Building the Docker image now..."

    # Step 6.1: Create Dockerfile and build the image if it's missing
    echo -e "\033[33mCreating a Dockerfile and building the image...\033[0m"
    cat <<EOF > Dockerfile
# Use a base image, such as Ubuntu
FROM ubuntu:20.04

# Install dependencies
RUN apt update && apt install -y \
    wget \
    unzip \
    x11-apps \
    apt-transport-https \
    ca-certificates \
    curl \
    docker.io

# Install Docker
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu focal stable" > /etc/apt/sources.list.d/docker.list && \
    apt update && apt install -y docker-ce

# Expose necessary ports and set entry point
EXPOSE 8080
CMD ["your-command-to-start-openledger-node"]
EOF

    # Build the Docker image from the created Dockerfile
    docker build -t openledger-node-x11 .
else
    echo -e "\033[32mDocker image 'openledger-node-x11:latest' found.\033[0m"
fi

# Step 7: Run OpenLedger Node container with X11 forwarding via MobaXterm
echo -e "\033[33mStarting OpenLedger Node container with X11 forwarding...\033[0m"
docker run -d --name openledger-node-x11 \
    --env DISPLAY=host.docker.internal:0 \  # Use `host.docker.internal:0` for Docker Desktop (Windows/Mac)
    --volume /tmp/.X11-unix:/tmp/.X11-unix \
    --network host \
    openledger-node-x11:latest

# Step 8: Confirm Docker container is running
echo -e "\033[33mChecking if OpenLedger Node container is running...\033[0m"
docker ps

# Final message
echo -e "\033[32mOpenLedger Node installation and setup completed!\033[0m"
