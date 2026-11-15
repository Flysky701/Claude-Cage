"""Offline child libraries and legacy x86_64 probe packaging. Never uses adb."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import zipfile

SOURCE = Path(__file__).resolve().parent
ROOT = SOURCE.parents[4]
GBOX_MOD = SOURCE.parents[1]
if str(GBOX_MOD) not in sys.path:
    sys.path.insert(0, str(GBOX_MOD))
import toolchain

WORK = ROOT / "mobile/.build/gbox-mod/child-probe"
JDK = toolchain.default_jdk()
TOOLS = toolchain.default_tools(ROOT)
LLVM = toolchain.llvm_prebuilt(toolchain.default_ndk(ROOT))
ANDROID = toolchain.default_android_jar(ROOT)


def build_library(work, run, env, llvm=LLVM, abi="x86_64"):
    work.mkdir(parents=True, exist_ok=True)
    sysroot = llvm / "sysroot"
    profiles = {"x86_64": ("x86_64-linux-android", "elf_x86_64", 62),
                "arm64-v8a": ("aarch64-linux-android", "aarch64linux", 183)}
    if abi not in profiles:
        raise ValueError("Unsupported child policy ABI")
    triple, emulation, machine = profiles[abi]
    libraries = sysroot / f"usr/lib/{triple}/28"
    if not (libraries / "libc.so").is_file():
        raise RuntimeError("Run child/fetch_ndk_x86.py for the missing official NDK link inputs")
    flags = ["-fintegrated-cc1", "--target=" + triple + "28", "--sysroot=" + str(sysroot),
             "-resource-dir=" + str(toolchain.clang_resource_dir(llvm)), "-std=c11", "-D_GNU_SOURCE", "-O2", "-fPIC",
             "-fvisibility=hidden", "-Wall", "-Wextra", "-Werror"]
    link = ["-z", "now", "-z", "relro", "--hash-style=gnu", "--eh-frame-hdr", "-m", emulation, "--build-id=sha1",
            "--no-undefined", "-L" + str(libraries)]
    if abi == "arm64-v8a":
        flags.append("-mno-outline-atomics")
        link += ["-z", "max-page-size=16384", "-z", "noexecstack"]
    library = work / "libcage_child_properties.so"
    run(llvm / "bin/clang.exe", *flags, "-c", SOURCE / "property_preload.c", "-o", work / "policy.o", env=env)
    run(llvm / "bin/ld.lld.exe", "-shared", "-soname", library.name, *link, work / "policy.o", "-lc", "-ldl", "-o", library, env=env)
    data = library.read_bytes()
    if data[:6] != b"\x7fELF\x02\x01" or int.from_bytes(data[18:20], "little") != machine:
        raise RuntimeError("Child library ABI changed")
    return library, flags, link


def build(work: Path, context: dict) -> dict:
    output = Path(work) / "privacy-child"
    temporary = output / "tmp"
    temporary.mkdir(parents=True, exist_ok=True)
    env = dict(context["env"], TEMP=str(temporary), TMP=str(temporary))
    root = Path(context["root"])
    ndk = Path(context.get("ndk") or toolchain.default_ndk(root))
    libraries = {}
    for abi in ("x86_64", "arm64-v8a"):
        library, _, _ = build_library(output / abi, context["run"], env, toolchain.llvm_prebuilt(ndk), abi)
        libraries[abi] = library
    metadata = {
        "elfMachines": {"x86_64": 62, "arm64-v8a": 183},
        "abis": ["x86_64", "arm64-v8a"], "packaging": "assets only; host APK ABIs unchanged",
        "hooks": ["__system_property_get", "__system_property_read", "__system_property_read_callback"],
        "scope": "Selected guest process children in guarded MuMu Android 12 or native arm64 Android 16 profiles",
        "parentGate": "Selected current guest identity plus the matching architecture-specific gate",
        "javaBuildCacheComparison": "Diagnostic booleans only; original VLite can rewrite these guest cache fields",
        "childGate": "Actual executable ELF and raw system-property checks for the compiled ABI",
        "preservedProperties": ["persist.radio.multisim.config", "telephony.active_modems.max_count"],
        "originalPreloadAndEnvironmentRestoredOnDeactivate": True,
        "runtimeEnabled": True, "independentProbeValidation": "HISTORICAL_MUMU_ONLY",
        "independentProbeEvidence": "mobile/.build/gbox-mod/mumu/child-property-probe01-result.json",
        "gboxIntegrationValidation": "NOT_RUN", "callbackSerial": "original opaque token; same as independent probe",
        "mumuX86_64": {"elfMachine": 62, "sdk": [31, 32],
                       "parentGate": "Completed NativeCompat native property/sample verification plus SDK/64bit",
                       "childGate": "Existing fingerprint suffix, nonempty hardware/board, libnb.so and raw SDK31/32 checks",
                       "runtimeValidation": "NOT_RERUN_FOR_THIS_BUILD"},
        "android16Arm64": {"elfMachine": 183, "sdk": 36, "nativeBridge": "absent or disabled",
                           "parentGate": "Actual parent and system shell/getprop/date ELF machine plus SDK36 and selected guest identity",
                           "childGate": "Actual executable AArch64 ELF, raw SDK36, disabled bridge and explicit android16-arm64 profile",
                           "runtimeValidation": "NOT_RUN", "pageAlignment": 16384},
        "notClaimed": ["32-bit or unsupported-profile children", "explicit or early-cached ProcessBuilder environment maps",
                       "direct mapped property-area reads", "native VPN interfaces in children"],
    }
    (output / "metadata.json").write_text(json.dumps(metadata, indent=2) + "\n", encoding="utf-8")
    return {"extra_entries": {f"assets/cage-child/{abi}/libcage_child_properties.so": path
                              for abi, path in libraries.items()}, "metadata": metadata}


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
        "profile": "MuMu Android 12 fingerprint suffix, nonempty board/hardware, libnb.so; API 31/32",
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
