#!/usr/bin/env bash
# This script installs NVIDIA drivers and container toolkit on RHEL-based systems.
# Compatible with RHEL, CentOS, Rocky Linux, AlmaLinux, and Fedora.

set -euo pipefail

script_name=$(basename "$0")
prefix="[${script_name}]"
hostname=$(hostname)

# Color codes
GREEN='\e[32m'
BLUE='\e[34m'
RED='\e[31m'
NC='\e[0m' # No Color

function say {
    echo -e "${BLUE}${prefix} $(date +'%H:%M:%S')${NC}: $*"
}

function say_error {
    echo -e "${RED}${prefix} $(date +'%H:%M:%S')${NC}: $*" >&2
}

function say_success {
    echo -e "${GREEN}${prefix} $(date +'%H:%M:%S')${NC}: $*"
}

function pre_checks {
    if ! grep -qiE 'rhel|centos|rocky|almalinux|fedora' /etc/os-release; then
        say_error "This script is only meant to run on RHEL-based systems"
        exit 1
    fi
}

function check_nvidia_gpu_presence() {
    say "Checking for NVIDIA GPU..."
    
    if ! lspci | grep -i "NVIDIA" &>/dev/null; then
        say_error "No NVIDIA GPU detected in the system. Installation cannot proceed."
        exit 1
    fi
    
    local gpu_count=$(lspci | grep -i "NVIDIA" | wc -l)
    say "Found ${gpu_count} NVIDIA GPU(s)"
}

function install_dependencies() {
    say "Installing required dependencies..."
    sudo dnf install -y epel-release
    sudo dnf install -y kernel-devel kernel-headers gcc make dkms pciutils curl gnupg2
}

function install_nvidia_driver {
    if command -v nvidia-smi &>/dev/null; then
        say "NVIDIA drivers are already installed; skipping..."
        return
    fi

    say "Installing NVIDIA drivers..."
    
    sudo dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/rhel$(rpm -E %rhel)/x86_64/cuda-rhel$(rpm -E %rhel).repo
    sudo dnf clean all
    sudo dnf install -y nvidia-driver nvidia-settings nvidia-modprobe
    
    say "A reboot is required to load the NVIDIA drivers."
    echo -ne "\n\t${RED}Reboot now to load the NVIDIA drivers? [y/N]${NC} "
    read -r answer
    echo -e "\n"
    if [[ "${answer}" =~ ^[Yy]$ ]]; then
        say "Run this script again after the reboot to continue the installation."
        sleep 2
        sudo reboot
    fi
}

function install_container_toolkit {
    if command -v nvidia-container-toolkit &>/dev/null; then
        say "Container toolkit is already installed; skipping..."
        return
    fi
    
    say "Installing container toolkit..."
    
    sudo dnf install -y dnf-plugins-core
    sudo dnf config-manager --add-repo https://nvidia.github.io/libnvidia-container/rhel$(rpm -E %rhel)/libnvidia-container.repo
    sudo dnf install -y nvidia-container-toolkit
}

function configure_container_toolkit {
    say "Configuring container toolkit..."
    sudo nvidia-ctk runtime configure --runtime=docker
    say "Restarting Docker service..."
    sudo systemctl restart docker
}

function main {
    say "Starting ${script_name} on ${hostname}..."
    pre_checks
    sudo -v -p "[sudo] I need root access to install packages: "
    
    check_nvidia_gpu_presence
    install_dependencies
    install_nvidia_driver
    install_container_toolkit
    configure_container_toolkit
    
    say_success "Finished ${script_name} on ${hostname}!"
}

main "$@"
