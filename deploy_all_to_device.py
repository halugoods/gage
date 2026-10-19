import os
import sys
import subprocess
import shutil
import time

PROJECT_DIR = os.path.dirname(os.path.abspath(__file__))
APP_DIR = os.path.join(PROJECT_DIR, 'gage-app')
OUT_DIR = os.path.join(PROJECT_DIR, 'release_apks')
DEVICE = sys.argv[1] if len(sys.argv) > 1 else '192.168.137.212:37495'

APPS = [
    {
        'key': 'driver',
        'entry': 'lib/main_driver.dart',
        'name': 'GAGE Driver',
        'pkg': 'com.gage.driver',
        'apk': 'gage-driver-release.apk',
    },
    {
        'key': 'merchant',
        'entry': 'lib/main_merchant.dart',
        'name': 'GAGE Merchant',
        'pkg': 'com.gage.merchant',
        'apk': 'gage-merchant-release.apk',
    },
    {
        'key': 'admin',
        'entry': 'lib/main_admin.dart',
        'name': 'GAGE Admin',
        'pkg': 'com.gage.admin',
        'apk': 'gage-admin-release.apk',
    },
    {
        'key': 'customer',
        'entry': 'lib/main_customer.dart',
        'name': 'GAGE Customer',
        'pkg': 'com.gage.customer',
        'apk': 'gage-customer-release.apk',
    },
]

def build_app(app):
    print(f"\n=======================================================")
    print(f"[*] Building FRESH APK: {app['name']} [{app['pkg']}]")
    print(f"[*] Entrypoint: {app['entry']}")
    print(f"=======================================================\n")

    os.makedirs(OUT_DIR, exist_ok=True)
    final_dest = os.path.join(OUT_DIR, app['apk'])
    if os.path.exists(final_dest):
        try:
            os.remove(final_dest)
        except Exception:
            pass

    # Clean old gradle outputs
    candidates = [
        os.path.join(APP_DIR, 'build', 'app', 'outputs', 'flutter-apk', f"app-{app['key']}-release.apk"),
        os.path.join(APP_DIR, 'build', 'app', 'outputs', 'apk', app['key'], 'release', f"app-{app['key']}-release.apk"),
        os.path.join(APP_DIR, 'build', 'app', 'outputs', 'flutter-apk', 'app-release.apk'),
    ]
    for c in candidates:
        if os.path.exists(c):
            try:
                os.remove(c)
            except Exception:
                pass

    cmd = f"flutter build apk --release --flavor {app['key']} -t {app['entry']}"
    print(f"[*] Command: {cmd}")
    res = subprocess.run(cmd, cwd=APP_DIR, shell=True)
    if res.returncode != 0:
        print(f"[!] Build FAILED for {app['name']}")
        return None

    gradle_out = None
    for c in candidates:
        if os.path.exists(c):
            gradle_out = c
            break

    if gradle_out and os.path.exists(gradle_out):
        shutil.copy2(gradle_out, final_dest)
        size_mb = os.path.getsize(final_dest) / (1024 * 1024)
        print(f"[+] Successfully built: {final_dest} ({size_mb:.2f} MB)")
        return final_dest
    else:
        print(f"[!] Output APK not found for {app['name']}")
        return None

def install_app(app, apk_path):
    print(f"\n[*] Installing {app['name']} ({app['pkg']}) to device {DEVICE}...")
    cmd = f'adb -s {DEVICE} install -r -d "{apk_path}"'
    res = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    out = (res.stdout + res.stderr).strip()
    print(f"    Result: {out}")
    return 'Success' in out

def main():
    print(f"=== GAGE Multi-App Fresh Build & Deploy to {DEVICE} ===")
    results = {}

    for app in APPS:
        apk_path = build_app(app)
        if not apk_path:
            results[app['name']] = 'BUILD_FAILED'
            continue
        
        ok = install_app(app, apk_path)
        results[app['name']] = 'INSTALLED' if ok else 'INSTALL_FAILED'

    print("\n=======================================================")
    print("=== FINAL INSTALLATION SUMMARY ===")
    for name, status in results.items():
        print(f"  - {name}: {status}")
    print("=======================================================")

if __name__ == '__main__':
    main()
