from pathlib import Path
import json
import shutil
import sys
import uuid
from zipfile import ZipFile

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / 'mobile/sandbox/gbox-mod'))
from build import BUILD, MODULE, run, signature_entry
from native_relocation import TARGETS, relocate
from native_trace import apply

base = ROOT / 'dist/Cage-GBox-Baseline-02.apk'
baseline_work = BUILD / 'w9ccac7f'
work = BUILD / ('n' + uuid.uuid4().hex[:7])
work.mkdir()
decoded = work / 'd'
with ZipFile(base) as archive:
    if archive.read('classes4.dex') != (baseline_work / 'classes4.dex').read_bytes():
        raise ValueError('Baseline source cache does not match selected base APK')
    if 'classes8.dex' in archive.namelist():
        raise ValueError('Unexpected extra baseline DEX')
shutil.copytree(baseline_work / 'd/smali_classes4', decoded / 'smali_classes4')
if any('NativeTrace;' in file.read_text('utf-8') for file in (decoded / 'smali_classes4/com/vlite/sdk').rglob('*.smali')):
    raise ValueError('Baseline source cache already contains trace hooks')
for number in (1, 2, 3, 5, 6, 7):
    (decoded / ('smali' if number == 1 else f'smali_classes{number}')).mkdir()
changed, metadata = apply(decoded, work, 'com.cage.android')
jdk = Path('D:/Code/DevEnv/JAVA/jdk-17')
apktool = ROOT / 'mobile/.build/blackbox-source/apktool.jar'
replacement_dex = {}
for folder in sorted(changed):
    name = folder[len('smali_'):] + '.dex'
    print('Assembling ' + name, flush=True)
    path = work / name
    run(jdk / 'bin/java.exe', '-cp', apktool, MODULE / 'AssembleDex.java', decoded / folder, path, '28')
    replacement_dex[name] = path.read_bytes()
native = {}
with ZipFile(base) as source, ZipFile(work / 'unsigned.apk', 'w') as output:
    for entry in source.infolist():
        name = entry.filename
        if signature_entry(name):
            continue
        data = replacement_dex.get(name, source.read(name))
        if name in TARGETS:
            data, native[name] = relocate(name, data)
        output.writestr(entry, data)
    for name, data in replacement_dex.items():
        if name not in source.namelist():
            output.writestr(name, data)
if set(native) != set(TARGETS):
    raise ValueError('Expected all native host constant targets')
(work / 'incremental-build.json').write_text(json.dumps({
    'base': str(base.relative_to(ROOT)), 'sourceWork': str(baseline_work.relative_to(ROOT)),
    'assembledDex': sorted(replacement_dex), 'nativeHostRelocations': native,
}, indent=2), encoding='utf-8')
print(str(work / 'unsigned.apk'), flush=True)
