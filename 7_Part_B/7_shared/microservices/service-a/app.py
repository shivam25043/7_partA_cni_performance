# AI Declaration: This script skeleton was generated with AI assistance and must be reviewed by the team.

"""
Service A - Frontend Service
Runs on Worker-1. Receives external requests and forwards to Service B.
Architecture: Client → Service A (Worker-1) → Service B (Worker-2) → Service C (Worker-2)
"""
import os
import time
import json
import requests
from flask import Flask, jsonify, request

app = Flask(__name__)

SERVICE_B_URL = os.environ.get("SERVICE_B_URL", "http://service-b.cni-benchmark.svc.cluster.local:5001")

@app.route("/health", methods=["GET"])
def health():
    """Health check endpoint."""
    return jsonify({"status": "healthy", "service": "service-a", "node": os.environ.get("NODE_NAME", "unknown")})

@app.route("/", methods=["GET"])
def index():
    """Main endpoint - calls Service B and returns aggregated response."""
    start_time = time.time()
    
    try:
        # Call Service B
        b_response = requests.get(f"{SERVICE_B_URL}/process", timeout=10)
        b_data = b_response.json()
        
        total_time = time.time() - start_time
        
        response = {
            "service": "service-a",
            "node": os.environ.get("NODE_NAME", "unknown"),
            "pod": os.environ.get("POD_NAME", "unknown"),
            "timestamp": time.time(),
            "total_latency_ms": round(total_time * 1000, 2),
            "a_to_b_call": "success",
            "downstream": b_data
        }
        return jsonify(response)
    
    except requests.exceptions.RequestException as e:
        total_time = time.time() - start_time
        return jsonify({
            "service": "service-a",
            "node": os.environ.get("NODE_NAME", "unknown"),
            "pod": os.environ.get("POD_NAME", "unknown"),
            "error": str(e),
            "total_latency_ms": round(total_time * 1000, 2),
            "a_to_b_call": "failed"
        }), 502

@app.route("/benchmark", methods=["GET"])
def benchmark():
    """Benchmark endpoint - calls Service B N times and returns stats."""
    n = int(request.args.get("n", 10))
    latencies = []
    errors = 0
    
    for i in range(n):
        start = time.time()
        try:
            resp = requests.get(f"{SERVICE_B_URL}/process", timeout=10)
            elapsed = (time.time() - start) * 1000  # ms
            latencies.append(elapsed)
        except Exception:
            errors += 1
    
    if latencies:
        latencies.sort()
        result = {
            "service": "service-a",
            "total_requests": n,
            "successful": len(latencies),
            "errors": errors,
            "avg_latency_ms": round(sum(latencies) / len(latencies), 2),
            "min_latency_ms": round(min(latencies), 2),
            "max_latency_ms": round(max(latencies), 2),
            "p50_latency_ms": round(latencies[len(latencies) // 2], 2),
            "p95_latency_ms": round(latencies[int(len(latencies) * 0.95)], 2),
            "p99_latency_ms": round(latencies[int(len(latencies) * 0.99)], 2),
        }
    else:
        result = {"error": "all requests failed", "errors": errors}
    
    return jsonify(result)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=False)
