#!/usr/bin/env bash
# This script installs NVIDIA drivers and container toolkit on RHEL 9.
# It should be safe to run it multiple times: steps are skipped when not needed.
# This is an interactive script: system and services restarts are prompted to the user.

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
    if ! grep -q "Red Hat Enterprise Linux" /etc/os-release; then
        say_error "This script is only meant to run on Red Hat Enterprise Linux"
        exit 1
    fi
}

function enable-epel {
    if rpm -q epel-release &>/dev/null; then
        say "EPEL is already installed; skipping..."
        return
    fi
    dnf makecache
    sudo subscription-manager repos --enable "codeready-builder-for-rhel-9-$(uname -i)-rpms"
    sudo dnf install -y "https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm"
}

function check-nvidia-installed {
    lspci | grep -i nvidia &>/dev/null && nvidia-smi &>/dev/null && lsmod | grep -i nvidia &>/dev/null
}

function check-cuda-installed {
    command -v nvcc &>/dev/null && command -v nvidia-smi &>/dev/null
}

function check-container-toolkit-installed {
    nvidia-container-toolkit --version &>/dev/null
}

function install-nvidia-driver {
    if check-nvidia-installed; then
        say "NVIDIA drivers are already installed; skipping..."
        return
    fi
    say "Installing NVIDIA drivers..."
    sudo dnf install -y kernel-devel-"$(uname -r)" kernel-headers-"$(uname -r)" gcc make dkms acpid libglvnd-glx libglvnd-opengl libglvnd-devel pkgconfig
    sudo dnf config-manager --add-repo "http://developer.download.nvidia.com/compute/cuda/repos/rhel9/$(uname -i)/cuda-rhel9.repo"
    sudo dnf module install -y nvidia-driver:open-dkms
    # or use a specific version:
    # sudo dnf module install -y nvidia-driver:560

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

function install-container-toolkit {
    if check-container-toolkit-installed; then
        say "Container toolkit is already installed; skipping..."
        return
    fi
    say "Installing container toolkit..."
    sudo dnf config-manager --add-repo "https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo"
    sudo dnf install -y nvidia-container-toolkit
}

function check_if_docker_configured {
    docker_daemon_json="/etc/docker/daemon.json"
    grep -q "nvidia" ${docker_daemon_json}
}

function configure-container-toolkit {
    if check_if_docker_configured; then
        say "Docker is already configured to use NVIDIA runtime; skipping..."
        return
    fi
    say "Configuring container toolkit..."
    sudo nvidia-ctk runtime configure --runtime=docker
    say "These are the active containers:"
    docker ps --all --format "table {{.Names}},{{.Image}},{{.Status}}" | column -t -s ,
    echo -ne "\n\t\e[31mDo you want to restart docker now? [y/N]\e[0m "
    read -r answer
    echo -e "\n"
    if [[ "${answer}" =~ ^[Yy]$ ]]; then
        sudo systemctl restart docker
    fi
}

function show-nvidia-info {
    say "NVIDIA driver info:"
    nvidia-smi --query-gpu=gpu_name,driver_version,temperature.gpu,power.draw,memory.used,memory.total --format=csv | column -t -s ,
    say "Container toolkit info:"
    nvidia-container-toolkit --version
    say "Docker runtime info:"
    docker info | grep --color=always -C 2 nvidia || say "No NVIDIA runtime detected in Docker. Maybe try restarting the service?"
}

function _uninstall-drivers {
    sudo dnf remove -y nvidia-driver
    sudo dnf module reset -y nvidia-driver
}

function main {
    say "Starting ${script_name} on ${hostname}..."
    pre-checks
    sudo -v -p "[sudo] I need root access to install packages: "
    enable-epel
    install-nvidia-driver
    install-container-toolkit
    configure-container-toolkit
    show-nvidia-info
    # Build and run the container
    echo -e "${GREEN}Building and starting the container...${NC}"
    docker compose up --build -d
    echo -e "${GREEN}Installation completed! Check the logs with: docker-compose logs${NC}"
    say "Finished ${script_name} on ${hostname}!"
}

main "$@"
