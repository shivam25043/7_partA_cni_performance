#!/usr/bin/env bash
# AI Declaration: This script skeleton was generated with AI assistance and must be reviewed by the team.
set -euo pipefail

kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml
kubectl -n kube-flannel rollout status ds/kube-flannel-ds --timeout=180s
kubectl wait --for=condition=Ready node --all --timeout=240s
