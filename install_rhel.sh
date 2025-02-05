#!/usr/bin/env bash

# ... (keep existing initial settings and functions)

function check_nvidia_gpu_presence() {
    say "Checking for NVIDIA GPU..."
    
    # Check if any NVIDIA GPU is detected by the system
    if ! lspci | grep -i "NVIDIA" &>/dev/null; then
        say_error "No NVIDIA GPU detected in the system. Installation cannot proceed."
        echo "PCI devices found:"
        lspci | grep -i "VGA"
        exit 1
    fi
    
    # Get detailed GPU information
    local gpu_count=$(lspci | grep -i "NVIDIA" | wc -l)
    say "Found ${gpu_count} NVIDIA GPU(s)"
    
    # Display detailed GPU information
    echo "GPU details:"
    lspci -nn | grep -i "NVIDIA" | while read -r line; do
        echo "  - $line"
    done
    
    # Check for specific GPU capabilities (optional)
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
    
    # Check PCIe link speed and width (optional but useful)
    echo -e "\nPCIe connection details:"
    lspci -vv | grep -A 8 -i "NVIDIA" | grep -i "LnkCap\|LnkSta" | while read -r line; do
        echo "  - $line"
    done
    
    say "NVIDIA GPU check completed successfully"
}

# Modify the main function to include the new GPU check
function main {
    say "Starting ${script_name} on ${hostname}..."
    pre-checks
    sudo -v -p "[sudo] I need root access to install packages: "
    
    # Add GPU check early in the process
    check_nvidia_gpu_presence
    
    # Existing checks
    check_disk_space
    check_system_requirements
    check_repository_availability
    check_kernel_headers
    backup_existing_config
    
    enable-epel
    install-nvidia-driver
    install-container-toolkit
    
    check_running_containers
    configure-container-toolkit
    
    show-nvidia-info
    say "Finished ${script_name} on ${hostname}!"
}

# ... (keep existing cleanup and trap functions)
