# 7_step_by_step_plan

## Phase 1: Environment setup
1. Install Docker, `kubectl`, `kind`, `helm`, and `jq` on Linux host.
2. Verify tools:
   - `docker --version`
   - `kubectl version --client`
   - `kind version`
   - `helm version`
3. Keep one script owner and one observer during runs to avoid accidental config drift.

## Phase 2: Cluster bootstrap
1. Run `7_scripts/7_create_kind_cluster.sh`.
2. Confirm nodes are Ready using `kubectl get nodes -o wide`.
3. Apply baseline namespace and workloads only after CNI install.

### Fallback (if new cluster creation fails on host)
1. Reuse an existing healthy cluster context (example: `kind-latency-lab`).
2. Verify with:
   - `kubectl config use-context kind-latency-lab`
   - `kubectl get nodes -o wide`
3. Continue experiments with workload scripts and record that this is a reused testbed in report setup details.

## Phase 3: CNI-wise experiment loop
Repeat these steps for each plugin (Flannel, Calico, Cilium):
1. Fresh cluster (recommended) or fully cleaned previous setup.
2. Install CNI using corresponding script.
3. Deploy server/client manifests with fixed node placement scenario.
4. Run traffic benchmark script.
5. Collect metrics to CSV templates.
6. Record observations in report notes immediately.

## Phase 4: Placement scenarios
Run at least these scenarios for each CNI:
1. Client and server on same node (intra-node).
2. Client and server on different nodes (inter-node).
3. Increased load (higher concurrency) to observe scaling behavior.

## Phase 5: Analysis and plotting
1. Fill CSV result files in `7_data/`.
2. Copy final numeric points into hardcoded arrays in `7_plots/*.py`.
3. Run each plot script to generate PNGs for report inclusion.

## Phase 6: Part A write-up
1. Use `7_docs/7_partA_report_template.md` as structure.
2. Replace template text with your final, team-authored content.
3. Add plots and discussion in Evaluation section.
4. Export final report to `7_report.pdf` (or required final filename with `7_` prefix).

## Phase 7: Final packaging
1. Ensure all files start with `7_`.
2. Keep folder clean (no binary executables, no junk files).
3. Create archive: `7_partA_cni_performance.zip`.
4. Push same project folder contents to GitHub repository.
5. Single designated member submits ZIP.

## Phase 8: Part B Multi-Node Transition
1. Shift from single-node KinD to distributed microservices.
2. Implement Python-based orchestration (`7_run.py`).
3. Setup SSH-based worker deployment (using `pexpect` for password/key handling).
4. Run cross-system benchmarks and aggregate results in `7_data/7_results_partB.csv`.
