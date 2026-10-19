import socket
import sys
from concurrent.futures import ThreadPoolExecutor

def check_port(ip, port):
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.settimeout(0.3)
    try:
        if s.connect_ex((ip, port)) == 0:
            return port
    except Exception:
        pass
    finally:
        s.close()
    return None

def scan_ip(ip):
    print(f"Fast scanning {ip} (30000-50000)...")
    with ThreadPoolExecutor(max_workers=200) as executor:
        futures = {executor.submit(check_port, ip, p): p for p in range(30000, 50001)}
        for future in futures:
            p = future.result()
            if p:
                print(f"FOUND OPEN PORT on {ip}: {p}")
                return p
    return None

if __name__ == "__main__":
    for ip in ["192.168.137.212", "192.168.1.8"]:
        found = scan_ip(ip)
        if found:
            print(f"SUCCESS: {ip}:{found}")
            sys.exit(0)
    print("No open ports found")
