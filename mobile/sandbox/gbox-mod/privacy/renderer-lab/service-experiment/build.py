"""Build an isolated, no-INTERNET experiment. Never installs or changes Cage."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import uuid
from zipfile import ZipFile

HERE = Path(__file__).resolve().parent
MOD = HERE.parents[2]
ROOT = MOD.parents[2]
sys.path.insert(0, str(MOD))
import toolchain


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--jdk", type=Path, default=toolchain.default_jdk())
    parser.add_argument("--build-tools", type=Path, default=toolchain.default_tools(ROOT))
    parser.add_argument("--android-jar", type=Path, default=toolchain.default_android_jar(ROOT))
    parser.add_argument("--apktool", type=Path, default=toolchain.default_apktool(ROOT))
    parser.add_argument("--llvm", type=Path, default=toolchain.llvm_prebuilt(toolchain.default_ndk(ROOT)))
    parser.add_argument("--hidden-api-smali", type=Path,
        default=ROOT / "mobile/.build/gbox-mod/decoded-original/smali_classes6/org/lsposed/hiddenapibypass")
    args = parser.parse_args()
    if args.output.exists():
        raise FileExistsError("Choose a new lab artifact")
    work = ROOT / "mobile/.build/gbox-mod" / ("renderer-lab-" + uuid.uuid4().hex[:8])
    work.mkdir(parents=True)
    classes, dex = work / "classes", work / "dex"
    classes.mkdir(); dex.mkdir()
    binary = lambda parent, name: parent / (name + (".exe" if os.name == "nt" else ""))
    java = binary(args.jdk / "bin", "java")

    def run(*command):
        proc = subprocess.run([str(x) for x in command], capture_output=True)
        if proc.returncode:
            raise RuntimeError(proc.stdout.decode("utf-8", "replace") + proc.stderr.decode("utf-8", "replace"))

    llvm=args.llvm
    resource=toolchain.clang_resource_dir(llvm)
    native=work / "librenderer_timezone.so"
    run(binary(llvm / "bin", "clang++"), "-fintegrated-cc1", "--target=aarch64-linux-android28",
        "--sysroot="+str(llvm / "sysroot"), "-resource-dir="+str(resource), "-std=c++17",
        "-O2", "-fPIC", "-fno-exceptions", "-fno-rtti", "-fvisibility=hidden", "-mno-outline-atomics",
        "-Wall", "-Wextra", "-Werror", "-c", HERE / "renderer_timezone.cpp", "-o", work / "native.o")
    run(binary(llvm / "bin", "ld.lld"), "-shared", "-m", "aarch64linux", "--hash-style=gnu", "--eh-frame-hdr",
        "--build-id=sha1", "-z", "defs", "-z", "now", "-z", "relro", "-z", "noexecstack",
        "-z", "max-page-size=16384", "-soname", native.name,
        "-L"+str(llvm / "sysroot/usr/lib/aarch64-linux-android/28"), work / "native.o",
        toolchain.clang_builtins(llvm,"aarch64"), "-lc", "-ldl", "-llog", "-o",native)
    sources = sorted(HERE.glob("*.java")) + [MOD / "privacy/java/io/github/leexeo/cage/privacy/WebViewTimezone.java"]
    run(binary(args.jdk / "bin", "javac"), "--release", "8", "-encoding", "UTF-8",
        "-cp", args.android_jar, "-d", classes, *sources)
    with ZipFile(work / "classes.jar", "w") as out:
        for path in sorted(classes.rglob("*.class")):
            out.write(path, path.relative_to(classes).as_posix())
    run(java, "-cp", args.build_tools / "lib/d8.jar", "com.android.tools.r8.D8", "--min-api", "29",
        "--lib", args.android_jar, "--output", dex, work / "classes.jar")
    # Assemble only the pre-existing upstream helper, not unrelated container classes.
    helper_sources = sorted(args.hidden_api_smali.rglob("*.smali"))
    if not helper_sources or not (args.hidden_api_smali / "HiddenApiBypass.smali").is_file():
        raise FileNotFoundError("Original container's hidden-api helper is required")
    run(java, "-cp", args.apktool, MOD / "AssembleDex.java", args.hidden_api_smali,
        work / "helper.dex", "29")
    run(binary(args.build_tools, "aapt2"), "link", "-I", args.android_jar,
        "--manifest", HERE / "AndroidManifest.xml", "-o", work / "unsigned.apk")
    with ZipFile(work / "unsigned.apk", "a") as out:
        out.write(dex / "classes.dex", "classes.dex")
        out.write(work / "helper.dex", "classes2.dex")
        out.write(native,"lib/arm64-v8a/librenderer_timezone.so")
        baseline = MOD / "dist/Cage-Android-Review-Checks02.apk"
        if hashlib.sha256(baseline.read_bytes()).hexdigest() != "1567aaf6c84e7af7dbecbcd90211358f9fc40602273b4541a63f5618b9075b61":
            raise ValueError("Dependency carrier does not match the reviewed Checks02 artifact")
        with ZipFile(baseline) as original:
            for name in ("libshadowhook.so","libshadowhook_nothing.so"):
                entry="lib/arm64-v8a/"+name
                out.writestr(entry,original.read(entry))
        out.write(MOD / "privacy/native/third_party/NOTICE.txt", "assets/cage-renderer/THIRD-PARTY-NOTICES.txt")
    run(binary(args.build_tools, "zipalign"), "-p", "-f", "4", work / "unsigned.apk", work / "aligned.apk")
    args.output.parent.mkdir(parents=True, exist_ok=True)
    run(java, "-jar", args.build_tools / "lib/apksigner.jar", "sign", "--ks",
        ROOT / "mobile/.build/sandbox/development.p12", "--ks-pass", "pass:android",
        "--out", args.output, work / "aligned.apk")
    run(java, "-jar", args.build_tools / "lib/apksigner.jar", "verify", args.output)
    sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
    metadata = {"artifactSha256": sha(args.output), "productionChange": False,
                "networkPermission": False, "runtimeValidation": "NOT_RUN",
                "sourceSha256": {str(p.relative_to(ROOT)): sha(p) for p in sources + [HERE / "renderer_timezone.cpp", HERE / "AndroidManifest.xml"]},
                "helperSha256": {p.name: sha(p) for p in helper_sources}}
    args.output.with_suffix(".json").write_text(json.dumps(metadata, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"artifact": str(args.output), "sha256": metadata["artifactSha256"]}))


if __name__ == "__main__":
    main()
