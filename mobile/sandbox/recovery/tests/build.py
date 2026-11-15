"""Build the separate, same-certificate instrumentation APK for the recovery copy."""
import argparse
import os
from pathlib import Path
import sys
import tempfile
from zipfile import ZipFile

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
sys.path.insert(0, str(HERE.parent))
from rebuild import run


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--jdk', type=Path, required=True)
    parser.add_argument('--sdk', type=Path, required=True)
    parser.add_argument('--build-tools', default='34.0.0')
    parser.add_argument('--keystore', type=Path, default=ROOT / 'mobile/.build/sandbox/development.p12')
    parser.add_argument('--output', type=Path, default=ROOT / 'dist/Cage-Installer-Test.apk')
    parser.add_argument('--report-store-apk', type=Path, help='Optional original Play 38.4.22 APK for ReportStoreSetup')
    parser.add_argument('--claude-bundle', type=Path, help='Optional original split APK archive for ExistingClaudeInstall')
    args = parser.parse_args()
    env = dict(os.environ, JAVA_HOME=str(args.jdk.resolve()))
    if 'CAGE_RECOVERY_KEYSTORE_PASSWORD' not in env:
        if args.keystore.resolve() != (ROOT / 'mobile/.build/sandbox/development.p12').resolve():
            parser.error('Set CAGE_RECOVERY_KEYSTORE_PASSWORD for a custom signing key')
        env['CAGE_RECOVERY_KEYSTORE_PASSWORD'] = 'android'
    bt = args.sdk / 'build-tools' / args.build_tools
    android = args.sdk / 'platforms/android-35/android.jar'
    build_root = ROOT / 'mobile/.build/play-installer-tests'
    build_root.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(dir=build_root) as temporary:
        work = Path(temporary)
        manifest = work / 'AndroidManifest.xml'
        manifest.write_text('''<manifest xmlns:android="http://schemas.android.com/apk/res/android" package="io.github.leexeo.cage.installertest">
<uses-sdk android:minSdkVersion="28" android:targetSdkVersion="28"/>
<application android:label="Cage installer test"/>
<instrumentation android:name="io.github.leexeo.cage.test.InstallerSmoke" android:targetPackage="top.niunaijun.microrec" android:functionalTest="true"/>
<instrumentation android:name="io.github.leexeo.cage.test.ReportStoreSetup" android:targetPackage="top.niunaijun.microrec" android:functionalTest="true"/>
<instrumentation android:name="io.github.leexeo.cage.test.ExistingClaudeInstall" android:targetPackage="top.niunaijun.microrec" android:functionalTest="true"/>
</manifest>''', encoding='utf-8')
        classes = work / 'classes'
        classes.mkdir()
        run(args.jdk / 'bin/javac.exe', '--release', '8', '-encoding', 'UTF-8',
            '-cp', android, '-d', classes, *sorted(HERE.glob('*.java')))
        jar = work / 'test.jar'
        with ZipFile(jar, 'w') as archive:
            for file in classes.rglob('*.class'):
                archive.write(file, file.relative_to(classes).as_posix())
        run(bt / 'd8.bat', '--min-api', '28', '--lib', android, '--output', work, jar, env=env)
        unsigned = work / 'unsigned.apk'
        run(bt / 'aapt.exe', 'package', '-f', '-M', manifest, '-I', android, '-F', unsigned)
        with ZipFile(unsigned, 'a') as archive:
            archive.write(work / 'classes.dex', 'classes.dex')
            if args.report_store_apk:
                archive.write(args.report_store_apk, 'assets/report-store.apk')
            if args.claude_bundle:
                archive.write(args.claude_bundle, 'assets/claude-original.xapk')
        aligned = work / 'aligned.apk'
        run(bt / 'zipalign.exe', '-f', '4', unsigned, aligned)
        args.output.parent.mkdir(parents=True, exist_ok=True)
        run(bt / 'apksigner.bat', 'sign', '--ks', args.keystore,
            '--ks-pass', 'env:CAGE_RECOVERY_KEYSTORE_PASSWORD', '--out', args.output, aligned, env=env)
    print(args.output)


if __name__ == '__main__':
    main()
