# AI Declaration: This script skeleton was generated with AI assistance and must be reviewed by the team.

"""
Service B - API/Middleware Service
Runs on Worker-2. Receives calls from Service A, calls Service C.
Architecture: Service A (Worker-1) → Service B (Worker-2) → Service C (Worker-2)
"""
import os
import time
import requests
from flask import Flask, jsonify, request

app = Flask(__name__)

SERVICE_C_URL = os.environ.get("SERVICE_C_URL", "http://service-c.cni-benchmark.svc.cluster.local:5002")

@app.route("/health", methods=["GET"])
def health():
    return jsonify({"status": "healthy", "service": "service-b", "node": os.environ.get("NODE_NAME", "unknown")})

@app.route("/process", methods=["GET"])
def process():
    """Receives from Service A, enriches data, calls Service C."""
    start_time = time.time()

    try:
        c_response = requests.get(f"{SERVICE_C_URL}/data", timeout=10)
        c_data = c_response.json()

        b_time = time.time() - start_time

        response = {
            "service": "service-b",
            "node": os.environ.get("NODE_NAME", "unknown"),
            "pod": os.environ.get("POD_NAME", "unknown"),
            "b_processing_ms": round(b_time * 1000, 2),
            "b_to_c_call": "success",
            "downstream": c_data
        }
        return jsonify(response)

    except requests.exceptions.RequestException as e:
        b_time = time.time() - start_time
        return jsonify({
            "service": "service-b",
            "node": os.environ.get("NODE_NAME", "unknown"),
            "pod": os.environ.get("POD_NAME", "unknown"),
            "b_processing_ms": round(b_time * 1000, 2),
            "b_to_c_call": "failed",
            "error": str(e)
        }), 502

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5001, debug=False)
