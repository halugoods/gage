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

    # 1. Clean all known stale APK output locations
    possible_old_apks = [
        os.path.join(APP_DIR, 'build', 'app', 'outputs', 'flutter-apk', f'app-{flavor_key}-release.apk'),
        os.path.join(APP_DIR, 'build', 'app', 'outputs', 'flutter-apk', 'app-release.apk'),
        os.path.join(APP_DIR, 'build', 'app', 'outputs', 'apk', flavor_key, 'release', f'app-{flavor_key}-release.apk'),
    ]
    for old_path in possible_old_apks:
        if os.path.exists(old_path):
            try:
                os.remove(old_path)
                print(f"[*] Removed stale APK: {old_path}")
            except Exception as e:
                print(f"[!] Warning removing old APK: {e}")

    os.makedirs(OUT_DIR, exist_ok=True)
    dest = os.path.join(OUT_DIR, info['output_name'])
    if os.path.exists(dest):
        try:
            os.remove(dest)
            print(f"[*] Removed stale destination APK: {dest}")
        except Exception as e:
            print(f"[!] Warning removing old dest APK: {e}")

    # 2. Build command
    cmd_str = f"flutter build apk --release --flavor {flavor_key} -t {info['entry']}"
    print(f"[*] Running: {cmd_str}")
    res = subprocess.run(cmd_str, cwd=APP_DIR, shell=True)
    if res.returncode != 0:
        print(f"[!] FAILED building {flavor_key}!")
        return False

    # 3. Locate generated APK from possible output locations
    candidate_apks = [
        os.path.join(APP_DIR, 'build', 'app', 'outputs', 'flutter-apk', f'app-{flavor_key}-release.apk'),
        os.path.join(APP_DIR, 'build', 'app', 'outputs', 'apk', flavor_key, 'release', f'app-{flavor_key}-release.apk'),
        os.path.join(APP_DIR, 'build', 'app', 'outputs', 'flutter-apk', 'app-release.apk'),
    ]
    gradle_out = None
    for cand in candidate_apks:
        if os.path.exists(cand):
            gradle_out = cand
            break

    if gradle_out and os.path.exists(gradle_out):
        shutil.copy2(gradle_out, dest)
        size_mb = os.path.getsize(dest) / (1024 * 1024)
        print(f"\n[+] SUCCESS! Output: {dest} ({size_mb:.2f} MB)")

        # 4. Forensic verification of compiled libapp.so
        try:
            import zipfile
            with zipfile.ZipFile(dest, 'r') as z:
                so_names = [n for n in z.namelist() if 'libapp.so' in n]
                if so_names:
                    sample_so = so_names[0]
                    content = z.read(sample_so)
                    has_sim = b'Simulasi Pindai' in content
                    has_buat = b'Buat Pembayaran' in content
                    print(f"[*] Forensic Verification ({sample_so}):")
                    print(f"    - 'Simulasi Pindai' present : {has_sim} (Expected: False)")
                    print(f"    - 'Buat Pembayaran' present : {has_buat} (Expected: True)")
                    if has_sim:
                        print("[!] CRITICAL WARNING: 'Simulasi Pindai' is still found in libapp.so!")
                    elif has_buat:
                        print("[V] VERIFIED: APK successfully contains latest clean build changes!")
        except Exception as e:
            print(f"[*] Forensic check skipped: {e}")

        return True
    else:
        print(f"[!] Warning: APK output file not found in any candidate path!")
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
