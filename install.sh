#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting installation process...${NC}"

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Docker is not installed. Please install Docker...${NC}"
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker compose &> /dev/null; then
    echo -e "${RED}Docker Compose is not installed. Please Install Docker Compose...${NC}"
    exit 1
fi

# Check if NVIDIA drivers are installed
if ! command -v nvidia-smi &> /dev/null; then
    echo -e "${RED}NVIDIA drivers are not installed. Please install NVIDIA drivers first.${NC}"
    exit 1
fi

# Install NVIDIA Container Toolkit
if ! dnf list installed | grep -q nvidia-container-toolkit; then
    echo -e "${GREEN}Installing NVIDIA Container Toolkit...${NC}"
    distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
    curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
    curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list
    sudo dnf config-manager --add-repo https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo && \
    sudo dnf install -y nvidia-container-toolkit
    sudo systemctl restart docker
fi

# Build and run the container
echo -e "${GREEN}Building and starting the container...${NC}"
docker compose up --build -d

echo -e "${GREEN}Installation completed! Check the logs with: docker-compose logs${NC}"
