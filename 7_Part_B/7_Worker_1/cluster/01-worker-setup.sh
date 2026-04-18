#!/bin/bash

# AI Declaration: This script skeleton was generated with AI assistance and must be reviewed by the team.
###############################################################################
# [WORKER-1] Kubernetes Worker Node Setup Script
# Machine: Worker-1 (Service A - Frontend runs here)
# Run: sudo bash 01-worker-setup.sh
###############################################################################
set -euo pipefail

echo "============================================="
echo "  WORKER-1: Kubernetes Node Setup"
echo "============================================="

# Set hostname
echo "[STEP 1] Setting hostname to worker-1..."
sudo hostnamectl set-hostname worker-1
echo "  ✓ Hostname set to worker-1"

# Disable swap
echo "[STEP 2] Disabling swap..."
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Kernel modules
echo "[STEP 3] Loading kernel modules..."
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
sudo modprobe overlay
sudo modprobe br_netfilter

# Sysctl
echo "[STEP 4] Setting sysctl parameters..."
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sudo sysctl --system

# Install containerd
echo "[STEP 5] Installing containerd..."
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

# Install Docker (for building images)
echo "[STEP 6] Installing Docker..."
sudo apt-get install -y docker-ce docker-ce-cli docker-buildx-plugin docker-compose-plugin || true
sudo usermod -aG docker ${SUDO_USER:-$USER} || true
sudo systemctl enable docker || true

# Install kubeadm, kubelet, kubectl
echo "[STEP 7] Installing Kubernetes tools..."
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg --yes
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update -y
sudo apt-mark unhold kubelet kubeadm kubectl || true
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
sudo systemctl enable kubelet

echo ""
echo "============================================="
echo "  ✓ Worker-1 setup complete!"
echo ""
echo "  NEXT: Run the join command from Master:"
echo "  sudo kubeadm join <MASTER_IP>:6443 --token <TOKEN> --discovery-token-ca-cert-hash sha256:<HASH>"
echo "============================================="
