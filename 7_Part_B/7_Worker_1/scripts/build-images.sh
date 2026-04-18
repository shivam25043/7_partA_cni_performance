#!/bin/bash

# AI Declaration: This script skeleton was generated with AI assistance and must be reviewed by the team.
###############################################################################
# [WORKER] Build Docker images and load into containerd
# Run this on any worker that needs images locally
# Usage: bash build-images.sh
###############################################################################
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MICRO_DIR="$SCRIPT_DIR/../../shared/microservices"

echo "============================================="
echo "  Building Docker Images"
echo "============================================="

for SVC in service-a service-b service-c; do
    echo "[*] Building $SVC..."
    docker build -t $SVC:latest $MICRO_DIR/$SVC/
    echo "  ✓ $SVC built"
done

echo ""
echo "[*] Saving images to tar files..."
for SVC in service-a service-b service-c; do
    docker save $SVC:latest | sudo ctr -n k8s.io images import -
    echo "  ✓ $SVC loaded into containerd"
done

echo ""
echo "============================================="
echo "  ✓ All images built and loaded!"
echo "============================================="
