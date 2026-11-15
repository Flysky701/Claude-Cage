"""Adapt the existing no-native network probe for GBox ARM64 import; no requests."""
import argparse
import base64
import hashlib
import json
import os
from pathlib import Path
import re
import struct
import subprocess
import sys
from zipfile import ZipFile, ZIP_DEFLATED

SOURCE = Path(__file__).resolve().parent
ROOT = SOURCE.parents[3]
sys.path.insert(0, str(SOURCE.parent))
from build import _length8, _length16, signature_entry
import toolchain

JDK = toolchain.default_jdk()
TOOLS = toolchain.default_tools(ROOT)
LLVM = toolchain.llvm_prebuilt(toolchain.default_ndk(ROOT))
WORK = ROOT / "mobile/.build/gbox-mod/network-probe02"
INPUT = ROOT / "mobile/.build/gbox-test/GBox-Isolation-Probe.apk"


def manifest(data):
    strings, locations, elements = [], [], []
    position = 8
    pool_flags = None
    while position < len(data):
        kind, header, size = struct.unpack_from("<HHI", data, position)
        if size < header or position + size > len(data): raise ValueError("Invalid resource chunk")
        if kind == 1:
            count, _, flags, start, _ = struct.unpack_from("<IIIII", data, position + 8)
            pool_flags = position + 16
            for i in range(count):
                p = position + start + struct.unpack_from("<I", data, position + header + 4 * i)[0]
                encoding = "utf-8" if flags & 256 else "utf-16le"
                if flags & 256:
                    _, p = _length8(data, p)
                    length, p = _length8(data, p)
                else:
                    length, p = _length16(data, p)
                    length *= 2
                strings.append(data[p:p + length].decode(encoding))
                locations.append((p, length, encoding))
        elif kind == 0x102:
            name = struct.unpack_from("<I", data, position + 20)[0]
            offset, stride, count = struct.unpack_from("<HHH", data, position + 24)
            attributes, positions = {}, {}
            for i in range(count):
                at = position + 16 + offset + i * stride
                _, key, raw, _, _, value_type, value = struct.unpack_from("<IIIHBBI", data, at)
                attributes[strings[key]] = strings[value] if value_type == 3 else value
                positions[strings[key]] = (at, value_type, value, raw)
            elements.append({"name": strings[name], "attributes": attributes, "positions": positions})
        position += size
    return elements, locations, pool_flags


def logical(elements):
    return [{"name": item["name"], "attributes": dict(item["attributes"])} for item in elements]


def upgrade_manifest(original):
    elements, locations, flags_at = manifest(original)
    root = elements[0]
    expected = {"package": "io.github.leexeo.cage.gboxtst", "versionCode": 3, "versionName": "0.3"}
    if root["name"] != "manifest" or any(root["attributes"].get(k) != v for k, v in expected.items()):
        raise ValueError("Network probe manifest differs from the inspected sample")
    updated = bytearray(original)
    at, value_type, _, _ = root["positions"]["versionCode"]
    if value_type != 16: raise ValueError("Unexpected versionCode encoding")
    struct.pack_into("<I", updated, at + 8, 0xffffffff)
    struct.pack_into("<I", updated, at + 16, 4)
    _, value_type, string_index, _ = root["positions"]["versionName"]
    if value_type != 3: raise ValueError("Unexpected versionName encoding")
    pos, length, encoding = locations[string_index]
    replacement = "2.0".encode(encoding)
    if len(replacement) != length: raise ValueError("Version name would resize string pool")
    updated[pos:pos + length] = replacement
    flags = struct.unpack_from("<I", updated, flags_at)[0]
    struct.pack_into("<I", updated, flags_at, flags & ~1)
    after = logical(manifest(bytes(updated))[0])
    before = logical(elements)
    before[0]["attributes"].update(versionCode=4, versionName="2.0")
    if before != after: raise ValueError("Manifest changes exceed the two version attributes")
    return bytes(updated), after


def verify_marker(data):
    if data[:6] != b"\x7fELF\x02\x01" or struct.unpack_from("<H", data, 18)[0] != 183:
        raise ValueError("Marker is not ARM64")
    phoff = struct.unpack_from("<Q", data, 32)[0]
    phsize, count = struct.unpack_from("<HH", data, 54)
    for i in range(count):
        kind, flags, offset, _, _, size, _, _ = struct.unpack_from("<IIQQQQQQ", data, phoff + i * phsize)
        if kind == 0x6474e551 and flags & 1: raise ValueError("Marker requests executable stack")
        if kind == 2:
            for pos in range(offset, offset + size, 16):
                tag, value = struct.unpack_from("<qQ", data, pos)
                if tag == 0: break
                if tag in (1, 12, 13, 25, 26, 32): raise ValueError("Marker has a dependency or initializer")
    if b"JNI_OnLoad" in data or b"cage_network_probe_arm64_marker\0" not in data:
        raise ValueError("Marker export contract changed")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=ROOT / "dist/Cage-GBox-Network-Probe-02.apk")
    parser.add_argument("--finalize-only", action="store_true")
    args = parser.parse_args()
    if args.output.exists(): raise FileExistsError("Output exists")
    WORK.mkdir(parents=True, exist_ok=True)
    env = dict(os.environ, CAGE_NETWORK_BUILD_PASSWORD="android")
    def run(*command):
        p = subprocess.run([str(x) for x in command], env=env, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        if p.returncode: raise RuntimeError(Path(command[0]).name + " failed: " + p.stdout.decode("utf-8", "replace"))
        return p.stdout.decode("utf-8", "replace")
    certs = run(JDK / "bin/java.exe", "-jar", TOOLS / "lib/apksigner.jar", "verify", "--print-certs", INPUT)
    original_signers = re.findall(r"certificate SHA-256 digest: ([0-9a-f]+)", certs)
    public = run(JDK / "bin/keytool.exe", "-J-Duser.language=en", "-J-Duser.country=US", "-list", "-rfc",
        "-keystore", ROOT / "mobile/.build/sandbox/development.p12", "-storepass:env", "CAGE_NETWORK_BUILD_PASSWORD")
    certificates = re.findall(r"-----BEGIN CERTIFICATE-----(.*?)-----END CERTIFICATE-----", public, re.S)
    local = [hashlib.sha256(base64.b64decode(item)).hexdigest() for item in certificates]
    if len(local) != 1 or local != original_signers: raise ValueError("Original signer differs from development.p12")
    library = WORK / "libcage_network_probe_abi.so"
    if not args.finalize_only:
        run(LLVM / "bin/clang.exe", "-fintegrated-cc1", "--target=aarch64-linux-android28",
            "--sysroot=" + str(LLVM / "sysroot"), "-resource-dir=" + str(toolchain.clang_resource_dir(LLVM)),
            "-std=c11", "-O2", "-fPIC", "-fvisibility=hidden", "-mno-outline-atomics", "-Wall", "-Wextra", "-Werror",
            "-c", SOURCE / "abi_marker.c", "-o", WORK / "marker.o")
        run(LLVM / "bin/ld.lld.exe", "-shared", "-m", "aarch64linux", "-z", "defs", "-z", "noexecstack",
            "-z", "now", "-z", "relro", "--hash-style=gnu", "--build-id=sha1", "-soname", library.name,
            WORK / "marker.o", "-o", library)
        verify_marker(library.read_bytes())
        with ZipFile(INPUT) as source, ZipFile(WORK / "unsigned.apk", "w") as output:
            if any(n.startswith("lib/") for n in source.namelist()): raise ValueError("Input unexpectedly contains native libraries")
            for entry in source.infolist():
                if signature_entry(entry.filename): continue
                data = source.read(entry.filename)
                if entry.filename == "AndroidManifest.xml": data, _ = upgrade_manifest(data)
                output.writestr(entry, data)
            output.write(library, "lib/arm64-v8a/" + library.name, compress_type=ZIP_DEFLATED)
    run(TOOLS / "zipalign.exe", "-f", "4", WORK / "unsigned.apk", WORK / "aligned.apk")
    run(JDK / "bin/java.exe", "-jar", TOOLS / "lib/apksigner.jar", "sign", "--ks", ROOT / "mobile/.build/sandbox/development.p12",
        "--ks-pass", "env:CAGE_NETWORK_BUILD_PASSWORD", "--out", args.output, WORK / "aligned.apk")
    signed = run(JDK / "bin/java.exe", "-jar", TOOLS / "lib/apksigner.jar", "verify", "--print-certs", args.output)
    if re.findall(r"certificate SHA-256 digest: ([0-9a-f]+)", signed) != original_signers: raise ValueError("Final signer mismatch")
    with ZipFile(INPUT) as source, ZipFile(args.output) as output:
        changed = [n for n in source.namelist() if not signature_entry(n) and source.read(n) != output.read(n)]
        added = sorted(n for n in output.namelist() if n not in source.namelist() and not signature_entry(n))
        if changed != ["AndroidManifest.xml"] or added != ["lib/arm64-v8a/" + library.name]:
            raise ValueError("Unexpected package changes")
        verify_marker(output.read(added[0]))
        expected_manifest, manifest_view = upgrade_manifest(source.read("AndroidManifest.xml"))
        if expected_manifest != output.read("AndroidManifest.xml"): raise ValueError("Manifest mismatch")
        dex = {n: hashlib.sha256(output.read(n)).hexdigest() for n in output.namelist() if re.fullmatch(r"classes(?:\d+)?\.dex", n)}
    metadata = {"artifact": str(args.output), "package": "io.github.leexeo.cage.gboxtst", "activity": ".SandboxActivity",
        "originalVersionCode": 3, "versionCode": 4, "versionName": "2.0", "abi": ["arm64-v8a"],
        "signatureVerified": True, "originalSignerPreserved": True, "signerSha256": original_signers[0],
        "originalDexAndResourcesByteIdentical": True, "dexSha256": dex, "manifestOnlyVersionChanged": True,
        "permissions": [x["attributes"]["name"] for x in manifest_view if x["name"] == "uses-permission"],
        "permissionAndComponentScopeUnchanged": True, "networkTargetsAndRequestLogicUnchanged": True,
        "marker": {"noJniOnLoad": True, "noInitializersOrDependencies": True, "javaDoesNotCallMarker": True},
        "build": "PASS", "purpose": "ARM64 import compatibility only", "deviceImport": "NOT_RUN", "networkValidation": "NOT_RUN",
        "accountOperations": False, "publicNetworkRequestsDuringBuild": 0,
        "inputSha256": hashlib.sha256(INPUT.read_bytes()).hexdigest(), "artifactSha256": hashlib.sha256(args.output.read_bytes()).hexdigest()}
    args.output.with_suffix(".json").write_text(json.dumps(metadata, indent=2), encoding="utf-8")
    print(json.dumps({"artifact": str(args.output), "versionCode": 4, "versionName": "2.0", "abi": metadata["abi"], "dexUnchanged": True, "signerPreserved": True}))


if __name__ == "__main__": main()
