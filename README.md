# **GPU-Accelerated AI with Docker – Complete Guide**

## **Introduction**
This repository provides a comprehensive guide on setting up NVIDIA GPU acceleration for AI workloads using Docker. It covers the advantages of using GPUs for AI, manual installation steps for both Debian-based and RHEL 9 systems, and automated installation scripts for ease of use.

## **Why Use NVIDIA GPUs for AI?**
- **High Performance:** Parallel processing enables faster AI model training and inference.
- **Optimized for AI Workloads:** CUDA and cuDNN support deep learning frameworks like TensorFlow and PyTorch.
- **Cost-Efficient:** Reduces computational time, optimizing resource usage.

## **Why Use Docker for AI?**
- **Portability:** Ensures AI applications run consistently across different environments.
- **Scalability:** Easily scale workloads using Kubernetes and cloud platforms.
- **Isolation:** Prevents dependency conflicts between different projects.

## **Installation Guide**
### **Manual Installation (Debian-Based Systems)**
#### **1. System Preparation**
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y build-essential linux-headers-$(uname -r) pkg-config dkms curl gnupg software-properties-common apt-transport-https ca-certificates
```
#### **2. Install NVIDIA Drivers**
```bash
sudo apt install -y nvidia-driver
reboot
```
#### **3. Install Docker**
```bash
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
newgrp docker
```
#### **4. Install NVIDIA Container Toolkit**
```bash
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://nvidia.github.io/libnvidia-container/stable/deb/ $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
sudo apt update && sudo apt install -y nvidia-container-toolkit
sudo systemctl restart docker
```

### **Manual Installation (RHEL 9-Based Systems)**
#### **1. System Preparation**
```bash
sudo dnf install -y epel-release
sudo dnf config-manager --set-enabled crb
sudo dnf install -y dkms kernel-devel-$(uname -r) kernel-headers-$(uname -r) gcc make curl
```
#### **2. Install NVIDIA Drivers**
```bash
sudo dnf install -y nvidia-driver
reboot
```
#### **3. Install Docker**
```bash
sudo dnf install -y dnf-plugins-core
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo dnf install -y docker-ce docker-ce-cli containerd.io
dsudo systemctl enable --now docker
sudo usermod -aG docker $USER
newgrp docker
```
#### **4. Install NVIDIA Container Toolkit**
```bash
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
echo "[nvidia-container-toolkit]\nname=NVIDIA Container Toolkit\nbaseurl=https://nvidia.github.io/libnvidia-container/stable/rpm/\$basearch\nenabled=1\ngpgcheck=1\ngpgkey=https://nvidia.github.io/libnvidia-container/gpgkey" | sudo tee /etc/yum.repos.d/nvidia-container-toolkit.repo
sudo dnf install -y nvidia-container-toolkit
sudo systemctl restart docker
```

## **Using the Installation Script**
For an automated setup, use the provided installation script:
```bash
chmod +x install_nvidia_docker.sh
sudo ./install_nvidia_docker.sh
```

## **Validating Installation**
After installation, check if NVIDIA GPU is available inside Docker:
```bash
docker run --rm --gpus all nvidia/cuda:11.0-base nvidia-smi
```
Expected output should display GPU details.

## **Advantages of This Implementation**
- **Boosts AI Performance:** Up to 10x faster than CPU-based execution.
- **Seamless Deployment:** Containers ensure consistency across environments.
- **Optimized Resource Utilization:** Maximizes the use of available hardware.

## **Next Steps**
- Deploy AI models in GPU-accelerated Docker containers.
- Benchmark performance improvements.
- Scale using Kubernetes and cloud services.

**Let's accelerate AI development with NVIDIA GPUs and Docker!**

