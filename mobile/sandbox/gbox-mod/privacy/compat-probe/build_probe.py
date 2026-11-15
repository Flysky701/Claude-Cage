"""Build only. Device execution is owned by the coordinating MuMu actor."""
import json
import os
from pathlib import Path
import subprocess
import zipfile

SOURCE = Path(__file__).resolve().parent
ROOT = SOURCE.parents[4]
WORK = ROOT / "mobile/.build/gbox-mod/nativebridge-probe"
JDK = Path("D:/Code/DevEnv/JAVA/jdk-17")
TOOLS = ROOT / "mobile/.build/client-integration/build-tools35/android-15"
NDK = ROOT / "mobile/.build/client-integration/ndk/toolchains/llvm/prebuilt/windows-x86_64"
ANDROID = ROOT / "mobile/.build/gbox-test/android.jar"
OUTPUT = ROOT / "dist/Cage-NativeBridge-Probe-05.apk"
ENV = dict(os.environ, CAGE_NATIVE_PROBE_STORE_PASSWORD="android", TEMP=str(WORK / "tmp"), TMP=str(WORK / "tmp"))

def run(*args):
    subprocess.run([str(arg) for arg in args], env=ENV, check=True)

for folder in (WORK, WORK / "classes", WORK / "dex", WORK / "tmp", OUTPUT.parent):
    folder.mkdir(parents=True, exist_ok=True)
run(NDK / "bin/clang++.exe", "-fintegrated-cc1", "--target=aarch64-linux-android28", "--sysroot=" + str(NDK / "sysroot"),
    "-resource-dir=" + str(NDK / "lib/clang/18"), "-fPIC", "-fno-exceptions", "-fno-rtti", "-mno-outline-atomics", "-O1", "-c",
    SOURCE / "critical_probe05.cpp", "-o", WORK / "probe.o")
run(NDK / "bin/ld.lld.exe", "-shared", "-z", "now", "-z", "relro", "--hash-style=gnu", "--eh-frame-hdr",
    "-m", "aarch64linux", "--build-id=sha1", "-L" + str(NDK / "sysroot/usr/lib/aarch64-linux-android/28"),
    "-L" + str(NDK / "sysroot/usr/lib/aarch64-linux-android"), WORK / "probe.o", "-lc", "-ldl",
    "-o", WORK / "libcage_nativebridge_probe.so")
run(JDK / "bin/javac.exe", "--release", "8", "-encoding", "UTF-8", "-cp", ANDROID,
    "-d", WORK / "classes", SOURCE / "NativeBridgeProbeActivity.java")
with zipfile.ZipFile(WORK / "classes.jar", "w") as archive:
    for item in sorted((WORK / "classes").rglob("*.class")):
        archive.write(item, item.relative_to(WORK / "classes").as_posix())
run(JDK / "bin/java.exe", "-cp", TOOLS / "lib/d8.jar", "com.android.tools.r8.D8", "--min-api", "26",
    "--lib", ANDROID, "--output", WORK / "dex", WORK / "classes.jar")
run(TOOLS / "aapt2.exe", "link", "-I", ANDROID, "--manifest", SOURCE / "AndroidManifest.xml", "-o", WORK / "base.apk")
with zipfile.ZipFile(WORK / "base.apk", "a") as archive:
    archive.write(WORK / "dex/classes.dex", "classes.dex", compress_type=zipfile.ZIP_DEFLATED)
    archive.write(WORK / "libcage_nativebridge_probe.so", "lib/arm64-v8a/libcage_nativebridge_probe.so", compress_type=zipfile.ZIP_DEFLATED)
run(TOOLS / "zipalign.exe", "-f", "4", WORK / "base.apk", WORK / "aligned.apk")
run(JDK / "bin/java.exe", "-jar", TOOLS / "lib/apksigner.jar", "sign", "--ks", ROOT / "mobile/.build/sandbox/development.p12",
    "--ks-pass", "env:CAGE_NATIVE_PROBE_STORE_PASSWORD", "--out", OUTPUT, WORK / "aligned.apk")
run(JDK / "bin/java.exe", "-jar", TOOLS / "lib/apksigner.jar", "verify", OUTPUT)
info = {"package": "io.github.leexeo.cage.nativebridgeprobe", "activity": ".NativeBridgeProbeActivity", "abi": "arm64-v8a",
        "android": "12 only (API 31/32)", "artifact": str(OUTPUT), "build": "PASS", "deviceValidation": "NOT_RUN",
        "report": "files/latest-native-bridge-report.txt", "logTag": "CageNativeBridgeProbe", "endsOwnProcess": True,
        "target": "Binder.getCallingUid()I, compare only without logging UID", "accountOrNetworkAccess": False}
info["variant"] = "raw original before registration, then Java caller and separate ARM JNI health checks; pure CriticalNative callback"
OUTPUT.with_suffix(".json").write_text(json.dumps(info, indent=2), encoding="utf-8")
print(json.dumps(info))
