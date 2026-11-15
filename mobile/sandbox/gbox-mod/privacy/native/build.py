"""Build only the selected-guest ARM64 native reading policy; no device operations."""
from pathlib import Path
import json

MODULE = Path(__file__).resolve().parent


def build(work: Path, context: dict) -> dict:
    output = Path(work) / "privacy-native"
    output.mkdir(parents=True, exist_ok=True)
    root = Path(context["root"])
    llvm = Path(context.get("ndk", root / "mobile/.build/client-integration/ndk")) / "toolchains/llvm/prebuilt/windows-x86_64"
    run, env = context["run"], context["env"]
    temporary = output / "tmp"
    temporary.mkdir(exist_ok=True)
    env = dict(env, TEMP=str(temporary), TMP=str(temporary))
    obj, library = output / "privacy.o", output / "libcage_privacy.so"
    run(llvm / "bin/clang++.exe", "-fintegrated-cc1", "--target=aarch64-linux-android28",
        "--sysroot=" + str(llvm / "sysroot"), "-resource-dir=" + str(llvm / "lib/clang/18"),
        "-std=c++17", "-O2", "-fPIC", "-fno-exceptions", "-fno-rtti", "-fvisibility=hidden",
        "-mno-outline-atomics", "-Wall", "-Wextra", "-Werror", "-Wno-deprecated-declarations",
        "-I" + str(MODULE), "-c", MODULE / "privacy.cpp", "-o", obj, env=env)
    run(llvm / "bin/ld.lld.exe", "-shared", "-m", "aarch64linux", "--hash-style=gnu", "--eh-frame-hdr",
        "--build-id=sha1", "-z", "defs", "-z", "now", "-z", "relro", "-z", "noexecstack",
        "-z", "max-page-size=4096", "-soname", library.name,
        "-L" + str(llvm / "sysroot/usr/lib/aarch64-linux-android/28"),
        "-L" + str(llvm / "sysroot/usr/lib/aarch64-linux-android"), obj,
        llvm / "lib/clang/18/lib/linux/libclang_rt.builtins-aarch64-android.a",
        "-lc", "-ldl", "-llog", "-o", library, env=env)
    metadata = {
        "abi": "arm64-v8a", "hooks": ["__system_property_get", "__system_property_read",
                                         "__system_property_read_callback", "getifaddrs"],
        "mechanism": "Existing ByteHook 1.0.8 AUTOMATIC / verified ARM caller PLT",
        "scope": "Selected guest code/native/data roots; per-call selected policy gate",
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
    (output / "metadata.json").write_text(json.dumps(metadata, indent=2) + "\n", encoding="utf-8")
    return {"extra_entries": {"lib/arm64-v8a/libcage_privacy.so": library}, "metadata": metadata}
