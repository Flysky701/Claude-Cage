"""Single persistent Windows space worker; JSON lines only on standard output.

Application admission comes only from this process's current active checks and
expiring watchdog evidence. Saved reports and configuration cannot grant it.
"""
import argparse
import copy
from contextlib import redirect_stdout
import ipaddress
import json
import os
from pathlib import Path
import shutil
import struct
import subprocess
import sys
import tempfile
import time
from urllib.parse import urlsplit
import uuid


VERSION = 1
MAX_REQUEST = 1024 * 1024
HIDDEN = "<已隐藏>"
ENTRY_LABELS = {
    "browser": "浏览器", "claude_web": "Claude 网页", "claude_desktop": "Claude 桌面版",
    "shell": "终端", "claude": "Claude Code", "editor": "编辑器",
}
APPLICATION_IDS = tuple(key for key in ENTRY_LABELS if key != "claude_web")
NO_PROBE = "空间尚未通过本次应用监控，暂不允许启动应用。"
# The user requested replacing the Sandboxie backend after its free classic
# file rules failed the required default-deny boundary. Preserve this prototype
# and its evidence, but never turn it into application permission by accident.
SANDBOXIE_RUNTIME_ENABLED = False


def absolute_path(value, *, optional=False):
    if optional and value == "":
        return ""
    if not isinstance(value, str) or not value or "\0" in value or len(value) > 32768:
        raise ValueError("文件路径无效，请填写完整路径。")
    path = Path(os.path.expandvars(value))
    if not path.is_absolute():
        raise ValueError("文件路径必须是绝对路径。")
    return str(path.resolve())


def read_object(path):
    with Path(path).open("r", encoding="utf-8-sig") as stream:
        data = stream.read(MAX_REQUEST + 1)
    if len(data) > MAX_REQUEST:
        raise ValueError("配置文件过大。")
    result = json.loads(data)
    if not isinstance(result, dict):
        raise ValueError("配置内容必须是对象。")
    return result


def first_file(paths):
    return next((str(path.resolve()) for path in paths if path.is_file()), "")


def default_settings():
    system = Path(os.environ.get("SystemRoot", r"C:\Windows"))
    program = Path(os.environ.get("ProgramFiles", r"C:\Program Files"))
    program86 = Path(os.environ.get("ProgramFiles(x86)", r"C:\Program Files (x86)"))
    local = Path(os.environ.get("LOCALAPPDATA", str(Path.home() / "AppData" / "Local")))
    apps = {key: {"program": "", "arguments": []} for key in APPLICATION_IDS}
    apps["browser"]["program"] = first_file([
        program86 / "Microsoft/Edge/Application/msedge.exe",
        program / "Microsoft/Edge/Application/msedge.exe",
        program / "Google/Chrome/Application/chrome.exe",
    ])
    apps["shell"] = {"program": first_file([system / "System32/WindowsPowerShell/v1.0/powershell.exe"]),
                     "arguments": ["-NoLogo", "-NoProfile", "-NoExit"]}
    apps["editor"]["program"] = first_file([
        local / "Programs/Microsoft VS Code/Code.exe", program / "Microsoft VS Code/Code.exe",
    ])
    candidate = shutil.which("claude.exe")
    if candidate:
        apps["claude"]["program"] = str(Path(candidate).resolve())
    core = ""
    try:
        core = absolute_path(read_object(Path.home() / ".claude-cage/proxy/managed-process.json").get("executable", ""))
    except (OSError, ValueError, TypeError):
        pass
    return {"sandboxieDirectory": str(program / "Sandboxie-Plus"), "proxyCore": core,
            "connectionFile": str(Path.home() / ".claude-cage/config.json"),
            "projectDirectory": "", "applications": apps}


def redact_arguments(arguments):
    result, redact_next = [], False
    for arg in arguments:
        lower = arg.lower()
        secret_option = lower.startswith(("--password", "--token", "--api-key", "--api_key", "--secret"))
        if redact_next:
            result.append(HIDDEN)
            redact_next = False
        elif secret_option:
            if "=" in arg:
                result.append(arg.split("=", 1)[0] + "=" + HIDDEN)
            else:
                result.append(arg)
                redact_next = True
        else:
            try:
                parsed = urlsplit(arg)
                sensitive_url = bool(parsed.scheme and parsed.username is not None)
            except ValueError:
                sensitive_url = True
            result.append(HIDDEN if sensitive_url else arg)
    return result


def public_settings(settings):
    result = copy.deepcopy(settings)
    for app in result["applications"].values():
        app["arguments"] = redact_arguments(app["arguments"])
    return result


def normalize_settings(update, previous, profile):
    if not isinstance(update, dict) or set(update) - set(previous):
        raise ValueError("空间设置包含未知字段。")
    result = copy.deepcopy(previous)
    for key in ("sandboxieDirectory", "proxyCore", "connectionFile", "projectDirectory"):
        if key in update:
            result[key] = absolute_path(update[key], optional=True)
    if "applications" in update:
        applications = update["applications"]
        if not isinstance(applications, dict) or set(applications) - set(APPLICATION_IDS):
            raise ValueError("应用入口无效。")
        for key, app in applications.items():
            if not isinstance(app, dict) or set(app) - {"program", "arguments", "workingDirectory"}:
                raise ValueError("应用设置包含未知字段。")
            item = result["applications"][key]
            if "program" in app:
                item["program"] = absolute_path(app["program"], optional=True)
            if "arguments" in app:
                args = app["arguments"]
                if (not isinstance(args, list) or len(args) > 128 or
                        any(not isinstance(arg, str) or "\0" in arg or len(arg) > 32768 for arg in args)):
                    raise ValueError("应用参数必须是字符串数组。")
                old, public = item["arguments"], redact_arguments(item["arguments"])
                restored = []
                for index, arg in enumerate(args):
                    if HIDDEN in arg:
                        if index >= len(old) or arg != public[index] or public[index] == old[index]:
                            raise ValueError("隐藏参数无法匹配原值，请重新填写该参数。")
                        arg = old[index]
                    restored.append(arg)
                item["arguments"] = restored
            if "workingDirectory" in app:
                item["workingDirectory"] = absolute_path(app["workingDirectory"], optional=True)
    if result["projectDirectory"]:
        selected = Path(result["projectDirectory"])
        private = Path(profile).resolve()
        personal = (Path.home() / ".claude-cage").resolve()
        if (selected == Path.home().resolve() or selected == selected.parent or
                selected == private or private in selected.parents or selected in private.parents or
                selected == personal or personal in selected.parents or selected in personal.parents):
            raise ValueError("请选择具体项目目录，不能共享用户主目录或 Cage 私有数据目录。")
    return result


def check_x64(path):
    if not path or not Path(path).is_file():
        return False
    try:
        with Path(path).open("rb") as stream:
            if stream.read(2) != b"MZ":
                return False
            stream.seek(0x3C)
            offset = int.from_bytes(stream.read(4), "little")
            if offset > 16 * 1024 * 1024:
                return False
            stream.seek(offset)
            if stream.read(6) != b"PE\0\0\x64\x86":
                return False
            stream.seek(offset + 22)
            flags, magic = struct.unpack("<HH", stream.read(4))
            return bool(flags & 2 and not flags & 0x2000 and magic == 0x20B)
    except (OSError, ValueError, struct.error):
        return False


def validate_connection(path):
    data = read_object(path)
    for key in ("proxy_url", "dns_url"):
        value = data.get(key)
        if not isinstance(value, str) or any(c in value for c in "\r\n\0"):
            raise ValueError("连接配置格式无效。")
    proxy, dns = urlsplit(data["proxy_url"]), urlsplit(data["dns_url"])
    if (proxy.scheme not in ("socks5", "socks5h") or not proxy.port or
            proxy.path or proxy.query or proxy.fragment):
        raise ValueError("连接需要数值 IP 和端口的 SOCKS5 入口。")
    if dns.scheme != "https" or dns.username is not None or dns.fragment:
        raise ValueError("DNS 需要数值 IP 的 HTTPS DoH 地址。")
    ipaddress.ip_address(proxy.hostname)
    ipaddress.ip_address(dns.hostname)
    if dns.port is not None and not 1 <= dns.port <= 65535:
        raise ValueError("DNS 端口无效。")


def clean_environment():
    # No PATH, proxy variables, API keys or inherited provider credentials.
    allowed = ("SystemRoot", "WINDIR", "SystemDrive", "COMSPEC", "TEMP", "TMP",
               "USERPROFILE", "LOCALAPPDATA", "APPDATA", "ProgramFiles", "ProgramFiles(x86)", "ProgramData")
    result = {key: os.environ[key] for key in allowed if key in os.environ}
    system = os.environ.get("SystemRoot", r"C:\Windows")
    result["PATH"] = str(Path(system) / "System32") + os.pathsep + system
    return result


class SandboxControl:
    def __init__(self, directory, name):
        self.directory, self.name = Path(directory), name

    def _run(self, executable, arguments):
        result = subprocess.run([str(self.directory / executable), *arguments],
                                stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
                                env=clean_environment(), timeout=12,
                                creationflags=getattr(subprocess, "CREATE_NO_WINDOW", 0))
        if result.returncode:
            raise RuntimeError("Sandboxie 未接受操作，请检查安装及权限。")
        return result.stdout.decode("utf-16-le" if b"\0" in result.stdout else "mbcs", "replace").lstrip("\ufeff").splitlines()

    def settings(self, *args):
        if len(args)==3 and args[0]=="query" and (self.directory/"SbieDll.dll").is_file():
            # The CLI's redirected C-locale output can truncate Unicode paths.
            # Read through the official UTF-16 API, retaining every value.
            from setup import WindowsBackend, NOT_FOUND
            import ctypes
            api=WindowsBackend(self.directory).dll
            values=[]
            for index in range(2048):
                value=ctypes.create_unicode_buffer(16384)
                rc=api.SbieApi_QueryConf(args[1],args[2],0x70000000|index,value,ctypes.sizeof(value))
                if rc&0xffffffff in NOT_FOUND:return values
                if rc:raise RuntimeError("无法读取完整隔离配置。")
                values.append(value.value)
            raise RuntimeError("隔离配置值过多，未使用不完整证据。")
        return self._run("SbieIni.exe", args)

    def pids(self):
        if (self.directory/"SbieDll.dll").is_file():
            from setup import WindowsBackend
            import ctypes
            api=WindowsBackend(self.directory).dll
            values=(ctypes.c_ulong*2048)();count=ctypes.c_ulong(2048)
            rc=api.SbieApi_EnumProcessEx(self.name,1,0,values,ctypes.byref(count))
            if rc or count.value>=2048:raise RuntimeError("无法确认完整空间进程列表。")
            return list(values[:count.value])
        lines = self._run("Start.exe", ["/box:" + self.name, "/listpids"])
        if not lines or not lines[0].strip().isdigit() or any(not line.strip().isdigit() for line in lines[1:] if line.strip()):
            raise RuntimeError("无法确认盒内进程，保持网络状态未知。")
        pids = [int(line.strip()) for line in lines[1:] if line.strip()]
        if int(lines[0].strip()) != len(pids) or any(pid <= 0 for pid in pids) or len(set(pids)) != len(pids):
            raise RuntimeError("盒内进程列表不完整，无法确认空间已停止。")
        return pids

    def terminate(self):
        self._run("Start.exe", ["/box:" + self.name, "/terminate"])


class SpaceWorker:
    def __init__(self, profile, *, control_factory=SandboxControl, platform=None):
        self.profile = Path(absolute_path(str(profile)))
        self.platform = sys.platform if platform is None else platform
        self.control_factory = control_factory
        self.phase, self.message, self.network = "stopped", "空间已停止；启动时会执行本次隔离与出口检查。", "closed"
        self.checks, self.process_count = [], 0
        self._verified_session = None
        self._runtime = None
        self.profile.mkdir(parents=True, exist_ok=True)
        self._lock = None
        try:
            self._acquire_lock()
            self.record_path = self.profile / "space.json"
            if self.record_path.exists():
                saved = read_object(self.record_path)
                if saved.get("version") != VERSION or set(saved) != {"version", "id", "settings"}:
                    raise ValueError("空间记录版本或内容无效，原文件已保留。")
                self.identity = str(uuid.UUID(saved["id"]))
                self.settings = normalize_settings(saved["settings"], default_settings(), self.profile)
            else:
                self.identity = str(uuid.uuid4())
                self.settings = default_settings()
                self._save()
            self.box_name = "CageSpace_" + self.identity.replace("-", "")[:24]
        except BaseException:
            self._release_lock()
            raise

    def _acquire_lock(self):
        self._lock = (self.profile / "space.lock").open("a+b")
        self._lock.seek(0)
        try:
            if sys.platform == "win32":
                import msvcrt
                msvcrt.locking(self._lock.fileno(), msvcrt.LK_NBLCK, 1)
            else:
                import fcntl
                fcntl.flock(self._lock.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
        except OSError as exc:
            self._lock.close()
            self._lock = None
            raise RuntimeError("此空间已有管理进程，请先关闭原检查窗口。") from exc

    def _release_lock(self):
        if self._lock is not None:
            self._lock.close()
            self._lock = None

    def _save(self):
        data = {"version": VERSION, "id": self.identity, "settings": self.settings}
        descriptor, temporary = tempfile.mkstemp(prefix=".space-", suffix=".json", dir=self.profile)
        try:
            with os.fdopen(descriptor, "w", encoding="utf-8", newline="\n") as stream:
                json.dump(data, stream, ensure_ascii=False, indent=2)
                stream.write("\n")
                stream.flush()
                os.fsync(stream.fileno())
            os.replace(temporary, self.record_path)
        finally:
            # This is precisely the newly created temporary file, never space data.
            Path(temporary).unlink(missing_ok=True)

    def _control(self):
        return self.control_factory(self.settings["sandboxieDirectory"], self.box_name)

    def _owned_box(self, control):
        names = control.settings("query", "*")
        if self.box_name not in names:
            return False
        identity = control.settings("query", self.box_name, "CageLiteSpaceId")
        root = control.settings("query", self.box_name, "FileRootPath")
        expected = str((self.profile / "state" / "files").resolve())
        if (identity != [self.identity] or len(root) != 1 or
                os.path.normcase(root[0]) != os.path.normcase(expected)):
            raise RuntimeError("同名盒的归属无法确认，未修改或结束其中的进程。")
        return True

    def preflight(self):
        if self._runtime is not None:
            self._refresh_runtime()
            return self.checks
        checks = []
        def add(key, label, ok, message):
            checks.append({"id": key, "label": label, "ok": bool(ok), "message": message})
        windows = self.platform == "win32" and struct.calcsize("P") == 8
        add("platform", "Windows x64", windows, "运行环境受支持。" if windows else "此检查版仅支持 Windows x64。")
        directory = Path(self.settings["sandboxieDirectory"] or ".")
        installed = windows and all((directory / item).is_file() for item in ("Start.exe", "SbieIni.exe", "SbieSvc.exe"))
        add("sandboxie", "Sandboxie 组件", installed, "组件文件存在；尚不代表隔离有效。" if installed else "未找到完整 Sandboxie 安装，请填写安装目录。")
        core_ok = check_x64(self.settings["proxyCore"])
        add("proxy-core", "代理核心", core_ok, "已找到 x64 代理程序；尚未启动。" if core_ok else "请选择可用的 x64 Mihomo 程序。")
        try:
            validate_connection(self.settings["connectionFile"])
            connection_ok = True
        except (OSError, ValueError, TypeError, KeyError):
            connection_ok = False
        add("connection", "出口配置", connection_ok, "SOCKS5 和 DoH 配置格式有效；尚未验证联网。" if connection_ok else "连接文件缺失或无效，需要数值 IP 的 SOCKS5 和 HTTPS DoH。")
        project = self.settings["projectDirectory"]
        project_ok = not project or Path(project).is_dir()
        add("project", "项目目录", project_ok, "未共享项目目录。" if not project else "项目目录存在；尚未开放共享。" if project_ok else "项目目录不存在，请更新路径。")
        wfp, owned, ownership_ok = False, False, True
        if installed:
            try:
                control = self._control()
                wfp = any(line.strip().lower() == "y" for line in control.settings("query", "GlobalSettings", "NetworkEnableWFP"))
                owned = self._owned_box(control)
                self.process_count = len(control.pids()) if owned else 0
                self.network = "unknown" if self.process_count else "closed"
            except (OSError, ValueError, RuntimeError, subprocess.SubprocessError):
                ownership_ok = False
                self.process_count, self.network = -1, "unknown"
        else:
            if self.process_count != 0 or self.network == "unknown":
                self.process_count, self.network, ownership_ok = -1, "unknown", False
        add("wfp", "内核网络过滤", wfp, "配置报告 WFP 已启用，仍需实际阻断探针。" if wfp else "未确认 WFP 已启用；本工具不会自动修改全局网络设置。")
        add("ownership", "空间进程归属", ownership_ok, "已确认现有盒归属。" if owned and ownership_ok else "尚未创建盒。" if ownership_ok else "无法确认盒归属或进程状态，禁止启动。")
        add("isolation", "隔离与出口实测", False, NO_PROBE)
        self.checks = checks
        return checks

    def snapshot(self):
        self._refresh_runtime()
        apps = []
        for entry, label in ENTRY_LABELS.items():
            app = self.settings["applications"]["browser" if entry == "claude_web" else entry]
            apps.append({"id": entry, "label": label, "program": app["program"],
                         "available": check_x64(app["program"]), "running": False})
        healthy=self._runtime is not None and self._runtime.healthy()
        browser=check_x64(self.settings["applications"]["browser"]["program"])
        terminal=(Path(__file__).resolve().parent/"runtime-bin/CageTerminal.exe").is_file()
        monitor=dict(self._runtime.monitor) if self._runtime else {"phase":"stopped","lastCheckedAt":None,"validUntil":None,"sessionId":"","configHash":"","reason":self.message,"checks":[]}
        return {"phase": self.phase, "message": self.message, "profile": str(self.profile),
                "boxName": self.box_name, "network": self.network, "checks": copy.deepcopy(self.checks),
                "applications": apps, "settings": public_settings(self.settings),
                "processCount": self.process_count, "acceptance": "verified" if healthy else "not-verified",
                "monitor":monitor,"capabilities":{"embedded_browser":healthy and browser,"terminal_stream":healthy and terminal,
                    "claude_terminal":healthy and terminal and check_x64(self.settings["applications"]["claude"]["program"]),
                    "project_sharing":healthy and bool(self.settings.get("projectDirectory"))}}

    def _refresh_runtime(self):
        if self._runtime is None:return
        state=self._runtime.state();self.process_count=state["processCount"]
        if state["healthy"]:
            self.phase,self.network="running","open"
            self.message="空间监控正常；浏览器和终端使用本次受控出口。"
            self._verified_session=self._runtime.session
        else:
            self.phase,self.network="blocked","unknown" if self.process_count<0 else "closed"
            self.message=self._runtime.monitor["reason"];self._verified_session=None
        self.checks=copy.deepcopy(self._runtime.monitor["checks"])

    def configure(self, update):
        if self.phase in ("starting", "running", "stopping"):
            raise RuntimeError("请先停止空间，再修改设置。")
        self.preflight()
        if self.process_count != 0 or self.network == "unknown":
            raise RuntimeError("尚有进程或状态无法确认，请先停止空间；原配置保持不变。")
        settings = normalize_settings(update, self.settings, self.profile)
        previous = self.settings
        self.settings = settings
        try:
            self._save()
        except BaseException:
            self.settings = previous
            raise
        self.phase, self.message = "stopped", "启动项和依赖设置已保存；下次启动将重新执行应用监控检查。"
        self.preflight()

    def start(self):
        if self._runtime is not None:
            if self._runtime.healthy():return
            self.stop()
        self.phase = "starting"
        self.preflight()
        failed = [item for item in self.checks if item["id"] != "isolation" and not item["ok"]]
        if failed:
            self.phase,self.message="blocked",failed[0]["message"]
            raise RuntimeError(self.message)
        if not SANDBOXIE_RUNTIME_ENABLED:
            self.phase,self.message="blocked","Windows 轻量底层正在替换；当前 Sandboxie 运行原型尚未满足所需隔离边界，应用保持未启动。"
            raise RuntimeError(self.message)
        from runtime import Runtime
        runtime=None
        try:
            runtime=Runtime(self);self._runtime=runtime
            runtime.start();self._refresh_runtime()
        except Exception as exc:
            if runtime:
                runtime.fail_closed(str(exc))
                try:runtime.close()
                except Exception:pass
                self._refresh_runtime()
            else:self.phase="blocked"
            raise RuntimeError("本次空间检查未通过，未允许应用运行："+str(exc)) from exc

    def launch_spec(self, entry):
        if entry not in ENTRY_LABELS:
            raise ValueError("未知应用入口。")
        app = copy.deepcopy(self.settings["applications"]["browser" if entry == "claude_web" else entry])
        if not check_x64(app["program"]):
            raise RuntimeError("此入口未配置可用的 x64 EXE，请先设置应用路径。")
        if entry == "claude_web":
            app["arguments"].append("https://claude.ai/")
        app["command"] = [str(Path(self.settings["sandboxieDirectory"]) / "Start.exe"),
                          "/box:" + self.box_name, "/silent", app["program"], *app["arguments"]]
        app["environment"] = clean_environment()
        return app

    def launch(self, entry):
        if entry not in ENTRY_LABELS:
            raise ValueError("未知应用入口。")
        if self.phase != "running" or self._verified_session is None:
            raise RuntimeError("空间尚未通过隔离检查，未启动任何应用。")
        if entry in ("browser","claude_web"):
            return self._runtime.browser_launch()
        raise RuntimeError("此入口尚未完成内嵌运行接入；终端请使用带验证票据的终端接口。")

    def stop(self):
        if self._runtime is not None:
            runtime=self._runtime
            try:runtime.close()
            except Exception:
                self._refresh_runtime();raise
            self._runtime=None;self._verified_session=None
            self.phase,self.network,self.process_count="stopped","closed",0
            self.message="空间已停止，应用和登录数据均保留。"
            return
        self.phase = "stopping"
        directory = Path(self.settings["sandboxieDirectory"] or ".")
        if self.platform == "win32" and all((directory / item).is_file() for item in ("Start.exe", "SbieIni.exe")):
            control = self._control()
            if self._owned_box(control):
                control.settings("set", self.box_name, "NetworkAccess", "*,Block")
                self.network = "closed"
                control.terminate()
                deadline = time.monotonic() + 4
                while control.pids():
                    if time.monotonic() >= deadline:
                        raise RuntimeError("仍有盒内进程，阻断规则已保留；请在 Sandboxie 中检查此盒。")
                    time.sleep(.1)
        elif self.process_count != 0 or self.network == "unknown":
            raise RuntimeError("Sandboxie 控制组件不可用，无法确认空间已停止；原数据保持不变。")
        self._verified_session = None
        self.phase, self.network, self.process_count = "stopped", "closed", 0
        self.message = "空间已停止，应用和登录数据均保留。"

    def handle(self, request):
        try:
            allowed={"action","settings","entry","kind","workspace","bridgePort","bridgeToken","cols","rows","claudeCommand","leaseId","pid","sessionId","configurationHash","configHash","boxName","profile"}
            if not isinstance(request, dict) or set(request) - allowed:
                raise ValueError("请求格式无效。")
            action = request.get("action")
            launch=None
            if action == "status":
                self.preflight()
            elif action == "configure":
                self.configure(request.get("settings"))
            elif action == "start":
                self.start()
            elif action == "launch":
                launch=self.launch(request.get("entry"))
            elif action in ("prepare-terminal","attach-terminal","release-terminal"):
                if self._runtime is None:raise RuntimeError(NO_PROBE)
                if action=="prepare-terminal":launch=self._runtime.prepare_terminal(request)
                elif action=="attach-terminal":launch=self._runtime.attach_terminal(request)
                else:self._runtime.release(request.get("leaseId"))
            elif action == "stop":
                self.stop()
            else:
                raise ValueError("未知空间操作。")
            reply={"ok": True, "state": self.snapshot()}
            if launch is not None:reply["launch"]=launch
            return reply
        except (OSError, ValueError, TypeError, KeyError, RuntimeError, subprocess.SubprocessError) as exc:
            error = str(exc) if isinstance(exc, (ValueError, RuntimeError)) else "操作失败，请检查文件、安装路径和权限；原数据已保留。"
            if not error or not any("\u4e00" <= char <= "\u9fff" for char in error):
                error = "请求或配置无效；原数据已保留。"
            if self.phase in ("starting", "stopping"):
                self.phase, self.network = "error", "unknown"
            self.message = error
            return {"ok": False, "error": error, "state": self.snapshot()}

    def close(self):
        try:
            self.stop()
        finally:
            self._release_lock()


def serve(worker, input_stream, output_stream):
    try:
        while True:
            line = input_stream.readline(MAX_REQUEST + 1)
            if not line:
                break
            if len(line) > MAX_REQUEST:
                while line and not line.endswith("\n"):
                    line = input_stream.readline(MAX_REQUEST + 1)
                reply = {"ok": False, "error": "请求过大。", "state": worker.snapshot()}
            else:
                try:
                    request = json.loads(line)
                except (ValueError, TypeError):
                    reply = {"ok": False, "error": "请求不是有效 JSON。", "state": worker.snapshot()}
                else:
                    with redirect_stdout(sys.stderr):
                        reply = worker.handle(request)
            output_stream.write(json.dumps(reply, ensure_ascii=False) + "\n")
            output_stream.flush()
    finally:
        worker.close()


def main():
    parser = argparse.ArgumentParser(description="Cage 单空间检查版后台")
    parser.add_argument("--profile", required=True)
    options = parser.parse_args()
    if hasattr(sys.stdin, "reconfigure"):
        sys.stdin.reconfigure(encoding="utf-8")
        sys.stdout.reconfigure(encoding="utf-8", newline="\n")
    try:
        worker = SpaceWorker(options.profile)
        serve(worker, sys.stdin, sys.stdout)
    except (OSError, ValueError, RuntimeError, KeyError, KeyboardInterrupt) as exc:
        # Startup/EOF failures cannot claim that an existing space is stopped.
        message = str(exc) if isinstance(exc, RuntimeError) else "空间后台未能初始化或完整停止；原数据已保留。"
        print(message, file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
