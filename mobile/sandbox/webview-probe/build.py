"""Build the standalone no-INTERNET WebView probe using only a local SDK and JDK."""
import argparse
import os
from pathlib import Path
import subprocess
import tempfile
from zipfile import ZIP_DEFLATED, ZipFile


def command(*args):
    subprocess.run([os.fspath(arg) for arg in args], check=True)


def binary(directory, name):
    return directory / (name + (".exe" if os.name == "nt" else ""))


def canonical(path):
    # os.path.realpath also handles Windows file-query restrictions on older Python 3.9.
    return Path(os.path.realpath(os.path.abspath(os.fspath(path))))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--sdk", type=Path, required=True, help="Android SDK root")
    parser.add_argument("--jdk", type=Path, required=True, help="JDK 17 or newer root")
    parser.add_argument("--build-tools", type=Path, required=True, help="SDK Build Tools version directory")
    parser.add_argument("--platform", default="android-35", help="installed SDK platform (default: android-35)")
    parser.add_argument("--output-dir", type=Path, help="default: this directory's .build")
    args = parser.parse_args()
    here = canonical(__file__).parent
    output = canonical(args.output_dir or here / ".build")
    android = canonical(args.sdk) / "platforms" / args.platform / "android.jar"
    java = binary(canonical(args.jdk) / "bin", "java")
    javac = binary(canonical(args.jdk) / "bin", "javac")
    keytool = binary(canonical(args.jdk) / "bin", "keytool")
    tools = canonical(args.build_tools)
    aapt = binary(tools, "aapt2")
    align = binary(tools, "zipalign")
    d8 = tools / "lib" / "d8.jar"
    signer = tools / "lib" / "apksigner.jar"
    for file in (android, java, javac, keytool, aapt, align, d8, signer):
        if not file.is_file():
            parser.error(f"required local tool not found: {file}")
    output.mkdir(parents=True, exist_ok=True)
    key = output / "webview-probe-development.p12"
    if not key.exists():
        command(keytool, "-genkeypair", "-alias", "webview-probe", "-keystore", key,
                "-storetype", "PKCS12", "-storepass", "android", "-keypass", "android",
                "-keyalg", "RSA", "-keysize", "2048", "-validity", "3650",
                "-dname", "CN=Cage WebView Probe Development", "-noprompt")
    apk = output / "Cage-WebView-Probe.apk"
    with tempfile.TemporaryDirectory(prefix="compile-", dir=output) as temporary:
        work = canonical(temporary)
        work.relative_to(output)  # Cleanup is confined to the newly created staging directory.
        classes = work / "classes"
        classes.mkdir()
        command(javac, "--release", "8", "-encoding", "UTF-8", "-cp", android,
                "-d", classes, *sorted(here.glob("*.java")))
        jar = work / "classes.jar"
        with ZipFile(jar, "w", ZIP_DEFLATED) as archive:
            for file in sorted(classes.rglob("*.class")):
                archive.write(file, file.relative_to(classes).as_posix())
        command(java, "-cp", d8, "com.android.tools.r8.D8", "--min-api", "28",
                "--lib", android, "--output", work, jar)
        resources = work / "resources.apk"
        command(aapt, "link", "-I", android, "--manifest", here / "AndroidManifest.xml",
                "-o", resources)
        unsigned = work / "unsigned.apk"
        with ZipFile(resources) as source, ZipFile(unsigned, "w", ZIP_DEFLATED) as target:
            for item in source.infolist():
                target.writestr(item, source.read(item))
            target.write(work / "classes.dex", "classes.dex")
        aligned = work / "aligned.apk"
        command(align, "-p", "-f", "4", unsigned, aligned)
        signed = work / "signed.apk"
        command(java, "-jar", signer, "sign", "--ks", key, "--ks-key-alias", "webview-probe",
                "--ks-pass", "pass:android", "--key-pass", "pass:android", "--out", signed, aligned)
        command(java, "-jar", signer, "verify", "--verbose", "--print-certs", signed)
        command(align, "-c", "4", signed)
        permissions = subprocess.check_output([os.fspath(aapt), "dump", "permissions", os.fspath(signed)],
                                              text=True, encoding="utf-8")
        if "uses-permission" in permissions or "android.permission.INTERNET" in permissions:
            raise RuntimeError("probe must not request any Android permissions")
        # Never publish a partial build over the last successful APK.
        signed.replace(apk)
    print("Verified manifest: no requested permissions")
    print(apk)


if __name__ == "__main__":
    main()
