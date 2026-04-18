# AI Declaration: This script skeleton was generated with AI assistance and must be reviewed by the team.

# CNI Benchmarking - Switch and Redeploy Commands

Follow these steps one by one to safely tear down the current network and applications, switch your CNI, and redeploy everything so your backend correctly tracks the performance metrics.

## Step 1: Tear Down Current Applications
First, remove the current frontend and backend to avoid orphaned pods while the network is changing.
```bash
cd "/home/iiitd/FILE (Copy)/7_partA_cni_performance/Part_B/Master"
kubectl delete -f k8s-manifests/deploy-all.yaml
```

## Step 2: Remove the Existing CNI
Run the command corresponding to the CNI you **currently** have installed:

**If moving away from Flannel:**
```bash
kubectl delete -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
```

**If moving away from Calico:**
```bash
kubectl delete -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.3/manifests/custom-resources.yaml
kubectl delete -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.3/manifests/tigera-operator.yaml
```

**If moving away from Cilium:**
```bash
cilium uninstall
```
*(Wait a few seconds for the networking pods to terminate completely before moving to the next step).*

## Step 3: Install the New CNI
Use your provided shell scripts to install the new CNI:

**To install Flannel:**
```bash
bash cluster/03-install-flannel.sh
```

**To install Calico:**
```bash
bash cluster/04-install-calico.sh
```

**To install Cilium:**
```bash
bash cluster/05-install-cilium.sh
```

## Step 4: Update the `ACTIVE_CNI` Environment Variable (Important)
You need to tell the backend which CNI is running so it records the benchmark data under the correct CNI in the leaderboard.

```bash
# If you just installed Flannel:
sed -i 's/value: .* # REPLACE_CNI/value: Flannel # REPLACE_CNI/g' k8s-manifests/deploy-all.yaml

# If you just installed Calico:
sed -i 's/value: .* # REPLACE_CNI/value: Calico # REPLACE_CNI/g' k8s-manifests/deploy-all.yaml

# If you just installed Cilium:
sed -i 's/value: .* # REPLACE_CNI/value: Cilium # REPLACE_CNI/g' k8s-manifests/deploy-all.yaml
```
*(Note: If you are doing this manually without sed, just open `deploy-all.yaml`, go to line 377 under `ACTIVE_CNI`, and change its value to "Flannel", "Calico", or "Cilium")*

## Step 5: Redeploy Frontend and Backend
Once the new CNI is fully online, redeploy your applications:
```bash
kubectl apply -f k8s-manifests/deploy-all.yaml
```

Check to make sure all pods are in the `Running` state:
```bash
kubectl get pods -n cni-benchmark -o wide
```
