#!/usr/bin/env bash
# AI Declaration: This script skeleton was generated with AI assistance and must be reviewed by the team.
set -euo pipefail

kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/calico.yaml
kubectl -n kube-system rollout status ds/calico-node --timeout=240s
kubectl wait --for=condition=Ready node --all --timeout=300s
