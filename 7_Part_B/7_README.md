# AI Declaration: This script skeleton was generated with AI assistance and must be reviewed by the team.

# 🚀 Part B - Multi-Node Kubernetes CNI Performance Benchmark

## 📂 Folder Structure
```
Part_B/
├── Master/                    ← Run on MASTER system (192.168.192.169)
│   ├── cluster/
│   │   ├── 01-master-setup.sh      # Install prerequisites
│   │   ├── 02-init-cluster.sh      # Initialize K8s cluster
│   │   ├── 03-install-flannel.sh   # Install Flannel CNI
│   │   ├── 04-install-calico.sh    # Install Calico CNI
│   │   ├── 05-install-cilium.sh    # Install Cilium CNI
│   │   └── 06-reset-cluster.sh     # Reset before switching CNI
│   ├── k8s-manifests/
│   │   ├── 00-namespace.yaml
│   │   ├── 01-service-a.yaml       # Frontend → Worker-1
│   │   ├── 02-service-b.yaml       # API → Worker-2
│   │   └── 03-service-c.yaml       # Mock DB → Worker-2
│   ├── scripts/
│   │   ├── deploy.sh               # Label nodes + deploy services
│   │   ├── benchmark.sh            # Run CNI latency/throughput test
│   │   ├── verify-connectivity.sh  # Verify A→B→C chain
│   │   └── compare-results.py      # Compare CNI results
│   └── data/                        # Benchmark results stored here
│
├── Worker_1/                  ← Run on WORKER-1 system (192.168.192.166)
│   ├── cluster/
│   │   ├── 01-worker-setup.sh      # Install prerequisites + set hostname
│   │   └── 02-reset.sh             # Reset before switching CNI
│   └── scripts/
│       └── build-images.sh         # Build Docker images locally
│
├── Worker_2/                  ← Run on WORKER-2 system (192.168.192.170)
│   ├── cluster/
│   │   ├── 01-worker-setup.sh
│   │   └── 02-reset.sh
│   └── scripts/
│       └── build-images.sh
│
└── shared/                    ← Shared microservice code (used by all)
    └── microservices/
        ├── service-a/              # Frontend (Flask) - runs on Worker-1
        │   ├── app.py
        │   ├── Dockerfile
        │   └── requirements.txt
        ├── service-b/              # API (Flask) - runs on Worker-2
        │   ├── app.py
        │   ├── Dockerfile
        │   └── requirements.txt
        └── service-c/              # Mock DB (Flask) - runs on Worker-2
            ├── app.py
            ├── Dockerfile
            └── requirements.txt
```

## 🖥️ Architecture
```
                    Physical Network (192.168.192.x)
    ┌────────────────────┬──────────────────┬──────────────────┐
    │   MASTER (.169)    │  WORKER-1 (.166) │  WORKER-2 (.170) │
    │   Control Plane    │  Service A       │  Service B       │
    │   kubectl, API     │  (Frontend)      │  (API Layer)     │
    │   Scheduler        │  NodePort:30080  │  Service C       │
    │                    │                  │  (Mock Database) │
    └────────────────────┴──────────────────┴──────────────────┘

    Request Flow: Client → Service A (Worker-1) →[CNI]→ Service B (Worker-2) → Service C (Worker-2)
```

---

## 📋 STEP-BY-STEP EXECUTION GUIDE

### PHASE 1: Initial Setup (Run ONCE on each machine)

#### Step 1: Send Part_B folder to all 3 machines
```bash
# On Master, create zip:
cd /home/iiitd/GRS_PARTB/7_partA_cni_performance/
zip -r Part_B.zip Part_B/

# Send to Worker-1:
scp Part_B.zip iiitd@192.168.192.166:~/

# Send to Worker-2:
scp Part_B.zip iiitd@192.168.192.170:~/

# On each worker, unzip:
cd ~/ && unzip Part_B.zip
```

#### Step 2: [MASTER] Setup Prerequisites
```bash
cd ~/Part_B/Master/
sudo bash cluster/01-master-setup.sh
```

#### Step 3: [WORKER-1] Setup Prerequisites
```bash
cd ~/Part_B/Worker_1/
sudo bash cluster/01-worker-setup.sh
```

#### Step 4: [WORKER-2] Setup Prerequisites
```bash
cd ~/Part_B/Worker_2/
sudo bash cluster/01-worker-setup.sh
```

#### Step 5: [WORKER-1] Build Docker Images
```bash
cd ~/Part_B/Worker_1/
bash scripts/build-images.sh
```

#### Step 6: [WORKER-2] Build Docker Images
```bash
cd ~/Part_B/Worker_2/
bash scripts/build-images.sh
```

---

### PHASE 2: Cluster Formation + Flannel CNI Test

#### Step 7: [MASTER] Initialize Cluster
```bash
cd ~/Part_B/Master/
bash cluster/02-init-cluster.sh 192.168.192.169
# ⚠️ COPY the "kubeadm join ..." command from the output!
```

#### Step 8: [WORKER-1] Join Cluster
```bash
# Paste the join command from Step 7:
sudo kubeadm join 192.168.192.169:6443 --token <TOKEN> --discovery-token-ca-cert-hash sha256:<HASH>
```

#### Step 9: [WORKER-2] Join Cluster
```bash
# Paste the SAME join command from Step 7:
sudo kubeadm join 192.168.192.169:6443 --token <TOKEN> --discovery-token-ca-cert-hash sha256:<HASH>
```

#### Step 10: [MASTER] Verify Nodes
```bash
kubectl get nodes -o wide
# Expected: 3 nodes (1 control-plane, 2 workers) - Status may be NotReady until CNI is installed
```

#### Step 11: [MASTER] Install Flannel CNI
```bash
bash cluster/03-install-flannel.sh
# Wait ~30s, then:
kubectl get nodes
# All nodes should show "Ready"
```

#### Step 12: [MASTER] Deploy & Benchmark Flannel
```bash
# Deploy microservices (replace with your DockerHub username or use local images)
bash scripts/deploy.sh cniproject

# Verify connectivity
bash scripts/verify-connectivity.sh 192.168.192.166

# Run benchmark
bash scripts/benchmark.sh flannel 192.168.192.166 500
```

---

### PHASE 3: Switch to Calico CNI

#### Step 13: [ALL 3 MACHINES] Reset Cluster
```bash
# On MASTER:
bash cluster/06-reset-cluster.sh
# On WORKER-1:
bash cluster/02-reset.sh
# On WORKER-2:
bash cluster/02-reset.sh
```

#### Step 14: [MASTER] Re-init + Install Calico
```bash
bash cluster/02-init-cluster.sh 192.168.192.169
# ⚠️ COPY the new join command!
```

#### Step 15: [WORKER-1 & WORKER-2] Re-join
```bash
sudo kubeadm join 192.168.192.169:6443 --token <NEW_TOKEN> --discovery-token-ca-cert-hash sha256:<NEW_HASH>
```

#### Step 16: [MASTER] Install Calico + Deploy + Benchmark
```bash
bash cluster/04-install-calico.sh
bash scripts/deploy.sh cniproject
bash scripts/verify-connectivity.sh 192.168.192.166
bash scripts/benchmark.sh calico 192.168.192.166 500
```

---

### PHASE 4: Switch to Cilium CNI
*(Repeat the same Reset → Init → Join → Install → Deploy → Benchmark pattern)*

```bash
# Reset all 3 machines (Step 13)
# Re-init master (Step 14)
# Re-join workers (Step 15)

# [MASTER] Install Cilium + Deploy + Benchmark:
bash cluster/05-install-cilium.sh
bash scripts/deploy.sh cniproject
bash scripts/verify-connectivity.sh 192.168.192.166
bash scripts/benchmark.sh cilium 192.168.192.166 500
```

---

### PHASE 5: Compare Results

```bash
# [MASTER]
python3 scripts/compare-results.py
# Results are in Master/data/ folder
```

---

## 💡 Explanation

### Master vs Workers
- **Master**: Runs the Kubernetes API server, scheduler, and controller. Does NOT run application pods.
- **Worker-1**: Runs Service A (Frontend). Receives external traffic via NodePort 30080.
- **Worker-2**: Runs Service B (API) and Service C (Database). Handles internal cluster traffic.

### How CNI is Involved
When Service A (Worker-1) calls Service B (Worker-2):
1. The request leaves the pod via a virtual ethernet (veth) interface
2. The **CNI plugin** on Worker-1 encapsulates/routes the packet across the physical network
3. The **CNI plugin** on Worker-2 receives and delivers it to Service B's pod
4. **Flannel** uses VXLAN tunnels (simple, more overhead)
5. **Calico** uses BGP routing (native L3, less overhead)
6. **Cilium** uses eBPF in the kernel (fastest, most advanced)

### Verifying CNI Traffic
```bash
# On Worker-1, watch Flannel VXLAN traffic:
sudo tcpdump -i flannel.1

# On Worker-2, watch Calico traffic:
sudo tcpdump -i cali+

# While traffic flows, run from Master:
curl http://192.168.192.166:30080/
```
