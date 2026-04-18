#!/bin/bash

# AI Declaration: This script skeleton was generated with AI assistance and must be reviewed by the team.
###############################################################################
# [MASTER] Install Calico CNI
###############################################################################
echo "[*] Installing Calico CNI..."
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.3/manifests/tigera-operator.yaml
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.3/manifests/custom-resources.yaml
echo "[*] Waiting 60s for Calico pods..."
sleep 60
kubectl get pods -n calico-system
kubectl get nodes
echo "  ✓ Calico installed"
