"""Privacy06: fixed diagnostic stages only; reuse Privacy05's unaffected code."""
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

base = ROOT / 'dist/Cage-GBox-Privacy-05.apk'
old_work = BUILD / 'pb23d0ff'
work = BUILD / ('pd' + uuid.uuid4().hex[:6])
decoded = work / 'd'
shutil.copytree(old_work / 'd/smali_classes4', decoded / 'smali_classes4')
with ZipFile(base) as archive:
    if archive.read('classes4.dex') != (old_work / 'classes4.dex').read_bytes():
        raise ValueError('Privacy05 DEX source cache mismatch')
spec = importlib.util.spec_from_file_location('privacy_overlay', MODULE / 'privacy/apply.py')
overlay = importlib.util.module_from_spec(spec)
spec.loader.exec_module(overlay)
overlay.add_bind_diagnostics(decoded)
client = (decoded / 'smali_classes4/com/vlite/sdk/client/k.smali').read_text('utf-8')
call = client.index('invoke-virtual {v6, v14, v15}, Landroid/content/Context;->createPackageContext(')
result = client.index('move-result-object v4', call)
before = client.index('->cagePrivacyBindBefore()', result)
bind = client.index('Lio/github/leexeo/cage/privacy/GuestPrivacy;->bind(', before)
after = client.index('->cagePrivacyBindAfter()', bind)
assert call < result < before < bind < after
assert client.count('.method private static cagePrivacyBindBefore()V') == 1
assert client.count('.method private static cagePrivacyBindAfter()V') == 1

jdk = Path('D:/Code/DevEnv/JAVA/jdk-17')
tools = ROOT / 'mobile/.build/client-integration/build-tools35/android-15'
apktool = ROOT / 'mobile/.build/blackbox-source/apktool.jar'
android = ROOT / 'mobile/.build/gbox-test/android.jar'
env = dict(os.environ, JAVA_HOME=str(jdk))
context = {'root': ROOT, 'jdk': jdk, 'tools': tools, 'android_jar': android, 'env': env, 'run': run}
native_spec = importlib.util.spec_from_file_location('privacy_native', MODULE / 'privacy/native/build.py')
native = importlib.util.module_from_spec(native_spec)
native_spec.loader.exec_module(native)
native_result = native.build(work, context)
if set(native_result['extra_entries']) != {'lib/arm64-v8a/libcage_privacy.so'}:
    raise ValueError('Unexpected diagnostic native output')

privacy = work / 'privacy'
shutil.copytree(old_work / 'privacy/generated', privacy / 'generated')
classes, dex = privacy / 'classes', privacy / 'dex'
classes.mkdir(); dex.mkdir()
run(jdk / 'bin/javac.exe', '--release', '8', '-encoding', 'UTF-8', '-g', '-cp', android,
    '-d', classes, *sorted((MODULE / 'privacy/java').rglob('*.java')), *sorted((privacy / 'generated').rglob('*.java')), env=env)
jar = privacy / 'privacy.jar'
with ZipFile(jar, 'w') as archive:
    for file in sorted(classes.rglob('*.class')):
        archive.write(file, file.relative_to(classes).as_posix())
run(tools / 'd8.bat', '--min-api', '28', '--lib', android, '--output', dex, jar, env=env)
run(jdk / 'bin/java.exe', '-cp', apktool, MODULE / 'AssembleDex.java', decoded / 'smali_classes4', work / 'classes4.dex', '28')
replacement = {'classes4.dex': work / 'classes4.dex', 'classes10.dex': dex / 'classes.dex', **native_result['extra_entries']}
with ZipFile(base) as source, ZipFile(work / 'unsigned.apk', 'w') as output:
    for entry in source.infolist():
        if not signature_entry(entry.filename):
            data = replacement[entry.filename].read_bytes() if entry.filename in replacement else source.read(entry.filename)
            output.writestr(entry, data)
    if not set(replacement).issubset(source.namelist()):
        raise ValueError('Diagnostic build unexpectedly added archive entries')

metadata = json.loads((old_work / 'privacy/metadata.json').read_text('utf-8'))
metadata['fixedBindDiagnostics'] = True
metadata['fixedPolicyStageDiagnostics'] = {
    'tag': 'CagePrivacy', 'before': 'stage.context.returned.beforeBind', 'after': 'stage.bind.returned',
    'covers': ['guest bind Java phases', 'NativePrivacy Java phases', 'native ownership/hook installation phases'],
    'labelsOnly': True, 'sensitiveValuesOrPaths': False, 'behaviorChanged': False,
    'legacyMarkerCaveat': 'In incrementally composed Privacy04/05/06, after.createPackageContext follows GuestPrivacy.bind; use the new exact boundary',
    'runtimeValidation': 'NOT_RUN'
}
metadata['nativeComponents']['native'] = native_result['metadata']
(privacy / 'metadata.json').write_text(json.dumps(metadata, ensure_ascii=False, indent=2), encoding='utf-8')
shutil.copytree(old_work / 'compat', work / 'compat')
shutil.copyfile(old_work / 'native-trace.json', work / 'native-trace.json')
validation = json.loads((old_work / 'combined-integration.json').read_text('utf-8'))
validation.update(base=str(base.relative_to(ROOT)), baseSha256=sha(base),
    changedExistingEntries=sorted(replacement), addedEntries=[], diagnosticsOnly=True,
    exactContextReturnAndPrivacyBindBoundaries=True, nativeChildLibraryReused=True,
    existingCoreAndCompatAndTraceDexReused=True, privacyRuntimeAcceptance='NOT_RUN', loginVerified=False)
(work / 'combined-integration.json').write_text(json.dumps(validation, indent=2), encoding='utf-8')
print(str(work / 'unsigned.apk'))
