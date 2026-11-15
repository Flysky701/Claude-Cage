"""Local-only proof for an owned x64 blocking-connect adapter, not app admission.

No real proxy credentials or personal files are read. WFP must already be active.
All experiment data and the disabled test box are retained for inspection.
"""
import argparse
import ctypes
from datetime import datetime, timezone
import hashlib
import hmac
import json
import os
from pathlib import Path
import secrets
import selectors
import shutil
import socket
import socketserver
import struct
import subprocess
import sys
import threading
import time
import uuid


HERE = Path(__file__).resolve().parent
REPO = HERE.parents[3]
NO_WINDOW = getattr(subprocess, "CREATE_NO_WINDOW", 0)


def notify(phase, **extra):
    print(json.dumps({"phase": phase, **extra}, ensure_ascii=False), flush=True)


def save(path, value):
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    os.replace(temporary, path)


def build(output):
    program86 = Path(os.environ.get("ProgramFiles(x86)", r"C:\Program Files (x86)"))
    vswhere = program86 / "Microsoft Visual Studio/Installer/vswhere.exe"
    result = subprocess.run([str(vswhere), "-latest", "-products", "*", "-requires",
                             "Microsoft.VisualStudio.Component.VC.Tools.x86.x64", "-find",
                             r"VC\Tools\MSVC\**\bin\Hostx64\x64\cl.exe"],
                            capture_output=True, text=True, check=True, creationflags=NO_WINDOW)
    compiler = Path(result.stdout.strip().splitlines()[0])
    msvc = compiler.parents[3]
    sdk = program86 / "Windows Kits/10"
    versions = sorted((sdk / "Include").glob("10.*"), key=lambda p: tuple(int(n) for n in p.name.split(".")))
    if not versions:
        raise RuntimeError("Windows SDK headers are missing")
    version = versions[-1].name
    includes = [msvc / "include", *[sdk / "Include" / version / kind for kind in ("ucrt", "shared", "um", "winrt")]]
    libraries = [msvc / "lib/x64", *[sdk / "Lib" / version / kind / "x64" for kind in ("ucrt", "um")]]
    environment = dict(os.environ, INCLUDE=os.pathsep.join(map(str, includes)), LIB=os.pathsep.join(map(str, libraries)))
    environment["PATH"] = str(compiler.parent) + os.pathsep + environment.get("PATH", "")
    binary = output / "bin"
    binary.mkdir()
    commands = [
        [str(compiler), "/nologo", "/O2", "/W4", "/MT", "/D_CRT_SECURE_NO_WARNINGS", "/LD",
         str(HERE / "sync_proxy.c"), "/Fe:CageSyncProxy.dll", "/link", "ws2_32.lib"],
        [str(compiler), "/nologo", "/O2", "/W4", "/MT", "/D_CRT_SECURE_NO_WARNINGS",
         str(HERE / "probe.c"), "/Fe:SyncParent.exe", "/link", "ws2_32.lib"],
    ]
    with (output / "build.log").open("w", encoding="utf-8") as log:
        for command in commands:
            result = subprocess.run(command, cwd=binary, env=environment, stdout=log, stderr=subprocess.STDOUT,
                                    creationflags=NO_WINDOW, timeout=60)
            if result.returncode:
                raise RuntimeError("Native build failed; inspect build.log")
    for image in ("SyncChild.exe", "SyncGrandchild.exe"):
        shutil.copy2(binary / "SyncParent.exe", binary / image)
    hashes = {path.name: hashlib.sha256(path.read_bytes()).hexdigest() for path in binary.glob("*.exe")}
    hashes["CageSyncProxy.dll"] = hashlib.sha256((binary / "CageSyncProxy.dll").read_bytes()).hexdigest()
    save(output / "build.json", {"compiler": str(compiler), "sdk": version, "sha256": hashes})
    return binary


def read_exact(connection, length):
    result = bytearray()
    while len(result) < length:
        block = connection.recv(length - len(result))
        if not block:
            raise EOFError("connection closed")
        result.extend(block)
    return bytes(result)


class TargetHandler(socketserver.StreamRequestHandler):
    def handle(self):
        self.connection.settimeout(15)
        try:
            while True:
                line = self.rfile.readline(256)
                if not line:
                    return
                if not line.endswith(b"\n") or len(line) > 240:
                    return
                challenge = line[:-1].decode("ascii")
                with self.server.lock:
                    self.server.requests.append(challenge)
                self.wfile.write(f"ACK:{self.server.target_id}:{challenge}\n".encode())
                self.wfile.flush()
        except (OSError, ValueError):
            pass


class Target(socketserver.ThreadingTCPServer):
    daemon_threads = True

    def __init__(self, target_id):
        self.target_id, self.requests = target_id, []
        self.lock = threading.Lock()
        super().__init__(("127.0.0.1", 0), TargetHandler)
        self.thread = threading.Thread(target=self.serve_forever, daemon=True)
        self.thread.start()


class SocksHandler(socketserver.BaseRequestHandler):
    def handle(self):
        remote = None
        connection = self.request
        connection.settimeout(5)
        with self.server.lock:
            self.server.connections.add(connection)
        try:
            if read_exact(connection, 3) != b"\x05\x01\x02":
                return
            connection.sendall(b"\x05\x02")
            version, length = read_exact(connection, 2)
            user = read_exact(connection, length)
            password = read_exact(connection, read_exact(connection, 1)[0])
            if version != 1 or not hmac.compare_digest(user, self.server.user) or not hmac.compare_digest(password, self.server.password):
                with self.server.lock:
                    self.server.events.append({"event": "auth-rejected"})
                connection.sendall(b"\x01\x01")
                return
            connection.sendall(b"\x01\x00")
            if read_exact(connection, 4) != b"\x05\x01\x00\x01":
                return
            destination = socket.inet_ntoa(read_exact(connection, 4))
            port = struct.unpack("!H", read_exact(connection, 2))[0]
            permitted = (destination, port) in self.server.allowed
            with self.server.lock:
                self.server.events.append({"event": "connect" if permitted else "target-rejected", "address": destination, "port": port})
            if not permitted:
                connection.sendall(b"\x05\x02\x00\x01\x00\x00\x00\x00\x00\x00")
                return
            remote = socket.create_connection((destination, port), timeout=3)
            with self.server.lock:
                self.server.connections.add(remote)
            connection.sendall(b"\x05\x00\x00\x01\x7f\x00\x00\x01\x00\x00")
            with selectors.DefaultSelector() as selector:
                selector.register(connection, selectors.EVENT_READ, remote)
                selector.register(remote, selectors.EVENT_READ, connection)
                while not self.server.cut.is_set():
                    for key, _ in selector.select(.1):
                        payload = key.fileobj.recv(8192)
                        if not payload:
                            return
                        key.data.sendall(payload)
        except (OSError, EOFError, ValueError):
            pass
        finally:
            for handle in (remote, connection):
                if handle is not None:
                    with self.server.lock:
                        self.server.connections.discard(handle)
                    handle.close()


class Socks(socketserver.ThreadingTCPServer):
    daemon_threads = True

    def __init__(self, targets):
        self.allowed = {target.server_address for target in targets}
        self.user, self.password = b"experiment", secrets.token_hex(24).encode()
        self.events, self.connections = [], set()
        self.lock, self.cut = threading.Lock(), threading.Event()
        self.stopped = False
        super().__init__(("127.0.0.1", 0), SocksHandler)
        self.thread = threading.Thread(target=self.serve_forever, daemon=True)
        self.thread.start()

    def disconnect(self):
        if self.stopped:
            return
        self.stopped = True
        self.cut.set()
        self.shutdown()
        self.server_close()
        with self.lock:
            handles = list(self.connections)
        for handle in handles:
            try:
                handle.shutdown(socket.SHUT_RDWR)
            except OSError:
                pass
            handle.close()


def clean_environment():
    names = ("SystemRoot", "WINDIR", "SystemDrive", "COMSPEC", "TEMP", "TMP", "USERPROFILE", "LOCALAPPDATA", "APPDATA", "ProgramFiles", "ProgramFiles(x86)", "ProgramData")
    return {name: os.environ[name] for name in names if name in os.environ}


class Control:
    def __init__(self, installation, box, identifier, state):
        self.installation, self.box, self.identifier, self.state = installation, box, identifier, state
        self.created = False
        self.api = ctypes.WinDLL(str(installation / "SbieDll.dll"))
        self.enumerate = self.api.SbieApi_EnumProcessEx
        self.enumerate.argtypes = [ctypes.c_wchar_p, ctypes.c_ubyte, ctypes.c_ulong, ctypes.POINTER(ctypes.c_ulong), ctypes.POINTER(ctypes.c_ulong)]
        self.enumerate.restype = ctypes.c_long

    def invoke(self, image, arguments, timeout=12):
        result = subprocess.run([str(self.installation / image), *arguments], stdin=subprocess.DEVNULL,
                                stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, timeout=timeout,
                                env=clean_environment(), creationflags=NO_WINDOW)
        if result.returncode:
            raise RuntimeError(f"Sandboxie {image} failed with status {result.returncode}")
        return result.stdout.decode("utf-16-le" if b"\0" in result.stdout else "mbcs", "replace").lstrip("\ufeff").splitlines()

    def setting(self, *arguments):
        result = self.invoke("SbieIni.exe", list(arguments))
        if len(arguments) == 4 and arguments[0] in ("set", "append"):
            actual = self.invoke("SbieIni.exe", ["query", arguments[1], arguments[2]])
            if arguments[0] == "set" and actual != [arguments[3]] or arguments[0] == "append" and arguments[3] not in actual:
                raise RuntimeError("Sandboxie did not retain the requested test setting: " + arguments[2])
        return result

    def pids(self):
        process_ids = (ctypes.c_ulong * 512)()
        count = ctypes.c_ulong(512)
        status = self.enumerate(self.box, 1, 0, process_ids, ctypes.byref(count))
        if status != 0 or count.value >= 512:
            raise RuntimeError("Incomplete sandbox process list")
        return list(process_ids[:count.value])

    def owned(self):
        return (self.setting("query", self.box, "CageSyncSpaceId") == [self.identifier] and
                [os.path.normcase(path) for path in self.setting("query", self.box, "FileRootPath")] == [os.path.normcase(str(self.state))])

    def configure(self, binary, results, proxy):
        if self.box in self.setting("query", "/boxes", "*"):
            raise RuntimeError("Unique test sandbox unexpectedly already exists")
        if self.setting("query", "GlobalSettings", "NetworkEnableWFP") != ["y"]:
            raise RuntimeError("WFP must be enabled before this experiment; no global changes were made")
        for key, value in (("Enabled", "n"), ("CageSyncSpaceId", self.identifier), ("FileRootPath", str(self.state))):
            self.setting("set", self.box, key, value)
        self.created = True
        for key, value in (("ConfigLevel", "10"), ("CageSyncProbe", "y"), ("NetworkAccess", "*,Block"),
                           ("OpenFilePath", str(results)), ("ClosedIpcPath", r"\RPC Control\DNSResolver"),
                           ("CageSyncProxyPort", str(proxy.server_address[1])), ("CageSyncProxyUser", proxy.user.decode()),
                           ("CageSyncProxyPassword", proxy.password.decode())):
            self.setting("set", self.box, key, value)
        self.setting("append", self.box, "NetworkAccess", f"*,Allow;Address=127.0.0.1;Port={proxy.server_address[1]};Protocol=TCP")
        for image in ("SyncParent.exe", "SyncChild.exe", "SyncGrandchild.exe"):
            self.setting("append", self.box, "CageSyncImage", str(binary / image))
        self.setting("set", self.box, "Enabled", "y")

    def stop(self, final=False):
        if not self.created:
            return
        if not self.owned():
            raise RuntimeError("Test sandbox ownership changed; unrelated processes were not touched")
        if final:
            self.setting("set", self.box, "NetworkAccess", "*,Block")
        self.invoke("Start.exe", ["/box:" + self.box, "/terminate"])
        until = time.monotonic() + 8
        while self.pids():
            if time.monotonic() > until:
                raise RuntimeError("Test processes remain; default block was retained")
            time.sleep(.1)
        if final:
            self.setting("set", self.box, "Enabled", "n")

    def launch(self, binary, results, phase, role, ports, nonce):
        return subprocess.Popen([str(self.installation / "Start.exe"), "/box:" + self.box, "/silent", "/wait",
                                 str(binary / "SyncParent.exe"), str(results), phase, role,
                                 *map(str, ports), "probe", nonce], stdin=subprocess.DEVNULL,
                                stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, env=clean_environment(), creationflags=NO_WINDOW)


def host_control(targets, phase, nonce):
    rows = []
    for target in targets:
        challenge = f"{nonce}:host:{phase}:{target.target_id}"
        with socket.create_connection(target.server_address, timeout=3) as connection:
            connection.sendall((challenge + "\n").encode())
            answer = connection.makefile("rb").readline(256).decode()
        if answer != f"ACK:{target.target_id}:{challenge}\n":
            raise RuntimeError("Host positive control failed")
        rows.append({"target": target.target_id, "port": target.server_address[1], "success": True})
    return rows


def wait_results(directory, names, processes, timeout=35):
    deadline = time.monotonic() + timeout
    while True:
        if all((directory / name).is_file() for name in names):
            return {name: json.loads((directory / name).read_text(encoding="utf-8")) for name in names}
        failures = [process.returncode for process in processes if process.poll() is not None and process.returncode != 0]
        if failures:
            raise RuntimeError("A probe launcher exited before producing results: " + str(failures))
        if time.monotonic() > deadline:
            raise RuntimeError("Timed out waiting for probe evidence: " + ", ".join(names))
        time.sleep(.05)


def require_rows(rows, box, ready, success):
    for name, row in rows.items():
        if row.get("box") != box or row.get("adapter_ready") is not ready or row.get("success") != success:
            raise RuntimeError(f"Probe evidence did not match expected boundary: {name}")


def experiment(output, binary, installation):
    identifier = uuid.uuid4().hex
    box = "CageProbeSync_" + identifier[:12]
    results = output / "results"
    results.mkdir()
    state = output / "state"
    state.mkdir()
    nonce = secrets.token_hex(16)
    targets, proxies, processes = [], [], []
    control = Control(installation, box, identifier, state)
    report = {"scope": "synthetic local IPv4, first-party x64 blocking Winsock connect only", "box": box,
              "output": str(output), "started": datetime.now(timezone.utc).isoformat(), "passed": False,
              "real_app_admission": False, "internet_egress_tested": False, "checks": {}}
    try:
        sandbox_api = ctypes.WinDLL(str(installation / "SbieDll.dll"))
        driver_info = sandbox_api.SbieApi_QueryDrvInfo
        driver_info.argtypes = [ctypes.c_int, ctypes.c_void_p, ctypes.c_ulong]
        driver_info.restype = ctypes.c_long
        flags = ctypes.c_ulong()
        status = driver_info(0, ctypes.byref(flags), ctypes.sizeof(flags))
        report["driver"] = {"query_status": status, "flags": flags.value, "wfp_active": bool(flags.value & 1)}
        if status != 0 or not flags.value & 1:
            raise RuntimeError("The Sandboxie driver has not confirmed active WFP; no box was created")
        targets = [Target(index) for index in range(3)]
        proxy = Socks(targets[:2]); proxies.append(proxy)
        ports = [target.server_address[1] for target in targets]
        report["ports"] = {"targets": ports, "proxy": proxy.server_address[1]}
        report["checks"]["host_before"] = host_control(targets, "before", nonce)
        control.configure(binary, results, proxy)
        notify("baseline_without_adapter", box=box)
        process = control.launch(binary, results, "no-adapter", "single", ports, nonce); processes.append(process)
        baseline = wait_results(results, ["single-no-adapter.json"], [process])
        require_rows(baseline, box, False, [0, 0, 0])
        if process.wait(timeout=10) != 0:
            raise RuntimeError("Baseline probe failed")
        control.stop()
        report["checks"]["no_adapter_blocked"] = baseline

        control.setting("set", box, "InjectDll64", str(binary / "CageSyncProxy.dll"))
        notify("three_generations_online", box=box)
        process = control.launch(binary, results, "online", "parent", ports, nonce); processes.append(process)
        online = wait_results(results, [f"{role}-online.json" for role in ("parent", "child", "grandchild")], [process])
        require_rows(online, box, True, [1, 1, 0])
        pids = control.pids()
        if not {row["pid"] for row in online.values()}.issubset(pids):
            raise RuntimeError("A probe was not tracked in the intended sandbox")
        report["checks"]["online"] = online
        report["checks"]["tracked_pids"] = pids

        notify("cutting_synthetic_proxy", box=box)
        proxy.disconnect()
        report["checks"]["host_after_proxy_cut"] = host_control(targets, "after-proxy-cut", nonce)
        (results / "cut.signal").write_text("cut\n", encoding="ascii")
        offline = wait_results(results, [f"{role}-after-cut.json" for role in ("parent", "child", "grandchild", "late")], [process])
        require_rows(offline, box, True, [0, 0, 0])
        for name, row in offline.items():
            if not name.startswith("late-") and row["existing_after_cut"] != [0, 0]:
                raise RuntimeError("Established connection survived the synthetic proxy cut")
        if process.wait(timeout=12) != 0:
            raise RuntimeError("Three-generation probe did not exit cleanly")
        control.stop()
        report["checks"]["after_cut"] = offline

        replacement = Socks(targets[:2]); proxies.append(replacement)
        control.setting("set", box, "NetworkAccess", "*,Block")
        control.setting("append", box, "NetworkAccess", f"*,Allow;Address=127.0.0.1;Port={replacement.server_address[1]};Protocol=TCP")
        control.setting("set", box, "CageSyncProxyPort", str(replacement.server_address[1]))
        control.setting("set", box, "CageSyncProxyPassword", secrets.token_hex(24))
        notify("incorrect_session_credentials", box=box)
        process = control.launch(binary, results, "wrong-auth", "single", ports, nonce); processes.append(process)
        wrong = wait_results(results, ["single-wrong-auth.json"], [process])
        require_rows(wrong, box, True, [0, 0, 0])
        if process.wait(timeout=10) != 0:
            raise RuntimeError("Wrong-credential probe failed")
        control.stop()
        report["checks"]["wrong_auth_blocked"] = wrong

        control.setting("set", box, "CageSyncProxyPassword", replacement.password.decode())
        notify("restored_proxy", box=box)
        process = control.launch(binary, results, "restored", "single", ports, nonce); processes.append(process)
        restored = wait_results(results, ["single-restored.json"], [process])
        require_rows(restored, box, True, [1, 1, 0])
        if process.wait(timeout=10) != 0:
            raise RuntimeError("Restored probe failed")
        control.stop()
        report["checks"]["restored"] = restored
        report["checks"]["host_final"] = host_control(targets, "final", nonce)
        for target in targets[:2]:
            expected = {f"{nonce}:{role}:initial:{target.target_id}" for role in ("parent", "child", "grandchild", "single")}
            if not expected.issubset(set(target.requests)):
                raise RuntimeError("The synthetic targets did not observe all successful probe challenges")
        if any(":host:" not in challenge for challenge in targets[2].requests):
            raise RuntimeError("A boxed request reached the forbidden local target")
        if sum(event["event"] == "connect" for event in proxy.events) != 6 or sum(event["event"] == "connect" for event in replacement.events) != 2:
            raise RuntimeError("Successful probe requests were not accounted for by the SOCKS relays")
        report["passed"] = True
    except Exception as error:
        report["failure"] = str(error)
    finally:
        try:
            control.stop(final=True)
            report["cleanup"] = {"processes": control.pids() if control.created else [],
                                 "default_block_retained": control.created,
                                 "box_disabled": control.created, "data_preserved": True}
        except Exception as error:
            report["cleanup_error"] = str(error)
            report["passed"] = False
        for proxy in proxies:
            proxy.disconnect()
        for process in processes:
            try:
                process.wait(timeout=4)
            except subprocess.TimeoutExpired:
                process.kill(); process.wait(timeout=4)
        report["launcher_exit_codes"] = [process.returncode for process in processes]
        report["proxy_events"] = [proxy.events for proxy in proxies]
        report["target_requests"] = {str(target.target_id): list(target.requests) for target in targets}
        for target in targets:
            target.shutdown(); target.server_close()
        report["finished"] = datetime.now(timezone.utc).isoformat()
        save(output / "verification.json", report)
    notify("finished", passed=report["passed"], report=str(output / "verification.json"), failure=report.get("failure"), cleanup_error=report.get("cleanup_error"))
    return 0 if report["passed"] else 1


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--sandboxie", default=r"C:\Program Files\Sandboxie-Plus")
    parser.add_argument("--build-only", action="store_true")
    options = parser.parse_args()
    if sys.platform != "win32" or struct.calcsize("P") != 8:
        raise RuntimeError("This experiment requires x64 Windows and x64 Python")
    output = REPO / "_output/windows-lite" / ("transparent-sync-" + datetime.now().strftime("%Y%m%d-%H%M%S-") + uuid.uuid4().hex[:8])
    output.mkdir(parents=True, exist_ok=False)
    notify("building", output=str(output))
    binary = build(output)
    if options.build_only:
        notify("build_complete", output=str(output))
        return 0
    return experiment(output, binary, Path(options.sandboxie).resolve())


if __name__ == "__main__":
    sys.exit(main())
