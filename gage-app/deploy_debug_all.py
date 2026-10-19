import os
import sys
import subprocess
import time

ADB_EXE = r"C:\Users\ertyui\android_sdk\platform-tools\adb.exe"
if not os.path.exists(ADB_EXE):
    ADB_EXE = "adb"

APK_DIR = os.path.join(os.path.dirname(__file__), "build", "app", "outputs", "flutter-apk")

APKS = [
    ("GAGE Customer", "com.gage.customer", "app-customer-debug.apk"),
    ("GAGE Driver",   "com.gage.driver",   "app-driver-debug.apk"),
    ("GAGE Merchant", "com.gage.merchant", "app-merchant-debug.apk"),
    ("GAGE Admin",    "com.gage.admin",    "app-admin-debug.apk"),
]

def get_devices():
    try:
        out = subprocess.check_output([ADB_EXE, "devices", "-l"], text=True, errors="replace")
        devices = []
        for line in out.strip().splitlines()[1:]:
            line = line.strip()
            if not line:
                continue
            parts = line.split()
            dev_id = parts[0]
            status = parts[1] if len(parts) > 1 else "unknown"
            if status == "device":
                devices.append(dev_id)
        return devices
    except Exception as e:
        print(f"Error checking devices: {e}")
        return []

def install_apk(device_id, name, pkg, filename):
    filepath = os.path.join(APK_DIR, filename)
    if not os.path.exists(filepath):
        print(f"[FAIL] {name} APK not found: {filepath}")
        return False
    size_mb = os.path.getsize(filepath) / (1024 * 1024)
    print(f"\n--> Installing {name} ({size_mb:.1f} MB) to {device_id}...")
    t0 = time.time()
    try:
        res = subprocess.run([ADB_EXE, "-s", device_id, "install", "-r", "-d", filepath], capture_output=True, text=True, timeout=300)
        dur = time.time() - t0
        if "success" in res.stdout.lower():
            print(f"[OK] {name} installed successfully in {dur:.1f}s!")
            return True
        else:
            print(f"[FAIL] {name} install failed:\n{res.stdout}\n{res.stderr}")
            return False
    except Exception as e:
        print(f"[ERROR] {name} install exception: {e}")
        return False

def main():
    target_device = sys.argv[1] if len(sys.argv) > 1 else None
    if not target_device:
        devices = get_devices()
        if not devices:
            print("[WARN] No ADB device connected! Please plug in USB or connect wireless debugging.")
            sys.exit(1)
        target_device = devices[0]
        print(f"[INFO] Auto-selected device: {target_device}")
    else:
        print(f"[INFO] Target device specified: {target_device}")

    print("==================================================")
    print(f"  DEPLOYING 4 GAGE PORTALS (DEBUG) -> {target_device}")
    print("==================================================")
    
    results = {}
    for name, pkg, filename in APKS:
        ok = install_apk(target_device, name, pkg, filename)
        results[name] = ok

    print("\n==================================================")
    print("  SUMMARY INSTALLASI GAGE")
    print("==================================================")
    for name, ok in results.items():
        status_str = "BERHASIL" if ok else "GAGAL"
        print(f"  {name:15} : {status_str}")
    print("==================================================")

if __name__ == "__main__":
    main()
