#!/bin/bash

# AI Declaration: This script skeleton was generated with AI assistance and must be reviewed by the team.
###############################################################################
# [MASTER] Install Flannel CNI
###############################################################################
echo "[*] Installing Flannel CNI..."
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
echo "[*] Waiting 30s for Flannel pods..."
sleep 30
kubectl get pods -n kube-flannel
kubectl get nodes
echo "  ✓ Flannel installed"
