#!/bin/bash

# AI Declaration: This script skeleton was generated with AI assistance and must be reviewed by the team.
###############################################################################
# [WORKER-1] CNI Benchmark Script
# Measures latency and throughput of A→B→C chain for each CNI plugin.
# Usage: ./benchmark.sh <CNI_NAME> <WORKER1_IP> [NUM_REQUESTS] [CONCURRENCY]
#   CNI_NAME    : flannel | calico | cilium
#   WORKER1_IP  : IP of Worker-1 node (Service A NodePort host)
#   NUM_REQUESTS: total requests (default: 500)
#   CONCURRENCY : parallel workers (default: 10)
###############################################################################
set -euo pipefail

CNI="${1:-flannel}"
WORKER1_IP="${2:-192.168.192.170}"
NUM_REQUESTS="${3:-500}"
CONCURRENCY="${4:-10}"
NODEPORT="30080"
URL="http://${WORKER1_IP}:${NODEPORT}/"
RESULTS_DIR="$(cd "$(dirname "$0")/../data" && pwd)"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RESULT_FILE="$RESULTS_DIR/${CNI}_${TIMESTAMP}.json"
RAW_FILE="$RESULTS_DIR/${CNI}_${TIMESTAMP}_raw.txt"
NODE_TOP_FILE="$RESULTS_DIR/${CNI}_${TIMESTAMP}_node_top.txt"
POD_TOP_FILE="$RESULTS_DIR/${CNI}_${TIMESTAMP}_pod_top.txt"

mkdir -p "$RESULTS_DIR"

echo "============================================="
echo "  CNI Benchmark: $CNI"
echo "  Target: $URL"
echo "  Requests: $NUM_REQUESTS  Concurrency: $CONCURRENCY"
echo "  Results: $RESULT_FILE"
echo "============================================="

# ---- Warm-up ----
echo ""
echo "[*] Warming up (10 requests)..."
for i in $(seq 1 10); do
    curl -s "$URL" > /dev/null 2>&1 || true
done

# ---- Curl-based latency measurement ----
echo ""
echo "[*] Running curl latency test ($NUM_REQUESTS requests, sequential)..."
CURL_LATENCIES=()
CURL_ERRORS=0

for i in $(seq 1 $NUM_REQUESTS); do
    RESULT=$(curl -s -o /dev/null -w "%{time_total}" --max-time 10 "$URL" 2>/dev/null || echo "error")
    if [[ "$RESULT" == "error" ]]; then
        ((CURL_ERRORS++))
    else
        LATENCY_MS=$(echo "$RESULT * 1000" | bc -l)
        CURL_LATENCIES+=("$LATENCY_MS")
        echo "$LATENCY_MS" >> "$RAW_FILE"
    fi
    # Progress every 50 requests
    if (( i % 50 == 0 )); then
        echo "  Progress: $i/$NUM_REQUESTS"
    fi
done

echo ""
echo "[*] Capturing CPU/memory snapshots..."
if kubectl top nodes --no-headers > "$NODE_TOP_FILE" 2>/dev/null; then
    echo "  Node metrics captured: $NODE_TOP_FILE"
else
    echo "# metrics unavailable: kubectl top nodes failed (metrics-server may be missing)" > "$NODE_TOP_FILE"
    echo "  [!] Node metrics unavailable (metrics-server may be missing)"
fi

if kubectl top pods -n cni-benchmark --no-headers > "$POD_TOP_FILE" 2>/dev/null; then
    echo "  Pod metrics captured:  $POD_TOP_FILE"
else
    echo "# metrics unavailable: kubectl top pods failed (metrics-server may be missing)" > "$POD_TOP_FILE"
    echo "  [!] Pod metrics unavailable (metrics-server may be missing)"
fi

echo ""
echo "[*] Computing statistics..."

# Compute stats using Python
python3 - <<PYEOF
import json, math, sys
from pathlib import Path

raw_path = Path("$RAW_FILE")
node_top_path = Path("$NODE_TOP_FILE")
pod_top_path = Path("$POD_TOP_FILE")

with raw_path.open() as f:
    latencies = [float(x.strip()) for x in f if x.strip()]

if not latencies:
    print("ERROR: No successful requests!")
    sys.exit(1)

def cpu_to_millicores(token):
    token = (token or "").strip()
    if not token or token.startswith("<"):
        return None
    if token.endswith("m"):
        try:
            return float(token[:-1])
        except ValueError:
            return None
    try:
        return float(token) * 1000.0
    except ValueError:
        return None

def mem_to_mib(token):
    token = (token or "").strip()
    if not token or token.startswith("<"):
        return None
    units = {
        "Ki": 1.0 / 1024.0,
        "Mi": 1.0,
        "Gi": 1024.0,
        "Ti": 1024.0 * 1024.0,
    }
    for unit, factor in units.items():
        if token.endswith(unit):
            try:
                return float(token[:-2]) * factor
            except ValueError:
                return None
    try:
        return float(token)
    except ValueError:
        return None

def parse_node_top(path):
    rows = []
    if not path.exists():
        return rows
    for line in path.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        parts = line.split()
        if len(parts) < 4:
            continue
        rows.append({
            "name": parts[0],
            "cpu_m": cpu_to_millicores(parts[1]),
            "mem_mib": mem_to_mib(parts[3]),
        })
    return rows

def parse_pod_top(path):
    rows = []
    if not path.exists():
        return rows
    for line in path.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        parts = line.split()
        if len(parts) < 3:
            continue
        rows.append({
            "name": parts[0],
            "cpu_m": cpu_to_millicores(parts[1]),
            "mem_mib": mem_to_mib(parts[2]),
        })
    return rows

node_rows = parse_node_top(node_top_path)
pod_rows = parse_pod_top(pod_top_path)

node_cpu = [r["cpu_m"] for r in node_rows if r["cpu_m"] is not None]
node_mem = [r["mem_mib"] for r in node_rows if r["mem_mib"] is not None]
pod_cpu = [r["cpu_m"] for r in pod_rows if r["cpu_m"] is not None]
pod_mem = [r["mem_mib"] for r in pod_rows if r["mem_mib"] is not None]

service_cpu = {"service-a": 0.0, "service-b": 0.0, "service-c": 0.0}
service_mem = {"service-a": 0.0, "service-b": 0.0, "service-c": 0.0}
for row in pod_rows:
    for service_name in service_cpu:
        if row["name"].startswith(service_name):
            if row["cpu_m"] is not None:
                service_cpu[service_name] += row["cpu_m"]
            if row["mem_mib"] is not None:
                service_mem[service_name] += row["mem_mib"]

latencies.sort()
n = len(latencies)
avg = sum(latencies) / n
p50 = latencies[int(n * 0.50)]
p75 = latencies[int(n * 0.75)]
p90 = latencies[int(n * 0.90)]
p95 = latencies[int(n * 0.95)]
p99 = latencies[min(int(n * 0.99), n-1)]
mn  = latencies[0]
mx  = latencies[-1]

# Throughput estimate: using avg latency (sequential)
throughput = 1000.0 / avg if avg > 0 else 0

result = {
    "cni": "$CNI",
    "timestamp": "$TIMESTAMP",
    "target_url": "$URL",
    "benchmark_scope": "A->B->C chain via service-a NodePort",
    "total_requests": $NUM_REQUESTS,
    "successful_requests": n,
    "errors": $NUM_REQUESTS - n,
    "latency_ms": {
        "min": round(mn, 3),
        "avg": round(avg, 3),
        "p50": round(p50, 3),
        "p75": round(p75, 3),
        "p90": round(p90, 3),
        "p95": round(p95, 3),
        "p99": round(p99, 3),
        "max": round(mx, 3)
    },
    "throughput_rps_estimated": round(throughput, 2),
    "resource_overhead": {
        "metrics_server_available": bool(node_rows or pod_rows),
        "node_cpu_avg_millicores": round(sum(node_cpu) / len(node_cpu), 2) if node_cpu else None,
        "node_cpu_max_millicores": round(max(node_cpu), 2) if node_cpu else None,
        "node_memory_avg_mib": round(sum(node_mem) / len(node_mem), 2) if node_mem else None,
        "node_memory_max_mib": round(max(node_mem), 2) if node_mem else None,
        "benchmark_pod_cpu_total_millicores": round(sum(pod_cpu), 2) if pod_cpu else None,
        "benchmark_pod_memory_total_mib": round(sum(pod_mem), 2) if pod_mem else None,
        "service_cpu_millicores": {k: round(v, 2) for k, v in service_cpu.items()},
        "service_memory_mib": {k: round(v, 2) for k, v in service_mem.items()},
    },
    "artifacts": {
        "latency_raw_file": str(raw_path),
        "node_top_file": str(node_top_path),
        "pod_top_file": str(pod_top_path),
    },
}

with open("$RESULT_FILE", "w") as f:
    json.dump(result, f, indent=2)

print(json.dumps(result, indent=2))
PYEOF

# ---- hey load test (if available) ----
if command -v hey &>/dev/null; then
    echo ""
    echo "[*] Running 'hey' throughput test ($NUM_REQUESTS requests, concurrency $CONCURRENCY)..."
    HEY_OUTPUT_FILE="$RESULTS_DIR/${CNI}_${TIMESTAMP}_hey.txt"
    hey -n $NUM_REQUESTS -c $CONCURRENCY "$URL" | tee "$HEY_OUTPUT_FILE"
    echo ""
    echo "  hey results saved to: $HEY_OUTPUT_FILE"
else
    echo ""
    echo "  [!] 'hey' not found. Skipping throughput test. Install with:"
    echo "      wget https://hey-release.s3.us-east-2.amazonaws.com/hey_linux_amd64 -O /usr/local/bin/hey && chmod +x /usr/local/bin/hey"
fi

echo ""
echo "============================================="
echo "  ✓ Benchmark complete for CNI: $CNI"
echo "  Results saved to: $RESULT_FILE"
echo "  Raw latencies: $RAW_FILE"
echo "  Node metrics:  $NODE_TOP_FILE"
echo "  Pod metrics:   $POD_TOP_FILE"
echo "============================================="
