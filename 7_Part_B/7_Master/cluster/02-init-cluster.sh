#!/bin/bash

# AI Declaration: This script skeleton was generated with AI assistance and must be reviewed by the team.
###############################################################################
# [MASTER] Initialize Kubernetes Cluster
# Run this AFTER 01-master-setup.sh completes
###############################################################################
set -euo pipefail

MASTER_IP="${1:-192.168.192.169}"

echo "============================================="
echo "  Initializing Kubernetes Cluster"
echo "  Master IP: $MASTER_IP"
echo "============================================="

# Reset any previous state
echo "[*] Resetting previous cluster state..."
sudo kubeadm reset -f 2>/dev/null || true
sudo rm -rf /etc/cni/net.d /var/lib/etcd
sudo iptables -F && sudo iptables -t nat -F && sudo iptables -t mangle -F

# Initialize
echo "[*] Running kubeadm init..."
sudo kubeadm init \
    --apiserver-advertise-address=$MASTER_IP \
    --pod-network-cidr=10.244.0.0/16

# Setup kubeconfig
echo "[*] Setting up kubeconfig..."
mkdir -p $HOME/.kube
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u $SUDO_USER):$(id -g $SUDO_USER) $HOME/.kube/config

echo ""
echo "============================================="
echo "  ✓ Cluster initialized!"
echo ""
echo "  IMPORTANT: Copy the 'kubeadm join' command"
echo "  shown above and run it on Worker-1 and Worker-2"
echo ""
echo "  NEXT: Install a CNI plugin (03/04/05 scripts)"
echo "============================================="
