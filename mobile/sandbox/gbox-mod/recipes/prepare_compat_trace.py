"""Incremental candidate assembly; run only after the runtime bridge is ready."""
from pathlib import Path
import importlib.util
import json
import os
import shutil
import sys
import uuid
from zipfile import ZipFile

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / 'mobile/sandbox/gbox-mod'))
from build import BUILD, MODULE, run, signature_entry
from native_trace import apply as add_trace

base = ROOT / 'dist/Cage-GBox-Baseline-03.apk'
baseline_work = BUILD / 'w9ccac7f'
work = BUILD / ('c' + uuid.uuid4().hex[:7])
work.mkdir()
decoded = work / 'd'
with ZipFile(base) as archive:
    if archive.read('classes4.dex') != (baseline_work / 'classes4.dex').read_bytes():
        raise ValueError('Baseline source cache does not match selected base APK')
    if 'classes8.dex' in archive.namelist():
        raise ValueError('Unexpected extra baseline DEX')
    manifest = archive.read('AndroidManifest.xml')
shutil.copytree(baseline_work / 'd/smali_classes4', decoded / 'smali_classes4')
for number in (1, 2, 3, 5, 6, 7):
    (decoded / ('smali' if number == 1 else f'smali_classes{number}')).mkdir()
(decoded / 'AndroidManifest.xml').write_bytes(manifest)
jdk = Path('D:/Code/DevEnv/JAVA/jdk-17')
tools = ROOT / 'mobile/.build/client-integration/build-tools35/android-15'
apktool = ROOT / 'mobile/.build/blackbox-source/apktool.jar'
context = {'root': ROOT, 'jdk': jdk, 'tools': tools, 'apktool': apktool,
           'android_jar': ROOT / 'mobile/.build/gbox-test/android.jar',
           'input': ROOT / 'mobile/.build/gbox-test/GBox-1.8.4.02.apk',
           'ndk': ROOT / 'mobile/.build/client-integration/ndk',
           'env': dict(os.environ, JAVA_HOME=str(jdk)), 'run': run, 'host_package': 'com.cage.android',
           'native_trace': True}
spec = importlib.util.spec_from_file_location('compat_apply', MODULE / 'compat/apply.py')
compat = importlib.util.module_from_spec(spec)
spec.loader.exec_module(compat)
overlay = compat.apply(decoded, work, context)
changed = {'smali_' + name[:-4] for name in overlay['changed_dex']}
trace_changed, trace_metadata = add_trace(decoded, work, 'com.cage.android', asset_paths=True)
changed |= trace_changed
replacement_dex = {}
for folder in sorted(changed):
    name = folder[len('smali_'):] + '.dex'
    print('Assembling ' + name, flush=True)
    path = work / name
    run(jdk / 'bin/java.exe', '-cp', apktool, MODULE / 'AssembleDex.java', decoded / folder, path, '28')
    replacement_dex[name] = path.read_bytes()
with ZipFile(base) as source, ZipFile(work / 'unsigned.apk', 'w') as output:
    for entry in source.infolist():
        name = entry.filename
        if not signature_entry(name):
            output.writestr(entry, replacement_dex.get(name, source.read(name)))
    for name, data in replacement_dex.items():
        if name not in source.namelist():
            output.writestr(name, data)
    for name, path in overlay['extra_entries'].items():
        if name in source.namelist():
            raise ValueError('Compatibility overlay cannot replace original APK entries')
        output.write(path, name)
(work / 'incremental-build.json').write_text(json.dumps({
    'base': str(base.relative_to(ROOT)), 'sourceWork': str(baseline_work.relative_to(ROOT)),
    'assembledDex': sorted(replacement_dex), 'newEntries': sorted(overlay['extra_entries']),
    'nativeCoreInstructionsOnDiskUnchanged': True,
}, indent=2), encoding='utf-8')
print(str(work / 'unsigned.apk'), flush=True)
