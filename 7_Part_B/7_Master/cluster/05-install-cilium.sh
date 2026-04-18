#!/bin/bash

# AI Declaration: This script skeleton was generated with AI assistance and must be reviewed by the team.
###############################################################################
# [MASTER] Install Cilium CNI
###############################################################################
echo "[*] Installing Cilium CLI..."
CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-amd64.tar.gz
sudo tar xzvfC cilium-linux-amd64.tar.gz /usr/local/bin
rm cilium-linux-amd64.tar.gz

echo "[*] Installing Cilium..."
cilium install
echo "[*] Waiting 60s for Cilium pods..."
sleep 60
cilium status
kubectl get nodes
echo "  ✓ Cilium installed"
