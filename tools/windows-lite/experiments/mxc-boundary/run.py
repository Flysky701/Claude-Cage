"""Run a synthetic filesystem/child/persistence check through official MXC only."""
import argparse
import ctypes
import hashlib
import json
import os
import subprocess
import time
import uuid
from datetime import datetime
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[3]
NO_WINDOW = getattr(subprocess, 'CREATE_NO_WINDOW', 0)


def save(path, value):
    path.write_text(json.dumps(value, indent=2, ensure_ascii=False), encoding='utf-8')


def acl_hash(path):
    api = ctypes.WinDLL('advapi32', use_last_error=True).GetFileSecurityW
    api.argtypes = [ctypes.c_wchar_p, ctypes.c_uint32, ctypes.c_void_p, ctypes.c_uint32, ctypes.POINTER(ctypes.c_uint32)]
    api.restype = ctypes.c_int
    size = ctypes.c_uint32()
    api(str(path), 7, None, 0, ctypes.byref(size))
    data = ctypes.create_string_buffer(size.value)
    if not api(str(path), 7, data, size.value, ctypes.byref(size)):
        raise ctypes.WinError(ctypes.get_last_error())
    return hashlib.sha256(data.raw[:size.value]).hexdigest()


def build(directory):
    program = Path(os.environ.get('ProgramFiles(x86)', r'C:\Program Files (x86)'))
    locator = program / 'Microsoft Visual Studio/Installer/vswhere.exe'
    found = subprocess.check_output([str(locator), '-latest', '-products', '*', '-requires', 'Microsoft.VisualStudio.Component.VC.Tools.x86.x64', '-find', r'VC\Tools\MSVC\**\bin\Hostx64\x64\cl.exe'], text=True)
    compiler = Path(found.strip().splitlines()[0])
    msvc = compiler.parents[3]
    sdk = program / 'Windows Kits/10'
    version = sorted((sdk / 'Include').glob('10.*'), key=lambda p: tuple(map(int, p.name.split('.'))))[-1].name
    includes = [msvc / 'include', *[sdk / 'Include' / version / key for key in ('ucrt', 'shared', 'um', 'winrt')]]
    libs = [msvc / 'lib/x64', *[sdk / 'Lib' / version / key / 'x64' for key in ('ucrt', 'um')]]
    env = dict(os.environ, INCLUDE=os.pathsep.join(map(str, includes)), LIB=os.pathsep.join(map(str, libs)))
    env['PATH'] = str(compiler.parent) + os.pathsep + env.get('PATH', '')
    with (directory / 'build.log').open('w', encoding='utf-8') as log:
        subprocess.run([str(compiler), '/nologo', '/O2', '/W4', '/MT', '/D_CRT_SECURE_NO_WARNINGS', str(HERE / 'probe.c'), '/Fe:CageMxcBoundaryProbe.exe', '/link', 'advapi32.lib', 'crypt32.lib'], cwd=directory, env=env, stdout=log, stderr=subprocess.STDOUT, creationflags=NO_WINDOW, check=True)
    return directory / 'CageMxcBoundaryProbe.exe'


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--launcher', type=Path, required=True)
    parser.add_argument('--deny-drive-roots', action='store_true')
    parser.add_argument('--persistence', action='store_true')
    args = parser.parse_args()
    launcher = args.launcher.resolve(strict=True)
    tag = datetime.now().strftime('%Y%m%d-%H%M%S') + '-' + uuid.uuid4().hex[:8]
    root = REPO / '_output/windows-lite' / ('mxc-boundary-' + tag)
    root.mkdir(parents=True, exist_ok=False)
    binary, data, host = (root / key for key in ('bin', 'data', 'host-private'))
    for directory in (binary, data, host):
        directory.mkdir()
    exe = build(binary)
    marker = uuid.uuid4().hex
    sentinel = host / 'host-sentinel.txt'
    sentinel.write_text('synthetic host-only marker', encoding='utf-8')
    readonly_sentinel = binary / 'bin-ro-sentinel.txt'
    readonly_sentinel.write_text('synthetic read-only binary directory marker', encoding='utf-8')
    watched = [root, binary, exe, data, host, sentinel, readonly_sentinel]
    acl_before = {str(path): acl_hash(path) for path in watched}
    windows = os.environ.get('SystemRoot', r'C:\Windows')
    env = [f'SystemRoot={windows}', f'windir={windows}', f'SystemDrive={windows[:2]}', f'PATH={windows}\\System32;{windows}', f'LOCALAPPDATA={data}', f'APPDATA={data}', f'TEMP={data}', f'TMP={data}', f'USERPROFILE={data}']
    base = {'version': '1.0.0', 'containerId': 'CageMxcBoundary-' + uuid.uuid4().hex, 'containment': 'processcontainer', 'lifecycle': {'destroyOnExit': True, 'preservePolicy': False}, 'filesystem': {'readonlyPaths': [str(binary)], 'readwritePaths': [str(data)], 'deniedPaths': []}, 'network': {'egress': {'default': 'deny'}, 'ingress': {'default': 'deny', 'hostLoopback': 'deny'}}, 'ui': {'disable': True, 'clipboard': 'none', 'injection': False}, 'process': {'cwd': str(data), 'env': env, 'inheritDefaultEnv': False, 'timeout': 25000}}
    if args.deny_drive_roots:
        drives = ctypes.WinDLL('kernel32').GetLogicalDrives()
        base['filesystem']['deniedPaths'] = [chr(65 + bit) + ':\\' for bit in range(26) if drives & (1 << bit)]
        base['filesystem']['readonlyPaths'].append(str(Path(windows) / 'System32'))
    report = {'root': str(root), 'launcher': str(launcher), 'launcherSha256': hashlib.sha256(launcher.read_bytes()).hexdigest(), 'binarySha256': hashlib.sha256(exe.read_bytes()).hexdigest(), 'sourceSha256': hashlib.sha256((HERE / 'probe.c').read_bytes()).hexdigest(), 'scope': 'Official MXC launcher, synthetic program only, no ACL mutations, no network access, no real applications', 'rounds': []}
    report['denyDriveRoots'] = args.deny_drive_roots
    report['supplementalPersistenceRequested'] = args.persistence
    report['syntheticRegistryPath'] = 'HKEY_CURRENT_USER\\Software\\CageMxcSynthetic\\' + marker if args.persistence else None
    print(json.dumps({'stage': 'created', 'root': str(root)}), flush=True)
    try:
        for round in ('1', '2'):
            command = [str(exe), 'parent', str(data), str(host), round, marker, 'synthetic-only']
            if args.persistence:
                command.append('persistence')
            base['process']['commandLine'] = subprocess.list2cmdline(command)
            policy = root / f'policy-{round}.json'
            save(policy, base)
            check = subprocess.run([str(launcher), '--probe', str(policy)], capture_output=True, timeout=20, creationflags=NO_WINDOW)
            (root / f'probe-{round}.stdout').write_bytes(check.stdout)
            (root / f'probe-{round}.stderr').write_bytes(check.stderr)
            verdict = json.loads(check.stdout)
            if check.returncode or verdict.get('tier') != 'base-container' or verdict.get('needsDaclAugmentation') is not False:
                raise RuntimeError(f'MXC request probe rejected: exit={check.returncode}, result={verdict}')
            record = {'round': int(round), 'probe': verdict}
            report['rounds'].append(record)
            with (root / f'run-{round}.stdout').open('wb') as out, (root / f'run-{round}.stderr').open('wb') as err:
                process = subprocess.Popen([str(launcher), '--log-file', str(root / f'run-{round}.log'), str(policy)], stdin=subprocess.DEVNULL, stdout=out, stderr=err, creationflags=NO_WINDOW)
                record['launcherPID'] = process.pid
                try:
                    until = time.monotonic() + 18
                    ready = data / f'round{round}.ready'
                    while not ready.exists() and process.poll() is None and time.monotonic() < until:
                        time.sleep(.05)
                    if not ready.exists():
                        raise RuntimeError(f'Contained probe did not become ready; launcher exit={process.poll()}')
                    (host / f'late-{round}.txt').write_text('new synthetic host-only marker', encoding='utf-8')
                    (data / f'round{round}.continue').write_text('continue', encoding='utf-8')
                    record['exitCode'] = process.wait(timeout=30)
                finally:
                    if process.poll() is None:
                        process.terminate()
                        process.wait(timeout=10)
            record['results'] = {role: json.loads((data / f'{role}-{round}.json').read_text(encoding='utf-8')) for role in ('parent', 'child')}
            if args.persistence:
                record['supplemental'] = json.loads((data / f'supplemental-{round}.json').read_text(encoding='utf-8'))
            if record['exitCode'] or not all(value['passed'] for value in record['results'].values()):
                raise RuntimeError(f'Round {round} failed')
        report['passed'] = True
    except Exception as error:
        report['passed'] = False
        report['error'] = str(error)
    finally:
        report['aclUnchanged'] = acl_before == {str(path): acl_hash(path) for path in watched}
        report['hostUnchanged'] = sentinel.read_text(encoding='utf-8') == 'synthetic host-only marker' and not (host / 'must-not-create.txt').exists()
        report['readonlyBinaryUnchanged'] = readonly_sentinel.read_text(encoding='utf-8') == 'synthetic read-only binary directory marker' and not list(binary.glob('bin-must-not-create-*.txt'))
        report['dataPreserved'] = True
        report['passed'] = report.get('passed', False) and report['aclUnchanged'] and report['hostUnchanged'] and report['readonlyBinaryUnchanged']
        report['filesystemBoundaryPassed'] = report['passed']
        if args.persistence:
            report['dpapiPersistencePassed'] = len(report['rounds']) == 2 and all(item.get('supplemental', {}).get('dpapi', {}).get('passed') is True for item in report['rounds'])
            report['registryPersistencePassed'] = len(report['rounds']) == 2 and all(item.get('supplemental', {}).get('registry', {}).get('passed') is True for item in report['rounds'])
            report['passed'] = report['passed'] and report['dpapiPersistencePassed'] and report['registryPersistencePassed']
        save(root / 'report.json', report)
        print(json.dumps({'root': str(root), 'passed': report['passed'], 'error': report.get('error'), 'aclUnchanged': report['aclUnchanged'], 'hostUnchanged': report['hostUnchanged']}), flush=True)
    if not report['passed']:
        raise SystemExit(1)


if __name__ == '__main__':
    main()
