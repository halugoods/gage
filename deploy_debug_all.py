import os
import sys
import subprocess

PROJECT_DIR = os.path.dirname(os.path.abspath(__file__))
APP_DIR = os.path.join(PROJECT_DIR, 'gage-app')
DEVICE = sys.argv[1] if len(sys.argv) > 1 else '192.168.137.212:37495'

APPS = [
    {
        'key': 'driver',
        'entry': 'lib/main_driver.dart',
        'name': 'GAGE Driver',
        'pkg': 'com.gage.driver',
        'apk': 'app-driver-debug.apk',
    },
    {
        'key': 'merchant',
        'entry': 'lib/main_merchant.dart',
        'name': 'GAGE Merchant',
        'pkg': 'com.gage.merchant',
        'apk': 'app-merchant-debug.apk',
    },
    {
        'key': 'admin',
        'entry': 'lib/main_admin.dart',
        'name': 'GAGE Admin',
        'pkg': 'com.gage.admin',
        'apk': 'app-admin-debug.apk',
    },
    {
        'key': 'customer',
        'entry': 'lib/main_customer.dart',
        'name': 'GAGE Customer',
        'pkg': 'com.gage.customer',
        'apk': 'app-customer-debug.apk',
    },
]

def build_and_install(app):
    print(f"\n=======================================================")
    print(f"[*] Building DEBUG: {app['name']} [{app['pkg']}]")
    print(f"[*] Entry: {app['entry']}")
    print(f"=======================================================\n")

    cmd = f"flutter build apk --debug --flavor {app['key']} -t {app['entry']}"
    res = subprocess.run(cmd, cwd=APP_DIR, shell=True)
    if res.returncode != 0:
        print(f"[!] FAILED building debug for {app['name']}")
        return False

    # Possible candidate paths for debug APK
    candidates = [
        os.path.join(APP_DIR, 'build', 'app', 'outputs', 'flutter-apk', app['apk']),
        os.path.join(APP_DIR, 'build', 'app', 'outputs', 'apk', app['key'], 'debug', app['apk']),
    ]
    apk_path = None
    for c in candidates:
        if os.path.exists(c):
            apk_path = c
            break

    if not apk_path:
        print(f"[!] APK not found: {app['apk']}")
        return False

    size_mb = os.path.getsize(apk_path) / (1024 * 1024)
    print(f"[+] Debug APK generated: {apk_path} ({size_mb:.2f} MB)")

    print(f"[*] Installing {app['name']} to {DEVICE}...")
    install_cmd = f'adb -s {DEVICE} install -r -d "{apk_path}"'
    i_res = subprocess.run(install_cmd, shell=True, capture_output=True, text=True)
    out = (i_res.stdout + i_res.stderr).strip()
    print(f"    Install result: {out}")
    return 'Success' in out

def main():
    print(f"=== GAGE Multi-App DEBUG Build & Install to {DEVICE} ===")
    results = {}
    for app in APPS:
        ok = build_and_install(app)
        results[app['name']] = 'INSTALLED' if ok else 'FAILED'

    print("\n=======================================================")
    print("=== SUMMARY INSTALL DEBUG APKS ===")
    for name, status in results.items():
        print(f"  * {name}: {status}")
    print("=======================================================")

if __name__ == '__main__':
    main()
