"""Free Sandboxie policy for explicitly protected host data.

This is a limited policy, not a host-filesystem allowlist. Sandboxie's free
classic rule ordering cannot carve readable exceptions out of a box-only
drive rule. Do not replace the protected paths below with a drive wildcard.
"""
import os
from pathlib import Path


def _path(value, base):
    if not isinstance(value, (str, os.PathLike)) or not str(value).strip():
        raise ValueError("文件路径不能为空")
    expanded = os.path.expandvars(str(value))
    # INI values accept program selectors and glob patterns. A configured path
    # must remain a literal path, including after environment expansion.
    if any(c in expanded for c in '\x00\r\n,*?%') or any(ord(c) < 32 for c in expanded):
        raise ValueError("文件路径不能包含 Sandboxie 规则字符或未展开的环境变量")
    path = (base / expanded).resolve()
    if path.drive.startswith("\\\\") or str(path).startswith("\\\\"):
        raise ValueError("仅支持本机磁盘路径")
    if path == Path(path.anchor):
        raise ValueError("不能将整个磁盘作为应用或共享目录")
    return path


def _within(path, parent):
    return path == parent or parent in path.parents


def _overlap(left, right):
    return _within(left, right) or _within(right, left)


def _directory_rule(path):
    # Sandboxie appends '*'; the separator avoids matching sibling prefixes.
    return str(path).rstrip("\\/") + "\\"


def _protected_paths(home, source):
    profile = Path(os.environ["USERPROFILE"]).resolve()
    local = Path(os.environ["LOCALAPPDATA"]).resolve()
    roaming = Path(os.environ["APPDATA"]).resolve()
    boxed = [profile / name for name in (
        ".ssh", ".aws", ".azure", ".config", ".claude", ".claude.json",
        ".codex", ".npmrc", ".gitconfig", ".git-credentials",
    )]
    boxed.extend((
        local / "Google" / "Chrome" / "User Data",
        local / "Microsoft" / "Edge" / "User Data",
        local / "Mozilla" / "Firefox",
        roaming / "Mozilla" / "Firefox",
        roaming / "Claude",
        home / "profiles",
    ))
    for key in ("TEMP", "TMP"):
        if os.environ.get(key):
            boxed.append(Path(os.environ[key]).resolve())
    # Control files must not become available from an older sandbox copy.
    closed = [profile / ".claude-cage", home / "private", home / "boxes"]
    if source is not None:
        closed.append(source)
    return list(dict.fromkeys(boxed)), list(dict.fromkeys(closed))


def build_policy(program, helpers, home, output, source, sbie, spec, config_dir, root):
    """Return repeated INI key/value pairs; caller must append repeated keys.

    sharedFolders explicitly exposes host data, with read-only or read-write
    access. runtimeDirectories exposes program dependencies for reading only.
    Unlisted ordinary host files remain readable under Sandboxie's classic
    virtualization; protected credential and browser paths are box-only.
    """
    if not isinstance(spec, dict):
        raise ValueError("应用配置必须为对象")
    config_dir = Path(config_dir).resolve()
    program = _path(program, config_dir)
    helpers = [_path(p, config_dir) for p in helpers]
    home = _path(home, config_dir)
    output = _path(output, config_dir)
    source = _path(source, config_dir) if source is not None else None
    sbie = _path(sbie, config_dir)
    root = _path(root, config_dir)
    boxed, closed = _protected_paths(home, source)
    protected = boxed + closed
    for path in protected:
        _path(path, config_dir)

    runtime = spec.get("runtimeDirectories", [])
    if not isinstance(runtime, list) or len(runtime) > 64:
        raise ValueError("runtimeDirectories 必须是最多 64 个目录的数组")
    runtime = [_path(p, config_dir) for p in runtime]
    for path in runtime:
        if not path.is_dir():
            raise ValueError("runtimeDirectories 中的目录不存在")
        if any(_overlap(path, private) for private in protected):
            raise ValueError("运行依赖目录不能包含宿主凭据或启动器控制目录")

    # Selected binaries and their side-by-side dependencies need host reads.
    # Existing classic virtualization already permits those reads, but making
    # them read-only prevents accidental edits to an installation directory.
    runtime = list(dict.fromkeys([program.parent, *(p.parent for p in helpers),
                                 sbie, root / "addon", root / "samples", *runtime]))
    for executable in [program, *helpers]:
        if any(_within(executable, private) for private in protected):
            raise ValueError("程序不能位于受保护的宿主资料或控制目录中")

    shares = spec.get("sharedFolders", [])
    if not isinstance(shares, list) or len(shares) > 64:
        raise ValueError("sharedFolders 必须是最多 64 个共享目录的数组")
    shared_rules = []
    shared_paths = []
    for entry in shares:
        if not isinstance(entry, dict) or set(entry) != {"path", "access"}:
            raise ValueError("每个 sharedFolders 条目需要 path 和 access")
        mode = entry["access"]
        if mode not in ("read-only", "read-write"):
            raise ValueError("共享目录 access 只能是 read-only 或 read-write")
        path = _path(entry["path"], config_dir)
        if not path.is_dir():
            raise ValueError("共享目录不存在")
        if any(_overlap(path, private) for private in protected):
            raise ValueError("共享目录不能包含宿主凭据或启动器控制目录")
        if _overlap(path, home):
            raise ValueError("不能共享沙箱存储根或其子目录")
        if any(_overlap(path, previous) for previous in shared_paths):
            raise ValueError("共享目录不能重复或互相包含")
        # With classic precedence, a read-only parent defeats a writable
        # child. Reject that ambiguous configuration before starting a box.
        if mode == "read-write" and any(_overlap(path, folder) for folder in runtime):
            raise ValueError("可写共享目录不能与程序运行目录重叠")
        shared_paths.append(path)
        # OpenPipePath also accepts a concrete file/directory path. Unlike
        # OpenFilePath it applies to executables installed inside the box.
        # This grants only this selected directory, not arbitrary IPC pipes.
        shared_rules.append(("ReadFilePath" if mode == "read-only" else "OpenPipePath",
                             _directory_rule(path)))

    if any(_overlap(output, private) for private in protected):
        raise ValueError("输出目录不能位于受保护的宿主资料或控制目录中")
    if any(_overlap(output, folder) for folder in runtime):
        raise ValueError("输出目录不能与只读程序运行目录重叠")
    if any(_overlap(output, path) for path in shared_paths):
        raise ValueError("输出目录不能与共享目录重叠")

    pairs = [
        ("DropAdminRights", "y"),
        ("NoSecurityIsolation", "n"),
        ("NoSecurityFiltering", "n"),
        ("BlockNetworkFiles", "y"),
        ("HideOtherBoxes", "y"),
        ("OpenClipboard", "n"),
        # Explicitly retain classic ordering. No supporter-only features.
        ("UseRuleSpecificity", "n"),
        ("WriteKeyPath", "HKEY_CURRENT_USER\\*"),
    ]
    pairs.extend(("WriteFilePath", str(path)) for path in boxed)
    pairs.extend(("ClosedFilePath", str(path)) for path in closed)
    pairs.extend(("ReadFilePath", _directory_rule(path)) for path in runtime)
    pairs.extend(shared_rules)
    pairs.append(("OpenPipePath", _directory_rule(output)))
    return pairs


def safe_environment(program, helpers, extra=None, source_env=None):
    """Build a Windows runtime environment without inheriting caller secrets.

    extra is only for values deliberately supplied by the launcher (such as
    this session's proxy). It is not a pass-through list of host variables.
    """
    source = {key.upper(): value for key, value in
              (os.environ if source_env is None else source_env).items()}
    keys = (
        "SYSTEMROOT", "WINDIR", "SYSTEMDRIVE", "COMSPEC", "OS",
        "PROGRAMFILES", "PROGRAMFILES(X86)", "PROGRAMW6432", "PROGRAMDATA",
        "ALLUSERSPROFILE", "USERPROFILE", "HOMEDRIVE", "HOMEPATH",
        "APPDATA", "LOCALAPPDATA", "TEMP", "TMP", "USERNAME", "USERDOMAIN",
        "COMPUTERNAME", "NUMBER_OF_PROCESSORS", "PROCESSOR_ARCHITECTURE",
        "PROCESSOR_IDENTIFIER", "PROCESSOR_LEVEL", "PROCESSOR_REVISION",
    )
    env = {key: source[key] for key in keys if key in source}
    windows = Path(source.get("SYSTEMROOT", r"C:\Windows"))
    directories = [windows / "System32", windows,
                   windows / "System32" / "Wbem",
                   windows / "System32" / "WindowsPowerShell" / "v1.0",
                   Path(program).parent, *(Path(p).parent for p in helpers)]
    env["PATH"] = ";".join(dict.fromkeys(str(path) for path in directories))
    env["PATHEXT"] = ".COM;.EXE;.BAT;.CMD"
    env["PSMODULEPATH"] = str(windows / "System32" / "WindowsPowerShell" / "v1.0" / "Modules")
    if extra is not None:
        if not isinstance(extra, dict):
            raise ValueError("显式环境变量必须为对象")
        for key, value in extra.items():
            if (not isinstance(key, str) or not key or "=" in key or
                    not isinstance(value, str) or "\x00" in key + value):
                raise ValueError("无效的显式环境变量")
            env[key.upper()] = value
    return env
