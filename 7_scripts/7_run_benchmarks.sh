#!/usr/bin/env bash
# AI Declaration: This script skeleton was generated with AI assistance and must be reviewed by the team.
set -euo pipefail

CNI_NAME="${1:-unknown}"
PLACEMENT="${2:-inter-node}"
SAMPLES="${3:-100}"

mkdir -p 7_data/raw

CLIENT_POD=$(kubectl -n cni-bench get pod -l app=curl-client -o jsonpath='{.items[0].metadata.name}')
TARGET_URL="http://http-echo-service.cni-bench.svc.cluster.local"
RAW_FILE="7_data/raw/7_latency_samples_${CNI_NAME}_${PLACEMENT}.txt"
START_EPOCH="$(date +%s.%N)"

for i in $(seq 1 "${SAMPLES}"); do
  kubectl -n cni-bench exec "${CLIENT_POD}" -- curl -s -o /dev/null -w "%{time_total}\n" "${TARGET_URL}" >> "${RAW_FILE}"
done

END_EPOCH="$(date +%s.%N)"

read -r P50_MS P95_MS <<< "$(python3 - <<PY
import math
from pathlib import Path

values = [float(x.strip()) * 1000.0 for x in Path("${RAW_FILE}").read_text().splitlines() if x.strip()]
values.sort()
if not values:
    print("0 0")
    raise SystemExit(0)

def percentile(sorted_values, p):
    if len(sorted_values) == 1:
        return sorted_values[0]
    index = (len(sorted_values) - 1) * p
    low = math.floor(index)
    high = math.ceil(index)
    if low == high:
        return sorted_values[int(index)]
    return sorted_values[low] + (sorted_values[high] - sorted_values[low]) * (index - low)

print(f"{percentile(values, 0.50):.3f} {percentile(values, 0.95):.3f}")
PY
)"

THROUGHPUT_RPS="$(python3 - <<PY
from pathlib import Path
samples = [x for x in Path("${RAW_FILE}").read_text().splitlines() if x.strip()]
elapsed = float("${END_EPOCH}") - float("${START_EPOCH}")
if elapsed <= 0:
    print("0.00")
else:
    print(f"{len(samples)/elapsed:.2f}")
PY
)"

RESULTS_FILE="7_data/7_results_template.csv"
TIMESTAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "${TIMESTAMP},${CNI_NAME},${PLACEMENT},${P50_MS},${P95_MS},${THROUGHPUT_RPS},0,0,0" >> "${RESULTS_FILE}"

echo "Saved latency samples to ${RAW_FILE}"
echo "Summary: p50=${P50_MS}ms p95=${P95_MS}ms throughput=${THROUGHPUT_RPS}rps"
