"""Run a selected x64 executable with a private Sandboxie profile and one proxy upstream."""
import argparse
from contextlib import ExitStack, contextmanager
import ctypes
from ctypes import wintypes
from dataclasses import dataclass
import hashlib
import ipaddress
import json
import msvcrt
import os
from pathlib import Path
import secrets
import socket
import ssl
import struct
import subprocess
import sys
import threading
import time
from urllib.parse import unquote, urlsplit

ROOT = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT / "dns.zip"))
from broker import DNSBroker, read_exact
from fixed_tcp import FixedService, service_specs


def read_json(path):
    return json.loads(path.read_text(encoding="utf-8-sig"))


def full_path(value, base):
    if not isinstance(value, str) or not value:
        raise ValueError("配置中的文件路径不能为空")
    return (base / os.path.expandvars(value)).resolve()


def require_amd64(path):
    with path.open("rb") as f:
        if f.read(2) != b"MZ":
            raise ValueError("请选择 Windows x64 EXE")
        f.seek(0x3c)
        offset = int.from_bytes(f.read(4), "little")
        f.seek(offset)
        if f.read(6) != b"PE\0\0\x64\x86":
            raise ValueError("所选文件不是原生 x64 PE 程序")
        f.seek(offset + 22)
        characteristics, magic = struct.unpack("<HH", f.read(4))
        if not characteristics & 2 or characteristics & 0x2000 or magic != 0x20b:
            raise ValueError("请选择可启动的 x64 EXE")


@contextmanager
def profile_lock(private):
    private.mkdir(parents=True, exist_ok=True)
    with (private / "session.lock").open("a+b") as file:
        file.seek(0)
        try:
            msvcrt.locking(file.fileno(), msvcrt.LK_NBLCK, 1)
        except OSError as exc:
            raise RuntimeError("此应用已有轻量壳会话，请先退出该会话") from exc
        try:
            yield
        finally:
            file.seek(0)
            msvcrt.locking(file.fileno(), msvcrt.LK_UNLCK, 1)


@dataclass
class Route:
    port: int
    user: str
    password: str
    doh: object
    tls: ssl.SSLContext


def validate_endpoints(saved):
    proxy, doh = urlsplit(saved["proxy_url"]), urlsplit(saved["dns_url"])
    if proxy.scheme not in ("socks5", "socks5h") or not proxy.port or not proxy.hostname:
        raise ValueError("连接配置需要包含 IP 和端口的 SOCKS5 入口")
    if doh.scheme != "https" or not doh.hostname or doh.username is not None or doh.fragment:
        raise ValueError("连接配置需要 HTTPS DoH 地址")
    # Bootstrap never consults host DNS.
    for endpoint in (proxy, doh):
        ipaddress.ip_address(endpoint.hostname)
    if any(c in saved["dns_url"] for c in "\r\n"):
        raise ValueError("无效的 DoH 地址")
    return proxy, doh


@contextmanager
def data_gateway(core, private, upstream, doh, *, reuse_session=None):
    if reuse_session is None:
        with socket.socket() as reserve:
            reserve.bind(("127.0.0.1", 0))
            port = reserve.getsockname()[1]
        route = Route(port, "session", secrets.token_hex(20), doh, ssl.create_default_context())
    else:
        # Keep session identity stable when isolating a relay restart in an integration test.
        route = reuse_session
        port = route.port
    node = {"name": "CageUpstream", "type": "socks5", "server": upstream.hostname,
            "port": upstream.port, "udp": False}
    if upstream.username is not None:
        node.update(username=unquote(upstream.username), password=unquote(upstream.password or ""))
    settings = {"mixed-port": port, "allow-lan": False, "bind-address": "127.0.0.1",
                "authentication": [route.user + ":" + route.password], "skip-auth-prefixes": [],
                "mode": "rule", "log-level": "silent", "geo-auto-update": False,
                "ipv6": False, "tun": {"enable": False}, "dns": {"enable": False},
                "proxies": [node], "rules": ["MATCH,CageUpstream"]}
    cache = private / "core"
    cache.mkdir(exist_ok=True)
    proc = subprocess.Popen([str(core), "-d", str(cache), "-f", "-"], stdin=subprocess.PIPE,
                            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                            creationflags=subprocess.CREATE_NO_WINDOW)
    try:
        with kill_on_parent_exit(proc):
            proc.stdin.write(json.dumps(settings).encode("utf-8"))
            proc.stdin.close()
            deadline = time.monotonic() + 10
            while True:
                if proc.poll() is not None:
                    raise RuntimeError("专用代理核心未能启动")
                try:
                    with socket.create_connection(("127.0.0.1", port), timeout=.5) as check:
                        check.sendall(b"\x05\x01\x02")
                        if read_exact(check, 2) != b"\x05\x02":
                            raise RuntimeError("本地代理未要求会话认证")
                        u, p = route.user.encode(), route.password.encode()
                        check.sendall(b"\x01" + bytes([len(u)]) + u + bytes([len(p)]) + p)
                        if read_exact(check, 2) != b"\x01\x00":
                            raise RuntimeError("专用代理身份校验失败")
                    break
                except (ConnectionRefusedError, TimeoutError):
                    if time.monotonic() >= deadline:
                        raise RuntimeError("专用代理没有就绪")
                    time.sleep(.1)
            yield route, proc
    finally:
        if proc.poll() is None:
            proc.kill()
        proc.wait()


@contextmanager
def kill_on_parent_exit(proc):
    # The only process assigned to this job is our newly created relay.
    kernel = ctypes.WinDLL("kernel32", use_last_error=True)
    kernel.CreateJobObjectW.argtypes = [ctypes.c_void_p, wintypes.LPCWSTR]
    kernel.CreateJobObjectW.restype = wintypes.HANDLE
    kernel.SetInformationJobObject.argtypes = [wintypes.HANDLE, ctypes.c_int, ctypes.c_void_p, wintypes.DWORD]
    kernel.AssignProcessToJobObject.argtypes = [wintypes.HANDLE, wintypes.HANDLE]
    kernel.CloseHandle.argtypes = [wintypes.HANDLE]
    job = kernel.CreateJobObjectW(None, None)
    if not job:
        raise ctypes.WinError(ctypes.get_last_error())
    try:
        limits = ctypes.create_string_buffer(144)  # x64 JOBOBJECT_EXTENDED_LIMIT_INFORMATION
        struct.pack_into("<I", limits, 16, 0x2000)
        if not kernel.SetInformationJobObject(job, 9, limits, len(limits)):
            raise ctypes.WinError(ctypes.get_last_error())
        if not kernel.AssignProcessToJobObject(job, int(proc._handle)):
            raise ctypes.WinError(ctypes.get_last_error())
        yield
    finally:
        kernel.CloseHandle(job)


class Sandbox:
    def __init__(self, directory, name):
        self.ini = str(directory / "SbieIni.exe")
        self.start = str(directory / "Start.exe")
        self.name = name

    def settings(self, *args):
        result = subprocess.run([self.ini, *args], stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
                                creationflags=subprocess.CREATE_NO_WINDOW, timeout=12)
        if result.returncode:
            raise RuntimeError(f"Sandboxie 配置操作失败（{args[0]}，代码 {result.returncode}）")
        raw = result.stdout
        encoding = "utf-16-le" if b"\0" in raw else "mbcs"
        return raw.decode(encoding, "replace").lstrip("\ufeff").splitlines()

    @contextmanager
    def configure(self, program, helpers, vault, state, output, source, route, broker, services):
        if self.name in self.settings("query", "*"):
            # A hard-stop may leave a legitimate box. Do not replace a stranger's box.
            previous = self.settings("query", self.name, "FileRootPath")
            if not previous or os.path.normcase(previous[0]) != os.path.normcase(str(state)):
                raise RuntimeError("同名 Sandboxie 盒已被其他配置占用")
            if self.pids():
                raise RuntimeError("上次会话仍有盒内进程。请先在 Sandboxie 关闭这个盒")
            self.settings("set", self.name, "*", "")
        pairs = [
            ("Enabled", "n"), ("FileRootPath", str(state)), ("ConfigLevel", "10"),
            ("CageLiteImage", str(program)), ("CageLiteDnsPort", str(broker.server_address[1])),
            ("CageLiteDnsTicket", broker.ticket.decode()), ("OpenFilePath", str(output)),
            ("ClosedIpcPath", r"\RPC Control\DNSResolver"), ("ClosedFilePath", str(vault)),
            ("NetworkAccess", "*,Block"),
            ("InjectDll64", str(ROOT / "addon" / "CageRegion.dll")),
        ]
        active = False
        try:
            for key, value in pairs:
                self.settings("set", self.name, key, value)
            for child in helpers:
                self.settings("append", self.name, "CageLiteImage", str(child))
            for path in {Path.home()/".claude-cage", source}:
                self.settings("append", self.name, "ClosedFilePath", str(path))
            for port in [broker.server_address[1], route.port, *services.values()]:
                self.settings("append", self.name, "NetworkAccess",
                              f"*,Allow;Address=127.0.0.1;Port={port};Protocol=TCP")
            self.settings("set", self.name, "Enabled", "y")
            active = True
            yield
        finally:
            if active:
                self.settings("set", self.name, "NetworkAccess", "*,Block")
                self.control("/terminate")
                deadline = time.monotonic() + 4
                while self.pids():
                    if time.monotonic() >= deadline:
                        raise RuntimeError("尚有盒内进程，已保留全阻断规则。请在 Sandboxie 中结束该盒")
                    time.sleep(.15)
            self.settings("set", self.name, "*", "")

    def control(self, arg):
        return subprocess.run([self.start, "/box:"+self.name, arg], timeout=15,
                              stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
                              creationflags=subprocess.CREATE_NO_WINDOW)

    def pids(self):
        result = self.control("/listpids")
        raw = result.stdout
        lines = raw.decode("utf-16-le" if b"\0" in raw else "mbcs","replace").strip().splitlines()
        if result.returncode or not lines or not lines[0].strip().isdigit():
            raise RuntimeError("无法确认旧盒中的进程")
        return [int(i.strip()) for i in lines[1:] if i.strip().isdigit()]

    def run(self, program, args, env, cwd, relay):
        command = [self.start, "/box:"+self.name, "/silent", "/wait", str(program), *args]
        with subprocess.Popen(command, env=env, cwd=cwd) as launched:
            try:
                while True:
                    try:
                        return launched.wait(timeout=.5)
                    except subprocess.TimeoutExpired:
                        if relay.poll() is not None:
                            raise RuntimeError("专用代理核心已退出，正在关闭会话")
            finally:
                if launched.poll() is None:
                    self.control("/terminate")
                    launched.terminate()


def launch(config_path, selection, trace_dns=False):
    cfg = read_json(config_path)
    name = selection or cfg["selected"]
    if name not in cfg["applications"]:
        raise ValueError("配置中没有选中的应用")
    spec = cfg["applications"][name]
    program = full_path(spec["program"], config_path.parent)
    require_amd64(program)
    child_paths = spec.get("childPrograms", [])
    if not isinstance(child_paths, list) or len(child_paths) > 63:
        raise ValueError("childPrograms 必须是最多 63 个 x64 程序路径的数组")
    helpers = list(dict.fromkeys(full_path(p, config_path.parent) for p in child_paths))
    for helper in helpers:
        require_amd64(helper)
    endpoints = service_specs(spec.get("tcpServices", {}))
    raw_args = spec.get("arguments", [])
    if not isinstance(raw_args, list) or not all(isinstance(a, str) for a in raw_args):
        raise ValueError("arguments 必须为字符串数组")
    sbie = full_path(cfg.get("sandboxieDirectory", r"%ProgramFiles%\Sandboxie-Plus"), config_path.parent)
    if not (sbie / "Start.exe").is_file() or not (sbie/"SbieIni.exe").is_file():
        raise FileNotFoundError("未找到已安装的 Sandboxie Plus")
    connection_file = full_path(cfg["connectionFile"], config_path.parent)
    upstream, doh = validate_endpoints(read_json(connection_file))
    core_path = cfg.get("proxyCore")
    if not core_path:
        core_path = read_json(Path.home()/".claude-cage"/"proxy"/"managed-process.json")["executable"]
    core = full_path(core_path, config_path.parent)
    if not core.is_file():
        raise FileNotFoundError("未找到 Mihomo，可在配置中填写 proxyCore")
    home = full_path(cfg["dataDirectory"], config_path.parent) if cfg.get("dataDirectory") else Path(os.environ["LOCALAPPDATA"]) / "CageLite"
    identity = hashlib.sha256((str(home)+"|"+str(program)).casefold().encode()).hexdigest()[:16]
    box = Sandbox(sbie, "CageLite_"+identity)
    private = home / "private" / identity
    state = home / "boxes" / identity
    output = home / "output" / identity
    output.mkdir(parents=True, exist_ok=True)
    with ExitStack() as stack:
        stack.enter_context(profile_lock(private))
        route, relay = stack.enter_context(data_gateway(core, private, upstream, doh))
        broker = stack.enter_context(DNSBroker(route, secrets.token_hex(32), trace=trace_dns))
        thread = threading.Thread(target=broker.serve_forever, daemon=True)
        thread.start()
        stack.callback(broker.shutdown)
        services = {}
        for service_name, service_spec in endpoints.items():
            service = stack.enter_context(FixedService(box, broker, service_spec))
            threading.Thread(target=service.serve_forever, daemon=True).start()
            stack.callback(service.shutdown)
            services[service_name] = service.server_address[1]
        stack.enter_context(box.configure(program, helpers, home/"private", state, output, connection_file,
                                          route, broker, services))
        address = f"http://127.0.0.1:{route.port}"
        authenticated = f"http://{route.user}:{route.password}@127.0.0.1:{route.port}"
        replacements = {"{output}":str(output), "{root}":str(ROOT), "{run}":"run-"+secrets.token_hex(4),
                        "{proxy}":address}
        for service_name, port in services.items():
            replacements["{tcpPort:"+service_name+"}"] = str(port)
            replacements["{tcp:"+service_name+"}"] = f"127.0.0.1:{port}"
        args = []
        for arg in raw_args:
            for key,value in replacements.items():
                arg = arg.replace(key,value)
            args.append(arg)
        env = os.environ.copy()
        for k in list(env):
            if k.lower() in {"http_proxy","https_proxy","all_proxy","no_proxy","cage_lite_proxy","cage_lite_user","cage_lite_password"}:
                del env[k]
        env.update(HTTP_PROXY=authenticated, HTTPS_PROXY=authenticated, ALL_PROXY=authenticated, NO_PROXY="",
                   CAGE_LITE_PROXY=address, CAGE_LITE_USER=route.user, CAGE_LITE_PASSWORD=route.password)
        print(f"{name} | {box.name}\n输出目录 {output}", flush=True)
        for service_name, port in services.items():
            print(f"TCP {service_name}  127.0.0.1:{port}", flush=True)
        if "y" not in [s.lower() for s in box.settings("query", "GlobalSettings", "NetworkEnableWFP")]:
            print("Sandboxie 全局 WFP 未启用，本次使用盒内网络规则。", flush=True)
        cwd = full_path(spec["workingDirectory"], config_path.parent) if "workingDirectory" in spec else program.parent
        return box.run(program, args, env, cwd, relay)


def main():
    ap=argparse.ArgumentParser(description="Cage Lite 独立 Windows x64 启动器")
    ap.add_argument("--config", type=Path, default=ROOT/"config.json")
    ap.add_argument("--app", help="本次使用的应用名称，默认读取 selected")
    ap.add_argument("--trace-dns", action="store_true", help="将本次域名和 DNS 返回码显示在控制台")
    ns=ap.parse_args()
    if sys.platform != "win32" or struct.calcsize("P") != 8:
        raise RuntimeError("需要 64 位 Windows 和 64 位 Python")
    return launch(ns.config.resolve(), ns.app, ns.trace_dns)


if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        sys.exit(130)
    except (OSError, RuntimeError, ValueError, KeyError, subprocess.SubprocessError) as exc:
        print("启动失败："+str(exc),file=sys.stderr)
        sys.exit(1)
