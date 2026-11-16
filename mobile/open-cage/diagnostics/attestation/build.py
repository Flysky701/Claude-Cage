"""Build the optional, standalone hardware-identity diagnostic (not bundled in Cage)."""
import argparse
import os
from pathlib import Path
import subprocess
from zipfile import ZipFile

p = argparse.ArgumentParser(description=__doc__)
p.add_argument("--jdk", type=Path, required=True)
p.add_argument("--sdk", type=Path, required=True)
p.add_argument("--aapt2", type=Path, required=True)
p.add_argument("--keystore", type=Path, required=True)
p.add_argument("--output", type=Path, required=True)
args = p.parse_args()
work = args.output.resolve()
work.mkdir(parents=True, exist_ok=True)
classes = work / "classes"
classes.mkdir(exist_ok=True)
android = args.sdk / "platforms/android-36/android.jar"
bt = args.sdk / "build-tools/36.1.0"
env = dict(os.environ, JAVA_HOME=str(args.jdk))


def run(*command):
    subprocess.run([str(value) for value in command], check=True, env=env)


manifest = work / "AndroidManifest.xml"
manifest.write_text('''<manifest xmlns:android="http://schemas.android.com/apk/res/android"
 package="io.github.flysky701.cage.attestationprobe" android:versionCode="1" android:versionName="0.1">
 <uses-sdk android:minSdkVersion="28" android:targetSdkVersion="28"/>
 <application android:debuggable="true" android:label="Cage hardware identity diagnostic">
  <activity android:name=".AttestationActivity" android:exported="true" android:screenOrientation="portrait">
   <intent-filter><action android:name="android.intent.action.MAIN"/><category android:name="android.intent.category.LAUNCHER"/></intent-filter>
  </activity>
 </application></manifest>''', encoding="utf-8")
run(args.jdk / "bin/javac.exe", "--release", "8", "-encoding", "UTF-8", "-cp", android,
    "-d", classes, Path(__file__).with_name("AttestationActivity.java"))
jar = work / "probe.jar"
with ZipFile(jar, "w") as archive:
    for file in classes.rglob("*.class"):
        archive.write(file, file.relative_to(classes).as_posix())
run(bt / "d8.bat", "--min-api", "28", "--lib", android, "--output", work, jar)
run(args.aapt2, "link", "-I", android, "--manifest", manifest, "-o", work / "unsigned.apk")
with ZipFile(work / "unsigned.apk", "a") as archive:
    archive.write(work / "classes.dex", "classes.dex")
output = work / "Cage-Attestation-Diagnostic.apk"
run(bt / "zipalign.exe", "-f", "4", work / "unsigned.apk", output)
run(bt / "apksigner.bat", "sign", "--ks", args.keystore, "--ks-pass", "pass:android", output)
print(output)
