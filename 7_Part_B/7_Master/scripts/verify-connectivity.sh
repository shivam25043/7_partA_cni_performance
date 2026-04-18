#!/bin/bash

# AI Declaration: This script skeleton was generated with AI assistance and must be reviewed by the team.
###############################################################################
# [WORKER-1] Verify Cluster Connectivity
# Verifies pod placement, service connectivity, and NodePort access.
###############################################################################
set -euo pipefail

WORKER1_IP="${1:-192.168.192.170}"
NODEPORT="30080"

echo "============================================="
echo "  Cluster Connectivity Verification"
echo "============================================="

echo ""
echo "[1] Pod Placement (kubectl get pods -o wide):"
kubectl get pods -n cni-benchmark -o wide

echo ""
echo "[2] Service List:"
kubectl get svc -n cni-benchmark

echo ""
echo "[3] Node Labels:"
kubectl get nodes --show-labels | grep -E "service-placement|NAME"

echo ""
echo "[4] Health checks via exec into service-a pod..."
SA_POD=$(kubectl get pod -n cni-benchmark -l app=service-a -o jsonpath='{.items[0].metadata.name}')
echo "  Service A pod: $SA_POD"

echo ""
echo "  Testing A→B connectivity:"
kubectl exec -n cni-benchmark $SA_POD -- \
    curl -s http://service-b.cni-benchmark.svc.cluster.local:5001/health | python3 -m json.tool || true

echo ""
echo "  Testing A→B→C chain:"
kubectl exec -n cni-benchmark $SA_POD -- \
    curl -s http://service-b.cni-benchmark.svc.cluster.local:5001/process | python3 -m json.tool || true

echo ""
echo "[5] External NodePort access:"
echo "  Calling http://$WORKER1_IP:$NODEPORT/"
curl -s "http://$WORKER1_IP:$NODEPORT/" | python3 -m json.tool || echo "  NodePort call failed!"

echo ""
echo "[6] Benchmark endpoint (5 requests):"
curl -s "http://$WORKER1_IP:$NODEPORT/benchmark?n=5" | python3 -m json.tool || true

echo ""
echo "============================================="
echo "  ✓ Verification complete!"
echo "============================================="
