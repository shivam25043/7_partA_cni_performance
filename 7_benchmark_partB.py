#!/usr/bin/env python3
"""
7_benchmark_partB.py - CNI Performance Benchmark for A→B→C microservice chain
Measures latency (p50, p95, avg) and throughput (RPS) via the NodePort endpoint.
Results saved to 7_data/7_results_partB_k8s.csv
"""
import json
import time
import statistics
import csv
import os
import urllib.request
import argparse
from datetime import datetime

TARGET_URL = "http://192.168.192.166:30080/"
DATA_DIR = os.path.join(os.path.dirname(__file__), "7_data")
OUTPUT_CSV = os.path.join(DATA_DIR, "7_results_partB_k8s.csv")

def run_benchmark(cni_name, num_requests=100, concurrency=1):
    """Run benchmark and collect latency samples."""
    print(f"\n{'='*60}")
    print(f"  Benchmarking CNI: {cni_name}")
    print(f"  Target: {TARGET_URL}")
    print(f"  Requests: {num_requests}")
    print(f"{'='*60}")

    latencies_ms = []
    chain_a_to_b = []
    chain_b_to_c = []
    errors = 0

    for i in range(num_requests):
        t0 = time.time()
        try:
            with urllib.request.urlopen(TARGET_URL, timeout=10) as resp:
                data = json.load(resp)
                total_ms = round((time.time() - t0) * 1000, 3)
                latencies_ms.append(total_ms)
                chain_a_to_b.append(data.get("total_a_to_b_ms", 0))
                b_chain = data.get("chain", {})
                chain_b_to_c.append(b_chain.get("hop_b_to_c_ms", 0))
        except Exception as e:
            errors += 1
            print(f"  [!] Request {i+1} failed: {e}")

        if (i + 1) % 20 == 0:
            print(f"  Progress: {i+1}/{num_requests} | Avg so far: {statistics.mean(latencies_ms):.2f}ms")

    if not latencies_ms:
        print("  [ERROR] No successful requests!")
        return

    # Compute stats
    sorted_lat = sorted(latencies_ms)
    avg = statistics.mean(latencies_ms)
    p50 = sorted_lat[int(len(sorted_lat) * 0.50)]
    p95 = sorted_lat[int(len(sorted_lat) * 0.95)]
    total_time = sum(latencies_ms) / 1000.0
    rps = round(len(latencies_ms) / total_time, 2)

    result = {
        "timestamp": datetime.now().isoformat(),
        "cni": cni_name,
        "requests": num_requests,
        "success": len(latencies_ms),
        "errors": errors,
        "avg_latency_ms": round(avg, 3),
        "p50_latency_ms": round(p50, 3),
        "p95_latency_ms": round(p95, 3),
        "min_latency_ms": round(min(latencies_ms), 3),
        "max_latency_ms": round(max(latencies_ms), 3),
        "throughput_rps": rps,
        "avg_a_to_b_ms": round(statistics.mean(chain_a_to_b), 3) if chain_a_to_b else 0,
        "avg_b_to_c_ms": round(statistics.mean(chain_b_to_c), 3) if chain_b_to_c else 0,
    }

    print(f"\n  === RESULTS for {cni_name} ===")
    print(f"  Successful Requests : {result['success']}/{num_requests}")
    print(f"  Avg Latency         : {result['avg_latency_ms']} ms")
    print(f"  P50 Latency         : {result['p50_latency_ms']} ms")
    print(f"  P95 Latency         : {result['p95_latency_ms']} ms")
    print(f"  Throughput          : {result['throughput_rps']} RPS")
    print(f"  Hop A→B avg         : {result['avg_a_to_b_ms']} ms")
    print(f"  Hop B→C avg         : {result['avg_b_to_c_ms']} ms")

    # Save to CSV
    os.makedirs(DATA_DIR, exist_ok=True)
    file_exists = os.path.isfile(OUTPUT_CSV)
    with open(OUTPUT_CSV, "a", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=result.keys())
        if not file_exists:
            writer.writeheader()
        writer.writerow(result)

    print(f"\n  Results saved to: {OUTPUT_CSV}")
    return result

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="CNI Benchmark for A→B→C chain")
    parser.add_argument("--cni", default="flannel", help="CNI name (flannel/calico/cilium)")
    parser.add_argument("--requests", type=int, default=100, help="Number of requests")
    args = parser.parse_args()

    run_benchmark(cni_name=args.cni, num_requests=args.requests)
