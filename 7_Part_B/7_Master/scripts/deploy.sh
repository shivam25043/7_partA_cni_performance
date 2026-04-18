#!/bin/bash

# AI Declaration: This script skeleton was generated with AI assistance and must be reviewed by the team.
###############################################################################
# [MASTER] Label Nodes & Deploy Microservices
# Run AFTER workers have joined and CNI is installed
# Usage: bash deploy.sh <DOCKERHUB_USERNAME>
###############################################################################
set -euo pipefail

DOCKER_USER="${1:-cniproject}"

echo "============================================="
echo "  Deploying Microservices"
echo "============================================="

# Label nodes for pod placement
echo "[1] Labeling nodes..."
WORKER1=$(kubectl get nodes --no-headers | grep -v control-plane | awk 'NR==1{print $1}')
WORKER2=$(kubectl get nodes --no-headers | grep -v control-plane | awk 'NR==2{print $1}')

echo "  Worker-1: $WORKER1 → service-a"
echo "  Worker-2: $WORKER2 → service-b, service-c"

kubectl label node $WORKER1 service-placement=service-a --overwrite
kubectl label node $WORKER2 service-placement=service-b --overwrite
kubectl label node $WORKER2 service-placement=service-c --overwrite

# Update manifests with DockerHub username
echo "[2] Updating manifests with image: $DOCKER_USER"
MANIFEST_DIR="$(dirname $0)/../k8s-manifests"
sed -i "s|YOUR_DOCKERHUB_USERNAME|$DOCKER_USER|g" $MANIFEST_DIR/*.yaml

# Apply manifests
echo "[3] Applying Kubernetes manifests..."
kubectl apply -f $MANIFEST_DIR/00-namespace.yaml
kubectl apply -f $MANIFEST_DIR/01-service-a.yaml
kubectl apply -f $MANIFEST_DIR/02-service-b.yaml
kubectl apply -f $MANIFEST_DIR/03-service-c.yaml

echo "[4] Waiting for pods to be ready..."
kubectl wait --for=condition=ready pod -l app=service-a -n cni-benchmark --timeout=120s || true
kubectl wait --for=condition=ready pod -l app=service-b -n cni-benchmark --timeout=120s || true
kubectl wait --for=condition=ready pod -l app=service-c -n cni-benchmark --timeout=120s || true

echo ""
kubectl get pods -n cni-benchmark -o wide
kubectl get svc -n cni-benchmark

echo ""
echo "  ✓ Deployment complete!"
echo "  Access Service A at: http://<WORKER1_IP>:30080/"
