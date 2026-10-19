import os
import sys

# Ensure UTF-8 output on Windows console
if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding='utf-8', errors='replace')
        sys.stderr.reconfigure(encoding='utf-8', errors='replace')
    except Exception:
        pass

import json
import time
import queue
import shutil
import tempfile
import threading
import subprocess
from http.server import ThreadingHTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs

# Configuration
PORT = 4055
GAGE_ROOT = r"c:\Users\ertyui\ZCodeProject\gage"
GAGE_APP_DIR = os.path.join(GAGE_ROOT, "gage-app")
TOOLS_DIR = os.path.join(GAGE_ROOT, "gage-tools")
INDEX_HTML_PATH = os.path.join(TOOLS_DIR, "index.html")

FLUTTER_BAT = r"C:\flutter\bin\flutter.bat"
if not os.path.exists(FLUTTER_BAT):
    FLUTTER_BAT = shutil.which("flutter") or "flutter"

ADB_EXE = r"C:\Users\ertyui\android_sdk\platform-tools\adb.exe"
if not os.path.exists(ADB_EXE):
    ADB_EXE = shutil.which("adb") or "adb"

SCRCPY_EXE = r"C:\Users\ertyui\AppData\Local\Microsoft\WinGet\Packages\Genymobile.scrcpy_Microsoft.Winget.Source_8wekyb3d8bbwe\scrcpy-win64-v4.1\scrcpy.exe"
if not os.path.exists(SCRCPY_EXE):
    SCRCPY_EXE = shutil.which("scrcpy") or "scrcpy"

# State
PROCESS_LOCK = threading.RLock()
FLUTTER_PROCESS = None
FLUTTER_TARGET = "lib/main.dart"
FLUTTER_DEVICE = None
FLUTTER_STATUS = "idle"  # idle, building, running, reloading, stopped
LOG_BUFFER = []
SUBSCRIBERS = set()

def emit_log(line, log_type=None):
    global FLUTTER_STATUS
    if log_type is None:
        lower = line.lower()
        if "error" in lower or "exception" in lower or "failure" in lower or "fatal" in lower:
            log_type = "error"
        elif "reloaded" in lower or "restarted" in lower or "all tests passed" in lower:
            log_type = "success"
            if "reloaded" in lower or "restarted" in lower:
                FLUTTER_STATUS = "running"
        elif "syncing files" in lower or "performing hot" in lower:
            log_type = "action"
            FLUTTER_STATUS = "reloading"
        elif "flutter run key commands" in lower or "running with sound null safety" in lower or "flutter:" in lower or "to hot reload" in lower or "is being served at" in lower or "application running" in lower:
            log_type = "info"
            FLUTTER_STATUS = "running"
        elif "warning" in lower:
            log_type = "warning"
        else:
            log_type = "default"

    entry = {
        "time": time.strftime("%H:%M:%S"),
        "text": line,
        "type": log_type
    }
    with PROCESS_LOCK:
        LOG_BUFFER.append(entry)
        if len(LOG_BUFFER) > 4000:
            del LOG_BUFFER[0:1000]
        dead = []
        for q in SUBSCRIBERS:
            try:
                q.put_nowait(entry)
            except Exception:
                dead.append(q)
        for d in dead:
            SUBSCRIBERS.discard(d)

def read_process_stdout(proc):
    global FLUTTER_PROCESS, FLUTTER_STATUS
    try:
        for raw_line in iter(proc.stdout.readline, ''):
            line = raw_line.rstrip('\r\n')
            emit_log(line)
    except Exception as e:
        emit_log(f"[Error reading stdout: {e}]", "error")
    finally:
        try:
            proc.stdout.close()
        except Exception:
            pass
        returncode = proc.wait()
        with PROCESS_LOCK:
            if FLUTTER_PROCESS == proc:
                FLUTTER_PROCESS = None
                FLUTTER_STATUS = "stopped"
        emit_log(f"--- Flutter process exited (exit code: {returncode}) ---", "warning" if returncode != 0 else "info")

def start_flutter(device_id, target_file="lib/main.dart", flavor=None):
    global FLUTTER_PROCESS, FLUTTER_TARGET, FLUTTER_DEVICE, FLUTTER_STATUS
    if not flavor:
        if "driver" in target_file.lower():
            flavor = "driver"
        elif "merchant" in target_file.lower():
            flavor = "merchant"
        elif "admin" in target_file.lower():
            flavor = "admin"
        else:
            flavor = "customer"

    with PROCESS_LOCK:
        if FLUTTER_PROCESS and FLUTTER_PROCESS.poll() is None:
            return False, "Flutter is already running! Click Stop (q) first."

        cmd = [FLUTTER_BAT, "run", "-d", device_id, "-t", target_file, "--flavor", flavor, "--device-user", "0"]
        FLUTTER_TARGET = f"{target_file} ({flavor})"
        FLUTTER_DEVICE = device_id
        FLUTTER_STATUS = "building"

    emit_log(f"=== Starting Flutter App ===", "info")
    emit_log(f"Command: {' '.join(cmd)}", "info")
    emit_log(f"Working Dir: {GAGE_APP_DIR}", "info")

    try:
        proc = subprocess.Popen(
            cmd,
            cwd=GAGE_APP_DIR,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            encoding="utf-8",
            errors="replace",
            bufsize=1
        )
        with PROCESS_LOCK:
            FLUTTER_PROCESS = proc

        t = threading.Thread(target=read_process_stdout, args=(proc,), daemon=True)
        t.start()
        return True, "Flutter process started successfully"
    except Exception as e:
        with PROCESS_LOCK:
            FLUTTER_STATUS = "stopped"
        emit_log(f"Failed to launch Flutter: {e}", "error")
        return False, str(e)

def send_flutter_command(char):
    global FLUTTER_PROCESS
    with PROCESS_LOCK:
        if not FLUTTER_PROCESS or FLUTTER_PROCESS.poll() is not None:
            return False, "Flutter is not currently running"
        try:
            FLUTTER_PROCESS.stdin.write(f"{char}\n")
            FLUTTER_PROCESS.stdin.flush()
            emit_log(f"[User Action] Sent '{char}' to Flutter stdin", "action")
            return True, f"Sent '{char}' successfully"
        except Exception as e:
            emit_log(f"Error sending command: {e}", "error")
            return False, str(e)

def stop_flutter():
    global FLUTTER_PROCESS, FLUTTER_STATUS
    with PROCESS_LOCK:
        if not FLUTTER_PROCESS or FLUTTER_PROCESS.poll() is not None:
            FLUTTER_STATUS = "stopped"
            return True, "Flutter is not running"
        proc = FLUTTER_PROCESS
        try:
            proc.stdin.write("q\n")
            proc.stdin.flush()
            emit_log("[User Action] Sent 'q' to stop Flutter", "action")
        except Exception:
            pass

    # Give it 3 seconds to exit gracefully
    for _ in range(30):
        if proc.poll() is not None:
            break
        time.sleep(0.1)

    if proc.poll() is None:
        emit_log("Process did not exit promptly, terminating...", "warning")
        try:
            proc.terminate()
        except Exception:
            pass
        time.sleep(0.5)
        if proc.poll() is None:
            try:
                proc.kill()
            except Exception:
                pass

    with PROCESS_LOCK:
        FLUTTER_PROCESS = None
        FLUTTER_STATUS = "stopped"
    return True, "Flutter stopped"

def run_flutter_task(cmd_args, title):
    def _run():
        full_cmd = [FLUTTER_BAT] + cmd_args
        emit_log(f"=== Running {title} ===", "info")
        emit_log(f"Command: {' '.join(full_cmd)}", "info")
        try:
            p = subprocess.Popen(
                full_cmd,
                cwd=GAGE_APP_DIR,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
                encoding="utf-8",
                errors="replace"
            )
            for raw in p.stdout:
                line = raw.rstrip('\r\n')
                emit_log(line)
            p.wait()
            emit_log(f"=== {title} finished with code {p.returncode} ===", "success" if p.returncode == 0 else "error")
        except Exception as e:
            emit_log(f"=== {title} execution failed: {e} ===", "error")
    t = threading.Thread(target=_run, daemon=True)
    t.start()

CACHED_DEVICES = []
LAST_DEVICE_SCAN = 0.0
DEVICE_LOCK = threading.Lock()

def get_adb_devices(force_refresh=False):
    global CACHED_DEVICES, LAST_DEVICE_SCAN
    now = time.time()
    with DEVICE_LOCK:
        if not force_refresh and (now - LAST_DEVICE_SCAN) < 8.0 and CACHED_DEVICES:
            return list(CACHED_DEVICES)
    try:
        res = subprocess.run([ADB_EXE, "devices", "-l"], capture_output=True, text=True, errors="replace", timeout=5)
        devices = []
        for line in res.stdout.strip().splitlines()[1:]:
            line = line.strip()
            if not line:
                continue
            parts = line.split()
            dev_id = parts[0]
            status = parts[1] if len(parts) > 1 else "unknown"
            model = dev_id
            for part in parts[2:]:
                if part.startswith("model:"):
                    model = part.split(":", 1)[1]
            devices.append({
                "id": dev_id,
                "status": status,
                "model": model,
                "is_wireless": ":" in dev_id,
                "raw": line
            })
        with DEVICE_LOCK:
            CACHED_DEVICES = devices
            LAST_DEVICE_SCAN = now
        return devices
    except Exception as e:
        with DEVICE_LOCK:
            return list(CACHED_DEVICES)

def capture_screenshot(device_id):
    # Rule 8: Anti-Corrupt protocol: save on device first then pull
    with tempfile.NamedTemporaryFile(suffix=".png", delete=False) as tmp:
        tmp_path = tmp.name
    try:
        display_id = None
        try:
            sf = subprocess.check_output([ADB_EXE, "-s", device_id, "shell", "dumpsys SurfaceFlinger --display-id"], text=True, timeout=5)
            for line in sf.splitlines():
                if "HWC display 0" in line:
                    parts = line.split()
                    if len(parts) >= 2 and parts[1].isdigit():
                        display_id = parts[1]
                        break
        except Exception:
            pass

        if display_id:
            cmd_cap = [ADB_EXE, "-s", device_id, "shell", f"screencap -p -d {display_id} /sdcard/gage_screen.png"]
        else:
            cmd_cap = [ADB_EXE, "-s", device_id, "shell", "screencap -p /sdcard/gage_screen.png"]

        subprocess.run(cmd_cap, check=True, timeout=15)
        subprocess.run([ADB_EXE, "-s", device_id, "pull", "/sdcard/gage_screen.png", tmp_path], check=True, timeout=15)
        subprocess.run([ADB_EXE, "-s", device_id, "shell", "rm /sdcard/gage_screen.png"], timeout=8)
        with open(tmp_path, "rb") as f:
            data = f.read()
        return data, "image/png"
    except Exception as e:
        emit_log(f"Screenshot capture error: {e}", "error")
        return None, str(e)
    finally:
        if os.path.exists(tmp_path):
            try:
                os.remove(tmp_path)
            except Exception:
                pass

def launch_scrcpy(device_id):
    try:
        cmd = [SCRCPY_EXE, "-s", device_id, "--window-title", f"GAGE - {device_id}"]
        subprocess.Popen(cmd)
        emit_log(f"Launched Scrcpy mirror for device {device_id}", "info")
        return True, "Scrcpy mirror started"
    except Exception as e:
        emit_log(f"Failed to launch Scrcpy: {e}", "error")
        return False, str(e)


class GageToolsHandler(BaseHTTPRequestHandler):
    def send_json(self, data, code=200):
        body = json.dumps(data).encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        self.wfile.write(body)

    def do_OPTIONS(self):
        self.send_response(204)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.end_headers()

    def do_GET(self):
        parsed = urlparse(self.path)
        path = parsed.path
        query = parse_qs(parsed.query)

        if path == "/" or path == "/index.html":
            if os.path.exists(INDEX_HTML_PATH):
                with open(INDEX_HTML_PATH, "rb") as f:
                    content = f.read()
                self.send_response(200)
                self.send_header("Content-Type", "text/html; charset=utf-8")
                self.send_header("Content-Length", str(len(content)))
                self.end_headers()
                self.wfile.write(content)
            else:
                self.send_error(404, "index.html not found")

        elif path == "/api/status":
            with PROCESS_LOCK:
                is_running = FLUTTER_PROCESS is not None and FLUTTER_PROCESS.poll() is None
                pid = FLUTTER_PROCESS.pid if is_running else None
                status = FLUTTER_STATUS if is_running else "stopped"
                target = FLUTTER_TARGET
                device = FLUTTER_DEVICE
            devices = get_adb_devices(force_refresh=False)
            self.send_json({
                "running": is_running,
                "status": status,
                "pid": pid,
                "target": target,
                "device": device,
                "devices": devices
            })

        elif path == "/api/devices":
            devices = get_adb_devices(force_refresh=True)
            self.send_json({"devices": devices})

        elif path == "/api/adb/screenshot":
            device_id = query.get("device", [None])[0]
            if not device_id:
                devices = get_adb_devices()
                if devices:
                    device_id = devices[0]["id"]
            if not device_id:
                self.send_json({"error": "No device connected"}, 400)
                return
            data, err = capture_screenshot(device_id)
            if data:
                self.send_response(200)
                self.send_header("Content-Type", "image/png")
                self.send_header("Content-Length", str(len(data)))
                self.send_header("Cache-Control", "no-cache")
                self.end_headers()
                self.wfile.write(data)
            else:
                self.send_json({"error": f"Screenshot failed: {err}"}, 500)

        elif path == "/api/flutter/logs":
            self.send_response(200)
            self.send_header("Content-Type", "text/event-stream")
            self.send_header("Cache-Control", "no-cache")
            self.send_header("Connection", "keep-alive")
            self.send_header("Access-Control-Allow-Origin", "*")
            self.end_headers()

            q = queue.Queue()
            with PROCESS_LOCK:
                SUBSCRIBERS.add(q)
                backlog = list(LOG_BUFFER)

            # Send backlog
            for item in backlog:
                msg = f"data: {json.dumps(item)}\n\n"
                try:
                    self.wfile.write(msg.encode("utf-8"))
                except Exception:
                    with PROCESS_LOCK:
                        SUBSCRIBERS.discard(q)
                    return
            try:
                self.wfile.flush()
            except Exception:
                pass

            # Stream live updates
            while True:
                try:
                    entry = q.get(timeout=25.0)
                    msg = f"data: {json.dumps(entry)}\n\n"
                    self.wfile.write(msg.encode("utf-8"))
                    self.wfile.flush()
                except queue.Empty:
                    # Ping / keep-alive comment
                    try:
                        self.wfile.write(b": ping\n\n")
                        self.wfile.flush()
                    except Exception:
                        break
                except Exception:
                    break

            with PROCESS_LOCK:
                SUBSCRIBERS.discard(q)

        elif path == "/api/flutter/recent_logs":
            limit = int(query.get("limit", [50])[0])
            with PROCESS_LOCK:
                recent = list(LOG_BUFFER)[-limit:]
            self.send_json({"logs": recent})

        else:
            self.send_error(404, "Endpoint not found")

    def do_POST(self):
        try:
            self._handle_post()
        except Exception as e:
            emit_log(f"Server error in POST: {e}", "error")
            self.send_json({"error": str(e)}, 500)

    def _handle_post(self):
        parsed = urlparse(self.path)
        path = parsed.path

        content_length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(content_length) if content_length > 0 else b"{}"
        try:
            params = json.loads(body.decode("utf-8")) if body else {}
        except Exception:
            params = {}

        if path == "/api/adb/connect":
            target = params.get("target", "").strip()
            if not target:
                self.send_json({"error": "Target IP:Port is required"}, 400)
                return
            emit_log(f"Running: adb connect {target}...", "info")
            try:
                out = subprocess.check_output([ADB_EXE, "connect", target], text=True, errors="replace", timeout=10)
                emit_log(out.strip(), "success" if "connected" in out.lower() else "warning")
                self.send_json({"success": True, "message": out.strip()})
            except Exception as e:
                emit_log(f"ADB connect error: {e}", "error")
                self.send_json({"error": str(e)}, 500)

        elif path == "/api/adb/disconnect":
            target = params.get("target", "").strip()
            if not target:
                self.send_json({"error": "Target is required"}, 400)
                return
            emit_log(f"Running: adb disconnect {target}...", "info")
            try:
                out = subprocess.check_output([ADB_EXE, "disconnect", target], text=True, errors="replace", timeout=10)
                emit_log(out.strip(), "info")
                self.send_json({"success": True, "message": out.strip()})
            except Exception as e:
                self.send_json({"error": str(e)}, 500)

        elif path == "/api/adb/pair":
            target = params.get("target", "").strip()
            code = params.get("code", "").strip()
            if not target or not code:
                self.send_json({"error": "Target IP:Port and 6-digit code are required"}, 400)
                return
            emit_log(f"Running: adb pair {target} <code>...", "info")
            try:
                out = subprocess.check_output([ADB_EXE, "pair", target, code], text=True, errors="replace", timeout=15)
                emit_log(out.strip(), "success" if "successful" in out.lower() else "warning")
                self.send_json({"success": True, "message": out.strip()})
            except Exception as e:
                emit_log(f"ADB pair error: {e}", "error")
                self.send_json({"error": str(e)}, 500)

        elif path == "/api/adb/scrcpy":
            device_id = params.get("device", "").strip()
            if not device_id:
                devices = get_adb_devices(force_refresh=False)
                if devices:
                    device_id = devices[0]["id"]
            if not device_id:
                self.send_json({"error": "No device selected"}, 400)
                return
            ok, msg = launch_scrcpy(device_id)
            self.send_json({"success": ok, "message": msg})

        elif path == "/api/flutter/start":
            device_id = params.get("device", "").strip()
            target = params.get("target", "lib/main.dart").strip()
            flavor = params.get("flavor", "").strip() or None
            if not device_id:
                devices = get_adb_devices(force_refresh=False)
                if devices:
                    device_id = devices[0]["id"]
            if not device_id:
                self.send_json({"error": "No ADB device connected or selected"}, 400)
                return
            ok, msg = start_flutter(device_id, target, flavor)
            self.send_json({"success": ok, "message": msg})

        elif path == "/api/flutter/reload":
            ok, msg = send_flutter_command("r")
            self.send_json({"success": ok, "message": msg})

        elif path == "/api/flutter/restart":
            ok, msg = send_flutter_command("R")
            self.send_json({"success": ok, "message": msg})

        elif path == "/api/flutter/stop":
            ok, msg = stop_flutter()
            self.send_json({"success": ok, "message": msg})

        elif path == "/api/flutter/command":
            cmd_char = params.get("char", "").strip()
            if not cmd_char:
                self.send_json({"error": "Command char is required"}, 400)
                return
            ok, msg = send_flutter_command(cmd_char)
            self.send_json({"success": ok, "message": msg})

        elif path == "/api/flutter/task":
            action = params.get("action", "")
            if action == "clean":
                run_flutter_task(["clean"], "Flutter Clean")
                self.send_json({"success": True, "message": "Flutter Clean started"})
            elif action == "pub_get":
                run_flutter_task(["pub", "get"], "Flutter Pub Get")
                self.send_json({"success": True, "message": "Flutter Pub Get started"})
            elif action == "clean_get":
                def _clean_get():
                    run_flutter_task(["clean"], "Flutter Clean")
                    time.sleep(2)
                    run_flutter_task(["pub", "get"], "Flutter Pub Get")
                threading.Thread(target=_clean_get, daemon=True).start()
                self.send_json({"success": True, "message": "Clean & Pub Get sequence started"})
            elif action == "analyze":
                run_flutter_task(["analyze"], "Flutter Analyze")
                self.send_json({"success": True, "message": "Flutter Analyze started"})
            elif action == "test":
                run_flutter_task(["test"], "Flutter Test")
                self.send_json({"success": True, "message": "Flutter Test started"})
            elif action == "deploy_all":
                device_id = params.get("device", "").strip()
                def _deploy():
                    cmd = [sys.executable, "-u", os.path.join(GAGE_APP_DIR, "deploy_debug_all.py")]
                    if device_id:
                        cmd.append(device_id)
                    emit_log(f"=== Starting 4 APKs Deployment to {device_id or 'auto-device'} ===", "info")
                    try:
                        p = subprocess.Popen(
                            cmd,
                            cwd=GAGE_APP_DIR,
                            stdout=subprocess.PIPE,
                            stderr=subprocess.STDOUT,
                            text=True,
                            encoding="utf-8",
                            errors="replace"
                        )
                        for raw in p.stdout:
                            line = raw.rstrip('\r\n')
                            emit_log(line)
                        p.wait()
                        emit_log(f"=== Deployment finished with code {p.returncode} ===", "success" if p.returncode == 0 else "error")
                    except Exception as e:
                        emit_log(f"=== Deployment failed: {e} ===", "error")
                threading.Thread(target=_deploy, daemon=True).start()
                self.send_json({"success": True, "message": "Deployment started"})
            else:
                self.send_json({"error": f"Unknown action {action}"}, 400)

        elif path == "/api/flutter/clear_logs":
            with PROCESS_LOCK:
                LOG_BUFFER.clear()
            self.send_json({"success": True, "message": "Logs cleared"})

        else:
            self.send_error(404, "Endpoint not found")

    def log_message(self, format, *args):
        # Suppress noisy SSE ping / status polling HTTP logs in python console
        if "/api/status" in args[0] or "/api/flutter/logs" in args[0]:
            return
        super().log_message(format, *args)


class ExclusiveServer(ThreadingHTTPServer):
    allow_reuse_address = True


def run_server():
    server = ExclusiveServer(("0.0.0.0", PORT), GageToolsHandler)
    print(f"=====================================================")
    print(f"[GAGE] Local Control Tools running on http://localhost:{PORT}")
    print(f"   - Target App: {GAGE_APP_DIR}")
    print(f"   - ADB Binary: {ADB_EXE}")
    print(f"   - Flutter:    {FLUTTER_BAT}")
    print(f"=====================================================")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nStopping server...")
        stop_flutter()
        server.server_close()

if __name__ == "__main__":
    run_server()
