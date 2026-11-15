"""Privacy07: update the two diagnosed guards; reuse every unaffected APK entry."""
from pathlib import Path
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

base = ROOT / 'dist/Cage-GBox-Privacy-06.apk'
old_work = BUILD / 'pd9805f7'
work = BUILD / ('pg' + uuid.uuid4().hex[:6])
privacy = work / 'privacy'
classes, dex = privacy / 'classes', privacy / 'dex'
shutil.copytree(old_work / 'privacy/classes', classes)
shutil.copytree(old_work / 'privacy/generated', privacy / 'generated')
dex.mkdir()
with ZipFile(base) as archive:
    if archive.read('classes10.dex') != (old_work / 'privacy/dex/classes.dex').read_bytes():
        raise ValueError('Privacy06 DEX source cache mismatch')

jdk = Path('D:/Code/DevEnv/JAVA/jdk-17')
tools = ROOT / 'mobile/.build/client-integration/build-tools35/android-15'
android = ROOT / 'mobile/.build/gbox-test/android.jar'
env = dict(os.environ, JAVA_HOME=str(jdk))
child_source = MODULE / 'privacy/java/io/github/leexeo/cage/privacy/ChildPolicy.java'
run(jdk / 'bin/javac.exe', '--release', '8', '-encoding', 'UTF-8', '-g',
    '-cp', os.pathsep.join((str(android), str(classes))), '-d', classes, child_source, env=env)
changed_classes = [f.relative_to(classes).as_posix() for f in sorted(classes.rglob('*.class'))
                   if f.read_bytes() != (old_work / 'privacy/classes' / f.relative_to(classes)).read_bytes()]
if changed_classes != ['io/github/leexeo/cage/privacy/ChildPolicy.class']:
    raise ValueError('Unexpected Java class changes: ' + repr(changed_classes))
jar = privacy / 'privacy.jar'
with ZipFile(jar, 'w') as archive:
    for file in sorted(classes.rglob('*.class')):
        archive.write(file, file.relative_to(classes).as_posix())
run(tools / 'd8.bat', '--min-api', '28', '--lib', android, '--output', dex, jar, env=env)

# Reuse the module owner's completed -Werror/-z defs build; no second compilation.
native_source = BUILD / 'native-privacy-check/privacy-native'
native_output = work / 'privacy-native'
native_output.mkdir()
native_library = native_output / 'libcage_privacy.so'
shutil.copyfile(native_source / native_library.name, native_library)
shutil.copyfile(native_source / 'metadata.json', native_output / 'metadata.json')
native_bytes = native_library.read_bytes()
if native_bytes[:6] != b'\x7fELF\x02\x01' or int.from_bytes(native_bytes[18:20], 'little') != 183:
    raise ValueError('Unexpected parent native ABI')
if b'bytehook version 1.0.8\x00' not in native_bytes or b'api.tableAbi.exact19Slots\x00' not in native_bytes:
    raise ValueError('Native guard fix absent from compiled module')

replacement = {'classes10.dex': dex / 'classes.dex', 'lib/arm64-v8a/libcage_privacy.so': native_library}
with ZipFile(base) as source, ZipFile(work / 'unsigned.apk', 'w') as output:
    if not set(replacement).issubset(source.namelist()):
        raise ValueError('Incremental build unexpectedly adds archive entries')
    for entry in source.infolist():
        if not signature_entry(entry.filename):
            data = replacement[entry.filename].read_bytes() if entry.filename in replacement else source.read(entry.filename)
            output.writestr(entry, data)

metadata = json.loads((old_work / 'privacy/metadata.json').read_text('utf-8'))
metadata['nativeComponents']['native'] = json.loads((native_output / 'metadata.json').read_text('utf-8'))
metadata['nativeComponents']['native']['bytehookGuard'] = {
    'version': 'Exact complete original string, including bytehook version prefix',
    'table': 'Exact table address and all 19 original slot RVAs',
    'rejectionDiagnostics': 'Fixed reason labels; no values or paths',
    'runtimeValidation': 'NOT_RUN'
}
metadata['nativeComponents']['child'].update({
    'parentGate': 'Completed NativeCompat native property/sample verification plus SDK/64bit/current selected identity',
    'javaBuildCacheComparison': 'Diagnostic booleans only; original VLite can rewrite these guest cache fields',
    'childGate': 'Unchanged independent exact raw-property and actual executable ELF checks',
    'parentGateEvidence': 'mobile/.build/gbox-mod/child-probe/native-profile-gate-evidence.json',
    'gboxIntegrationValidation': 'NOT_RUN'
})
metadata['webView']['previousPrivacy06FirstScriptValidation'] = 'PASS; mobile/.build/gbox-mod/mumu/privacy06-comparison.json'
metadata['webView']['runtimeFirstScriptValidation'] = 'NOT_RUN for Privacy07; helper bytecode reused from Privacy06'
metadata['fixedPolicyStageDiagnostics']['legacyMarkerCaveat'] = 'Incremental Privacy04 through Privacy07 retain after.createPackageContext after GuestPrivacy.bind; use the exact bind markers'
(privacy / 'metadata.json').write_text(json.dumps(metadata, ensure_ascii=False, indent=2), encoding='utf-8')
shutil.copytree(old_work / 'compat', work / 'compat')
shutil.copyfile(old_work / 'native-trace.json', work / 'native-trace.json')
validation = json.loads((old_work / 'combined-integration.json').read_text('utf-8'))
validation.update(base=str(base.relative_to(ROOT)), baseSha256=sha(base),
    changedExistingEntries=sorted(replacement), changedExistingDex=['classes10.dex'], addedEntries=[],
    diagnosticsOnly=False, changedJavaClasses=changed_classes,
    guardFixes=['Original complete ByteHook version and exact table ABI',
               'Child parent guard uses completed native profile verification instead of virtualized Java caches'],
    nativeChildLibraryReused=True, existingCoreAndCompatAndTraceDexReused=True,
    privacyRuntimeAcceptance='NOT_RUN', loginVerified=False)
(work / 'combined-integration.json').write_text(json.dumps(validation, indent=2), encoding='utf-8')
print(str(work / 'unsigned.apk'))
