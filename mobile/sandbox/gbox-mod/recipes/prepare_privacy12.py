"""Privacy12: publish the verified Binder auxiliaries before the UID callback becomes callable."""
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

base = ROOT / 'dist/Cage-GBox-Privacy-11.apk'
old_work = BUILD / 'pk0cff07'
native_cache = BUILD / 'c5a628d3/compat'
work = BUILD / ('pl' + uuid.uuid4().hex[:6])
compat = work / 'compat'
temporary = compat / 'tmp'
temporary.mkdir(parents=True)
shutil.copytree(old_work / 'privacy', work / 'privacy')
shutil.copyfile(old_work / 'native-trace.json', work / 'native-trace.json')
shutil.copyfile(native_cache / 'path_trace.o', compat / 'path_trace.o')

spec = importlib.util.spec_from_file_location('cage_compat_build', MODULE / 'compat/apply.py')
compat_build = importlib.util.module_from_spec(spec)
spec.loader.exec_module(compat_build)
with ZipFile(ROOT / 'mobile/.build/gbox-test/GBox-1.8.4.02.apk') as original:
    compat_build.guard_header(original.read(compat_build.CORE), compat / 'sample_guard.h')

llvm = ROOT / 'mobile/.build/client-integration/ndk/toolchains/llvm/prebuilt/windows-x86_64'
env = dict(os.environ, TEMP=str(temporary), TMP=str(temporary))
for source in (MODULE / 'compat/gate.cpp', MODULE / 'privacy/compat/runtime.cpp'):
    run(llvm / 'bin/clang++.exe', '-fintegrated-cc1', '--target=aarch64-linux-android28',
        '--sysroot=' + str(llvm / 'sysroot'), '-resource-dir=' + str(llvm / 'lib/clang/18'),
        '-std=c++17', '-O2', '-fPIC', '-fno-exceptions', '-fno-rtti', '-fvisibility=hidden',
        '-mno-outline-atomics', '-Wall', '-Wextra', '-Werror', '-I' + str(MODULE / 'compat'),
        '-I' + str(compat), '-c', source, '-o', compat / (source.stem + '.o'), env=env)
library = compat / 'libcage_compat.so'
run(llvm / 'bin/ld.lld.exe', '-shared', '-m', 'aarch64linux', '--hash-style=gnu', '--eh-frame-hdr',
    '--build-id=sha1', '-z', 'defs', '-z', 'now', '-z', 'relro', '-z', 'noexecstack',
    '-z', 'max-page-size=4096', '-soname', library.name,
    '-L' + str(llvm / 'sysroot/usr/lib/aarch64-linux-android/28'),
    '-L' + str(llvm / 'sysroot/usr/lib/aarch64-linux-android'),
    compat / 'gate.o', compat / 'runtime.o', compat / 'path_trace.o',
    llvm / 'lib/clang/18/lib/linux/libclang_rt.builtins-aarch64-android.a',
    '-lc', '-ldl', '-llog', '-o', library, env=env)
raw = library.read_bytes()
if raw[:6] != b'\x7fELF\x02\x01' or int.from_bytes(raw[18:20], 'little') != 183:
    raise ValueError('Compatibility library has an unexpected ABI')
entry_name = 'lib/arm64-v8a/libcage_compat.so'
with ZipFile(base) as source, ZipFile(work / 'unsigned.apk', 'w') as output:
    if source.read(entry_name) == raw:
        raise ValueError('Compatibility library unexpectedly unchanged')
    for entry in source.infolist():
        if not signature_entry(entry.filename):
            output.writestr(entry, raw if entry.filename == entry_name else source.read(entry.filename))

publication = {
    'beforeUidRegistration': ['getCallingPid at core+0xe2848', 'getCallingWorkSourceUid at core+0xe2850'],
    'source': 'Already validated original CriticalNative entries from compatibility preparation',
    'slotGuard': 'Same core writable PT_LOAD; current value must be zero or the verified original',
    'publication': 'Aligned atomic stores, ordering fence and immediate readback before RegisterNatives',
    'originalGetterSequenceRetained': True,
    'finalSlotVerification': True,
    'callbackOrReturnSemanticsChanged': False,
    'runtimeValidation': 'NOT_RUN',
    'causalBoundary': 'Privacy11 zero-slot crash is consistent with this publication window; unique cause awaits actual validation',
}
metadata = json.loads((old_work / 'compat/metadata.json').read_text('utf-8'))
metadata.pop('nativeLibraryReusedFrom', None)
metadata['nativeLibrarySha256'] = sha(library)
metadata['inMemoryGuard'] = 'ELF header, build ID, JNI_OnLoad location and complete helper/getter/Binder callback/installer bodies'
metadata['binderAuxiliaryPublication'] = publication
metadata['deviceValidation'] = 'NOT_RUN_FOR_PRIVACY12'
(compat / 'metadata.json').write_text(json.dumps(metadata, indent=2), encoding='utf-8')
validation = {
    'base': str(base.relative_to(ROOT)), 'baseSha256': sha(base),
    'changedExistingEntries': [entry_name], 'changedExistingDex': [], 'addedEntries': [],
    'allDexAndParentAndHostAndChildAndWebViewReused': True,
    'originalCoreAndPresetsReused': True,
    'original17AdaptersAnd11VerificationSetUnchanged': True,
    'sourceChanges': ['compat/gate.cpp', 'compat/apply.py', 'privacy/compat/runtime.cpp'],
    'newReadOnlySampleWindows': [{'start': '0x2a7d4', 'size': '0xa2c', 'purpose': 'Binder callback'},
                                {'start': '0x2b200', 'size': '0x284', 'purpose': 'Binder installer'}],
    'unchangedNativeObject': 'path_trace.o from the existing compatibility build',
    'binderAuxiliaryPublication': publication,
    'privacy11Runtime': 'New host bridge installed and two ARM refresh notifications completed; earlier Binder-thread zero-slot crash prevented full report',
    'privacyRuntimeAcceptance': 'NOT_RUN', 'loginVerified': False,
}
(work / 'combined-integration.json').write_text(json.dumps(validation, indent=2), encoding='utf-8')
(BUILD / 'privacy12-work.json').write_text(json.dumps({'work': str(work.relative_to(ROOT))}), encoding='utf-8')
print(json.dumps({'unsigned': str(work / 'unsigned.apk'), 'changed': entry_name, 'compatSha256': sha(library)}))
