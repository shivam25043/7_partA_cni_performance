# AI Declaration: This script skeleton was generated with AI assistance and must be reviewed by the team.

# Distributed Chat Ledger - CNI Benchmarking Deployment Guide

This document outlines the step-by-step procedure to test and safely deploy the Distributed Chat Ledger (Frontend on Worker-1, Database Backend on Worker-2) under different Kubernetes CNI plugins.

## 1. Automated Testing Scripts

We have created three convenient automated scripts in the `7_Part_B` directory that handle the full cluster lifecycle (teardown, setup, node joining, CNI installation, and application deployment) for you.

Before running them, make sure they are executable:
```bash
chmod +x test_flannel.sh test_calico.sh test_cilium.sh
```

### Running the Tests

> [!WARNING]
> Do NOT use `sudo ./test_*.sh` to run these scripts!
> The scripts handle `sudo` internally. Running the outer script with `sudo` will force SSH commands to run as the `root` user, which does not have the pre-configured SSH keys for connecting to the worker nodes, resulting in "Permission denied" errors.

To fully tear down the cluster, reinstall a specific CNI, and immediately deploy the Chat Ledger application, simply execute one of the scripts below as your normal user (`iiitd`) from the master node.

#### Test Flannel
```bash
./test_flannel.sh
```

#### Test Calico
```bash
./test_calico.sh
```

#### Test Cilium
```bash
./test_cilium.sh
```

### Accessing the Application

Once any of the test scripts successfully complete, the "Distributed Chat Ledger" application will be up and running. 

You can access the interfaces from your browser at:
- **Frontend Console** (Worker-1): `http://192.168.192.170:30080`
- **Backend Dashboard** (Worker-2): `http://192.168.192.166:30081`

---

## 2. Step-by-Step Manual Deployment Guide

If you prefer to perform the steps manually (or need to debug a failure), follow these steps in order from the Master Node (192.168.192.169).

### Step 2.1: Master Node Reset & Initialize
```bash
cd /home/iiitd/Downloads/G_7_Part_B_CNIPerformance/7_partA_cni_performance/7_Part_B/7_Master

# Reset the broken/old cluster state
sudo ./cluster/06-reset-cluster.sh

# Spin up a fresh Kubernetes API
sudo ./cluster/02-init-cluster.sh

# Grab the join string (starts with "kubeadm join ...")
kubeadm token create --print-join-command
```

### Step 2.2: Reset and Join Worker Nodes
Instead of logging into Worker 1 and Worker 2 manually, you can execute commands securely via SSH from the Master node. 

> [!WARNING]
> Stale Network Interfaces: When switching between Flannel, Calico, and Cilium, you **must** manually delete their old host network interfaces (`flannel.1`, `cni0`, `cilium_host`), otherwise the new CNI will crash stating "address already in use".

**Worker 1 (192.168.192.170):**
```bash
ssh -o StrictHostKeyChecking=no iiitd@192.168.192.170 \
  "echo student | sudo -S kubeadm reset -f; \
   echo student | sudo -S ip link delete flannel.1 2>/dev/null; \
   echo student | sudo -S ip link delete cni0 2>/dev/null; \
   echo student | sudo -S ip link delete cilium_host 2>/dev/null; \
   echo student | sudo -S <INSERT_KUBEADM_JOIN_COMMAND_HERE>"
```

**Worker 2 (192.168.192.166):**
```bash
ssh -o StrictHostKeyChecking=no iiitd@192.168.192.166 \
  "echo student | sudo -S kubeadm reset -f; \
   echo student | sudo -S ip link delete flannel.1 2>/dev/null; \
   echo student | sudo -S ip link delete cni0 2>/dev/null; \
   echo student | sudo -S ip link delete cilium_host 2>/dev/null; \
   echo student | sudo -S <INSERT_KUBEADM_JOIN_COMMAND_HERE>"
```

### Step 2.3: Label the Nodes
Our frontend specifically looks for `worker-1` and backend looks for `worker-2`. Re-apply their roles:
```bash
kubectl label node worker-1 node-role.kubernetes.io/worker=worker
kubectl label node worker-2 node-role.kubernetes.io/worker=worker
```

### Step 2.4: Install ONE Networking Plugin (CNI)
Only install **one** CNI. Never install multiple CNIs simultaneously on a fresh cluster.
```bash
# Pick exactly one:
./cluster/03-install-flannel.sh
# OR
./cluster/04-install-calico.sh
# OR
./cluster/05-install-cilium.sh
```

### Step 2.5: Deploy the Application
We have consolidated the entire Distributed Chat Ledger architecture into `deploy-all.yaml`. 
```bash
# Make sure to update the ACTIVE_CNI variable manually inside the file so the dashboard displays it accurately!
nano k8s-manifests/deploy-all.yaml

# Deploy the application
kubectl apply -f k8s-manifests/deploy-all.yaml
```

Wait ~1 minute and run `kubectl get pods -A` to verify all components reach the `Running` state. Access your frontend on Worker-1 at `http://192.168.192.170:30080`.
