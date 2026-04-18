#!/usr/bin/env bash
# AI Declaration: This script skeleton was generated with AI assistance and must be reviewed by the team.
set -euo pipefail

ZIP_NAME="7_partA_cni_performance.zip"
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

cd "${PROJECT_ROOT}"

echo "[1/6] Cleaning generated cache files"
find . -type d -name '__pycache__' -prune -exec rm -rf {} +
find . -type f -name '*.pyc' -delete

echo "[2/6] Regenerating plots"
python3 7_plots/7_plot_latency.py
python3 7_plots/7_plot_throughput.py
python3 7_plots/7_plot_cpu_memory.py

echo "[3/6] Generating report PDF (best-effort)"
./7_scripts/7_generate_report_pdf.sh || true

echo "[4/6] Validating naming convention"
bad_files=$(find . -type f | sed 's|^./||' | awk -F/ '{print $NF}' | grep -v '^7_' || true)
if [[ -n "${bad_files}" ]]; then
  echo "Naming violations found:"
  echo "${bad_files}"
  exit 1
fi

echo "[5/6] Validating disallowed file types"
disallowed=$(find . -type f | grep -E '\.ipynb$|\.rar$|\.exe$|\.out$|\.class$' || true)
if [[ -n "${disallowed}" ]]; then
  echo "Disallowed files found:"
  echo "${disallowed}"
  exit 1
fi

echo "[6/6] Building zip"
rm -f "${ZIP_NAME}"
zip -r "${ZIP_NAME}" . -x '*.git*' >/dev/null
echo "Created ${ZIP_NAME}"
