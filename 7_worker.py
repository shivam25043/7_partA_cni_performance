import socket
import json
import time
import sys
import argparse
import subprocess
import os

def send_alert(title, message):
    """Sends a desktop notification on Linux."""
    try:
        # Try to find the DBUS session address to ensure notification shows over SSH
        if "DBUS_SESSION_BUS_ADDRESS" not in os.environ:
            uid = os.getuid()
            os.environ["DBUS_SESSION_BUS_ADDRESS"] = f"unix:path=/run/user/{uid}/bus"
        
        env = os.environ.copy()
        env["DISPLAY"] = ":0"
        
        subprocess.run(["notify-send", "-i", "utilities-terminal", title, message], 
                       env=env, stderr=subprocess.DEVNULL)
    except Exception:
        # Silently fail if notify-send is not available
        pass

def measure_latency(master_ip, port):
    """Measure round-trip time to the master server."""
    start_time = time.time()
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            s.connect((master_ip, port))
            # Send a probe
            s.sendall(json.dumps({"type": "probe"}).encode('utf-8'))
            data = s.recv(1024)
            end_time = time.time()
            if data == b"ACK":
                return (end_time - start_time) * 1000.0  # ms
    except Exception as e:
        print(f"Error measuring latency: {e}")
    return None

def run_worker(master_ip, port):
    print(f"Worker starting, master IP: {master_ip}")
    send_alert("Benchmark Started", f"Running CNI performance tests for master {master_ip}")
    
    # Perform 5 measurements and average them
    latencies = []
    for i in range(5):
        lat = measure_latency(master_ip, port)
        if lat is not None:
            latencies.append(lat)
        time.sleep(1)
    
    if latencies:
        avg_latency = sum(latencies) / len(latencies)
        payload = {
            "latency_ms": round(avg_latency, 3),
            "throughput_rps": 0,  # Placeholder for RPS benchmark
            "notes": "Python socket-based benchmark"
        }
        
        # Send final data to master
        try:
            with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
                s.connect((master_ip, port))
                s.sendall(json.dumps(payload).encode('utf-8'))
                print(f"Metrics sent to master: {payload}")
        except Exception as e:
            print(f"Error sending final metrics: {e}")
            send_alert("Benchmark Error", "Failed to send metrics to master server.")
    else:
        print("Failed to collect latency metrics.")
        send_alert("Benchmark Failed", "Could not collect latency samples.")

    send_alert("Benchmark Complete", "Performance metrics have been sent to the master server.")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--master", required=True, help="IP address of the master server")
    parser.add_argument("--port", type=int, default=5000, help="Port of the master server")
    args = parser.parse_args()
    
    run_worker(args.master, args.port)
