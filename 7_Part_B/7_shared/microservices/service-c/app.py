# AI Declaration: This script skeleton was generated with AI assistance and must be reviewed by the team.

"""
Service C - Mock Database Service
Runs on Worker-2. Returns simulated database records.
Architecture: Service A → Service B → Service C (Worker-2)
"""
import os
import time
import random
from flask import Flask, jsonify

app = Flask(__name__)

MOCK_DATA = [
    {"id": i, "product": f"Product-{i}", "price": round(random.uniform(5.0, 500.0), 2), "stock": random.randint(0, 1000)}
    for i in range(1, 51)
]

@app.route("/health", methods=["GET"])
def health():
    return jsonify({"status": "healthy", "service": "service-c", "node": os.environ.get("NODE_NAME", "unknown")})

@app.route("/data", methods=["GET"])
def get_data():
    """Simulate DB query with small delay."""
    time.sleep(0.002)  # 2ms simulated DB latency
    record = random.choice(MOCK_DATA)
    return jsonify({
        "service": "service-c",
        "node": os.environ.get("NODE_NAME", "unknown"),
        "pod": os.environ.get("POD_NAME", "unknown"),
        "record": record,
        "timestamp": time.time()
    })

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5002, debug=False)
