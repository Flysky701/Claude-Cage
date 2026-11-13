"""Build the two experiment APKs from the existing phone-tested shell and relay."""
import argparse
import os
from pathlib import Path
import struct
import subprocess
import tempfile
from zipfile import ZipFile
from space_manifest import add_space_activity
from space_accounts import account_runtime


def without_internet(xml):
    """Remove whole INTERNET uses-permission elements without rebuilding other resources."""
    u16 = lambda pos: struct.unpack_from("<H", xml, pos)[0]
    u32 = lambda pos: struct.unpack_from("<I", xml, pos)[0]
    pos = u16(2)
    result = bytearray(xml[:pos])
    strings = []
    removed = 0
    while pos < len(xml):
        kind, header, size = struct.unpack_from("<HHI", xml, pos)
        if size < header or size == 0 or pos + size > len(xml):
            raise ValueError("malformed binary manifest")
        if kind == 1:
            utf8 = bool(u32(pos + 16) & 256)
            pool = pos + u32(pos + 20)
            for i in range(u32(pos + 8)):
                start = pool + u32(pos + header + 4 * i)
                if utf8:
                    start += 2 if xml[start] & 128 else 1
                    length = xml[start]
                    start += 1
                    if length & 128:
                        length = ((length & 127) << 8) | xml[start]
                        start += 1
                    strings.append(xml[start:start + length].decode("utf-8", errors="replace"))
                else:
                    length = u16(start)
                    start += 2
                    if length & 32768:
                        length = ((length & 32767) << 16) | u16(start)
                        start += 2
                    strings.append(xml[start:start + 2 * length].decode("utf-16le"))
        if kind == 0x102 and strings[u32(pos + 20)] == "uses-permission":
            first = pos + 16 + u16(pos + 24)
            attributes = [first + i * u16(pos + 26) for i in range(u16(pos + 28))]
            if any(strings[u32(a + 4)] == "name" and xml[a + 15] == 3 and
                   strings[u32(a + 16)] == "android.permission.INTERNET" for a in attributes):
                end = pos + size
                if u16(end) != 0x103 or u32(end + 20) != u32(pos + 20):
                    raise ValueError("unexpected nonempty permission element")
                pos = end + u32(end + 4)
                removed += 1
                continue
        result.extend(xml[pos:pos + size])
        pos += size
    if not removed:
        raise ValueError("base shell did not request INTERNET")
    struct.pack_into("<I", result, 4, len(result))
    return result


def run(*args):
    subprocess.run([os.fspath(arg) for arg in args], check=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--sdk", required=True, type=Path)
    parser.add_argument("--jdk", required=True, type=Path)
    parser.add_argument("--build-tools", type=Path, help="Android Build Tools directory")
    parser.add_argument("--only", choices=("shell", "relay"))
    parser.add_argument("--ndk", type=Path, help="include the arm64 system-curl IPv4 transport")
    args = parser.parse_args()
    os.environ["JAVA_HOME"] = str(args.jdk)
    here = Path(__file__).resolve().parent
    build = here.parents[1] / ".build"
    blackbox = build / "blackbox-source"
    key = build / "sandbox/development.p12"
    output = build / "blackbox-light"
    output.mkdir(exist_ok=True)
    android = args.sdk / "platforms/android-35/android.jar"
    tools = args.build_tools or args.sdk / "build-tools/34.0.0"

    for shell in (True, False):
        if args.only and (args.only == "shell") != shell:
            continue
        name = "Cage-BlackBox-Light" if shell else "Cage-Light-Relay"
        if shell and args.ndk:
            name = "Cage-BlackBox-Curl4"
        source = here if shell else here.parent / "local-core"
        base = (blackbox / "BlackBoxReborn-2.1.0-Cage-BinderStream.apk" if shell
                else build / "on-device-core/Cage-LocalCore.apk")
        with tempfile.TemporaryDirectory(dir=output) as staging:
            work = Path(staging)
            classes = work / "classes"
            classes.mkdir()
            runtime_sources = sorted(p for p in source.glob("*.java") if p.name != "AssembleSpaceDex.java")
            run(args.jdk / "bin/javac.exe", "--release", "8", "-encoding", "UTF-8", "-cp", android,
                "-d", classes, here.parent / "shared/SpaceSites.java", *runtime_sources)
            jar = work / "classes.jar"
            with ZipFile(jar, "w") as out:
                if shell:
                    with ZipFile(blackbox / "region-runtime.jar") as previous:
                        for item in previous.infolist():
                            if item.filename.endswith(".class") and not (classes / item.filename).exists():
                                out.writestr(item, previous.read(item))
                for file in classes.rglob("*.class"):
                    out.write(file, file.relative_to(classes).as_posix())
            run(tools / "d8.bat", "--min-api", "28", "--lib", android, "--output", work, jar)
            native = work / "libcage_curl4.so"
            if shell and args.ndk:
                llvm = args.ndk / "toolchains/llvm/prebuilt/windows-x86_64"
                if not llvm.is_dir():
                    llvm = args.ndk
                run(llvm / "bin/clang.exe", "--target=aarch64-linux-android28", "--sysroot=" + str(llvm / "sysroot"),
                    "-std=c11", "-Os", "-fPIC", "-shared", "-Wall", "-Wextra", "-Werror", "-nostdlib",
                    "-Wl,-z,defs,-z,now,-z,relro,-z,noexecstack,-soname,libcage_curl4.so",
                    here / "curl4_local.c", "-lc", "-ldl", "-llog", "-o", native)
            replace = "classes2.dex" if shell else "classes.dex"
            with ZipFile(base) as old, ZipFile(work / "unsigned.apk", "w") as out:
                if replace not in old.namelist():
                    raise ValueError("unexpected base APK")
                for item in old.infolist():
                    if item.filename.upper().startswith("META-INF/") and item.filename.upper().endswith(
                            (".SF", ".RSA", ".DSA", ".EC", "/MANIFEST.MF")):
                        continue
                    data = old.read(item)
                    if item.filename == replace:
                        data = (work / "classes.dex").read_bytes()
                    elif shell and item.filename == "classes.dex":
                        data = account_runtime(base, work, args.jdk / "bin/java.exe", blackbox / "apktool.jar")
                    elif shell and item.filename == "AndroidManifest.xml":
                        data = add_space_activity(without_internet(data))
                    out.writestr(item, data)
                if native.exists():
                    out.write(native, "lib/arm64-v8a/libcage_curl4.so")
            run(tools / "zipalign.exe", "-p", "-f", "4", work / "unsigned.apk", work / "aligned.apk")
            run(tools / "apksigner.bat", "sign", "--ks", key, "--ks-pass", "pass:android", "--out",
                output / (name + ".apk"), work / "aligned.apk")
        print(output / (name + ".apk"))


if __name__ == "__main__":
    main()
