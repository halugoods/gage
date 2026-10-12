#!/usr/bin/env python3
"""
GAGE Multi-App Release Build Pipeline
Builds 4 separate standalone APKs:
  1. customer -> com.gage.customer ("GAGE Delivery")
  2. merchant -> com.gage.merchant ("GAGE Merchant")
  3. driver   -> com.gage.driver   ("GAGE Driver")
  4. admin    -> com.gage.admin    ("GAGE Admin")
"""

import sys
import os
import subprocess
import shutil

PROJECT_DIR = os.path.dirname(os.path.abspath(__file__))
APP_DIR = os.path.join(PROJECT_DIR, 'gage-app')
OUT_DIR = os.path.join(PROJECT_DIR, 'release_apks')

FLAVORS = {
    'customer': {
        'entry': 'lib/main_customer.dart',
        'name': 'GAGE Delivery (User)',
        'pkg': 'com.gage.customer',
        'output_name': 'gage-customer-release.apk',
    },
    'merchant': {
        'entry': 'lib/main_merchant.dart',
        'name': 'GAGE Merchant (Dapur)',
        'pkg': 'com.gage.merchant',
        'output_name': 'gage-merchant-release.apk',
    },
    'driver': {
        'entry': 'lib/main_driver.dart',
        'name': 'GAGE Driver (Kurir)',
        'pkg': 'com.gage.driver',
        'output_name': 'gage-driver-release.apk',
    },
    'admin': {
        'entry': 'lib/main_admin.dart',
        'name': 'GAGE Admin (Kecamatan Hub)',
        'pkg': 'com.gage.admin',
        'output_name': 'gage-admin-release.apk',
    },
}

def build_flavor(flavor_key):
    info = FLAVORS[flavor_key]
    print(f"\n=======================================================")
    print(f"[*] Building {info['name']} [{info['pkg']}]")
    print(f"[*] Entry: {info['entry']}")
    print(f"=======================================================\n")

    cmd = [
        'flutter', 'build', 'apk',
        '--release',
        '--flavor', flavor_key,
        '-t', info['entry'],
    ]

    res = subprocess.run(cmd, cwd=APP_DIR, shell=True)
    if res.returncode != 0:
        print(f"[!] FAILED building {flavor_key}!")
        return False

    # Locate generated apk
    gradle_out = os.path.join(APP_DIR, 'build', 'app', 'outputs', 'flutter-apk', f'app-{flavor_key}-release.apk')
    if not os.path.exists(gradle_out):
        # Fallback check
        gradle_out = os.path.join(APP_DIR, 'build', 'app', 'outputs', 'flutter-apk', 'app-release.apk')

    if os.path.exists(gradle_out):
        os.makedirs(OUT_DIR, exist_ok=True)
        dest = os.path.join(OUT_DIR, info['output_name'])
        shutil.copy2(gradle_out, dest)
        size_mb = os.path.getsize(dest) / (1024 * 1024)
        print(f"\n[+] SUCCESS! Output: {dest} ({size_mb:.2f} MB)")
        return True
    else:
        print(f"[!] Warning: APK output file not found at {gradle_out}")
        return False

def main():
    target = sys.argv[1].lower() if len(sys.argv) > 1 else 'customer'
    if target == 'all':
        success = True
        for f in FLAVORS:
            if not build_flavor(f):
                success = False
                break
        if success:
            print("\n[V] ALL 4 APKs BUILT SUCCESSFULLY!")
            print(f"Files saved in: {OUT_DIR}")
    elif target in FLAVORS:
        build_flavor(target)
    else:
        print(f"Unknown flavor '{target}'. Choose from: customer, merchant, driver, admin, all")

if __name__ == '__main__':
    main()
