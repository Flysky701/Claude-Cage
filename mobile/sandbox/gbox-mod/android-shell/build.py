"""Build a same-signature Cage Android home overlay; no device or release actions."""
import argparse
import importlib.util
import json
import os
from pathlib import Path
import re
import shutil
import sys
import uuid
from zipfile import ZipFile, ZIP_DEFLATED

HERE = Path(__file__).resolve().parent
MOD = HERE.parent
ROOT = MOD.parents[2]
sys.path.insert(0, str(MOD))
# Avoid importing this file itself as the parent's `build` module.
spec = importlib.util.spec_from_file_location('gbox_builder', MOD / 'build.py')
common = importlib.util.module_from_spec(spec)
spec.loader.exec_module(common)
import toolchain
from manifest import patch

BASE_SHA = '7094ba026f7c66740e6a8cd530b909e77857cf9e48340268e7a4a2aeb3982bc2'


def entries(path):
    with ZipFile(path) as archive:
        if len(archive.namelist()) != len(set(archive.namelist())):
            raise ValueError('Duplicate entries')
        return {n: archive.read(n) for n in archive.namelist() if not common.signature_entry(n)}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--base', type=Path, default=MOD / 'dist/Cage-GBox-Android16-Partial-20261115.apk')
    parser.add_argument('--probe', type=Path, default=ROOT / 'dist/Cage-GBox-Privacy-Probe-06.apk')
    parser.add_argument('--base-sha256', default=BASE_SHA)
    modes = parser.add_mutually_exclusive_group()
    modes.add_argument('--ui-only', action='store_true',
                        help='Reuse the first preview probe and non-UI class bytes; replace UI only')
    modes.add_argument('--checks-only', action='store_true',
                       help='Replace checks and the probe while verifying existing UI class bytes are preserved')
    parser.add_argument('--retained-shell-classes', type=Path,
                        help='Original home/classes.jar that reproduces the selected base classes11.dex')
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    if args.output.exists(): raise FileExistsError(args.output)
    if common.sha(args.base) != args.base_sha256: raise ValueError('Unexpected installed baseline')
    before = entries(args.base)
    work = ROOT / 'mobile/.build/gbox-mod' / ('android-shell-' + uuid.uuid4().hex[:8])
    work.mkdir(parents=True)
    jdk, tools, android = toolchain.default_jdk(), toolchain.default_tools(ROOT), toolchain.default_android_jar(ROOT)
    java = jdk / 'bin/java.exe'
    env = dict(os.environ, CAGE_GBOX_KEYSTORE_PASSWORD='android', JAVA_HOME=str(jdk))
    def run(*cmd): return common.run(*cmd, env=env)
    def cert(path):
        output = run(java, '-jar', tools / 'lib/apksigner.jar', 'verify', '--print-certs', path)
        values = re.findall(r'Signer #\d+ certificate SHA-256 digest: ([0-9a-f]+)', output)
        if len(values) != 1: raise ValueError('Certificate count')
        return values[0]
    def compile_dex(name, sources, retained=None):
        folder = work / name
        classes, dex = folder / 'classes', folder / 'dex'
        classes.mkdir(parents=True); dex.mkdir()
        classpath = str(android)
        if retained:
            classpath += os.pathsep + str(retained)
            with ZipFile(retained) as archive:
                for entry in archive.namelist():
                    if entry.endswith('.class') and not any(entry.startswith('io/github/leexeo/cage/shell/' + n)
                        for n in ('HomeActivity', 'CageTheme', 'LineIcon')):
                        target = classes / entry
                        target.parent.mkdir(parents=True, exist_ok=True)
                        target.write_bytes(archive.read(entry))
        run(jdk / 'bin/javac.exe', '--release', '8', '-encoding', 'UTF-8', '-cp', classpath, '-d', classes, *sources)
        jar = folder / 'classes.jar'
        with ZipFile(jar, 'w') as archive:
            for path in sorted(classes.rglob('*.class')): archive.write(path, path.relative_to(classes).as_posix())
        run(java, '-cp', tools / 'lib/d8.jar', 'com.android.tools.r8.D8', '--min-api', '28', '--lib', android, '--output', dex, jar)
        return (dex / 'classes.dex').read_bytes()
    def package(base, replacements, name):
        raw, aligned, signed = (work / (name + suffix) for suffix in ('-raw.apk', '-aligned.apk', '.apk'))
        with ZipFile(base) as source, ZipFile(raw, 'w') as archive:
            original = set(source.namelist())
            for info in source.infolist():
                if not common.signature_entry(info.filename): archive.writestr(info, replacements.get(info.filename, source.read(info)))
            for key in sorted(replacements.keys() - original): archive.writestr(key, replacements[key], compress_type=ZIP_DEFLATED)
        run(tools / 'zipalign.exe', '-p', '-f', '4', raw, aligned)
        run(java, '-jar', tools / 'lib/apksigner.jar', 'sign', '--ks', ROOT / 'mobile/.build/sandbox/development.p12',
            '--ks-pass', 'env:CAGE_GBOX_KEYSTORE_PASSWORD', '--out', signed, aligned)
        if cert(signed) != cert(base): raise ValueError('Changed signing identity')
        before, after = entries(base), entries(signed)
        if before.keys() - after.keys(): raise ValueError('Removed APK entries')
        changed = {n for n in before.keys() & after.keys() if before[n] != after[n]}
        added = after.keys() - before.keys()
        if changed | added != replacements.keys(): raise ValueError('APK delta mismatch')
        if any(after[n] != data for n, data in replacements.items()): raise ValueError('Packaged bytes mismatch')
        return signed, sorted(changed), sorted(added)

    probe_sources = [MOD / 'probe/ProbeActivity.java', HERE / 'java/io/github/leexeo/cage/preflight/NetworkProbe.java',
                     HERE / 'java/io/github/leexeo/cage/preflight/NetworkMetadata.java']
    if args.checks_only:
        if not args.retained_shell_classes or 'classes11.dex' not in before or 'assets/cage-android/preflight.apk' not in before:
            raise ValueError('Checks-only mode requires an existing shell and its exact class cache')
        verification = work / 'retained-shell-dex'; verification.mkdir()
        run(java, '-cp', tools / 'lib/d8.jar', 'com.android.tools.r8.D8', '--min-api', '28',
            '--lib', android, '--output', verification, args.retained_shell_classes)
        if (verification / 'classes.dex').read_bytes() != before['classes11.dex']:
            raise ValueError('Retained class cache does not reproduce selected shell DEX')
    if args.ui_only:
        reference = MOD / 'dist/Cage-Android-Preview-Test01.apk'
        if common.sha(reference) != '70e923053ba098cbd320ff5f8baae05434d1c0be4b7b459e12cf93dc5978f1b6':
            raise ValueError('UI reference changed')
        reference_entries = entries(reference)
        for entry in ('classes11.dex', 'assets/cage-android/preflight.apk'):
            if before.get(entry) != reference_entries[entry]:
                raise ValueError('UI-only base must retain the initial shell/probe: ' + entry)
        meta = json.loads(reference.with_suffix('.json').read_text(encoding='utf-8'))
        retained = ROOT / meta['buildDirectory'] / 'home/classes.jar'
        verification = work / 'reference-dex'; verification.mkdir()
        run(java, '-cp', tools / 'lib/d8.jar', 'com.android.tools.r8.D8', '--min-api', '28',
            '--lib', android, '--output', verification, retained)
        if (verification / 'classes.dex').read_bytes() != before['classes11.dex']:
            raise ValueError('Retained class cache does not reproduce baseline DEX')
        sources = [HERE / 'java/io/github/leexeo/cage/shell' / (n + '.java')
                   for n in ('HomeActivity', 'CageTheme', 'LineIcon')]
        dex = compile_dex('home', sources, retained=retained)
        with ZipFile(retained) as old, ZipFile(work / 'home/classes.jar') as new:
            for entry in old.namelist():
                if entry.endswith('.class') and not entry.startswith('io/github/leexeo/cage/shell/HomeActivity'):
                    if new.read(entry) != old.read(entry): raise ValueError('Non-UI class changed: ' + entry)
        probe = work / 'preflight.apk'
        probe.write_bytes(before['assets/cage-android/preflight.apk'])
        probe_sources = []
    else:
        probe_before = entries(args.probe)
        probe_dex = compile_dex('probe', probe_sources)
        if not common.dex_classes(probe_before['classes.dex']).issubset(common.dex_classes(probe_dex)):
            raise ValueError('Probe class removed')
        probe, _, _ = package(args.probe, {'classes.dex': probe_dex}, 'preflight')
        info_source = work / 'BuildInfo.java'
        info_source.write_text('package io.github.leexeo.cage.shell; final class BuildInfo { static final String PROBE_SHA="'
                               + common.sha(probe) + '"; }\n', encoding='utf-8')
        sources = sorted((HERE / 'java').rglob('*.java'))
        dex = compile_dex('home', sources + [info_source])
        if 'classes11.dex' in before and not args.checks_only: raise ValueError('DEX slot already used')
        if args.checks_only:
            allowed = {'io/github/leexeo/cage/shell/' + name for name in
                       ('Checks', 'CheckPolicy', 'BuildInfo', 'ContainerBridge')}
            with ZipFile(args.retained_shell_classes) as old, ZipFile(work / 'home/classes.jar') as new:
                for entry in old.namelist():
                    if not entry.endswith('.class'): continue
                    root_class = entry[:-6].split('$', 1)[0]
                    if root_class not in allowed and new.read(entry) != old.read(entry):
                        raise ValueError('Unrelated shell/UI class changed: ' + entry)
    new_classes = common.dex_classes(dex)
    if not all(n.startswith(('Lio/github/leexeo/cage/shell/', 'Lio/github/leexeo/cage/preflight/')) for n in new_classes):
        raise ValueError('Unexpected shell class')
    for key, data in before.items():
        if key != 'classes11.dex' and re.fullmatch(r'classes(?:\d+)?\.dex', key) and common.dex_classes(data) & new_classes:
            raise ValueError('Duplicate class')
    replacements = {'classes11.dex': dex}
    if args.checks_only:
        replacements['assets/cage-android/preflight.apk'] = probe.read_bytes()
    else:
        replacements['assets/cage-android/logo.png'] = (ROOT / 'ui/src/logo.png').read_bytes()
    if not args.ui_only and not args.checks_only:
        replacements.update({'assets/cage-android/preflight.apk': probe.read_bytes(),
                             'AndroidManifest.xml': patch(before['AndroidManifest.xml'])})
    signed, changed, added = package(args.base, replacements, 'cage-android')
    badging = run(tools / 'aapt2.exe', 'dump', 'badging', signed)
    if "package: name='com.cage.android' versionCode='1080402' versionName='1.8.4.02'" not in badging:
        raise ValueError('Package/version changed')
    if "launchable-activity: name='io.github.leexeo.cage.shell.HomeActivity'" not in badging:
        raise ValueError('Launcher not replaced')
    # Pure policy checks run on the host JVM, never against personal data.
    tests = work / 'tests'; tests.mkdir()
    run(jdk / 'bin/javac.exe', '--release', '8', '-encoding', 'UTF-8', '-d', tests,
        HERE / 'java/io/github/leexeo/cage/shell/CheckPolicy.java', HERE / 'tests/CheckPolicyTest.java')
    test_result = run(java, '-cp', tests, 'io.github.leexeo.cage.shell.CheckPolicyTest')
    metadata = dict(baseSha256=args.base_sha256, artifactSha256=common.sha(signed), probeSha256=common.sha(probe),
        certificateSha256=cert(signed), sameCertificate=True, package='com.cage.android', versionCode=1080402,
        changedEntries=changed, addedEntries=added, allOtherEntriesByteIdentical=True, buildDirectory=str(work.relative_to(ROOT)),
        sourceHashes={str(p.relative_to(ROOT)):common.sha(p) for p in sources + probe_sources + [Path(__file__),HERE/'manifest.py']},
        policyTests=test_result.strip(), uiOnly=args.ui_only, nonUiClassBytesPreserved=args.ui_only,
        checksOnly=args.checks_only, uiClassBytesPreserved=args.checks_only,
        retainedShellClassSha256=common.sha(args.retained_shell_classes) if args.checks_only else None,
        deviceValidation='NOT_RUN', release=False)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(signed,args.output)
    args.output.with_suffix('.json').write_text(json.dumps(metadata,indent=2),encoding='utf-8')
    print(json.dumps({k:metadata[k] for k in ('artifactSha256','changedEntries','addedEntries','policyTests','buildDirectory')}))


if __name__ == '__main__': main()
