#!/usr/bin/env bash
# AI Declaration: This script skeleton was generated with AI assistance and must be reviewed by the team.
set -euo pipefail

helm repo add cilium https://helm.cilium.io/
helm repo update

kubectl get ns kube-system >/dev/null

helm upgrade --install cilium cilium/cilium \
  --namespace kube-system \
  --create-namespace \
  --set kubeProxyReplacement=false \
  --set routingMode=tunnel

kubectl -n kube-system rollout status ds/cilium --timeout=300s
kubectl wait --for=condition=Ready node --all --timeout=300s
