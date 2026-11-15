"""Build the disposable host-loader proof APK only; never controls a device."""
import argparse
import hashlib
import json
import os
import shutil
from pathlib import Path
import subprocess
import sys
from zipfile import ZipFile, ZIP_DEFLATED

SOURCE = Path(__file__).resolve().parent
ROOT = SOURCE.parents[4]
WORK = ROOT / 'mobile/.build/gbox-mod/host-load-probe02'
JDK = Path('D:/Code/DevEnv/JAVA/jdk-17')
TOOLS = ROOT / 'mobile/.build/client-integration/build-tools35/android-15'
LLVM = ROOT / 'mobile/.build/client-integration/ndk/toolchains/llvm/prebuilt/windows-x86_64'
ANDROID = ROOT / 'mobile/.build/gbox-test/android.jar'
PACKAGE = 'io.github.leexeo.cage.hostloadprobe'
ARM_LIBRARIES = ['libcage_host_load_arm.so', 'libcage_sentinel_baseline.so',
                 'libcage_sentinel_after.so', 'libcage_sentinel_nested.so', 'libcage_sentinel_leaf.so']


def run(*args, env):
    subprocess.run([str(arg) for arg in args], env=env, check=True)


def native(source, output, architecture, env, definitions=(), log=False):
    target, machine = ('aarch64', 'aarch64linux') if architecture == 'arm64' else ('x86_64', 'elf_x86_64')
    flags = ['-fintegrated-cc1', '--target=' + target + '-linux-android28',
             '--sysroot=' + str(LLVM / 'sysroot'), '-resource-dir=' + str(LLVM / 'lib/clang/18'),
             '-std=c++17', '-O2', '-fPIC', '-fno-exceptions', '-fno-rtti', '-fvisibility=hidden',
             '-Wall', '-Wextra', '-Werror']
    if architecture == 'arm64': flags.append('-mno-outline-atomics')
    obj = output.with_suffix('.o')
    run(LLVM / 'bin/clang++.exe', *flags, *definitions, '-c', source, '-o', obj, env=env)
    libraries = LLVM / ('sysroot/usr/lib/' + target + '-linux-android')
    # These sources use only the NDK C ABI, not a second C++ runtime.
    run(LLVM / 'bin/ld.lld.exe', '-shared', '-m', machine, '--hash-style=gnu', '--eh-frame-hdr',
        '--build-id=sha1', '-z', 'defs', '-z', 'now', '-z', 'relro', '-z', 'noexecstack',
        '-z', 'max-page-size=4096', '-soname', output.name, '-L' + str(libraries / '28'),
        '-L' + str(libraries), obj,
        LLVM / ('lib/clang/18/lib/linux/libclang_rt.builtins-' + target + '-android.a'),
        '-lc', '-ldl', *(['-llog'] if log else []), '-o', output, env=env)
    data = output.read_bytes()
    if data[:6] != b'\x7fELF\x02\x01' or int.from_bytes(data[18:20], 'little') != (183 if architecture == 'arm64' else 62):
        raise ValueError('Unexpected ELF architecture: ' + output.name)


def java_dex(sources, directory, env):
    classes, dex = directory / 'classes', directory / 'dex'
    classes.mkdir(parents=True, exist_ok=True)
    dex.mkdir(exist_ok=True)
    run(JDK / 'bin/javac.exe', '--release', '8', '-encoding', 'UTF-8', '-g', '-cp', ANDROID,
        '-d', classes, *sources, env=env)
    jar = directory / 'classes.jar'
    with ZipFile(jar, 'w') as output:
        for file in sorted(classes.rglob('*.class')):
            output.write(file, file.relative_to(classes).as_posix())
    run(JDK / 'bin/java.exe', '-cp', TOOLS / 'lib/d8.jar', 'com.android.tools.r8.D8',
        '--min-api', '31', '--lib', ANDROID, '--output', dex, jar, env=env)
    return dex / 'classes.dex'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, default=ROOT / 'dist/Cage-Host-Load-Probe-02.apk')
    parser.add_argument('--reuse-base', type=Path, help='Reuse unchanged host helper, host DEX and four sentinels from Probe01 build cache')
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument('--compile-only', action='store_true')
    mode.add_argument('--finalize-only', action='store_true')
    args = parser.parse_args()
    if args.output.exists(): raise FileExistsError('Use a new probe artifact name')
    for folder in (WORK, WORK / 'tmp', WORK / 'native', args.output.parent):
        folder.mkdir(parents=True, exist_ok=True)
    env = dict(os.environ, JAVA_HOME=str(JDK), CAGE_HOST_PROBE_STORE_PASSWORD='android',
               TEMP=str(WORK / 'tmp'), TMP=str(WORK / 'tmp'))
    main_dex, host_dex = WORK / 'main/dex/classes.dex', WORK / 'host/dex/classes.dex'
    host_library = WORK / 'native/libcage_host_load_bridge.so'
    if not args.finalize_only:
        native(SOURCE / 'native/arm_bridge.cpp', WORK / 'native/libcage_host_load_arm.so', 'arm64', env, log=True)
        if args.reuse_base:
            base = args.reuse_base.resolve()
            if not base.is_relative_to((ROOT / 'mobile/.build/gbox-mod').resolve()) or base == WORK.resolve():
                raise ValueError('Unexpected reusable build cache')
            for name in ARM_LIBRARIES[1:] + [host_library.name]:
                shutil.copyfile(base / 'native' / name, WORK / 'native' / name)
            host_dex.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(base / 'host/dex/classes.dex', host_dex)
            host_classes = set(json.loads((base / 'compile.json').read_text('utf-8'))['hostClasses'])
        else:
            for identifier, name in enumerate(ARM_LIBRARIES[1:], 1):
                definitions = ['-DCAGE_SENTINEL_ID=' + str(identifier)]
                if identifier == 3: definitions.append('-DCAGE_SENTINEL_NESTED=1')
                native(SOURCE / 'native/sentinel.cpp', WORK / 'native' / name, 'arm64', env, definitions)
            native(SOURCE / 'native/host_bridge.cpp', host_library, 'x86_64', env)
        package_sources = SOURCE / 'java/io/github/leexeo/cage/hostloadprobe'
        main_dex = java_dex([SOURCE / 'HostLoadProbeActivity.java', package_sources / 'ArmBridge.java',
                            package_sources / 'Sentinel.java'], WORK / 'main', env)
        # Deliberately omit the application classes from this compiler's classpath.
        if not args.reuse_base:
            host_dex = java_dex([package_sources / 'host/HostBridge.java'], WORK / 'host', env)
        sys.path.insert(0, str(SOURCE.parents[1]))
        from build import dex_classes
        main_classes = dex_classes(main_dex.read_bytes())
        if not args.reuse_base: host_classes = dex_classes(host_dex.read_bytes())
        host_prefix = 'Lio/github/leexeo/cage/hostloadprobe/host/'
        if (not host_classes or any(not name.startswith(host_prefix) for name in host_classes)
                or any(name.startswith(host_prefix) for name in main_classes)):
            raise ValueError('Host helper DEX must remain isolated from application classes')
        (WORK / 'compile.json').write_text(json.dumps({
            'build': 'COMPILED', 'mainClasses': sorted(main_classes), 'hostClasses': sorted(host_classes),
            'mainAbi': 'arm64-v8a', 'hostAssetElfMachine': 62,
            'nativeCompile': '-Werror', 'nativeLink': '-z defs',
        }, indent=2), encoding='utf-8')
    if args.compile_only:
        print(json.dumps({'build': 'COMPILED', 'work': str(WORK)}))
        return
    if not (WORK / 'compile.json').is_file(): raise RuntimeError('Compile the probe first')
    run(TOOLS / 'aapt2.exe', 'link', '-I', ANDROID, '--manifest', SOURCE / 'AndroidManifest.xml',
        '-o', WORK / 'base.apk', env=env)
    with ZipFile(WORK / 'base.apk', 'a') as apk:
        apk.write(main_dex, 'classes.dex', compress_type=ZIP_DEFLATED)
        apk.write(host_dex, 'assets/host-bridge.dex', compress_type=ZIP_DEFLATED)
        apk.write(host_library, 'assets/' + host_library.name, compress_type=ZIP_DEFLATED)
        for name in ARM_LIBRARIES:
            apk.write(WORK / 'native' / name, 'lib/arm64-v8a/' + name, compress_type=ZIP_DEFLATED)
    run(TOOLS / 'zipalign.exe', '-f', '4', WORK / 'base.apk', WORK / 'aligned.apk', env=env)
    run(JDK / 'bin/java.exe', '-jar', TOOLS / 'lib/apksigner.jar', 'sign', '--ks',
        ROOT / 'mobile/.build/sandbox/development.p12', '--ks-pass', 'env:CAGE_HOST_PROBE_STORE_PASSWORD',
        '--out', args.output, WORK / 'aligned.apk', env=env)
    run(JDK / 'bin/java.exe', '-jar', TOOLS / 'lib/apksigner.jar', 'verify', args.output, env=env)
    with ZipFile(args.output) as apk:
        native_entries = sorted(name for name in apk.namelist() if name.startswith('lib/'))
        if native_entries != sorted('lib/arm64-v8a/' + name for name in ARM_LIBRARIES):
            raise ValueError('APK native ABI changed')
    metadata = {
        'artifact': str(args.output), 'sha256': hashlib.sha256(args.output.read_bytes()).hexdigest(),
        'package': PACKAGE, 'activity': '.HostLoadProbeActivity', 'versionCode': 2,
        'build': 'PASS', 'signatureVerified': True, 'deviceValidation': 'NOT_RUN',
        'abi': 'arm64-v8a', 'hostHelperAbi': 'x86_64 assets only',
        'hostHelperLoader': 'Independent DexClassLoader with Object.class bootstrap parent',
        'permissions': [], 'networkOrAccounts': False, 'gboxIntegrationTested': False,
        'report': 'files/latest-host-load-report.json', 'partialReport': 'files/latest-host-load-report.txt',
        'logTag': 'CageHostLoadProbe', 'completionMarker': 'FINISHED passed=',
        'endsOwnProcess': True,
        'diagnosticChange': 'Fixed open/install results and raw host/ARM arrays are persisted before assertions; ARM callback adds stage diagnostics only',
        'passCriteriaUnchanged': True,
        'armDetailsFields': ['entries', 'exits', 'filenameNonNull', 'findClassOk', 'getMethodOk',
                             'callMaskOk', 'expectedSeenBit', 'exceptions', 'lastErrorStage',
                             'lastErrorKind', 'lastSeenMask', 'ownerNonNull'],
        'checks': ['ARM baseline JNI_OnLoad FindClass application-only Sentinel',
                   'host loader cannot resolve Sentinel', 'host x86 helper ELF and native Runtime original metadata',
                   'unchanged original method identity with direct x86 JNI delegation',
                   'one wrapped ARM library and one nested ARM load with a distinct leaf library',
                   'each of four JNI_OnLoad functions invoked once', 'three x86-to-ARM success callbacks return',
                   'missing library original error preserved and does not notify',
                   'real WebView initializes and local empty HTML reaches onPageFinished with network loads blocked',
                   'JNI health and Runtime metadata remain intact after WebView'],
        'notClaimed': ['GBox integration', 'privacy filtering', 'account login', 'other devices or runtime profiles'],
    }
    args.output.with_suffix('.json').write_text(json.dumps(metadata, indent=2), encoding='utf-8')
    print(json.dumps(metadata))


if __name__ == '__main__': main()
