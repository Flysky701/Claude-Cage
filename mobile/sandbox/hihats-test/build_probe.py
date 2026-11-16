"""Build a small independent fixture for real-device container compatibility checks."""
import argparse
import os
from pathlib import Path
import subprocess
import tempfile
from zipfile import ZipFile

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--jdk', type=Path, required=True)
    parser.add_argument('--sdk', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    env = dict(os.environ, JAVA_HOME=str(args.jdk.resolve()), CAGE_PROBE_KEY_PASSWORD='android')
    bt = args.sdk / 'build-tools/34.0.0'
    android = args.sdk / 'platforms/android-35/android.jar'
    key = ROOT / 'mobile/.build/sandbox/development.p12'
    args.output.parent.mkdir(parents=True, exist_ok=True)
    def run(*command):
        subprocess.run([str(x) for x in command], check=True, env=env)
    with tempfile.TemporaryDirectory(dir=args.output.parent) as temporary:
        work = Path(temporary)
        manifest = work / 'AndroidManifest.xml'
        manifest.write_text('''<manifest xmlns:android="http://schemas.android.com/apk/res/android" package="io.github.flysky701.hihatsprobe" android:versionCode="1" android:versionName="1.0">
<uses-sdk android:minSdkVersion="28" android:targetSdkVersion="28"/>
<application android:label="Cage HIHATS Probe" android:debuggable="true" android:theme="@android:style/Theme.Material.Light.NoActionBar">
<activity android:name=".ProbeActivity" android:exported="true"><intent-filter><action android:name="android.intent.action.MAIN"/><category android:name="android.intent.category.LAUNCHER"/></intent-filter></activity>
<service android:name=".ProbeService" android:process=":worker" android:exported="false"/>
<provider android:name=".ProbeProvider" android:authorities="io.github.flysky701.hihatsprobe.data" android:process=":provider" android:exported="false"/>
</application></manifest>''', encoding='utf-8')
        classes = work / 'classes'
        classes.mkdir()
        run(args.jdk / 'bin/javac.exe', '--release', '8', '-encoding', 'UTF-8', '-cp', android, '-d', classes, *sorted(HERE.glob('*.java')))
        jar = work / 'probe.jar'
        with ZipFile(jar, 'w') as archive:
            for file in classes.rglob('*.class'):
                archive.write(file, file.relative_to(classes).as_posix())
        run(bt / 'd8.bat', '--min-api', '28', '--lib', android, '--output', work, jar)
        unsigned = work / 'unsigned.apk'
        run(bt / 'aapt.exe', 'package', '-f', '-M', manifest, '-I', android, '-F', unsigned)
        with ZipFile(unsigned, 'a') as archive:
            archive.write(work / 'classes.dex', 'classes.dex')
        aligned = work / 'aligned.apk'
        run(bt / 'zipalign.exe', '-f', '4', unsigned, aligned)
        run(bt / 'apksigner.bat', 'sign', '--ks', key, '--ks-pass', 'env:CAGE_PROBE_KEY_PASSWORD', '--out', args.output, aligned)
    print(args.output)

if __name__ == '__main__':
    main()
