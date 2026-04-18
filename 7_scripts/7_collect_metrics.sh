#!/usr/bin/env bash
# AI Declaration: This script skeleton was generated with AI assistance and must be reviewed by the team.
set -euo pipefail

mkdir -p 7_data/raw

kubectl top nodes > 7_data/raw/7_node_top_snapshot.txt || true
kubectl -n kube-system get pods -o wide > 7_data/raw/7_kubesystem_pods.txt
kubectl -n cni-bench get pods -o wide > 7_data/raw/7_bench_pods.txt

echo "Metric snapshots collected in 7_data/raw"
