import socket
import json
import csv
import os
from datetime import datetime

# Configuration
HOST = '0.0.0.0'  # Listen on all interfaces
PORT = 5000
RESULTS_FILE = '7_data/7_results_partB.csv'

def setup_csv():
    """Ensure the results CSV has headers."""
    if not os.path.exists('7_data'):
        os.makedirs('7_data')
    
    if not os.path.exists(RESULTS_FILE):
        with open(RESULTS_FILE, 'w', newline='') as f:
            writer = csv.writer(f)
            writer.writerow(['timestamp', 'worker_ip', 'latency_ms', 'throughput_rps', 'notes'])

def log_result(worker_ip, data):
    """Log received data to CSV."""
    timestamp = datetime.now().isoformat()
    latency = data.get('latency_ms', 0)
    throughput = data.get('throughput_rps', 0)
    notes = data.get('notes', '')
    
    with open(RESULTS_FILE, 'a', newline='') as f:
        writer = csv.writer(f)
        writer.writerow([timestamp, worker_ip, latency, throughput, notes])
    print(f"[{timestamp}] Logged result from {worker_ip}: {latency}ms")

def start_master():
    setup_csv()
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.bind((HOST, PORT))
        s.listen()
        print(f"Master Server listening on {HOST}:{PORT}...")
        
        while True:
            conn, addr = s.accept()
            with conn:
                print(f"Connected by {addr}")
                data = conn.recv(1024)
                if not data:
                    continue
                try:
                    payload = json.loads(data.decode('utf-8'))
                    log_result(addr[0], payload)
                    conn.sendall(b"ACK")
                except json.JSONDecodeError:
                    print("Received invalid JSON payload")
                    conn.sendall(b"NACK")

if __name__ == "__main__":
    try:
        start_master()
    except KeyboardInterrupt:
        print("\nMaster Server stopping...")
