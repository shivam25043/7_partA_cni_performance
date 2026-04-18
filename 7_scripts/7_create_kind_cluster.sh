#!/usr/bin/env bash
# AI Declaration: This script skeleton was generated with AI assistance and must be reviewed by the team.
set -euo pipefail

CLUSTER_NAME="cni-bench"
K8S_IMAGE="${K8S_IMAGE:-kindest/node:v1.30.8}"
KIND_BIN="${KIND_BIN:-$HOME/.local/bin/kind}"

if [[ ! -x "${KIND_BIN}" ]]; then
  KIND_BIN="kind"
fi

"${KIND_BIN}" delete cluster --name "${CLUSTER_NAME}" || true
"${KIND_BIN}" create cluster --name "${CLUSTER_NAME}" --config - <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
    image: ${K8S_IMAGE}
  - role: worker
    image: ${K8S_IMAGE}
  - role: worker
    image: ${K8S_IMAGE}
networking:
  disableDefaultCNI: true
EOF

kubectl get nodes -o wide
echo "Cluster created with default CNI disabled. Install one CNI plugin next."
