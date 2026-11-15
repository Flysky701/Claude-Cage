"""Privacy11: reuse the original compatibility library and add the host-ISA loader bridge."""
from pathlib import Path
import importlib.util
import json
import os
import shutil
import sys
import uuid
from zipfile import ZipFile, ZIP_DEFLATED

ROOT = Path(__file__).resolve().parents[3]
MODULE = ROOT / 'mobile/sandbox/gbox-mod'
sys.path.insert(0, str(MODULE))
from build import BUILD, dex_classes, run, signature_entry, sha

base = ROOT / 'dist/Cage-GBox-Privacy-10.apk'
compat_base = ROOT / 'dist/Cage-GBox-Privacy-09.apk'
old_work = BUILD / 'pj54e69b'
work = BUILD / ('pk' + uuid.uuid4().hex[:6])
privacy, compat = work / 'privacy', work / 'compat'
classes, dex = privacy / 'classes', privacy / 'dex'
shutil.copytree(old_work / 'privacy/classes', classes)
shutil.copytree(old_work / 'privacy/generated', privacy / 'generated')
dex.mkdir()
compat.mkdir()
with ZipFile(base) as archive:
    if archive.read('classes10.dex') != (old_work / 'privacy/dex/classes.dex').read_bytes():
        raise ValueError('Privacy10 DEX source cache mismatch')

jdk = Path('D:/Code/DevEnv/JAVA/jdk-17')
tools = ROOT / 'mobile/.build/client-integration/build-tools35/android-15'
android = ROOT / 'mobile/.build/gbox-test/android.jar'
env = dict(os.environ, JAVA_HOME=str(jdk))
updated = privacy / 'updated-classes'
updated.mkdir()
run(jdk / 'bin/javac.exe', '--release', '8', '-encoding', 'UTF-8', '-g',
    '-cp', os.pathsep.join((str(android), str(classes))), '-d', updated,
    MODULE / 'privacy/java/io/github/leexeo/cage/privacy/NativePrivacy.java',
    MODULE / 'privacy/java/io/github/leexeo/cage/privacy/GuestPrivacy.java',
    MODULE / 'privacy/java/io/github/leexeo/cage/privacy/HostLoadPolicy.java', env=env)
families = ('NativePrivacy', 'GuestPrivacy', 'HostLoadPolicy')
package = Path('io/github/leexeo/cage/privacy')
for file in (classes / package).glob('*.class'):
    if any(file.stem == family or file.stem.startswith(family + '$') for family in families):
        file.unlink()
for file in updated.rglob('*.class'):
    target = classes / file.relative_to(updated)
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(file, target)
changed_classes = []
for file in sorted(classes.rglob('*.class')):
    relative = file.relative_to(classes)
    previous = old_work / 'privacy/classes' / relative
    if not previous.exists() or file.read_bytes() != previous.read_bytes():
        changed_classes.append(relative.as_posix())
if any(not name.startswith(tuple('io/github/leexeo/cage/privacy/' + family for family in families))
       for name in changed_classes):
    raise ValueError('Unexpected Java changes: ' + repr(changed_classes))
jar = privacy / 'privacy.jar'
with ZipFile(jar, 'w') as archive:
    for file in sorted(classes.rglob('*.class')):
        archive.write(file, file.relative_to(classes).as_posix())
run(tools / 'd8.bat', '--min-api', '28', '--lib', android, '--output', dex, jar, env=env)
if any(name.startswith('Lio/github/leexeo/cage/privacy/host/') for name in dex_classes((dex / 'classes.dex').read_bytes())):
    raise ValueError('Host helper leaked into the application DEX')

spec = importlib.util.spec_from_file_location('cage_privacy_host_build', MODULE / 'privacy/host/build.py')
host_build = importlib.util.module_from_spec(spec)
spec.loader.exec_module(host_build)
host = host_build.build(work, {'root': ROOT, 'jdk': jdk, 'tools': tools,
                             'android_jar': android, 'run': run, 'env': env})
host_classes = dex_classes(host['extra_entries']['assets/cage-host/host-bridge.dex'].read_bytes())
if host_classes != {'Lio/github/leexeo/cage/privacy/host/HostBridge;'}:
    raise ValueError('Unexpected classes in isolated host DEX')

# This exact library predates the failed copied Runtime observer. The owner has
# also restored its source and compared runtime.o byte-for-byte with this build.
compat_library = compat / 'libcage_compat.so'
with ZipFile(compat_base) as archive:
    compat_library.write_bytes(archive.read('lib/arm64-v8a/libcage_compat.so'))
if sha(compat_library) != 'ba9c5d9e2725cdd07f139b6c68e4c72f7d274f5a0369c24e2d5383fd3913c441':
    raise ValueError('Original compatibility library identity mismatch')
native_source = BUILD / 'native-privacy-check/privacy11/privacy-native'
native_output = work / 'privacy-native'
native_output.mkdir()
native_library = native_output / 'libcage_privacy.so'
shutil.copyfile(native_source / native_library.name, native_library)
shutil.copyfile(native_source / 'metadata.json', native_output / 'metadata.json')
for library in (native_library, compat_library):
    raw = library.read_bytes()
    if raw[:6] != b'\x7fELF\x02\x01' or int.from_bytes(raw[18:20], 'little') != 183:
        raise ValueError('Unexpected native library ABI')

replacement = {'classes10.dex': dex / 'classes.dex',
               'lib/arm64-v8a/libcage_privacy.so': native_library,
               'lib/arm64-v8a/libcage_compat.so': compat_library}
added = host['extra_entries']
with ZipFile(base) as source, ZipFile(work / 'unsigned.apk', 'w') as output:
    if any(source.read(name) == path.read_bytes() for name, path in replacement.items()):
        raise ValueError('Expected replacement did not change')
    if set(source.namelist()).intersection(added):
        raise ValueError('Host asset name already exists')
    for entry in source.infolist():
        if not signature_entry(entry.filename):
            contents = replacement[entry.filename].read_bytes() if entry.filename in replacement else source.read(entry.filename)
            output.writestr(entry, contents)
    for name, path in added.items():
        output.writestr(name, path.read_bytes(), compress_type=ZIP_DEFLATED)

boundary = {
    'method': 'java.lang.Runtime.nativeLoad(String, ClassLoader, Class): String',
    'abi': 'Host x86_64 ordinary JNI wrapper; callback by JNI into the ARM policy library',
    'originalRuntimeArtMethodIdentityPreserved': True,
    'copiedRuntimeMethodObserverRemoved': True,
    'originalCall': 'Direct saved host JNI entry on the original Runtime method',
    'originalParametersAndResultPreserved': True,
    'originalPendingExceptionPreserved': True,
    'observerPendingException': 'Logged and propagated; not silently cleared or counted as a successful notification',
    'registrationAttemptFailure': 'Unknown or partially registered state is fatal to reuse',
    'legitimateNestedNativeLoadsAllowed': True,
    'separateFromOriginal11Installations': True,
    'trigger': 'Synchronous notification after original null result with no pending exception, before returning to Java',
    'refresh': 'Exact-sample original core post_dlopen(task_manager), retaining existing partial tasks',
    'periodicRefresh': False,
    'independentProof': 'mobile/.build/gbox-mod/mumu/host-load-probe02-result.json',
    'probe01Cause': 'Undetermined; no causal repair claimed from added diagnostics',
    'missingLibraryFailureCheck': 'Same original error String and zero refresh notifications',
    'notClaimed': host['metadata']['notClaimed'] + ['direct-resolved calls', 'raw syscalls'],
    'runtimeValidation': 'NOT_RUN_FOR_PRIVACY11'
}
metadata = json.loads((old_work / 'privacy/metadata.json').read_text('utf-8'))
native_metadata = json.loads((native_output / 'metadata.json').read_text('utf-8'))
for name in ('bytehookGuard', 'hostMapsParseFix'):
    native_metadata[name] = metadata['nativeComponents']['native'][name]
native_metadata['postNativeLoadRefresh'] = boundary
metadata['nativeComponents']['native'] = native_metadata
metadata['nativeComponents']['host'] = host['metadata']
metadata['nativeLoadDiagnostics']['runtimeValidation'] = 'Privacy10 failed in WebView JNI_OnLoad due to copied Runtime method loader identity; Privacy11 not run'
metadata['webView']['runtimeFirstScriptValidation'] = 'Privacy08/09 PASS; helper bytecode reused unchanged; Privacy11 not run'
metadata['nativeComponents']['child']['gboxIntegrationValidation'] = 'Privacy08/09 PASS; library and Java classes unchanged; Privacy11 not run'
metadata['notClaimed'] = [item for item in metadata['notClaimed'] if item != 'unvalidated GBox child integration']
(privacy / 'metadata.json').write_text(json.dumps(metadata, ensure_ascii=False, indent=2), encoding='utf-8')
compat_metadata = json.loads((BUILD / 'pie61c44/compat/metadata.json').read_text('utf-8'))
compat_metadata['nativeLibraryReusedFrom'] = str(compat_base.relative_to(ROOT))
compat_metadata['runtimeNativeLoadModifiedByCompatibilityModule'] = False
compat_metadata['copiedRuntimeLoadObserverIncluded'] = False
(compat / 'metadata.json').write_text(json.dumps(compat_metadata, indent=2), encoding='utf-8')
shutil.copyfile(old_work / 'native-trace.json', work / 'native-trace.json')
validation = {
    'base': str(base.relative_to(ROOT)), 'baseSha256': sha(base),
    'changedExistingEntries': sorted(replacement), 'changedExistingDex': ['classes10.dex'],
    'addedEntries': sorted(added), 'changedJavaClasses': changed_classes,
    'isolatedHelperClasses': sorted(host_classes),
    'childAndWebViewClassesReused': True,
    'guestFirstBindingAdmissionUnchanged': True,
    'frameworkPathAndTraceDexReused': True,
    'originalCoreAndPresetsReused': True,
    'original17AdaptersAnd11VerificationSetUnchanged': True,
    'lifecycleChecksReusedFrom': 'dist/Cage-GBox-Privacy-08.apk',
    'compatibilityNativeReusedFrom': str(compat_base.relative_to(ROOT)),
    'copiedRuntimeLoadObserverRemoved': True,
    'parentNativeLibrary': str(native_source.relative_to(ROOT) / 'libcage_privacy.so'),
    'hostHelperPackaging': 'Independent DEX and x86_64 ELF assets only; no native ABI directory added',
    'nativeLoadBoundary': boundary,
    'privacyRuntimeAcceptance': 'NOT_RUN', 'loginVerified': False
}
(work / 'combined-integration.json').write_text(json.dumps(validation, indent=2), encoding='utf-8')
(BUILD / 'privacy11-work.json').write_text(json.dumps({'work': str(work.relative_to(ROOT))}), encoding='utf-8')
print(json.dumps({'unsigned': str(work / 'unsigned.apk'), 'changedJavaClasses': changed_classes}))
