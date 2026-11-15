"""Build a temporary same-certificate instrumentation APK for the recovery copy."""
import argparse
import os
from pathlib import Path
import sys
import tempfile
from zipfile import ZipFile

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
sys.path.insert(0, str(ROOT / "mobile/sandbox/recovery"))
from rebuild import run


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--jdk", type=Path, required=True)
    parser.add_argument("--sdk", type=Path, required=True)
    args = parser.parse_args()
    env = dict(os.environ, JAVA_HOME=str(args.jdk.resolve()), CAGE_RECOVERY_KEYSTORE_PASSWORD="android")
    bt = args.sdk / "build-tools/34.0.0"
    android = args.sdk / "platforms/android-35/android.jar"
    output = ROOT / "mobile/.build/integrity-test/Recovery-Probe.apk"
    with tempfile.TemporaryDirectory(dir=output.parent) as temporary:
        work = Path(temporary)
        manifest = work / "AndroidManifest.xml"
        manifest.write_text('''<manifest xmlns:android="http://schemas.android.com/apk/res/android" package="io.github.flysky701.recoveryprobe">
<uses-sdk android:minSdkVersion="28" android:targetSdkVersion="28"/>
<application android:label="Integrity recovery probe"/>
<instrumentation android:name="io.github.flysky701.recoveryprobe.RecoveryProbe" android:targetPackage="top.niunaijun.microrec" android:functionalTest="true"/>
</manifest>''', encoding="utf-8")
        classes = work / "classes"
        classes.mkdir()
        run(args.jdk / "bin/javac.exe", "--release", "8", "-encoding", "UTF-8", "-cp", android,
            "-d", classes, *sorted((HERE / "probe").glob("*.java")))
        jar = work / "probe.jar"
        with ZipFile(jar, "w") as archive:
            for file in classes.rglob("*.class"):
                archive.write(file, file.relative_to(classes).as_posix())
        run(bt / "d8.bat", "--min-api", "28", "--lib", android, "--output", work, jar, env=env)
        unsigned = work / "unsigned.apk"
        run(bt / "aapt.exe", "package", "-f", "-M", manifest, "-I", android, "-F", unsigned)
        with ZipFile(unsigned, "a") as archive:
            archive.write(work / "classes.dex", "classes.dex")
        aligned = work / "aligned.apk"
        run(bt / "zipalign.exe", "-f", "4", unsigned, aligned)
        run(bt / "apksigner.bat", "sign", "--ks", ROOT / "mobile/.build/sandbox/development.p12",
            "--ks-pass", "env:CAGE_RECOVERY_KEYSTORE_PASSWORD", "--out", output, aligned, env=env)
    print(output)


if __name__ == "__main__":
    main()
