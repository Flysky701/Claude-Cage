"""Trace06: retain tested Trace05 native bytes and assemble only changed Java DEX."""
from pathlib import Path
import importlib.util
import json
import os
import shutil
import sys
import uuid
from zipfile import ZipFile

ROOT = Path(__file__).resolve().parents[3]
MODULE = ROOT / 'mobile/sandbox/gbox-mod'
sys.path.insert(0, str(MODULE))
from build import BUILD, run, signature_entry, sha
from native_trace import apply as add_trace

base = ROOT / 'dist/Cage-GBox-Native-Trace-05.apk'
old_work = BUILD / 'c5a628d3'
baseline = BUILD / 'w9ccac7f'
work = BUILD / ('f' + uuid.uuid4().hex[:7])
work.mkdir()
decoded = work / 'd'
shutil.copytree(baseline / 'd/smali_classes4', decoded / 'smali_classes4')
for number in (1, 2, 3, 5, 6, 7):
    (decoded / ('smali' if number == 1 else f'smali_classes{number}')).mkdir()
with ZipFile(ROOT / 'dist/Cage-GBox-Baseline-03.apk') as archive:
    if archive.read('classes4.dex') != (baseline / 'classes4.dex').read_bytes():
        raise ValueError('Baseline DEX source cache mismatch')
with ZipFile(base) as archive:
    if archive.read('classes9.dex') != (old_work / 'classes9.dex').read_bytes():
        raise ValueError('Trace05 DEX source cache mismatch')
    (decoded / 'AndroidManifest.xml').write_bytes(archive.read('AndroidManifest.xml'))
    native_bytes = archive.read('lib/arm64-v8a/libcage_compat.so')
    if native_bytes != (old_work / 'compat/libcage_compat.so').read_bytes():
        raise ValueError('Trace05 native cache mismatch')
out = work / 'compat'
out.mkdir()
(out / 'libcage_compat.so').write_bytes(native_bytes)
jdk = Path('D:/Code/DevEnv/JAVA/jdk-17')
tools = ROOT / 'mobile/.build/client-integration/build-tools35/android-15'
apktool = ROOT / 'mobile/.build/blackbox-source/apktool.jar'
android = ROOT / 'mobile/.build/gbox-test/android.jar'
env = dict(os.environ, JAVA_HOME=str(jdk))
classes = out / 'classes'
classes.mkdir()
run(jdk / 'bin/javac.exe', '--release', '8', '-encoding', 'UTF-8', '-cp', android,
    '-d', classes, *(MODULE / 'compat' / name for name in ('NativeCompat.java', 'AssetPathTrace.java', 'FrameworkPaths.java')), env=env)
with ZipFile(out / 'compat.jar', 'w') as archive:
    for path in classes.rglob('*.class'):
        archive.write(path, path.relative_to(classes).as_posix())
dex = out / 'dex'
dex.mkdir()
run(tools / 'd8.bat', '--min-api', '28', '--lib', android, '--output', dex, out / 'compat.jar', env=env)
with ZipFile(out / 'compat-only.apk', 'w') as archive:
    archive.write(decoded / 'AndroidManifest.xml', 'AndroidManifest.xml')
    archive.write(dex / 'classes.dex', 'classes.dex')
run(jdk / 'bin/java.exe', '-jar', apktool, 'd', '--no-res', '--no-assets', '-o', out / 'smali-output', out / 'compat-only.apk', env=env)
shutil.copytree(out / 'smali-output/smali', decoded / 'smali_classes8')
# Same fixed Native.i entry/exit instrumentation as compat.apply(), no native rebuild.
path = decoded / 'smali_classes4/com/vlite/sdk/jni/Native.smali'
source = path.read_text('utf-8')
begin = source.index('.method public static i(Ljava/lang/String;)V')
end = source.index('.end method', begin)
method = source[begin:end]
before, after = '    :cond_0\n    :try_start_0\n', '    :goto_0\n    const/4 p0, 0x1\n'
if method.count(before) != 1 or method.count(after) != 1:
    raise ValueError('Native.i shape changed')
bridge = 'Lio/github/leexeo/cage/gbox/NativeCompat;'
method = method.replace(before, '    :cond_0\n    invoke-static {}, ' + bridge + '->beforeStart()V\n    :try_start_0\n')
method = method.replace(after, '    :goto_0\n    invoke-static {}, ' + bridge + '->afterStart()V\n    const/4 p0, 0x1\n')
path.write_text(source[:begin] + method + source[end:], encoding='utf-8', newline='\n')
spec = importlib.util.spec_from_file_location('framework_apply', MODULE / 'compat/apply.py')
compat = importlib.util.module_from_spec(spec)
spec.loader.exec_module(compat)
compat.patch_framework_sources(decoded)
add_trace(decoded, work, 'com.cage.android', asset_paths=True)
def sources(folder):
    return {str(path.relative_to(folder)): path.read_bytes() for path in folder.rglob('*.smali')}
if sources(decoded / 'smali_classes9') != sources(old_work / 'd/smali_classes9'):
    raise ValueError('Trace DEX changed; cannot reuse it')
replacement = {}
for number in (4, 8):
    path = work / f'classes{number}.dex'
    print('Assembling ' + path.name, flush=True)
    run(jdk / 'bin/java.exe', '-cp', apktool, MODULE / 'AssembleDex.java', decoded / f'smali_classes{number}', path, '28')
    replacement[path.name] = path.read_bytes()
shutil.copyfile(old_work / 'classes9.dex', work / 'classes9.dex')
with ZipFile(base) as original, ZipFile(work / 'unsigned.apk', 'w') as output:
    for entry in original.infolist():
        if not signature_entry(entry.filename):
            output.writestr(entry, replacement.get(entry.filename, original.read(entry.filename)))
metadata = json.loads((old_work / 'compat/metadata.json').read_text('utf-8'))
metadata['frameworkPathAdapter'] = {
    'gate': 'Native compatibility verified, original I/O returned zero, current guest bound with existing code/CE/DE roots',
    'inputs': ['bindData ApplicationInfo copy', 'guest PM ApplicationInfo return copy including cache fallback'],
    'mappingSource': 'Existing Native.a rules only; physical paths already inside the permitted root stay unchanged',
    'optionalUnmappedAndNullPaths': 'preserved', 'requiredCodeAndDataPathsOutsideRoot': 'explicit failure',
    'outsideGuestRootMappings': 'rejected', 'guestContextMayExposePhysicalPrivatePaths': True,
    'serverPackageRecordsModified': False, 'arbitrarySyscallIsolationClaim': False,
}
metadata['nativeLibraryReusedFrom'] = 'dist/Cage-GBox-Native-Trace-05.apk'
(out / 'metadata.json').write_text(json.dumps(metadata, indent=2), encoding='utf-8')
(work / 'incremental-build.json').write_text(json.dumps({
    'base': str(base.relative_to(ROOT)), 'baseSha256': sha(base),
    'assembledDex': sorted(replacement), 'nativeAndTraceDexPreservedByteForByte': True,
}, indent=2), encoding='utf-8')
print(str(work / 'unsigned.apk'), flush=True)
