# PyTorch GPU Application

This application demonstrates GPU usage with PyTorch in a Docker container. It creates a random tensor and verifies GPU availability.

## Prerequisites

- NVIDIA GPU with CUDA support
- NVIDIA drivers installed
- Linux-based operating system (Ubuntu recommended)

## Quick Start

1. Make the installation script executable and run it:
   ```bash
   chmod +x install.sh
   ./install.sh
   ```

The script will:
- Install Docker if not present
- Install Docker Compose if not present
- Install NVIDIA Container Toolkit
- Build and run the container

## Manual Installation

If you prefer to install manually:

1. Install Docker:
   ```bash
   curl -fsSL https://get.docker.com -o get-docker.sh
   sudo sh get-docker.sh
   ```

2. Install NVIDIA Container Toolkit:
   ```bash
   distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
   curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
   curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list
   sudo apt-get update && sudo apt-get install -y nvidia-container-toolkit
   ```

3. Build and run:
   ```bash
   docker-compose up --build -d
   ```

## Project Structure

```
.
├── app.py              # Main application file
├── Dockerfile          # Docker configuration
├── docker-compose.yml  # Docker Compose configuration
├── install.sh          # Installation script
└── README.md           # This file
```

## Monitoring

- View logs: `docker-compose logs`
- Stop application: `docker-compose down`
- Restart application: `docker-compose restart`

## Troubleshooting

1. If GPU is not detected:
   - Verify NVIDIA drivers are installed: `nvidia-smi`
   - Check Docker GPU support: `docker run --gpus all nvidia/cuda:10.2-base nvidia-smi`

2. If Docker permission issues occur:
   ```bash
   sudo usermod -aG docker $USER
   newgrp docker
   ```

## License

This project is open-source and available under the MIT License.
