"""Inspect Sandboxie or enable its free WFP component; one JSON response.

This helper does not install software, restart services, stop boxes, or grant
application admission. The caller owns installer elevation and UI decisions.
"""
import argparse
import ctypes
from datetime import datetime, timezone
import hashlib
import json
import ntpath
import os
from pathlib import Path
import shutil
import sys
import uuid

REQUIRED_FILES = ("Start.exe", "SbieIni.exe", "SbieDll.dll", "SbieSvc.exe", "SbieDrv.sys")
WFP_FLAG = 0x00000001
RECONFIGURE_FLAG = 0x00000001
NO_EXPAND = 0x20000000
NO_GLOBAL_OR_TEMPLATES = 0x50000000
NOT_FOUND = {0xC0000034, 0xC000003A, 0xC000008B, 0x8000001A}


class SetupError(Exception):
    def __init__(self, code, message):
        self.code, self.message = code, message
        super().__init__(message)


def status_ok(status, code, message):
    if status:
        raise SetupError(code, message + f"（状态 0x{status & 0xffffffff:08X}）")


def resolve_ini_location(location, directory, windows_directory):
    if location == "H":
        return directory / "Sandboxie.ini"
    if location == "W":
        return windows_directory / "Sandboxie.ini"
    if location.startswith("\\??\\"):
        location = location[4:]
        if location.upper().startswith("UNC\\"):
            location = "\\\\" + location[4:]
    if not ntpath.isabs(location) or location.startswith("\\Device\\"):
        raise SetupError("unknown-ini-location", "无法确认隔离组件的配置文件位置，未修改配置。")
    return Path(location)


class WindowsBackend:
    def __init__(self, directory):
        self.directory = directory
        self._dll = None

    def services_running(self):
        from ctypes import wintypes as w
        api = ctypes.WinDLL("advapi32", use_last_error=True)
        api.OpenSCManagerW.argtypes = [w.LPCWSTR, w.LPCWSTR, w.DWORD]
        api.OpenSCManagerW.restype = w.HANDLE
        api.OpenServiceW.argtypes = [w.HANDLE, w.LPCWSTR, w.DWORD]
        api.OpenServiceW.restype = w.HANDLE
        api.QueryServiceStatusEx.argtypes = [w.HANDLE, ctypes.c_int, ctypes.c_void_p, w.DWORD, ctypes.POINTER(w.DWORD)]
        api.QueryServiceStatusEx.restype = w.BOOL
        api.CloseServiceHandle.argtypes = [w.HANDLE]
        api.CloseServiceHandle.restype = w.BOOL
        manager = api.OpenSCManagerW(None, None, 1)
        if not manager:
            raise SetupError("service-query-failed", "无法检查隔离组件服务状态。")
        states = []
        try:
            for name in ("SbieSvc", "SbieDrv"):
                handle = api.OpenServiceW(manager, name, 4)
                if not handle:
                    if ctypes.get_last_error() == 1060:
                        states.append(False)
                        continue
                    raise SetupError("service-query-failed", "无法检查隔离组件服务状态。")
                try:
                    info = (w.DWORD * 9)()
                    needed = w.DWORD()
                    if not api.QueryServiceStatusEx(handle, 0, info, ctypes.sizeof(info), ctypes.byref(needed)):
                        raise SetupError("service-query-failed", "无法检查隔离组件服务状态。")
                    states.append(info[1] == 4)
                finally:
                    api.CloseServiceHandle(handle)
        finally:
            api.CloseServiceHandle(manager)
        return all(states)

    def version(self):
        from ctypes import wintypes as w
        executable = self.directory / "SandMan.exe"
        if not executable.is_file():
            executable = self.directory / "SbieSvc.exe"
        api = ctypes.WinDLL("version", use_last_error=True)
        api.GetFileVersionInfoSizeW.argtypes = [w.LPCWSTR, ctypes.POINTER(w.DWORD)]
        api.GetFileVersionInfoSizeW.restype = w.DWORD
        api.GetFileVersionInfoW.argtypes = [w.LPCWSTR, w.DWORD, w.DWORD, ctypes.c_void_p]
        api.GetFileVersionInfoW.restype = w.BOOL
        api.VerQueryValueW.argtypes = [ctypes.c_void_p, w.LPCWSTR, ctypes.POINTER(ctypes.c_void_p), ctypes.POINTER(w.UINT)]
        api.VerQueryValueW.restype = w.BOOL
        ignored = w.DWORD()
        size = api.GetFileVersionInfoSizeW(str(executable), ctypes.byref(ignored))
        if not size:
            return ""
        data = ctypes.create_string_buffer(size)
        if not api.GetFileVersionInfoW(str(executable), 0, size, data):
            return ""
        pointer, length = ctypes.c_void_p(), w.UINT()
        if not api.VerQueryValueW(data, "\\", ctypes.byref(pointer), ctypes.byref(length)) or length.value < 52:
            return ""
        fixed = ctypes.cast(pointer, ctypes.POINTER(w.DWORD * 13)).contents
        if fixed[0] != 0xFEEF04BD:
            return ""
        parts = [fixed[2] >> 16, fixed[2] & 65535, fixed[3] >> 16, fixed[3] & 65535]
        if parts[-1] == 0:
            parts.pop()
        return ".".join(map(str, parts))

    @property
    def dll(self):
        if self._dll is None:
            self._dll = ctypes.WinDLL(str(self.directory / "SbieDll.dll"))
            signatures = {
                "SbieApi_QueryDrvInfo": ([ctypes.c_int, ctypes.c_void_p, ctypes.c_ulong], ctypes.c_long),
                "SbieApi_ReloadConf": ([ctypes.c_ulong, ctypes.c_ulong], ctypes.c_long),
                "SbieApi_QueryConf": ([ctypes.c_wchar_p, ctypes.c_wchar_p, ctypes.c_ulong, ctypes.c_wchar_p, ctypes.c_ulong], ctypes.c_long),
                "SbieApi_GetHomePath": ([ctypes.c_wchar_p, ctypes.c_ulong, ctypes.c_wchar_p, ctypes.c_ulong], ctypes.c_long),
                "SbieApi_EnumProcessEx": ([ctypes.c_wchar_p, ctypes.c_ubyte, ctypes.c_ulong, ctypes.c_void_p, ctypes.POINTER(ctypes.c_ulong)], ctypes.c_long),
                "SbieDll_UpdateConf": ([ctypes.c_wchar, ctypes.c_wchar_p, ctypes.c_wchar_p, ctypes.c_wchar_p, ctypes.c_wchar_p], ctypes.c_ulong),
            }
            for name, (args, result) in signatures.items():
                fn = getattr(self._dll, name)
                fn.argtypes, fn.restype = args, result
        return self._dll

    def validate_home(self):
        # GetHomePath takes characters and packs their byte length into USHORT.
        home = ctypes.create_unicode_buffer(16384)
        rc = self.dll.SbieApi_GetHomePath(None, 0, home, len(home))
        status_ok(rc, "driver-query-failed", "无法确认正在运行的隔离组件目录。")
        if os.path.normcase(str(Path(home.value).resolve())) != os.path.normcase(str(self.directory.resolve())):
            raise SetupError("installation-mismatch", "选择的隔离组件目录与当前驱动不一致，未修改配置。")

    def wfp_enabled(self):
        flags = ctypes.c_ulong()
        rc = self.dll.SbieApi_QueryDrvInfo(0, ctypes.byref(flags), 4)
        status_ok(rc, "driver-query-failed", "无法读取内核网络过滤状态。")
        return bool(flags.value & WFP_FLAG)

    def query(self, section, key, *, optional=False):
        # QueryConf takes bytes; stay below its 16-bit UNICODE_STRING limit.
        value = ctypes.create_unicode_buffer(16384)
        flags = NO_EXPAND | (NO_GLOBAL_OR_TEMPLATES if section else 0)
        rc = self.dll.SbieApi_QueryConf(section, key, flags, value, ctypes.sizeof(value))
        if optional and rc & 0xffffffff in NOT_FOUND:
            return ""
        status_ok(rc, "configuration-query-failed", "无法读取隔离组件设置。")
        return value.value

    def wfp_configured(self):
        return self.query("GlobalSettings", "NetworkEnableWFP", optional=True).lower() == "y"

    def ini_path(self):
        kernel = ctypes.WinDLL("kernel32", use_last_error=True)
        kernel.GetWindowsDirectoryW.argtypes = [ctypes.c_wchar_p, ctypes.c_uint]
        kernel.GetWindowsDirectoryW.restype = ctypes.c_uint
        path = ctypes.create_unicode_buffer(32768)
        size = kernel.GetWindowsDirectoryW(path, len(path))
        if not size or size >= len(path):
            raise SetupError("unknown-windows-directory", "无法确认系统目录，未修改配置。")
        return resolve_ini_location(self.query(None, "IniLocation"), self.directory, Path(path.value))

    def active_process_count(self):
        count = ctypes.c_ulong()
        rc = self.dll.SbieApi_EnumProcessEx(None, 1, 0xffffffff, None, ctypes.byref(count))
        status_ok(rc, "process-query-failed", "无法确认现有空间的运行状态，未修改配置。")
        return count.value

    def enable_setting(self):
        rc = self.dll.SbieDll_UpdateConf("s", None, "GlobalSettings", "NetworkEnableWFP", "y")
        if rc == 0xC000006A:
            raise SetupError("configuration-password-required", "隔离组件配置受密码保护，未更改该保护。")
        status_ok(rc, "configuration-update-failed", "无法保存内核网络过滤设置。")
        if not self.wfp_configured():
            raise SetupError("configuration-update-failed", "内核网络过滤设置未保存成功。")

    def reconfigure(self):
        rc = self.dll.SbieApi_ReloadConf(0xffffffff, RECONFIGURE_FLAG)
        status_ok(rc, "driver-reconfigure-failed", "无法加载内核网络过滤；已保留配置备份。")


def initial_result(directory, supported):
    return {"supported": supported, "installed": False, "servicesRunning": False,
            "wfpEnabled": False, "version": "", "directory": str(directory), "message": ""}


def inspect(directory, backend, *, supported=True):
    result = initial_result(directory, supported)
    if not supported:
        result.update(errorCode="unsupported", message="unsupported：轻量沙箱环境安装仅支持 Windows。")
        return result
    result["installed"] = all((directory/name).is_file() for name in REQUIRED_FILES)
    if not result["installed"]:
        result["message"] = "尚未安装完整的 Sandboxie Plus 组件。"
        return result
    try:
        result["version"] = backend.version()
        result["servicesRunning"] = backend.services_running()
        if not result["servicesRunning"]:
            result["message"] = "隔离组件服务尚未运行；本工具不会自动重启服务。"
            return result
        backend.validate_home()
        result["wfpEnabled"] = backend.wfp_enabled()
        result["message"] = "隔离组件与内核网络过滤已就绪；应用隔离验收仍需另行完成。" if result["wfpEnabled"] else "隔离组件已安装，内核网络过滤尚未启用。"
    except SetupError as exc:
        result.update(errorCode=exc.code, message=exc.message)
    except (OSError, AttributeError):
        result.update(errorCode="native-query-failed", message="无法读取隔离组件状态，请检查组件版本和访问权限。")
    return result


def backup_configuration(source, backup_root, configured, enabled):
    backup_root.mkdir(parents=True, exist_ok=True)
    folder = backup_root / ("wfp-" + datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ-") + uuid.uuid4().hex[:8])
    folder.mkdir()
    manifest = {"source": str(source), "existed": source.exists(), "wfpConfiguredBefore": configured,
                "wfpEnabledBefore": enabled, "createdUtc": datetime.now(timezone.utc).isoformat(),
                "restoreNote": "Keep later configuration edits; do not blindly replace a shared configuration with this backup."}
    if manifest["existed"]:
        before = source.read_bytes()
        target = folder / "Sandboxie.ini.before"
        with target.open("xb") as stream:
            stream.write(before)
            stream.flush()
            os.fsync(stream.fileno())
        shutil.copystat(source, target)
        manifest.update(sha256=hashlib.sha256(before).hexdigest(), size=len(before), backup=str(target))
        if target.read_bytes() != before or source.read_bytes() != before:
            raise SetupError("configuration-changed", "备份时配置发生变化，未继续修改，请重试。")
    (folder/"manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8")
    return folder


def enable_wfp(directory, backend, backup_root, *, supported=True):
    result = inspect(directory, backend, supported=supported)
    result["changed"] = False
    if not supported or not result["installed"] or not result["servicesRunning"] or result.get("errorCode"):
        result.setdefault("errorCode", "environment-not-ready")
        return result
    if backup_root is None:
        result.update(errorCode="backup-directory-required", message="启用前需要指定完整备份目录。")
        return result
    try:
        configured = backend.wfp_configured()
        if configured and result["wfpEnabled"]:
            result["message"] = "内核网络过滤已经启用，未改动配置；应用隔离验收仍需另行完成。"
            return result
        if backend.active_process_count():
            raise SetupError("spaces-running", "现有沙箱中仍有程序运行，请关闭这些程序后重试；本工具不会终止它们。")
        source = backend.ini_path()
        folder = backup_configuration(source, backup_root, configured, result["wfpEnabled"])
        result["backupDirectory"] = str(folder)
        if not configured:
            backend.enable_setting()
            result["changed"] = True
        backend.reconfigure()
        result["wfpEnabled"] = backend.wfp_enabled()
        if not result["wfpEnabled"]:
            raise SetupError("wfp-not-active", "设置已保存，但内核网络过滤尚未生效；已保留备份，未重启服务或终止程序。")
        result["changed"] = True
        result["message"] = "内核网络过滤已启用，原配置已备份；应用隔离验收仍需另行完成。"
    except SetupError as exc:
        result.update(errorCode=exc.code, message=exc.message)
    except (OSError, AttributeError):
        result.update(errorCode="setup-failed", message="准备或启用内核网络过滤失败；未重启服务或终止程序。")
    return result


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    modes = parser.add_mutually_exclusive_group(required=True)
    modes.add_argument("--check", action="store_true")
    modes.add_argument("--enable-wfp", action="store_true")
    parser.add_argument("--sandboxie-dir", type=Path, default=Path(os.environ.get("ProgramFiles", r"C:\Program Files"))/"Sandboxie-Plus")
    parser.add_argument("--backup-dir", type=Path)
    args = parser.parse_args(argv)
    directory = args.sandboxie_dir.expanduser().resolve()
    supported = sys.platform == "win32"
    backend = WindowsBackend(directory) if supported else None
    result = enable_wfp(directory, backend, args.backup_dir.resolve() if args.backup_dir else None, supported=supported) if args.enable_wfp else inspect(directory, backend, supported=supported)
    print(json.dumps(result, ensure_ascii=True, separators=(",", ":")), flush=True)
    return 1 if args.enable_wfp and result.get("errorCode") else 0


if __name__ == "__main__":
    raise SystemExit(main())
