#!/usr/bin/env bash
# This script installs NVIDIA drivers and container toolkit on Debian-based systems.
# Tested on Ubuntu and Debian.

set -euo pipefail

script_name=$(basename "$0")
prefix="[${script_name}]"
hostname=$(hostname)

function say {
    echo -e "\e[34m${prefix} $(date +'%H:%M:%S')\e[0m: $*"
}

function say_error {
    echo -e "\e[31m${prefix} $(date +'%H:%M:%S')\e[0m: $*" >&2
}

function pre-checks {
    if ! grep -qiE 'debian|ubuntu' /etc/os-release; then
        say_error "This script is only meant to run on Debian-based systems"
        exit 1
    fi
}

function check_nvidia_gpu_presence() {
    say "Checking for NVIDIA GPU..."
    
    if ! lspci | grep -i "NVIDIA" &>/dev/null; then
        say_error "No NVIDIA GPU detected in the system. Installation cannot proceed."
        echo "PCI devices found:"
        lspci | grep -i "VGA"
        exit 1
    fi
    
    local gpu_count=$(lspci | grep -i "NVIDIA" | wc -l)
    say "Found ${gpu_count} NVIDIA GPU(s)"
    
    echo "GPU details:"
    lspci -nn | grep -i "NVIDIA" | while read -r line; do
        echo "  - $line"
    done
    
    if ! lspci -v | grep -i "NVIDIA" | grep -i "3D controller\|VGA compatible controller" &>/dev/null; then
        say_error "Warning: NVIDIA GPU found but may not support graphics/compute capabilities"
        echo -ne "\n\t\e[31mDo you want to continue anyway? [y/N]\e[0m "
        read -r answer
        echo -e "\n"
        if [[ ! "${answer}" =~ ^[Yy]$ ]]; then
            say "Installation aborted by user"
            exit 1
        fi
    fi
}

function check_disk_space() {
    local required_space=10 # Required space in GB
    local available_space=$(df -BG /usr | awk 'NR==2 {print $4}' | sed 's/G//')
    
    say "Checking available disk space..."
    if [ "${available_space}" -lt "${required_space}" ]; then
        say_error "Insufficient disk space. Required: ${required_space}GB, Available: ${available_space}GB"
        exit 1
    fi
    say "Sufficient disk space available: ${available_space}GB"
}

function check_system_requirements() {
    local min_ram=8 # Minimum RAM in GB
    local ram_gb=$(free -g | awk '/^Mem:/{print $2}')
    
    say "Checking system requirements..."
    
    if [ "${ram_gb}" -lt "${min_ram}" ]; then
        say_error "Insufficient RAM. Required: ${min_ram}GB, Available: ${ram_gb}GB"
        exit 1
    fi

    local min_cores=2
    local cpu_cores=$(nproc)
    if [ "${cpu_cores}" -lt "${min_cores}" ]; then
        say_error "Insufficient CPU cores. Required: ${min_cores}, Available: ${cpu_cores}"
        exit 1
    fi

    say "System requirements met: ${ram_gb}GB RAM, ${cpu_cores} CPU cores"
}

function install_dependencies() {
    say "Installing required dependencies..."
    sudo apt-get update
    sudo apt-get install -y \
        build-essential \
        linux-headers-$(uname -r) \
        pkg-config \
        dkms \
        curl \
        gnupg \
        software-properties-common
}

function check-nvidia-installed {
    nvidia-smi &>/dev/null
}

function install-nvidia-driver {
    if check-nvidia-installed; then
        say "NVIDIA drivers are already installed; skipping..."
        return
    fi

    say "Installing NVIDIA drivers..."
    
    # Add NVIDIA repository
    curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
    curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
        sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
        sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

    sudo apt-get update
    
    # Install NVIDIA drivers
    sudo apt-get install -y nvidia-driver-535  # You can change version number if needed

    say "A reboot is required to load the NVIDIA drivers."
    say "These are the users connected to the system:"
    who
    echo -ne "\n\t\e[31mDo you want to reboot now? [y/N]\e[0m "
    read -r answer
    echo -e "\n"
    if [[ "${answer}" =~ ^[Yy]$ ]]; then
        say "Run this script again after the reboot to continue the installation."
        sleep 2
        say "Rebooting in 10 seconds... Ctrl+C to cancel."
        sleep 10
        sudo reboot
    fi
}

function check-container-toolkit-installed {
    nvidia-container-toolkit --version &>/dev/null
}

function install-container-toolkit {
    if check-container-toolkit-installed; then
        say "Container toolkit is already installed; skipping..."
        return
    fi
    
    say "Installing container toolkit..."
    # Install Docker if not present
    if ! command -v docker &>/dev/null; then
        say "Installing Docker..."
        curl -fsSL https://get.docker.com | sh
        sudo usermod -aG docker $USER
        say "Added current user to docker group. You may need to log out and back in."
    fi

    # Install NVIDIA Container Toolkit
    sudo apt-get install -y nvidia-container-toolkit
}

function check_running_containers() {
    if ! command -v docker &>/dev/null; then
        return
    }
    
    local running_containers=$(docker ps -q | wc -l)
    
    if [ "${running_containers}" -gt 0 ]; then
        say_error "Warning: ${running_containers} containers are currently running"
        echo -e "\nRunning containers:"
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Image}}"
        echo -ne "\n\t\e[31mContinue with Docker service restart? This will stop all containers [y/N]\e[0m "
        read -r answer
        echo -e "\n"
        if [[ ! "${answer}" =~ ^[Yy]$ ]]; then
            say "Aborting Docker service restart"
            exit 1
        fi
    fi
}

function configure-container-toolkit {
    say "Configuring container toolkit..."
    sudo nvidia-ctk runtime configure --runtime=docker
    
    check_running_containers
    
    say "Restarting Docker service..."
    sudo systemctl restart docker
}

function show-nvidia-info {
    say "NVIDIA driver info:"
    nvidia-smi --query-gpu=gpu_name,driver_version,temperature.gpu,power.draw,memory.used,memory.total --format=csv | column -t -s ,
    say "Container toolkit info:"
    nvidia-container-toolkit --version
    say "Docker runtime info:"
    docker info | grep -A 2 "Runtimes"
}

function backup_existing_config() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_dir="/root/nvidia_install_backup_${timestamp}"
    
    say "Creating backup of existing configuration..."
    sudo mkdir -p "${backup_dir}"
    
    if [ -f "/etc/docker/daemon.json" ]; then
        sudo cp "/etc/docker/daemon.json" "${backup_dir}/"
    fi
    
    if [ -d "/etc/nvidia" ]; then
        sudo cp -r "/etc/nvidia" "${backup_dir}/"
    fi
    
    say "Backup created at ${backup_dir}"
}

function cleanup() {
    local exit_code=$?
    if [ ${exit_code} -ne 0 ]; then
        say_error "Installation failed with exit code ${exit_code}"
        say "Checking for backup to restore..."
        local latest_backup=$(ls -td /root/nvidia_install_backup_* 2>/dev/null | head -1)
        if [ -n "${latest_backup}" ]; then
            say "Would you like to restore from backup at ${latest_backup}? [y/N]"
            read -r answer
            if [[ "${answer}" =~ ^[Yy]$ ]]; then
                say "Restoring from backup..."
                if [ -f "${latest_backup}/daemon.json" ]; then
                    sudo cp "${latest_backup}/daemon.json" "/etc/docker/"
                fi
                if [ -d "${latest_backup}/nvidia" ]; then
                    sudo cp -r "${latest_backup}/nvidia" "/etc/"
                fi
                say "Backup restored"
            fi
        fi
    fi
}

function main {
    say "Starting ${script_name} on ${hostname}..."
    pre-checks
    sudo -v -p "[sudo] I need root access to install packages: "
    
    check_nvidia_gpu_presence
    check_disk_space
    check_system_requirements
    backup_existing_config
    
    install_dependencies
    install-nvidia-driver
    install-container-toolkit
    configure-container-toolkit
    
    show-nvidia-info
    say "Finished ${script_name} on ${hostname}!"
}

trap cleanup EXIT

main "$@"
