"""Build the diagnostic APK locally; does not install or contact any device."""
import argparse
import json
import os
from pathlib import Path
import subprocess
import zipfile


def main():
    source = Path(__file__).resolve().parent
    repo = source.parents[3]
    parser = argparse.ArgumentParser()
    parser.add_argument('--jdk', type=Path, default=Path('D:/Code/DevEnv/JAVA/jdk-17'))
    parser.add_argument('--build-tools', type=Path, default=repo / 'mobile/.build/client-integration/build-tools35/android-15')
    parser.add_argument('--android-jar', type=Path, default=repo / 'mobile/.build/gbox-test/android.jar')
    parser.add_argument('--ndk', type=Path, default=repo / 'mobile/.build/client-integration/ndk')
    parser.add_argument('--keystore', type=Path, default=repo / 'mobile/.build/sandbox/development.p12')
    parser.add_argument('--output', type=Path, default=repo / 'dist/Cage-GBox-Privacy-Probe-06.apk')
    parser.add_argument('--package-only', action='store_true', help='Reuse compiled outputs after a packaging-tool failure')
    args = parser.parse_args()
    work = repo / 'mobile/.build/gbox-mod/probe'
    for directory in [work, work / 'classes', work / 'dex', work / 'tmp', args.output.parent]:
        directory.mkdir(parents=True, exist_ok=True)
    env = os.environ.copy()
    env.setdefault('CAGE_PROBE_KEYSTORE_PASSWORD', 'android')
    env.update(TEMP=str(work / 'tmp'), TMP=str(work / 'tmp'))
    def run(*command):
        subprocess.run([str(item) for item in command], check=True, env=env)
    java = args.jdk / 'bin/java.exe'
    llvm = args.ndk / 'toolchains/llvm/prebuilt/windows-x86_64'
    native = work / 'libcage_privacy_probe.so'
    if not args.package_only:
        compile_probe(source, args, work, run, java, llvm, native)
    for compiled in (native, work / 'dex/classes.dex'):
        if not compiled.is_file():
            raise FileNotFoundError(compiled)
    base = work / 'base.apk'
    run(args.build_tools / 'aapt2.exe', 'link', '-I', args.android_jar, '--manifest',
        source / 'AndroidManifest.xml', '-o', base)
    with zipfile.ZipFile(base, 'a') as archive:
        archive.write(work / 'dex/classes.dex', 'classes.dex', compress_type=zipfile.ZIP_DEFLATED)
        archive.write(native, 'lib/arm64-v8a/' + native.name, compress_type=zipfile.ZIP_DEFLATED)
    aligned = work / 'aligned.apk'
    run(args.build_tools / 'zipalign.exe', '-f', '4', base, aligned)
    signer = args.build_tools / 'lib/apksigner.jar'
    run(java, '-jar', signer, 'sign', '--ks', args.keystore, '--ks-pass', 'env:CAGE_PROBE_KEYSTORE_PASSWORD',
        '--out', args.output, aligned)
    run(java, '-jar', signer, 'verify', args.output)
    info = {'package': 'io.github.leexeo.cage.gboxprobe', 'activity': '.ProbeActivity', 'versionCode': 6,
            'apk': args.output.name, 'build': 'PASS', 'deviceValidation': 'NOT_RUN',
            'nativeAbi': 'arm64-v8a', 'nativeScope': 'Three property APIs, getifaddrs and localtime; direct syscall/netlink coverage not claimed',
            'webviewReadings': ['first HTML script', 'after page finished'],
            'networkRequests': 'NONE', 'report': 'private files/latest-report.json; CageGBoxProbe logcat'}
    args.output.with_suffix('.json').write_text(json.dumps(info, indent=2), encoding='utf-8')
    print(json.dumps(info))


def compile_probe(source, args, work, run, java, llvm, native):
    run(llvm / 'bin/clang++.exe', '-fintegrated-cc1', '--target=aarch64-linux-android28',
        '--sysroot=' + str(llvm / 'sysroot'), '-resource-dir=' + str(llvm / 'lib/clang/18'),
        '-std=c++17', '-O2', '-fPIC', '-fno-exceptions', '-fno-rtti', '-fvisibility=hidden',
        '-mno-outline-atomics', '-Wall', '-Wextra', '-Werror', '-c', source / 'native_probe.cpp', '-o', work / 'native_probe.o')
    run(llvm / 'bin/ld.lld.exe', '-shared', '-m', 'aarch64linux', '--hash-style=gnu', '--eh-frame-hdr',
        '-z', 'defs', '-z', 'now', '-z', 'relro', '-z', 'noexecstack', '-z', 'max-page-size=4096',
        '-soname', native.name, '-L' + str(llvm / 'sysroot/usr/lib/aarch64-linux-android/28'),
        '-L' + str(llvm / 'sysroot/usr/lib/aarch64-linux-android'), work / 'native_probe.o',
        llvm / 'lib/clang/18/lib/linux/libclang_rt.builtins-aarch64-android.a', '-lc', '-o', native)
    run(args.jdk / 'bin/javac.exe', '--release', '8', '-encoding', 'UTF-8', '-cp', args.android_jar,
        '-d', work / 'classes', source / 'ProbeActivity.java')
    jar = work / 'classes.jar'
    with zipfile.ZipFile(jar, 'w') as archive:
        for item in sorted((work / 'classes').rglob('*.class')):
            archive.write(item, item.relative_to(work / 'classes').as_posix())
    run(java, '-cp', args.build_tools / 'lib/d8.jar', 'com.android.tools.r8.D8', '--min-api', '26',
        '--lib', args.android_jar, '--output', work / 'dex', jar)


if __name__ == '__main__':
    main()
