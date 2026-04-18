# Group 7 Project Workspace

## Project Title
Performance Comparison of Kubernetes CNI Plugins: Architectural Impacts on Microservice Communication

## Team Members
- Suman Moond (MT25047) - suman25047@iiitd.ac.in
- Jatin Aggarwal (MT25027) - jatin25027@iiitd.ac.in
- Shivam Minde (MT25043) - shivam25043@iiitd.ac.in
- Jalakam Chandra Harsha (MT25022) - chandra25022@iiitd.ac.in

## Folder Layout
- `7_docs/` - report template, submission checklist, execution plan
- `7_scripts/` - setup and benchmark automation scripts
- `7_configs/` - Kubernetes manifests used in experiments
- `7_data/` - raw and aggregated CSV results
- `7_plots/` - matplotlib `.py` files with hardcoded values
- `7_run.py` - Part B master-worker orchestrator
- `7_master.py` - Part B local metrics server
- `7_worker.py` - Part B remote benchmark client

## Naming Convention Used
All files are prefixed with `7_` to satisfy group-ID naming rules.

## Suggested ZIP Name
`7_partA_cni_performance.zip`

## GitHub Repository Name (suggested)
`7_partA_cni_performance`

## Part B: Multi-Node Orchestration
The project has been evolved to support cross-system benchmarking:
- **Master Server**: Started locally via `7_run.py`, listens for metrics and logs to `7_data/7_results_partB.csv`.
- **Worker Client**: Deployed remotely via SSH/SCP, measures latency and reports back to the master.
- **Orchestration**: Run `python3 7_run.py` to automate the entire setup and execution sequence.

## Important Policy Reminder
Your instruction says not to use GenAI for final content. Treat these files as structure + workflow templates, and rewrite/finalize report text in your own words before submission.
