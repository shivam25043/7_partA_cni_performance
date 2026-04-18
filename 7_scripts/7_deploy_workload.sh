#!/usr/bin/env bash
# AI Declaration: This script skeleton was generated with AI assistance and must be reviewed by the team.
set -euo pipefail

PLACEMENT="${1:-inter-node}"

mapfile -t WORKER_NODES < <(kubectl get nodes -l '!node-role.kubernetes.io/control-plane' -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}')

if [[ "${#WORKER_NODES[@]}" -lt 1 ]]; then
	echo "No worker nodes found."
	exit 1
fi

SERVER_NODE="${WORKER_NODES[0]}"
CLIENT_NODE="${WORKER_NODES[0]}"

if [[ "${PLACEMENT}" == "inter-node" ]]; then
	if [[ "${#WORKER_NODES[@]}" -lt 2 ]]; then
		echo "Need at least 2 worker nodes for inter-node placement."
		exit 1
	fi
	CLIENT_NODE="${WORKER_NODES[1]}"
fi

kubectl apply -f 7_configs/7_namespace.yaml
kubectl apply -f 7_configs/7_server_deployment.yaml
kubectl apply -f 7_configs/7_server_service.yaml
kubectl apply -f 7_configs/7_client_deployment.yaml

kubectl -n cni-bench patch deployment http-echo-server --type='merge' -p "{\"spec\":{\"template\":{\"spec\":{\"nodeSelector\":{\"kubernetes.io/hostname\":\"${SERVER_NODE}\"}}}}}"
kubectl -n cni-bench patch deployment curl-client --type='merge' -p "{\"spec\":{\"template\":{\"spec\":{\"nodeSelector\":{\"kubernetes.io/hostname\":\"${CLIENT_NODE}\"}}}}}"

kubectl -n cni-bench rollout status deploy/http-echo-server --timeout=180s
kubectl -n cni-bench rollout status deploy/curl-client --timeout=180s

echo "Placement mode: ${PLACEMENT}"
echo "Server node: ${SERVER_NODE}"
echo "Client node: ${CLIENT_NODE}"
kubectl -n cni-bench get pods -o wide
