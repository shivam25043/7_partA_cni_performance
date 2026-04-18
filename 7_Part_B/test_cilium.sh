#!/bin/bash

# AI Declaration: This script skeleton was generated with AI assistance and must be reviewed by the team.
# ----------------------------------------------------
# test_cilium.sh - Redeploy the cluster with Cilium
# ----------------------------------------------------

echo "======================================"
echo "    Redeploying Cluster: CILIUM       "
echo "======================================"

cd "$(dirname "$0")/7_Master"

# 1. Reset Master Node entirely
echo "-> Resetting Master node..."
echo student | sudo -S -E ./cluster/06-reset-cluster.sh

# 2. Re-initialize Master 
echo "-> Initiating new Kubernetes cluster..."
echo student | sudo -S -E ./cluster/02-init-cluster.sh

# 3. Capture join token
JOIN_CMD=$(echo student | sudo -S kubeadm token create --print-join-command --kubeconfig=/etc/kubernetes/admin.conf)
echo "-> Captured Join Command: $JOIN_CMD"

# 4. Clean and Join Worker Nodes
# NOTE: Worker 1 is .170, Worker 2 is .166 based on your configuration
echo "-> Resetting and Joining Worker-1 (192.168.192.170)..."
ssh -o BatchMode=yes -o StrictHostKeyChecking=no iiitd@192.168.192.170 "echo student | sudo -S kubeadm reset -f; echo student | sudo -S ip link delete flannel.1 2>/dev/null; echo student | sudo -S ip link delete cni0 2>/dev/null; echo student | sudo -S ip link delete cilium_host 2>/dev/null; echo student | sudo -S $JOIN_CMD"

echo "-> Resetting and Joining Worker-2 (192.168.192.166)..."
ssh -o BatchMode=yes -o StrictHostKeyChecking=no iiitd@192.168.192.166 "echo student | sudo -S kubeadm reset -f; echo student | sudo -S ip link delete flannel.1 2>/dev/null; echo student | sudo -S ip link delete cni0 2>/dev/null; echo student | sudo -S ip link delete cilium_host 2>/dev/null; echo student | sudo -S $JOIN_CMD"

# 5. Label Nodes
echo "-> Labeling worker nodes..."
kubectl label node worker-1 node-role.kubernetes.io/worker=worker
kubectl label node worker-2 node-role.kubernetes.io/worker=worker

# 6. Install Cilium CNI
echo "-> Installing Cilium CNI..."
./cluster/05-install-cilium.sh

# 7. Wait for cluster state to stabilize
echo "-> Waiting 30s for CNI pods to stabilize..."
sleep 30

# 8. Deploy Distributed Application
echo "-> Deploying distributed application with Active CNI set to Cilium..."
sed -i 's/value: .* # REPLACE_CNI/value: Cilium # REPLACE_CNI/g' k8s-manifests/deploy-all.yaml
kubectl apply -f k8s-manifests/deploy-all.yaml

echo "======================================"
echo "    CILIUM Deployment Complete!       "
echo "    Verify pods: kubectl get pods -A  "
echo "======================================"
