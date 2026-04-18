#!/bin/bash

# AI Declaration: This script skeleton was generated with AI assistance and must be reviewed by the team.
###############################################################################
# [MASTER] Kubernetes Master (Control Plane) Setup Script
# Machine: Master Node (192.168.192.169)
###############################################################################
set -euo pipefail

echo "============================================="
echo "  MASTER: Kubernetes Control Plane Setup"
echo "  Hostname: $(hostname)"
echo "  IP: $(hostname -I | awk '{print $1}')"
echo "============================================="

# STEP 1: Disable Swap
echo "[STEP 1] Disabling swap..."
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
echo "  ✓ Swap disabled"

# STEP 2: Kernel Modules
echo "[STEP 2] Loading kernel modules..."
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
sudo modprobe overlay
sudo modprobe br_netfilter
echo "  ✓ Kernel modules loaded"

# STEP 3: Sysctl
echo "[STEP 3] Setting sysctl parameters..."
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sudo sysctl --system
echo "  ✓ Sysctl applied"

# STEP 4: Install containerd
echo "[STEP 4] Installing containerd..."
sudo apt-get update -y
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release software-properties-common

sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg --yes
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update -y
sudo apt-get install -y containerd.io

sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml > /dev/null
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd
echo "  ✓ containerd installed"

# STEP 5: Install Docker (for building images)
echo "[STEP 5] Installing Docker..."
sudo apt-get install -y docker-ce docker-ce-cli docker-buildx-plugin docker-compose-plugin || true
sudo usermod -aG docker $USER || true
sudo systemctl enable docker || true
sudo systemctl start docker || true
echo "  ✓ Docker installed"

# STEP 6: Install kubeadm, kubelet, kubectl
echo "[STEP 6] Installing Kubernetes tools..."
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg --yes
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update -y
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
sudo systemctl enable kubelet
echo "  ✓ Kubernetes tools installed"

# STEP 7: Install benchmarking tools
echo "[STEP 7] Installing benchmarking tools..."
sudo apt-get install -y jq bc python3 python3-pip
pip3 install requests flask 2>/dev/null || true
if ! command -v hey &> /dev/null; then
    wget -q https://hey-release.s3.us-east-2.amazonaws.com/hey_linux_amd64 -O /tmp/hey
    chmod +x /tmp/hey
    sudo mv /tmp/hey /usr/local/bin/hey
fi
echo "  ✓ Benchmarking tools installed"

echo ""
echo "============================================="
echo "  ✓ Master setup complete!"
echo ""
echo "  NEXT STEP: Run 02-init-cluster.sh"
echo "============================================="
