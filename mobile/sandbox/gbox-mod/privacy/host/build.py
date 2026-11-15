"""Build the independently loaded host helper as assets; leave APK native ABIs unchanged."""
import hashlib
import json
from pathlib import Path
from zipfile import ZipFile

MODULE = Path(__file__).resolve().parent


def build(work: Path, context: dict) -> dict:
    output = Path(work) / 'privacy-host'
    temporary = output / 'tmp'
    temporary.mkdir(parents=True, exist_ok=True)
    root = Path(context['root'])
    llvm = Path(context.get('ndk', root / 'mobile/.build/client-integration/ndk')) / 'toolchains/llvm/prebuilt/windows-x86_64'
    jdk, tools, android = (Path(context[name]) for name in ('jdk', 'tools', 'android_jar'))
    run = context['run']
    env = dict(context['env'], TEMP=str(temporary), TMP=str(temporary))
    native, obj = output / 'libcage_host_load_bridge.so', output / 'host_bridge.o'
    libraries = llvm / 'sysroot/usr/lib/x86_64-linux-android/28'
    if not (libraries / 'liblog.so').is_file():
        raise FileNotFoundError('The official NDK r27d x86_64 API28 liblog link input is required')
    run(llvm / 'bin/clang++.exe', '-fintegrated-cc1', '--target=x86_64-linux-android28',
        '--sysroot=' + str(llvm / 'sysroot'), '-resource-dir=' + str(llvm / 'lib/clang/18'),
        '-std=c++17', '-O2', '-fPIC', '-fno-exceptions', '-fno-rtti', '-fvisibility=hidden',
        '-Wall', '-Wextra', '-Werror', '-c', MODULE / 'host_bridge.cpp', '-o', obj, env=env)
    run(llvm / 'bin/ld.lld.exe', '-shared', '-m', 'elf_x86_64', '--hash-style=gnu', '--eh-frame-hdr',
        '--build-id=sha1', '-z', 'defs', '-z', 'now', '-z', 'relro', '-z', 'noexecstack',
        '-z', 'max-page-size=4096', '-soname', native.name, '-L' + str(libraries), obj,
        llvm / 'lib/clang/18/lib/linux/libclang_rt.builtins-x86_64-android.a',
        '-lc', '-ldl', '-llog', '-o', native, env=env)
    raw = native.read_bytes()
    if raw[:6] != b'\x7fELF\x02\x01' or int.from_bytes(raw[18:20], 'little') != 62:
        raise ValueError('Host helper must be an x86_64 ELF')
    classes, dex = output / 'classes', output / 'dex'
    classes.mkdir()
    dex.mkdir()
    # The application classes are intentionally absent from this classpath.
    run(jdk / 'bin/javac.exe', '--release', '8', '-encoding', 'UTF-8', '-g', '-cp', android,
        '-d', classes, MODULE / 'HostBridge.java', env=env)
    jar = output / 'host.jar'
    with ZipFile(jar, 'w') as archive:
        for file in sorted(classes.rglob('*.class')):
            if not file.relative_to(classes).as_posix().startswith('io/github/leexeo/cage/privacy/host/'):
                raise ValueError('Unexpected class in isolated helper')
            archive.write(file, file.relative_to(classes).as_posix())
    run(tools / 'd8.bat', '--min-api', '31', '--lib', android, '--output', dex, jar, env=env)
    host_dex = dex / 'classes.dex'
    metadata = {
        'nativeAbi': 'x86_64', 'elfMachine': 62, 'packaging': 'assets only; no lib/x86_64 APK directory',
        'helperClass': 'io.github.leexeo.cage.privacy.host.HostBridge',
        'loader': 'Independent DexClassLoader with Object.class bootstrap parent and null native search path',
        'scope': 'NativeCompat state2 plus current selected guest, valid Context identity and private missing-path control',
        'originalRuntimeMethodIdentityPreserved': True,
        'originalCall': 'Saved true x86_64 JNI entry called directly by the x86_64 wrapper',
        'successNotification': 'Explicit JNI call to the ARM NativePrivacy.afterNativeLoad method',
        'helperAndCallbackClassesRetained': 'Native GlobalRefs for process lifetime',
        'independentEvidence': 'mobile/.build/gbox-mod/mumu/host-load-probe02-result.json',
        'probe01FailedAssertionCause': 'Undetermined; Probe02 diagnostic pass is not attributed to a proven repair',
        'gboxIntegrationValidation': 'NOT_RUN',
        'notClaimed': ['constructor or JNI_OnLoad reads', 'native-only dlopen', 'host x86 privacy reads',
                       'concurrent use before Java load returns', 'inner return during same-thread refresh reentry'],
        'assetSha256': {native.name: hashlib.sha256(raw).hexdigest(),
                        'host-bridge.dex': hashlib.sha256(host_dex.read_bytes()).hexdigest()},
    }
    (output / 'metadata.json').write_text(json.dumps(metadata, indent=2), encoding='utf-8')
    return {'extra_entries': {'assets/cage-host/host-bridge.dex': host_dex,
                             'assets/cage-host/x86_64/' + native.name: native}, 'metadata': metadata}
