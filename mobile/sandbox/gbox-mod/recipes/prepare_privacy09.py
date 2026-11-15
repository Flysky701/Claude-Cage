"""Privacy09: native load observations, reusing Privacy08's successful binding paths."""
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

base = ROOT / 'dist/Cage-GBox-Privacy-08.apk'
old_work = BUILD / 'phef19c3'
work = BUILD / ('pi' + uuid.uuid4().hex[:6])
privacy = work / 'privacy'
classes, dex = privacy / 'classes', privacy / 'dex'
shutil.copytree(old_work / 'privacy/classes', classes)
shutil.copytree(old_work / 'privacy/generated', privacy / 'generated')
dex.mkdir()
with ZipFile(base) as archive:
    if archive.read('classes10.dex') != (old_work / 'privacy/dex/classes.dex').read_bytes():
        raise ValueError('Privacy08 DEX source cache mismatch')

jdk = Path('D:/Code/DevEnv/JAVA/jdk-17')
tools = ROOT / 'mobile/.build/client-integration/build-tools35/android-15'
android = ROOT / 'mobile/.build/gbox-test/android.jar'
env = dict(os.environ, JAVA_HOME=str(jdk))
run(jdk / 'bin/javac.exe', '--release', '8', '-encoding', 'UTF-8', '-g',
    '-cp', os.pathsep.join((str(android), str(classes))), '-d', classes,
    MODULE / 'privacy/java/io/github/leexeo/cage/privacy/NativePrivacy.java', env=env)
changed_classes = []
for file in sorted(classes.rglob('*.class')):
    relative = file.relative_to(classes)
    previous = old_work / 'privacy/classes' / relative
    if not previous.exists() or file.read_bytes() != previous.read_bytes():
        changed_classes.append(relative.as_posix())
if not changed_classes or any(not name.startswith('io/github/leexeo/cage/privacy/NativePrivacy') for name in changed_classes):
    raise ValueError('Unexpected diagnostic Java class changes: ' + repr(changed_classes))
jar = privacy / 'privacy.jar'
with ZipFile(jar, 'w') as archive:
    for file in sorted(classes.rglob('*.class')):
        archive.write(file, file.relative_to(classes).as_posix())
run(tools / 'd8.bat', '--min-api', '28', '--lib', android, '--output', dex, jar, env=env)

native_source = BUILD / 'native-privacy-check/privacy-native'
native_output = work / 'privacy-native'
native_output.mkdir()
native_library = native_output / 'libcage_privacy.so'
shutil.copyfile(native_source / native_library.name, native_library)
shutil.copyfile(native_source / 'metadata.json', native_output / 'metadata.json')
data = native_library.read_bytes()
if data[:6] != b'\x7fELF\x02\x01' or int.from_bytes(data[18:20], 'little') != 183:
    raise ValueError('Unexpected native diagnostic ABI')
replacement = {'classes10.dex': dex / 'classes.dex', 'lib/arm64-v8a/libcage_privacy.so': native_library}
with ZipFile(base) as source, ZipFile(work / 'unsigned.apk', 'w') as output:
    for entry in source.infolist():
        if not signature_entry(entry.filename):
            output.writestr(entry, replacement[entry.filename].read_bytes() if entry.filename in replacement else source.read(entry.filename))

metadata = json.loads((old_work / 'privacy/metadata.json').read_text('utf-8'))
native_metadata = json.loads((native_output / 'metadata.json').read_text('utf-8'))
native_metadata['bytehookGuard'] = metadata['nativeComponents']['native']['bytehookGuard']
native_metadata['hostMapsParseFix'] = {
    'expectedAssignments': 5, 'suppressedConversionsNotCounted': True,
    'otherValidationConditionsUnchanged': True,
    'offlineEvidence': 'mobile/.build/gbox-mod/native-privacy-check/maps-count-check.json'
}
metadata['nativeComponents']['native'] = native_metadata
metadata['nativeLoadDiagnostics'] = {
    'observationsOnly': True, 'privacyStrategyChanged': False,
    'snapshots': ['before partial registration', 'next main-loop turn', 'binding+1s', 'binding+4s', 'binding+8s'],
    'deviceWait': 'Wait for the +8 second snapshot to be written before stopping the guest process',
    'selectedImagePaths': 'Restricted private guest diagnostic file only; no raw paths in logcat',
    'privateFile': 'guest.getFilesDir()/cage-native-privacy-diagnostic.txt',
    'completionMarker': 'CageNativePrivacy: observation.privateFile.written.3',
    'lifecycleChecks': 'Reused from Privacy08, not rerun',
    'runtimeValidation': 'NOT_RUN'
}
metadata['webView']['runtimeFirstScriptValidation'] = 'Privacy08 PASS; helper bytecode reused; Privacy09 not run'
metadata['nativeComponents']['child']['gboxIntegrationValidation'] = 'Privacy08 PASS; unchanged library and Java class; Privacy09 not run'
(privacy / 'metadata.json').write_text(json.dumps(metadata, ensure_ascii=False, indent=2), encoding='utf-8')
shutil.copytree(old_work / 'compat', work / 'compat', ignore=shutil.ignore_patterns('classes', 'dex', 'classes.jar'))
shutil.copyfile(old_work / 'native-trace.json', work / 'native-trace.json')
validation = json.loads((old_work / 'combined-integration.json').read_text('utf-8'))
validation.update(base=str(base.relative_to(ROOT)), baseSha256=sha(base),
    changedExistingEntries=sorted(replacement), changedExistingDex=['classes10.dex'],
    addedEntries=[], diagnosticsOnly=False, allNativeLibrariesReused=False,
    hostMapsAssignmentCountCorrected=True, nativePolicyScopeChanged=False,
    existingNativeLibrariesAndCompatDexReused=False, compatibilityJavaOnlyChanged=False,
    compatJavaAndNativeReused=True, originalCoreAndChildLibrariesReused=True,
    guestLifecycleAndChildAndWebViewClassesReused=True, changedJavaClasses=changed_classes,
    lifecycleChecksReusedFrom='dist/Cage-GBox-Privacy-08.apk',
    privacyRuntimeAcceptance='NOT_RUN', loginVerified=False)
(work / 'combined-integration.json').write_text(json.dumps(validation, indent=2), encoding='utf-8')
print(str(work / 'unsigned.apk'))
