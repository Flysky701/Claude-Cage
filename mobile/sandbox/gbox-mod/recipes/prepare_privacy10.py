"""Privacy10: synchronous post-nativeLoad refresh; reuse already validated guest paths."""
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

base = ROOT / 'dist/Cage-GBox-Privacy-09.apk'
old_work = BUILD / 'pie61c44'
native_cache = BUILD / 'c5a628d3/compat'
work = BUILD / ('pj' + uuid.uuid4().hex[:6])
privacy, compat = work / 'privacy', work / 'compat'
classes, dex = privacy / 'classes', privacy / 'dex'
shutil.copytree(old_work / 'privacy/classes', classes)
shutil.copytree(old_work / 'privacy/generated', privacy / 'generated')
dex.mkdir()
compat.mkdir()
with ZipFile(base) as archive:
    if archive.read('classes10.dex') != (old_work / 'privacy/dex/classes.dex').read_bytes():
        raise ValueError('Privacy09 DEX source cache mismatch')
    if archive.read('lib/arm64-v8a/libcage_compat.so') != (native_cache / 'libcage_compat.so').read_bytes():
        raise ValueError('Compatibility native object cache does not correspond to Privacy09')

jdk = Path('D:/Code/DevEnv/JAVA/jdk-17')
tools = ROOT / 'mobile/.build/client-integration/build-tools35/android-15'
android = ROOT / 'mobile/.build/gbox-test/android.jar'
llvm = ROOT / 'mobile/.build/client-integration/ndk/toolchains/llvm/prebuilt/windows-x86_64'
env = dict(os.environ, JAVA_HOME=str(jdk))
run(jdk / 'bin/javac.exe', '--release', '8', '-encoding', 'UTF-8', '-g',
    '-cp', os.pathsep.join((str(android), str(classes))), '-d', classes,
    MODULE / 'privacy/java/io/github/leexeo/cage/privacy/NativePrivacy.java',
    MODULE / 'privacy/java/io/github/leexeo/cage/privacy/GuestPrivacy.java', env=env)
changed_classes = []
for file in sorted(classes.rglob('*.class')):
    relative = file.relative_to(classes)
    previous = old_work / 'privacy/classes' / relative
    if not previous.exists() or file.read_bytes() != previous.read_bytes():
        changed_classes.append(relative.as_posix())
if any(not name.startswith(('io/github/leexeo/cage/privacy/NativePrivacy',
                            'io/github/leexeo/cage/privacy/GuestPrivacy')) for name in changed_classes):
    raise ValueError('Unexpected Java class changes: ' + repr(changed_classes))
jar = privacy / 'privacy.jar'
with ZipFile(jar, 'w') as archive:
    for file in sorted(classes.rglob('*.class')):
        archive.write(file, file.relative_to(classes).as_posix())
run(tools / 'd8.bat', '--min-api', '28', '--lib', android, '--output', dex, jar, env=env)

# gate and the read-only path diagnostic are unchanged; their original linked
# library was compared above. Recompile only the new Runtime observer.
for name in ('gate.o', 'path_trace.o', 'sample_guard.h'):
    shutil.copyfile(native_cache / name, compat / name)
temporary = compat / 'tmp'
temporary.mkdir()
native_env = dict(env, TEMP=str(temporary), TMP=str(temporary))
run(llvm / 'bin/clang++.exe', '-fintegrated-cc1', '--target=aarch64-linux-android28',
    '--sysroot=' + str(llvm / 'sysroot'), '-resource-dir=' + str(llvm / 'lib/clang/18'),
    '-std=c++17', '-O2', '-fPIC', '-fno-exceptions', '-fno-rtti', '-fvisibility=hidden',
    '-mno-outline-atomics', '-Wall', '-Wextra', '-Werror',
    '-I' + str(MODULE / 'compat'), '-I' + str(compat),
    '-c', MODULE / 'privacy/compat/runtime.cpp', '-o', compat / 'runtime.o', env=native_env)
compat_library = compat / 'libcage_compat.so'
run(llvm / 'bin/ld.lld.exe', '-shared', '-m', 'aarch64linux', '--hash-style=gnu', '--eh-frame-hdr',
    '--build-id=sha1', '-z', 'defs', '-z', 'now', '-z', 'relro', '-z', 'noexecstack',
    '-z', 'max-page-size=4096', '-soname', compat_library.name,
    '-L' + str(llvm / 'sysroot/usr/lib/aarch64-linux-android/28'),
    '-L' + str(llvm / 'sysroot/usr/lib/aarch64-linux-android'),
    compat / 'gate.o', compat / 'runtime.o', compat / 'path_trace.o',
    llvm / 'lib/clang/18/lib/linux/libclang_rt.builtins-aarch64-android.a',
    '-lc', '-ldl', '-llog', '-o', compat_library, env=native_env)

sys.path.insert(0, str(BUILD / 'native-analysis/python'))
from elftools.elf.elffile import ELFFile
with compat_library.open('rb') as stream:
    elf = ELFFile(stream)
    exported = elf.get_section_by_name('.dynsym').get_symbol_by_name('cage_compat_install_load_observer')
    if (not exported or len(exported) != 1 or exported[0]['st_info']['type'] != 'STT_FUNC'
            or exported[0]['st_info']['bind'] != 'STB_GLOBAL'
            or exported[0]['st_other']['visibility'] != 'STV_DEFAULT'
            or exported[0]['st_shndx'] == 'SHN_UNDEF'):
        raise ValueError('Native-load observer is not a defined public function')

native_source = BUILD / 'native-privacy-check/privacy-native'
native_output = work / 'privacy-native'
native_output.mkdir()
native_library = native_output / 'libcage_privacy.so'
shutil.copyfile(native_source / native_library.name, native_library)
shutil.copyfile(native_source / 'metadata.json', native_output / 'metadata.json')
for library in (native_library, compat_library):
    data = library.read_bytes()
    if data[:6] != b'\x7fELF\x02\x01' or int.from_bytes(data[18:20], 'little') != 183:
        raise ValueError('Unexpected native library ABI: ' + library.name)
replacement = {'classes10.dex': dex / 'classes.dex',
               'lib/arm64-v8a/libcage_privacy.so': native_library,
               'lib/arm64-v8a/libcage_compat.so': compat_library}
with ZipFile(base) as source, ZipFile(work / 'unsigned.apk', 'w') as output:
    if any(source.read(name) == path.read_bytes() for name, path in replacement.items()):
        raise ValueError('Expected replacement did not change')
    for entry in source.infolist():
        if not signature_entry(entry.filename):
            data = replacement[entry.filename].read_bytes() if entry.filename in replacement else source.read(entry.filename)
            output.writestr(entry, data)

boundary = {
    'method': 'java.lang.Runtime.nativeLoad(String, ClassLoader, Class): String',
    'abi': 'ordinary JNI',
    'originalParametersAndResultPreserved': True,
    'originalPendingExceptionPreserved': True,
    'independentMethodBackup': True,
    'legitimateNestedNativeLoadsAllowed': True,
    'separateFromOriginal11Installations': True,
    'trigger': 'Synchronous notification after original null result with no pending exception, before returning to Java',
    'refresh': 'Exact-sample original core post_dlopen(task_manager), retaining existing partial tasks',
    'periodicRefresh': False,
    'missingLibraryFailureCheck': 'Runtime verification requires the same original error String and zero refresh notifications',
    'notClaimed': ['ELF constructors', 'JNI_OnLoad reads', 'native-only dlopen',
                   'concurrent use before Java load returns', 'inner return during a same-thread refresh-triggered load',
                   'host x86 reads', 'direct-resolved calls', 'raw syscalls'],
    'staticEvidence': 'mobile/.build/gbox-mod/native-analysis/runtime-load/boundary.json',
    'runtimeValidation': 'NOT_RUN'
}
metadata = json.loads((old_work / 'privacy/metadata.json').read_text('utf-8'))
native_metadata = json.loads((native_output / 'metadata.json').read_text('utf-8'))
for name in ('bytehookGuard', 'hostMapsParseFix'):
    native_metadata[name] = metadata['nativeComponents']['native'][name]
native_metadata['postNativeLoadRefresh'] = boundary
metadata['nativeComponents']['native'] = native_metadata
metadata['nativeLoadDiagnostics']['runtimeValidation'] = 'Privacy09 observed a selected ARM ELF at +4/+8s with no corresponding filter/post observer hit; Privacy10 not run'
metadata['nativeLoadDiagnostics']['privacyStrategyChanged'] = False
metadata['nativeLoadDiagnostics']['loadDiscoveryMechanismChanged'] = True
metadata['nativeLoadDiagnostics']['observationsOnly'] = False
metadata['nativeLoadDiagnostics']['delayedSnapshotsRemainReadOnly'] = True
metadata['webView']['runtimeFirstScriptValidation'] = 'Privacy08/09 PASS; helper bytecode reused; Privacy10 not run'
metadata['nativeComponents']['child']['gboxIntegrationValidation'] = 'Privacy08/09 PASS; unchanged library and Java class; Privacy10 not run'
(privacy / 'metadata.json').write_text(json.dumps(metadata, ensure_ascii=False, indent=2), encoding='utf-8')
compat_metadata = json.loads((old_work / 'compat/metadata.json').read_text('utf-8'))
compat_metadata.pop('nativeLibraryReusedFrom', None)
compat_metadata['nativeLibrarySha256'] = sha(compat_library)
compat_metadata['runtimeLoadObserver'] = boundary
compat_metadata['unchangedNativeObjects'] = ['gate.o', 'path_trace.o']
(compat / 'metadata.json').write_text(json.dumps(compat_metadata, indent=2), encoding='utf-8')
shutil.copyfile(old_work / 'native-trace.json', work / 'native-trace.json')
validation = {
    'base': str(base.relative_to(ROOT)), 'baseSha256': sha(base),
    'changedExistingEntries': sorted(replacement), 'changedExistingDex': ['classes10.dex'],
    'addedEntries': [], 'changedJavaClasses': changed_classes,
    'childAndWebViewClassesReused': True,
    'guestFirstBindingAdmissionUnchanged': True,
    'guestLifecycleChanges': 'Read-only actual-scope query and persistent fatal loader-validation failure propagation through existing guards',
    'compatJavaAndCoreAndChildLibrariesReused': True,
    'original17AdaptersAnd11VerificationSetUnchanged': True,
    'lifecycleChecksReusedFrom': 'dist/Cage-GBox-Privacy-08.apk',
    'newObserverExportVerified': True,
    'compatNativeLink': '-Werror and -z defs passed',
    'parentNativeLibrary': str(native_source.relative_to(ROOT) / 'libcage_privacy.so'),
    'nativeLoadBoundary': boundary,
    'privacyRuntimeAcceptance': 'NOT_RUN', 'loginVerified': False
}
(work / 'combined-integration.json').write_text(json.dumps(validation, indent=2), encoding='utf-8')
print(str(work / 'unsigned.apk'))
