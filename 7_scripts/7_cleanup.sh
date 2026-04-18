#!/usr/bin/env bash
# AI Declaration: This script skeleton was generated with AI assistance and must be reviewed by the team.
set -euo pipefail

KIND_BIN="${KIND_BIN:-$HOME/.local/bin/kind}"
if [[ ! -x "${KIND_BIN}" ]]; then
  KIND_BIN="kind"
fi

kubectl delete ns cni-bench --ignore-not-found=true

if [[ "${1:-}" == "--delete-cluster" ]]; then
  "${KIND_BIN}" delete cluster --name cni-bench
fi

echo "Cleanup complete"
