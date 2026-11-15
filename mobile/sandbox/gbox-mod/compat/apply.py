"""Compile and add the guarded ARM64 MuMu compatibility module."""
import hashlib
import json
from pathlib import Path
import re
import shutil
import struct
from zipfile import ZipFile

MODULE = Path(__file__).resolve().parent
BRIDGE = 'Lio/github/leexeo/cage/gbox/NativeCompat;'
PATHS = 'Lio/github/leexeo/cage/gbox/FrameworkPaths;'
CORE = 'lib/arm64-v8a/libvlitecore64.so'
CORE_SHA = '7b8bd3b2061fc9d6ed86df4f330e5e203fa7003bb2ca18d69861fdcc3cff2b14'


def guard_header(data, output):
    if hashlib.sha256(data).hexdigest() != CORE_SHA:
        raise ValueError('Unknown core sample for MuMu compatibility')
    if data[:6] != b'\x7fELF\x02\x01' or struct.unpack_from('<H', data, 18)[0] != 183:
        raise ValueError('MuMu compatibility expects the exact ARM64 ELF')
    table = struct.unpack_from('<Q', data, 32)[0]
    entry_size, count = struct.unpack_from('<HH', data, 54)
    segments = [struct.unpack_from('<IIQQQQQQ', data, table + i * entry_size) for i in range(count)]
    def memory(address, length):
        for segment in segments:
            if segment[0] == 1 and segment[3] <= address and address + length <= segment[3] + segment[5]:
                offset = segment[2] + address - segment[3]
                return data[offset:offset + length]
        raise ValueError('Unmapped compatibility sample range')
    regions = {'kElfHeader': (0, 64), 'kBuildId': (0x200, 36),
               'kHelperBody': (0x26184, 0x528), 'kGetterBody': (0x25fd0, 0x60),
               'kBinderCallbackBody': (0x2a7d4, 0xa2c), 'kBinderInstallerBody': (0x2b200, 0x284)}
    text = '#pragma once\n#include <stdint.h>\n'
    text += 'static const uintptr_t kJniOnLoadOffset = 0x17f84;\n'
    text += 'static const uintptr_t kBuildIdOffset = 0x200;\n'
    text += 'static const uintptr_t kHelperOffset = 0x26184;\n'
    text += 'static const uintptr_t kGetterOffset = 0x25fd0;\n'
    text += 'static const uintptr_t kBinderCallbackOffset = 0x2a7d4;\n'
    text += 'static const uintptr_t kBinderInstallerOffset = 0x2b200;\n'
    for name, (address, length) in regions.items():
        raw = memory(address, length)
        text += 'static const unsigned char ' + name + '[] = {\n'
        for start in range(0, len(raw), 16):
            text += '    ' + ','.join(hex(value) for value in raw[start:start + 16]) + ',\n'
        text += '};\n'
    output.write_text(text, encoding='ascii')


def patch_framework_sources(decoded):
    core = Path(decoded) / 'smali_classes4/com/vlite/sdk'
    native = core / 'jni/Native.smali'
    source = native.read_text('utf-8')
    pattern = r'(    invoke-static \{p0, v2\}, Lcom/vlite/sdk/jni/Native;->start_iobox_with_error\(Ljava/lang/String;Ljava/lang/String;\)I\n\n    move-result v0)'
    source, count = re.subn(pattern, lambda match: match[0] + '\n    invoke-static {v0}, ' + PATHS + '->ioboxReturned(I)V', source)
    if count != 1:
        raise ValueError('Expected the unique actual I/O initialization return')
    native.write_text(source, encoding='utf-8', newline='\n')
    client = core / 'client/k.smali'
    source = client.read_text('utf-8')
    boundary = ('    invoke-virtual {v6, v14, v15}, Landroid/content/Context;->createPackageContext(Ljava/lang/String;I)Landroid/content/Context;\n\n'
                '    move-result-object v4')
    producer = ('    invoke-virtual {v1, v2, v12}, Lcom/vlite/sdk/client/k;->S0(Ljava/lang/String;Ljava/lang/String;)Lcom/vlite/sdk/client/k$d;\n\n'
                '    move-result-object v13')
    binding = (core / 'client/k$d.smali').read_text('utf-8')
    if (source.count(boundary) != 1 or source.count(producer) != 1
            or source.index(producer) >= source.index(boundary)
            or '.field public c:Landroid/content/pm/ApplicationInfo;' not in binding):
        raise ValueError('Framework path binding source changed')
    source = source.replace(boundary, '    invoke-static {v6, v13}, ' + PATHS
                            + '->bind(Landroid/content/Context;Ljava/lang/Object;)V\n' + boundary
                            + '\n    invoke-static {v4}, ' + PATHS + '->contextCreated(Landroid/content/Context;)V')
    client.write_text(source, encoding='utf-8', newline='\n')
    pm = core / 'client/hook/service/pm/a$m.smali'
    source = pm.read_text('utf-8')
    signature = '(Ljava/lang/Object;Ljava/lang/reflect/Method;[Ljava/lang/Object;)Ljava/lang/Object;'
    declaration = '.method public varargs b' + signature
    original = 'cageFrameworkOriginalQuery'
    if source.count(declaration) != 1 or original in source:
        raise ValueError('PM ApplicationInfo hook shape changed')
    source = source.replace(declaration, '.method public varargs ' + original + signature)
    source += ('\n.method public varargs b' + signature + '\n    .locals 1\n'
               '    invoke-virtual {p0, p1, p2, p3}, Lcom/vlite/sdk/client/hook/service/pm/a$m;->' + original + signature + '\n'
               '    move-result-object v0\n'
               '    invoke-static {v0}, ' + PATHS + '->fromPackageManager(Ljava/lang/Object;)Ljava/lang/Object;\n'
               '    move-result-object v0\n    return-object v0\n.end method\n')
    pm.write_text(source, encoding='utf-8', newline='\n')


def apply(decoded, work, context):
    decoded, work = Path(decoded), Path(work)
    output = work / 'compat'
    output.mkdir()
    run, env = context['run'], context['env']
    jdk, tools, android, apktool = (Path(context[key]) for key in ('jdk', 'tools', 'android_jar', 'apktool'))
    root = Path(context['root'])
    ndk = Path(context.get('ndk', root / 'mobile/.build/client-integration/ndk'))
    llvm = ndk / 'toolchains/llvm/prebuilt/windows-x86_64'
    runtime = MODULE.parent / 'privacy/compat/runtime.cpp'
    if not runtime.is_file():
        raise FileNotFoundError('The reviewed compatibility runtime is not ready: ' + str(runtime))
    with ZipFile(context['input']) as archive:
        guard_header(archive.read(CORE), output / 'sample_guard.h')
    native = output / 'libcage_compat.so'
    temporary = output / 'tmp'
    temporary.mkdir()
    native_env = dict(env, TEMP=str(temporary), TMP=str(temporary))
    diagnostics = bool(context.get('native_trace'))
    objects = []
    sources = [MODULE / 'gate.cpp', runtime]
    if diagnostics:
        sources.append(MODULE / 'path_trace.cpp')
    for source in sources:
        obj = output / (source.stem + '.o')
        run(llvm / 'bin/clang++.exe', '-fintegrated-cc1', '--target=aarch64-linux-android28',
            '--sysroot=' + str(llvm / 'sysroot'), '-resource-dir=' + str(llvm / 'lib/clang/18'),
            '-std=c++17', '-O2', '-fPIC', '-fno-exceptions', '-fno-rtti', '-fvisibility=hidden',
            '-mno-outline-atomics', '-Wall', '-Wextra', '-Werror', '-I' + str(MODULE), '-I' + str(output),
            '-c', source, '-o', obj, env=native_env)
        objects.append(obj)
    run(llvm / 'bin/ld.lld.exe', '-shared', '-m', 'aarch64linux', '--hash-style=gnu', '--eh-frame-hdr',
        '--build-id=sha1', '-z', 'defs', '-z', 'now', '-z', 'relro', '-z', 'noexecstack',
        '-z', 'max-page-size=4096', '-soname', 'libcage_compat.so',
        '-L' + str(llvm / 'sysroot/usr/lib/aarch64-linux-android/28'),
        '-L' + str(llvm / 'sysroot/usr/lib/aarch64-linux-android'), *objects,
        llvm / 'lib/clang/18/lib/linux/libclang_rt.builtins-aarch64-android.a',
        '-lc', '-ldl', '-llog', '-o', native, env=native_env)
    classes = output / 'classes'
    classes.mkdir()
    java_sources = [MODULE / 'NativeCompat.java', MODULE / 'FrameworkPaths.java']
    if diagnostics:
        java_sources.append(MODULE / 'AssetPathTrace.java')
    run(jdk / 'bin/javac.exe', '--release', '8', '-encoding', 'UTF-8', '-cp', android,
        '-d', classes, *java_sources, env=env)
    jar = output / 'compat.jar'
    with ZipFile(jar, 'w') as archive:
        for path in classes.rglob('*.class'):
            archive.write(path, path.relative_to(classes).as_posix())
    dex = output / 'dex'
    dex.mkdir()
    run(tools / 'd8.bat', '--min-api', '28', '--lib', android, '--output', dex, jar, env=env)
    stub = output / 'compat-only.apk'
    with ZipFile(stub, 'w') as archive:
        archive.write(decoded / 'AndroidManifest.xml', 'AndroidManifest.xml')
        archive.write(dex / 'classes.dex', 'classes.dex')
    isolated = output / 'smali-output'
    run(jdk / 'bin/java.exe', '-jar', apktool, 'd', '--no-res', '--no-assets', '-o', isolated, stub, env=env)
    indexes = [1] + [int(match[1]) for path in decoded.glob('smali_classes*')
                     if (match := re.fullmatch(r'smali_classes(\d+)', path.name))]
    index = max(indexes) + 1
    shutil.copytree(isolated / 'smali', decoded / f'smali_classes{index}')
    path = decoded / 'smali_classes4/com/vlite/sdk/jni/Native.smali'
    source = path.read_text('utf-8')
    begin = source.index('.method public static i(Ljava/lang/String;)V')
    end = source.index('.end method', begin)
    method = source[begin:end]
    before = '    :cond_0\n    :try_start_0\n'
    after = '    :goto_0\n    const/4 p0, 0x1\n'
    if method.count(before) != 1 or method.count(after) != 1 or BRIDGE in method:
        raise ValueError('Unexpected native initialization boundaries for compatibility')
    method = method.replace(before, '    :cond_0\n    invoke-static {}, ' + BRIDGE + '->beforeStart()V\n    :try_start_0\n')
    # Outside the upstream catchall: a failed compat verification must not be swallowed.
    method = method.replace(after, '    :goto_0\n    invoke-static {}, ' + BRIDGE + '->afterStart()V\n    const/4 p0, 0x1\n')
    path.write_text(source[:begin] + method + source[end:], encoding='utf-8', newline='\n')
    patch_framework_sources(decoded)
    metadata = {
        'scope': 'MuMu ARM64 guest on the confirmed API31/32 x86_64 runtime',
        'coreSampleSha256': CORE_SHA, 'runtimeFingerprintExactMatch': True,
        'hostArtArchitectureRequired': 'EM_X86_64', 'guestLibraryArchitecture': 'EM_AARCH64',
        'helperEntry': '0x26184', 'auxiliaryOriginalEntryGetter': '0x25fd0',
        'inMemoryGuard': 'ELF header, build ID, JNI_OnLoad location and complete helper/getter/Binder callback/installer bodies',
        'binderAuxiliaryPublication': {
            'beforeUidRegistration': ['getCallingPid at core+0xe2848', 'getCallingWorkSourceUid at core+0xe2850'],
            'source': 'Already validated original CriticalNative entries from compatibility preparation',
            'slotGuard': 'Same core writable PT_LOAD; current value must be zero or the verified original',
            'publication': 'Aligned atomic stores, ordering fence and immediate readback before RegisterNatives',
            'originalGetterSequenceRetained': True,
            'finalSlotVerification': True,
            'callbackOrReturnSemanticsChanged': False,
            'runtimeValidation': 'NOT_RUN',
            'causalBoundary': 'Privacy11 zero-slot crash is consistent with this publication window; unique cause awaits actual validation',
        },
        'otherEnvironments': 'original path; no core instruction writes',
        'coreApkInstructionsModified': False,
        'preserves': ['original ARM callbacks', 'I/O engine', 'lookup/native-modifier contracts', 'authentication and integrity behavior'],
        'verification': 'before the upstream initialized flag; outside its catchall',
        'ordinaryOriginalBridgeEvidence': 'nativebridge-probe03-result.json',
        'criticalOriginalBridgeEvidence': 'nativebridge-probe05-result.json',
        'criticalAbiBoundary': 'Probe05 Java caller and raw primitive original passed; Probe04 nested ARM JNI caller remains failed',
        'runtimeNativeLoadModifiedByCompatibilityModule': False,
        'copiedRuntimeLoadObserverIncluded': False,
        'readOnlyAssetPathDiagnostic': diagnostics,
        'frameworkPathAdapter': {
            'gate': 'Native compatibility verified, original I/O returned zero, current guest bound with existing code/CE/DE roots',
            'inputs': ['bindData ApplicationInfo copy', 'guest PM ApplicationInfo return copy including cache fallback'],
            'mappingSource': 'Existing Native.a rules only; physical paths already inside the permitted root stay unchanged',
            'optionalUnmappedAndNullPaths': 'preserved', 'requiredCodeAndDataPathsOutsideRoot': 'explicit failure',
            'outsideGuestRootMappings': 'rejected',
            'guestContextMayExposePhysicalPrivatePaths': True,
            'serverPackageRecordsModified': False, 'arbitrarySyscallIsolationClaim': False,
        },
        'deviceValidation': 'NOT_RUN', 'privacyAcceptance': 'NOT_RUN', 'loginVerified': False,
        'nativeLibrarySha256': hashlib.sha256(native.read_bytes()).hexdigest(),
    }
    (output / 'metadata.json').write_text(json.dumps(metadata, indent=2), encoding='utf-8')
    return {'changed_dex': ['classes4.dex', f'classes{index}.dex'],
            'extra_entries': {'lib/arm64-v8a/libcage_compat.so': native}, 'metadata': metadata}
