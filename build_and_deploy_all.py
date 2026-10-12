#!/usr/bin/env python3
"""
Build all 4 APKs (Customer, Merchant, Driver, Admin) and install all 4 to phone via ADB Wireless.
"""

import os
import sys
import subprocess
import time

PROJECT_DIR = os.path.dirname(os.path.abspath(__file__))
APP_DIR = os.path.join(PROJECT_DIR, 'gage-app')
OUT_DIR = os.path.join(PROJECT_DIR, 'release_apks')
PHONE_IP = '192.168.137.212:40291'

APPS = [
    {
        'key': 'customer',
        'entry': 'lib/main_customer.dart',
        'name': 'GAGE Delivery (User)',
        'pkg': 'com.gage.customer',
        'apk': 'gage-customer-release.apk',
    },
    {
        'key': 'merchant',
        'entry': 'lib/main_merchant.dart',
        'name': 'GAGE Merchant (Dapur)',
        'pkg': 'com.gage.merchant',
        'apk': 'gage-merchant-release.apk',
    },
    {
        'key': 'driver',
        'entry': 'lib/main_driver.dart',
        'name': 'GAGE Driver (Kurir)',
        'pkg': 'com.gage.driver',
        'apk': 'gage-driver-release.apk',
    },
    {
        'key': 'admin',
        'entry': 'lib/main_admin.dart',
        'name': 'GAGE Admin (Kecamatan)',
        'pkg': 'com.gage.admin',
        'apk': 'gage-admin-release.apk',
    },
]

def build_app(app):
    apk_path = os.path.join(OUT_DIR, app['apk'])
    if os.path.exists(apk_path):
        print(f"[*] APK already exists: {app['apk']} ({os.path.getsize(apk_path)/(1024*1024):.1f} MB)")
        return True

    print(f"\n=======================================================")
    print(f"[*] Building {app['name']} [{app['pkg']}]")
    print(f"=======================================================\n")

    cmd = f"flutter build apk --release --flavor {app['key']} -t {app['entry']}"
    res = subprocess.run(cmd, cwd=APP_DIR, shell=True)
    if res.returncode != 0:
        print(f"[!] FAILED building {app['key']}")
        return False

    gradle_out = os.path.join(APP_DIR, 'build', 'app', 'outputs', 'flutter-apk', f"app-{app['key']}-release.apk")
    if not os.path.exists(gradle_out):
        gradle_out = os.path.join(APP_DIR, 'build', 'app', 'outputs', 'flutter-apk', 'app-release.apk')

    if os.path.exists(gradle_out):
        os.makedirs(OUT_DIR, exist_ok=True)
        import shutil
        shutil.copy2(gradle_out, apk_path)
        print(f"[+] Built {app['apk']}")
        return True
    return False

def install_app_adb(app):
    apk_path = os.path.join(OUT_DIR, app['apk'])
    if not os.path.exists(apk_path):
        print(f"[!] Cannot install {app['apk']}: file missing")
        return False

    print(f"[*] Installing {app['name']} to phone ({PHONE_IP})...")
    cmd = f'adb -s {PHONE_IP} install -r "{apk_path}"'
    res = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    out = res.stdout + res.stderr
    print(f"    Output: {out.strip()}")
    return 'Success' in out

def main():
    print("[1] Building any missing APKs...")
    for app in APPS:
        if not build_app(app):
            print(f"[!] Aborting: Failed to build {app['key']}")
            sys.exit(1)

    print("\n[2] Connecting to ADB Wireless...")
    subprocess.run("adb disconnect", shell=True)
    subprocess.run("adb kill-server", shell=True)
    time.sleep(1)
    subprocess.run(f"adb connect {PHONE_IP}", shell=True)
    time.sleep(2)

    print("\n[3] Installing all 4 APKs to phone...")
    for app in APPS:
        install_app_adb(app)

    print("\n[V] ALL 4 APKS PROCESSED!")

if __name__ == '__main__':
    main()
