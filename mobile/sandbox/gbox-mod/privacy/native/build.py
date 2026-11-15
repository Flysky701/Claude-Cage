"""Build only the selected-guest ARM64 native reading policy; no device operations."""
from pathlib import Path
import json
import sys
import importlib.util

MODULE = Path(__file__).resolve().parent
GBOX_MOD = MODULE.parents[1]
if str(GBOX_MOD) not in sys.path:
    sys.path.insert(0, str(GBOX_MOD))
import toolchain


def build(work: Path, context: dict) -> dict:
    output = Path(work) / "privacy-native"
    output.mkdir(parents=True, exist_ok=True)
    root = Path(context["root"])
    ndk = Path(context.get("ndk") or toolchain.default_ndk(root))
    llvm = toolchain.llvm_prebuilt(ndk)
    resource_dir = toolchain.clang_resource_dir(llvm)
    builtins = toolchain.clang_builtins(llvm, "aarch64")
    run, env = context["run"], context["env"]
    temporary = output / "tmp"
    temporary.mkdir(exist_ok=True)
    env = dict(env, TEMP=str(temporary), TMP=str(temporary))
    obj, library = output / "privacy.o", output / "libcage_privacy.so"
    run(llvm / "bin/clang++.exe", "-fintegrated-cc1", "--target=aarch64-linux-android28",
        "--sysroot=" + str(llvm / "sysroot"), "-resource-dir=" + str(resource_dir),
        "-std=c++17", "-O2", "-fPIC", "-fno-exceptions", "-fno-rtti", "-fvisibility=hidden",
        "-mno-outline-atomics", "-Wall", "-Wextra", "-Werror", "-Wno-deprecated-declarations",
        "-I" + str(MODULE), "-c", MODULE / "privacy.cpp", "-o", obj, env=env)
    run(llvm / "bin/ld.lld.exe", "-shared", "-m", "aarch64linux", "--hash-style=gnu", "--eh-frame-hdr",
        "--build-id=sha1", "-z", "defs", "-z", "now", "-z", "relro", "-z", "noexecstack",
        "-z", "max-page-size=16384", "-soname", library.name,
        "-L" + str(llvm / "sysroot/usr/lib/aarch64-linux-android/28"),
        "-L" + str(llvm / "sysroot/usr/lib/aarch64-linux-android"), obj,
        builtins,
        "-lc", "-ldl", "-llog", "-o", library, env=env)
    metadata = {
        "abi": "arm64-v8a", "hooks": ["__system_property_get", "__system_property_read",
                                         "__system_property_read_callback", "getifaddrs"],
        "mechanism": "MuMu: existing ByteHook 1.0.8; native API36: separate pinned ByteHook 1.1.2 / ShadowHook 2.0.1; selected ARM caller PLT",
        "scope": "Selected guest code/native/data roots; per-call selected policy gate",
        "android16NativeArm64": {
            "sdk": 36, "nativeBridgeUsed": False,
            "loadNotification": "Dedicated ByteHook 1.1.2 / ShadowHook 2.0.1 native load observer; no MuMu host wrapper",
            "ifaddrsOwnership": "Exact full getifaddrs/allocation callback/freeifaddrs code sample from inspected phone libc",
            "libcSha256": "5d5e553e27e8a94d78685f18985433810caa5427c95a246478a697c3c538d5f6",
            "pageAlignment": 16384, "runtimeValidation": "NOT_RUN",
        },
        "nativeLoadNotification": {
            "gate": "Existing verified MuMu compatibility and active current selected guest",
            "method": "Runtime.nativeLoad(String, ClassLoader, Class): String; ordinary JNI",
            "originalCall": "True host x86_64 JNI wrapper directly calls original host entry on the unchanged Runtime ArtMethod; original arguments, error String and exception preserved",
            "refresh": "Synchronous original ByteHook post_dlopen after successful nativeLoad, before returning to Java",
            "sampleGuard": "Nine complete original function windows, six GOT targets, existing manager/callback state",
            "concurrency": "Different threads serialize their own events; same-thread pending events drain before outer notification returns",
            "failureCheck": "One absent private path: original method before registration versus wrapped error comparison; no successful load notification",
            "independentEvidence": "HostLoadProbe02: correct loader in successful/nested JNI_OnLoad, ARM callbacks [3,3,0], real WebView plus callbacks [5,5,0]; GBox integration pending",
            "priorFailure": "Privacy10 copied Runtime method broke ART JNI_OnLoad loader identity; its loader observer has been removed",
            "hostLoader": "Independent boot-parent helper DEX with empty native search path; host library is an asset, helper and callback classes retained with global JNI references",
            "originalCompatibilityHooks": "Original 17-entry table and 11 required installations remain separate",
        },
        "notClaimed": ["host x86 library reads", "raw netlink/syscalls", "dlsym direct reads", "subprocess inheritance",
            "ELF constructors before nativeLoad returns", "JNI_OnLoad reads before nativeLoad returns",
            "pure native loads bypassing Runtime.nativeLoad", "concurrent callers racing before the loader returns",
            "same-thread refresh-reentrant inner return before its pending event is drained"],
        "requiresRuntimeValidation": True,
    }
    spec = importlib.util.spec_from_file_location("privacy_android16_dependencies", MODULE / "dependencies.py")
    dependencies = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(dependencies)
    extra, records = dependencies.prepare(output / "dependencies")
    metadata["android16NativeArm64"]["dependencies"] = records
    extra["lib/arm64-v8a/libcage_privacy.so"] = library
    (output / "metadata.json").write_text(json.dumps(metadata, indent=2) + "\n", encoding="utf-8")
    return {"extra_entries": extra, "metadata": metadata}
