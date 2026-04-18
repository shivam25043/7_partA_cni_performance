#!/usr/bin/env bash
# AI Declaration: This script skeleton was generated with AI assistance and must be reviewed by the team.
set -euo pipefail

CNIS=(flannel calico cilium)
PLACEMENTS=(intra-node inter-node)
SAMPLES="${1:-100}"
KIND_BIN="${KIND_BIN:-$HOME/.local/bin/kind}"

if [[ ! -x "${KIND_BIN}" ]]; then
  KIND_BIN="kind"
fi

for cni in "${CNIS[@]}"; do
  ./7_scripts/7_create_kind_cluster.sh

  case "${cni}" in
    flannel)
      ./7_scripts/7_install_cni_flannel.sh
      ;;
    calico)
      ./7_scripts/7_install_cni_calico.sh
      ;;
    cilium)
      ./7_scripts/7_install_cni_cilium.sh
      ;;
  esac

  for placement in "${PLACEMENTS[@]}"; do
    ./7_scripts/7_deploy_workload.sh "${placement}"
    ./7_scripts/7_run_benchmarks.sh "${cni}" "${placement}" "${SAMPLES}"
    ./7_scripts/7_collect_metrics.sh
    ./7_scripts/7_cleanup.sh
  done

  "${KIND_BIN}" delete cluster --name cni-bench
done

echo "Full experiment matrix complete. Review files in 7_data/."
