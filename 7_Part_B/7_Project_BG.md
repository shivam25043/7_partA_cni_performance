# AI Declaration: This script skeleton was generated with AI assistance and must be reviewed by the team.

# Distributed CNI Benchmark (Flannel, Calico, Cilium)
**Final Project Execution Walkthrough**

This document provides the exact end-to-end commands required to initialize your physical Kubernetes cluster, link the Worker nodes, and cycle through the Flannel, Calico, and Cilium Networking Interfaces to populate the Persistent Storage Leaderboard.

---

## Phase 1: Cluster & Node Initialization
*Run these commands to provision the base Kubernetes software on all physical machines. Do not run any CNI scripts yet.*

### 1A. On Master Node (192.168.192.169)
```bash
cd ~/GRS_PARTB/7_partA_cni_performance/Part_B/Master
sudo ./cluster/01-master-setup.sh
sudo ./cluster/02-init-cluster.sh
```
*(Save the `kubeadm join` command that gets printed at the end of `02-init-cluster.sh`)*

### 1B. On Worker-1 Node (192.168.192.170)
```bash
cd ~/GRS_PARTB/7_partA_cni_performance/Part_B/Worker_1
sudo ./cluster/01-worker-setup.sh

# Now paste the join command from Master:
sudo kubeadm join 192.168.192.169:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash>
```

### 1C. On Worker-2 Node (192.168.192.166)
```bash
cd ~/GRS_PARTB/7_partA_cni_performance/Part_B/Worker_2
sudo ./cluster/01-worker-setup.sh

# Now paste the join command from Master:
sudo kubeadm join 192.168.192.169:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash>
```

---

## Phase 2: Evaluating Flannel CNI
*Now we deploy the application over Flannel and gather our baseline metrics.*

**On the Master Node:**
```bash
cd ~/GRS_PARTB/7_partA_cni_performance/Part_B/Master

# 1. Install Flannel core networking
./cluster/03-install-flannel.sh

# 2. Tell Kubernetes where your workers are
kubectl label node worker-1 node-role.kubernetes.io/worker=worker
kubectl label node worker-2 node-role.kubernetes.io/worker=worker

# 3. Open deploy-all.yaml and verify the environment variable says Flannel
# (Check line ~430) -> - name: ACTIVE_CNI \n value: "Flannel"

# 4. Deploy the Benchmark Architecture
kubectl apply -f k8s-manifests/deploy-all.yaml
```

**The Live Demo Execution (Flannel):**
1. Open the Backend Ledger (Worker-2): `http://192.168.192.166:30081/`
2. Open the Sender Client (Worker-1): `http://192.168.192.166:30080/`
3. Click your **Demo Macro Buttons (Burst/Video Stress)** or the **Interactive Game** to simulate load.
4. Watch the Dashboard lock in Flannel's Latency and Throughput stats.

---

## Phase 3: Evaluating Calico CNI
*We tear down Flannel, spin up Calico, and let the dashboard compare them side by side.*

**On the Master Node:**
```bash
# 1. Wipe the current cluster networking and pods
./cluster/06-reset-cluster.sh

# 2. Open deploy-all.yaml. Change the ACTIVE_CNI variable from Flannel to Calico!
sed -i 's/value: "Flannel"/value: "Calico"/g' k8s-manifests/deploy-all.yaml

# 3. Install Calico core networking
./cluster/04-install-calico.sh

# 4. Re-label nodes (since reset script wiped them)
kubectl label node worker-1 node-role.kubernetes.io/worker=worker
kubectl label node worker-2 node-role.kubernetes.io/worker=worker

# 5. Bring the Benchmark architecture back online
kubectl apply -f k8s-manifests/deploy-all.yaml
```

**The Live Demo Execution (Calico):**
1. Refresh the Frontend and Backend browser tabs.
2. Because of the `hostPath` drive on Worker-2, **Flannel's old High Score is still locked into the Dashboard leaderboard!**
3. Simulate load using your frontend Macros again. The dashboard will populate Calico's analytics right next to Flannel's for a live comparison!

---

## Phase 4: Evaluating Cilium CNI (The Finale)
*Finally, we swap to Cilium to complete the 3-way leaderboard.*

**On the Master Node:**
```bash
# 1. Wipe the Calico architecture
./cluster/06-reset-cluster.sh

# 2. Open deploy-all.yaml. Change the ACTIVE_CNI variable to Cilium!
sed -i 's/value: "Calico"/value: "Cilium"/g' k8s-manifests/deploy-all.yaml

# 3. Install Cilium core networking
./cluster/05-install-cilium.sh

# 4. Re-label nodes
kubectl label node worker-1 node-role.kubernetes.io/worker=worker
kubectl label node worker-2 node-role.kubernetes.io/worker=worker

# 5. Bring the Benchmark architecture back online
kubectl apply -f k8s-manifests/deploy-all.yaml
```

**The Final Reveal:**
1. Refresh the browser tabs one last time. 
2. The leaderboard displays Flannel and Calico's preserved data. 
3. Run your Demo Macros. Cilium's stats will drop into the final slot, completing your **Persistent Comparative CNI Presentation!**
