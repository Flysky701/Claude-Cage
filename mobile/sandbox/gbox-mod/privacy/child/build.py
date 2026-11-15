"""Offline x86_64 child library and independent probe packaging. Never uses adb."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
import zipfile

SOURCE = Path(__file__).resolve().parent
ROOT = SOURCE.parents[4]
WORK = ROOT / "mobile/.build/gbox-mod/child-probe"
JDK = Path("D:/Code/DevEnv/JAVA/jdk-17")
TOOLS = ROOT / "mobile/.build/client-integration/build-tools35/android-15"
LLVM = ROOT / "mobile/.build/client-integration/ndk/toolchains/llvm/prebuilt/windows-x86_64"
ANDROID = ROOT / "mobile/.build/gbox-test/android.jar"


def build_library(work, run, env):
    work.mkdir(parents=True, exist_ok=True)
    sysroot = LLVM / "sysroot"
    libraries = sysroot / "usr/lib/x86_64-linux-android/28"
    if not (libraries / "libc.so").is_file():
        raise RuntimeError("Run child/fetch_ndk_x86.py for the missing official r27d link inputs")
    flags = ["-fintegrated-cc1", "--target=x86_64-linux-android28", "--sysroot=" + str(sysroot),
             "-resource-dir=" + str(LLVM / "lib/clang/18"), "-std=c11", "-D_GNU_SOURCE", "-O2", "-fPIC",
             "-fvisibility=hidden", "-Wall", "-Wextra", "-Werror"]
    link = ["-z", "now", "-z", "relro", "--hash-style=gnu", "--eh-frame-hdr", "-m", "elf_x86_64", "--build-id=sha1",
            "--no-undefined", "-L" + str(libraries)]
    library = work / "libcage_child_properties.so"
    run(LLVM / "bin/clang.exe", *flags, "-c", SOURCE / "property_preload.c", "-o", work / "policy.o", env=env)
    run(LLVM / "bin/ld.lld.exe", "-shared", "-soname", library.name, *link, work / "policy.o", "-lc", "-ldl", "-o", library, env=env)
    data = library.read_bytes()
    if data[:6] != b"\x7fELF\x02\x01" or int.from_bytes(data[18:20], "little") != 62:
        raise RuntimeError("Child library ABI changed")
    return library, flags, link


def build(work: Path, context: dict) -> dict:
    output = Path(work) / "privacy-child"
    temporary = output / "tmp"
    temporary.mkdir(parents=True, exist_ok=True)
    env = dict(context["env"], TEMP=str(temporary), TMP=str(temporary))
    library, _, _ = build_library(output, context["run"], env)
    metadata = {
        "elfMachine": 62, "abi": "x86_64", "packaging": "assets only; host APK ABIs unchanged",
        "hooks": ["__system_property_get", "__system_property_read", "__system_property_read_callback"],
        "scope": "Selected guest process children in the exact guarded MuMu profile",
        "parentGate": "Completed NativeCompat native property/sample verification plus SDK/64bit/current selected identity",
        "javaBuildCacheComparison": "Diagnostic booleans only; original VLite can rewrite these guest cache fields",
        "childGate": "Unchanged independent exact raw-property and actual executable ELF checks",
        "preservedProperties": ["persist.radio.multisim.config", "telephony.active_modems.max_count"],
        "originalPreloadAndEnvironmentRestoredOnDeactivate": True,
        "runtimeEnabled": True, "independentProbeValidation": "PASS",
        "independentProbeEvidence": "mobile/.build/gbox-mod/mumu/child-property-probe01-result.json",
        "gboxIntegrationValidation": "NOT_RUN", "callbackSerial": "original opaque token; same as independent probe",
        "notClaimed": ["non-x86_64 children", "explicit or early-cached ProcessBuilder environment maps",
                       "direct mapped property-area reads", "native VPN interfaces in children"],
    }
    (output / "metadata.json").write_text(json.dumps(metadata, indent=2) + "\n", encoding="utf-8")
    return {"extra_entries": {"assets/cage-child/x86_64/libcage_child_properties.so": library}, "metadata": metadata}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=ROOT / "dist/Cage-Child-Property-Probe-01.apk")
    parser.add_argument("--finalize-only", action="store_true", help="Reuse compiled objects/classes; only package and sign")
    args = parser.parse_args()
    for directory in (WORK, WORK / "tmp", WORK / "classes", WORK / "dex", args.output.parent): directory.mkdir(parents=True, exist_ok=True)
    env = dict(os.environ, CAGE_CHILD_BUILD_PASSWORD="android", TEMP=str(WORK / "tmp"), TMP=str(WORK / "tmp"))
    def run(*cmd, env=env):
        subprocess.run([str(x) for x in cmd], check=True, env=env)
    library = WORK / "libcage_child_properties.so"
    reader = WORK / "cage_property_reader"
    sentinel = WORK / "libcage_existing_preload.so"
    if not args.finalize_only:
        library, flags, link = build_library(WORK, run, env)
        libraries = LLVM / "sysroot/usr/lib/x86_64-linux-android/28"
        run(LLVM / "bin/clang.exe", *flags, "-fPIE", "-c", SOURCE / "property_reader.c", "-o", WORK / "reader.o")
        run(LLVM / "bin/ld.lld.exe", "-pie", "-dynamic-linker", "/system/bin/linker64", *link,
            libraries / "crtbegin_dynamic.o", WORK / "reader.o", "-lc", "-ldl", libraries / "crtend_android.o", "-o", reader)
        run(LLVM / "bin/clang.exe", *flags, "-c", SOURCE / "existing_preload.c", "-o", WORK / "existing.o")
        run(LLVM / "bin/ld.lld.exe", "-shared", *link, WORK / "existing.o", "-o", sentinel)
        run(JDK / "bin/javac.exe", "--release", "8", "-encoding", "UTF-8", "-cp", ANDROID,
            "-d", WORK / "classes", SOURCE / "ChildPropertyProbeActivity.java")
        with zipfile.ZipFile(WORK / "classes.jar", "w") as jar:
            for file in sorted((WORK / "classes").rglob("*.class")): jar.write(file, file.relative_to(WORK / "classes").as_posix())
        run(JDK / "bin/java.exe", "-cp", TOOLS / "lib/d8.jar", "com.android.tools.r8.D8", "--min-api", "28", "--lib", ANDROID,
            "--output", WORK / "dex", WORK / "classes.jar")
    run(TOOLS / "aapt2.exe", "link", "-I", ANDROID, "--manifest", SOURCE / "AndroidManifest.xml", "-o", WORK / "base.apk")
    with zipfile.ZipFile(WORK / "base.apk", "a") as apk:
        apk.write(WORK / "dex/classes.dex", "classes.dex", compress_type=zipfile.ZIP_DEFLATED)
        for file in (library, reader, sentinel): apk.write(file, "assets/cage-child/x86_64/" + file.name, compress_type=zipfile.ZIP_DEFLATED)
    run(TOOLS / "zipalign.exe", "-f", "4", WORK / "base.apk", WORK / "aligned.apk")
    run(JDK / "bin/java.exe", "-jar", TOOLS / "lib/apksigner.jar", "sign", "--ks", ROOT / "mobile/.build/sandbox/development.p12",
        "--ks-pass", "env:CAGE_CHILD_BUILD_PASSWORD", "--out", args.output, WORK / "aligned.apk")
    run(JDK / "bin/java.exe", "-jar", TOOLS / "lib/apksigner.jar", "verify", args.output)
    metadata = {
        "artifact": str(args.output), "package": "io.github.leexeo.cage.childprobe", "activity": ".ChildPropertyProbeActivity",
        "build": "PASS", "deviceValidation": "NOT_RUN", "parentEnvironmentModified": False,
        "accountOrNetworkAccess": False, "nativeElfMachine": 62, "nativePackaging": "assets only; no lib ABI directories",
        "profile": "exact MuMu Android 12 fingerprint, board, hardware, native bridge; API 31/32",
        "report": "files/latest-child-property-report.json", "logTag": "CageChildProbe",
        "checks": ["three native property APIs", "system getprop", "system date", "actual executable ISA and preload marker",
                   "existing LD_PRELOAD preserved", "unselected and deactivated original behavior", "capacity properties unchanged"],
        "limitations": ["x86_64 children only", "no property writes", "no direct mapped property-memory interception",
                        "independent probe is separate from GBox environment activation"],
        "assetHashes": {file.name: hashlib.sha256(file.read_bytes()).hexdigest() for file in (library, reader, sentinel)}
    }
    args.output.with_suffix(".json").write_text(json.dumps(metadata, indent=2), encoding="utf-8")
    print(json.dumps(metadata))


if __name__ == "__main__": main()
