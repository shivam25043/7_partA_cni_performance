import pexpect
import subprocess
import time
import os
import sys

# Configuration
WORKER_IPS = ["192.168.192.166", "192.168.192.170"]
MASTER_IP = "192.168.192.169" # Local IP detected previously
PASSWORD = "student"
USERNAME = "iiitd" # Updated from student to iiitd
WORKER_SCRIPT = "7_worker.py"
MASTER_SCRIPT = "7_master.py"

def run_local_master():
    """Starts the master server as a background process."""
    print(f"Starting local master server: {MASTER_SCRIPT}...")
    proc = subprocess.Popen([sys.executable, MASTER_SCRIPT], 
                            stdout=subprocess.PIPE, 
                            stderr=subprocess.PIPE)
    return proc

def ssh_command(ip, user, password, command):
    """Executes a command on a remote host using pexpect."""
    ssh_newkey = 'Are you sure you want to continue connecting'
    conn_str = f"ssh {user}@{ip} '{command}'"
    print(f"Executing remote: {command}")
    
    child = pexpect.spawn(conn_str, timeout=30)
    i = child.expect([ssh_newkey, 'password:', pexpect.EOF, pexpect.TIMEOUT])
    
    if i == 0:
        child.sendline('yes')
        it = child.expect(['password:', pexpect.EOF])
        if it == 0:
            child.sendline(password)
            child.expect(pexpect.EOF)
    elif i == 1:
        child.sendline(password)
        child.expect(pexpect.EOF)
    elif i == 2:
        pass # Already got EOF, success!
    
    output = child.before.decode('utf-8')
    print(output)
    return output

def scp_file(ip, user, password, local_file, remote_path):
    """Copies a file to the remote host."""
    ssh_newkey = 'Are you sure you want to continue connecting'
    conn_str = f"scp {local_file} {user}@{ip}:{remote_path}"
    print(f"Syncing {local_file} to {ip}...")
    
    child = pexpect.spawn(conn_str, timeout=30)
    i = child.expect([ssh_newkey, 'password:', pexpect.EOF, pexpect.TIMEOUT])
    
    if i == 0:
        child.sendline('yes')
        it = child.expect(['password:', pexpect.EOF])
        if it == 0:
            child.sendline(password)
            child.expect(pexpect.EOF)
    elif i == 1:
        child.sendline(password)
        child.expect(pexpect.EOF)
    elif i == 2:
        pass # Already got EOF
    
    return True

def main():
    # 1. Start Master
    master_proc = run_local_master()
    time.sleep(2) # Give it time to bind
    
    try:
        for worker_ip in WORKER_IPS:
            # 2. Setup Worker
            print(f"--- Setting up Worker at {worker_ip} ---")
            scp_file(worker_ip, USERNAME, PASSWORD, WORKER_SCRIPT, f"/home/{USERNAME}/{WORKER_SCRIPT}")
            
            # 3. Start Worker
            print(f"--- Starting Worker at {worker_ip} ---")
            remote_cmd = f"python3 /home/{USERNAME}/{WORKER_SCRIPT} --master {MASTER_IP}"
            ssh_command(worker_ip, USERNAME, PASSWORD, remote_cmd)
        
        print("--- All benchmark runs requested ---")
        print("Check 7_data/7_results_partB.csv for results.")
        
        # Keep running for a bit to ensure master collects data from all workers
        time.sleep(10)
        
    finally:
        print("Shutting down master process...")
        master_proc.terminate()
        try:
            master_proc.wait(timeout=5)
        except subprocess.TimeoutExpired:
            master_proc.kill()

if __name__ == "__main__":
    main()
