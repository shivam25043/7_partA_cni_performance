#!/usr/bin/env python3

# AI Declaration: This script skeleton was generated with AI assistance and must be reviewed by the team.
"""
Compare benchmark results across CNI plugins and generate a report.
Usage: python3 compare-results.py <data_dir>
"""
import os
import sys
import json
import glob
from datetime import datetime

CNIS = ["flannel", "calico", "cilium"]

def load_results(data_dir):
    """Load the latest result for each CNI."""
    results = {}
    for cni in CNIS:
        pattern = os.path.join(data_dir, f"{cni}_*.json")
        files = sorted(glob.glob(pattern))
        if files:
            with open(files[-1]) as f:
                results[cni] = json.load(f)
    return results

def get_val(data, key, default="N/A"):
    parts = key.split(".")
    value = data
    for part in parts:
        if not isinstance(value, dict) or part not in value:
            return default
        value = value[part]
    if value is None:
        return default
    return value

def as_float(value):
    try:
        return float(value)
    except (TypeError, ValueError):
        return None

def fmt(value):
    if isinstance(value, float):
        return f"{value:.2f}"
    return str(value)

def generate_report(results, data_dir):
    lines = []
    lines.append("=" * 65)
    lines.append("  CNI PLUGIN PERFORMANCE COMPARISON REPORT")
    lines.append(f"  Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    lines.append("=" * 65)
    lines.append("")

    if not results:
        lines.append("  No results found. Run benchmark.sh for each CNI first.")
        return "\n".join(lines)

    # Table header
    hdr = f"{'Metric':<34} {'Flannel':>12} {'Calico':>12} {'Cilium':>12}"
    lines.append(hdr)
    lines.append("-" * 78)

    metrics = [
        ("Avg Latency (ms)",   "latency_ms.avg"),
        ("P50 Latency (ms)",   "latency_ms.p50"),
        ("P75 Latency (ms)",   "latency_ms.p75"),
        ("P90 Latency (ms)",   "latency_ms.p90"),
        ("P95 Latency (ms)",   "latency_ms.p95"),
        ("P99 Latency (ms)",   "latency_ms.p99"),
        ("Min Latency (ms)",   "latency_ms.min"),
        ("Max Latency (ms)",   "latency_ms.max"),
        ("Est. Throughput RPS","throughput_rps_estimated"),
        ("Node CPU Avg (m)", "resource_overhead.node_cpu_avg_millicores"),
        ("Node CPU Max (m)", "resource_overhead.node_cpu_max_millicores"),
        ("Node Mem Avg (Mi)", "resource_overhead.node_memory_avg_mib"),
        ("Pod CPU Total (m)", "resource_overhead.benchmark_pod_cpu_total_millicores"),
        ("Pod Mem Total (Mi)", "resource_overhead.benchmark_pod_memory_total_mib"),
        ("Total Requests",     "total_requests"),
        ("Errors",             "errors"),
    ]

    for label, key in metrics:
        vals = {}
        for cni in CNIS:
            if cni in results:
                vals[cni] = get_val(results[cni], key)
            else:
                vals[cni] = "N/A"
        row = (f"{label:<34} "
               f"{fmt(vals.get('flannel','N/A')):>12} "
               f"{fmt(vals.get('calico','N/A')):>12} "
               f"{fmt(vals.get('cilium','N/A')):>12}")
        lines.append(row)

    lines.append("-" * 78)
    lines.append("")

    # Winner analysis
    lines.append("WINNER ANALYSIS:")
    lines.append("")
    if all(c in results for c in CNIS):
        avg_latencies = {c: as_float(get_val(results[c], "latency_ms.avg")) for c in CNIS}
        valid_avg_latencies = {c: v for c, v in avg_latencies.items() if v is not None}
        if valid_avg_latencies:
            best_lat = min(valid_avg_latencies, key=valid_avg_latencies.get)
            lines.append(f"  Lowest Avg Latency : {best_lat.upper()} ({valid_avg_latencies[best_lat]:.2f} ms)")

        throughputs = {c: as_float(get_val(results[c], "throughput_rps_estimated")) for c in CNIS}
        valid_throughputs = {c: v for c, v in throughputs.items() if v is not None}
        if valid_throughputs:
            best_tp = max(valid_throughputs, key=valid_throughputs.get)
            lines.append(f"  Highest Throughput : {best_tp.upper()} ({valid_throughputs[best_tp]:.2f} RPS)")

        p95_values = {c: as_float(get_val(results[c], "latency_ms.p95")) for c in CNIS}
        valid_p95_values = {c: v for c, v in p95_values.items() if v is not None}
        if valid_p95_values:
            best_p95 = min(valid_p95_values, key=valid_p95_values.get)
            lines.append(f"  Best P95 Latency   : {best_p95.upper()} ({valid_p95_values[best_p95]:.2f} ms)")

        cpu_overhead = {c: as_float(get_val(results[c], "resource_overhead.node_cpu_avg_millicores")) for c in CNIS}
        valid_cpu_overhead = {c: v for c, v in cpu_overhead.items() if v is not None}
        if valid_cpu_overhead:
            lowest_cpu = min(valid_cpu_overhead, key=valid_cpu_overhead.get)
            lines.append(f"  Lowest Node CPU Avg: {lowest_cpu.upper()} ({valid_cpu_overhead[lowest_cpu]:.2f} m)")
        else:
            lines.append("  Lowest Node CPU Avg: N/A (metrics-server data missing in benchmark artifacts)")

    lines.append("")
    lines.append("METRICS AVAILABILITY:")
    for cni in CNIS:
        if cni in results:
            has_metrics = get_val(results[cni], "resource_overhead.metrics_server_available", False)
            lines.append(f"  {cni.upper()}: metrics-server {'available' if has_metrics else 'not available'} during run")

    lines.append("")
    lines.append("=" * 65)
    lines.append("  EXPLANATION OF METRICS:")
    lines.append("  - Avg Latency: Mean end-to-end response time (A→B→C→A)")
    lines.append("  - P50/P95/P99: Percentile latencies (tail latency matters!)")
    lines.append("  - Throughput: Estimated sequential requests per second")
    lines.append("  - Node CPU Avg/Max: Cluster-level CPU overhead while benchmark traffic runs")
    lines.append("  - Pod CPU/Mem Total: Resource usage of benchmark application pods")
    lines.append("  - Errors: Failed requests (network drops / timeouts)")
    lines.append("=" * 65)

    return "\n".join(lines)

if __name__ == "__main__":
    data_dir = sys.argv[1] if len(sys.argv) > 1 else "./data"
    results = load_results(data_dir)
    report = generate_report(results, data_dir)
    print(report)
    report_file = os.path.join(data_dir, "comparison_report.txt")
    os.makedirs(data_dir, exist_ok=True)
    with open(report_file, "w") as f:
        f.write(report)
    print(f"\n  Report saved to: {report_file}")
