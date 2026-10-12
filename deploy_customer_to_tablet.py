import os
import sys
import subprocess
import time
import shutil

PROJECT_DIR = os.path.dirname(os.path.abspath(__file__))
APP_DIR = os.path.join(PROJECT_DIR, 'gage-app')
OUT_DIR = os.path.join(PROJECT_DIR, 'release_apks')
TABLET_IP = '192.168.1.4:40395'
PKG_NAME = 'com.gage.customer'

print("=" * 60)
print("[*] MEMULAI FRESH CLEAN BUILD & DEPLOY GAGE CUSTOMER")
print(f"[*] Target ADB Wireless: {TABLET_IP}")
print(f"[*] Package: {PKG_NAME}")
print("=" * 60)

# 1. Build APK Customer Release (Fresh dari source murni)
build_cmd = "flutter build apk --release --flavor customer -t lib/main_customer.dart"
print(f"\n[*] Menjalankan fresh build APK: {build_cmd}")
res = subprocess.run(build_cmd, cwd=APP_DIR, shell=True)
if res.returncode != 0:
    print("[!] ERROR: Gagal melakukan build APK!")
    sys.exit(1)

apk_src = os.path.join(APP_DIR, 'build', 'app', 'outputs', 'flutter-apk', 'app-customer-release.apk')
if not os.path.exists(apk_src):
    apk_src = os.path.join(APP_DIR, 'build', 'app', 'outputs', 'flutter-apk', 'app-release.apk')

if not os.path.exists(apk_src):
    print(f"[!] ERROR: File APK tidak ditemukan di {apk_src}")
    sys.exit(1)

os.makedirs(OUT_DIR, exist_ok=True)
apk_dest = os.path.join(OUT_DIR, 'gage-customer-release.apk')
shutil.copy2(apk_src, apk_dest)
size_mb = os.path.getsize(apk_dest) / (1024 * 1024)
print(f"\n[+] SUCCESS Build APK Fresh: {apk_dest} ({size_mb:.2f} MB)")

# 2. Connect ADB Wireless
print(f"\n[*] Menghubungkan ke ADB Wireless {TABLET_IP}...")
subprocess.run(f"adb connect {TABLET_IP}", shell=True)

# 3. Install APK ke Device
print(f"\n[*] Menginstall APK fresh ke device ({TABLET_IP})...")
install_cmd = f"adb -s {TABLET_IP} install -r --user 0 \"{apk_dest}\""
install_res = subprocess.run(install_cmd, shell=True)
if install_res.returncode != 0:
    print("[*] Fallback install tanpa --user 0...")
    subprocess.run(f"adb -s {TABLET_IP} install -r \"{apk_dest}\"", shell=True)

# 4. Restart Aplikasi di Device (Force Stop lalu Launch)
print(f"\n[*] Me-restart aplikasi {PKG_NAME} di device...")
subprocess.run(f"adb -s {TABLET_IP} shell am force-stop {PKG_NAME}", shell=True)
time.sleep(1)
subprocess.run(f"adb -s {TABLET_IP} shell monkey -p {PKG_NAME} -c android.intent.category.LAUNCHER 1", shell=True)

print("\n" + "=" * 60)
print("[+] SELESAI! APK Fresh berhasil terpasang dan aplikasi telah terbuka.")
print("=" * 60)
