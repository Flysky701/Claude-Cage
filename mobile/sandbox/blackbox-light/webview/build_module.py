"""Compile the arm64 WebView transport and dependency-free Java module; never access a device."""
import argparse
import os
from pathlib import Path
import subprocess
import tempfile
from zipfile import ZIP_DEFLATED, ZipFile


def path(value):
    return Path(os.path.realpath(os.path.abspath(os.fspath(value))))


def run(*args):
    subprocess.run([os.fspath(value) for value in args], check=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--ndk", required=True, type=Path)
    parser.add_argument("--sdk", required=True, type=Path)
    parser.add_argument("--jdk", required=True, type=Path)
    parser.add_argument("--build-tools", required=True, type=Path)
    args = parser.parse_args()
    here = path(__file__).parent
    output = here / ".build"
    host = "windows-x86_64" if os.name == "nt" else ("darwin-x86_64" if os.uname().sysname == "Darwin" else "linux-x86_64")
    llvm = path(args.ndk) / "toolchains/llvm/prebuilt" / host
    suffix = ".exe" if os.name == "nt" else ""
    clang = llvm / "bin" / ("clang" + suffix)
    java = path(args.jdk) / "bin" / ("java" + suffix)
    javac = path(args.jdk) / "bin" / ("javac" + suffix)
    android = path(args.sdk) / "platforms/android-35/android.jar"
    d8 = path(args.build_tools) / "lib/d8.jar"
    for file in (clang, java, javac, android, d8):
        if not file.is_file():
            parser.error(f"required local tool missing: {file}")
    output.mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="compile-", dir=output) as temporary:
        work = path(temporary)
        work.relative_to(path(output))
        native = work / "libcage_webview.so"
        run(clang, "--target=aarch64-linux-android28", "--sysroot=" + str(llvm / "sysroot"),
            "-std=c11", "-O2", "-fPIC", "-shared", "-Wall", "-Wextra", "-Werror", "-Wconversion",
            "-fstack-protector-strong", "-mbranch-protection=standard", "-fvisibility=hidden",
            "-Wl,-z,defs,-z,now,-z,relro,-z,noexecstack,-z,max-page-size=16384,-soname,libcage_webview.so",
            here / "cage_webview.c", "-llog", "-ldl", "-o", native)
        classes = work / "classes"
        classes.mkdir()
        run(javac, "--release", "8", "-encoding", "UTF-8", "-Xlint:all", "-Werror",
            "-cp", android, "-d", classes, here / "RouteWebView.java")
        jar = work / "webview-route.jar"
        with ZipFile(jar, "w", ZIP_DEFLATED) as archive:
            for file in sorted(classes.rglob("*.class")):
                archive.write(file, file.relative_to(classes).as_posix())
        run(java, "-cp", d8, "com.android.tools.r8.D8", "--min-api", "28", "--lib", android,
            "--output", work, jar)
        for file in (native, jar, work / "classes.dex"):
            destination = output / file.name
            file.replace(destination)
            print(destination)


if __name__ == "__main__":
    main()
