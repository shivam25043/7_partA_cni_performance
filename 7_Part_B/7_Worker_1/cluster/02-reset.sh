#!/bin/bash

# AI Declaration: This script skeleton was generated with AI assistance and must be reviewed by the team.
###############################################################################
# [ALL NODES] Reset Cluster & Remove CNI
# Run this on MASTER, then on each WORKER before switching CNI
###############################################################################
set -euo pipefail

echo "============================================="
echo "  Resetting Kubernetes Cluster"
echo "============================================="

sudo kubeadm reset -f 2>/dev/null || true
sudo rm -rf /etc/cni/net.d /var/lib/etcd
sudo iptables -F
sudo iptables -t nat -F
sudo iptables -t mangle -F
sudo systemctl restart containerd
sudo systemctl restart kubelet

echo "  ✓ Node reset complete"
echo "  If this is MASTER: run 02-init-cluster.sh again"
echo "  If this is WORKER: wait for new join command from Master"
