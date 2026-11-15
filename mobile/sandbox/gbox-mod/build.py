"""Repackage the supplied GBox sample without replacing its native engine or presets.

All output is local. No device is selected, installed, cleared or configured here.
The source APK and optional privacy overlay are the inputs, not recovered upstream
Java/C++ source. The original APK remains necessary to reproduce the result.
"""
import argparse
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import re
import shutil
import struct
import subprocess
import uuid
from zipfile import ZipFile

from native_relocation import TARGETS as NATIVE_HOST_TARGETS, relocate as relocate_native_host
import toolchain

ROOT = Path(__file__).resolve().parents[3]
MODULE = Path(__file__).resolve().parent
BUILD = ROOT / "mobile/.build/gbox-mod"
OLD = "com.gbox.android"
NEW = "com.cage.android"
SHARED_OLD = "com.gbox.shared"
SHARED_NEW = "com.cage.shared"


def run(*args, env=None):
    completed = subprocess.run([os.fspath(a) for a in args], env=env,
                               stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    output = completed.stdout.decode("utf-8", "replace")
    if completed.returncode:
        raise RuntimeError(Path(args[0]).name + " exited " + str(completed.returncode)
                           + ": " + output)
    return output


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def signature_entry(name):
    return name.upper().startswith("META-INF/") and name.upper().endswith(
        (".SF", ".RSA", ".DSA", ".EC", "/MANIFEST.MF"))


def dex_classes(data):
    string_count, strings_at = struct.unpack_from("<II", data, 56)
    strings = []
    for index in range(string_count):
        pos = struct.unpack_from("<I", data, strings_at + index * 4)[0]
        while data[pos] & 128:
            pos += 1
        pos += 1
        end = data.index(b"\0", pos)
        # Only descriptors are used below; unrelated MUTF-8 string constants may
        # contain encoded NULs which ordinary UTF-8 does not accept.
        strings.append(data[pos:end].decode("utf-8", "replace"))
    count, offset = struct.unpack_from("<II", data, 64)
    types = [strings[struct.unpack_from("<I", data, offset + i * 4)[0]] for i in range(count)]
    count, offset = struct.unpack_from("<II", data, 96)
    return {types[struct.unpack_from("<I", data, offset + i * 32)[0]] for i in range(count)}


def rename_literal(value, class_names):
    # Several provider authorities can share one manifest string.
    if ";" in value and all(part.startswith((OLD + ".", NEW + "."))
                             for part in value.split(";")):
        return ";".join(NEW + part[len(OLD):] if part.startswith(OLD + ".") else part
                        for part in value.split(";"))
    if value == OLD:
        return NEW
    if value == SHARED_OLD:
        return SHARED_NEW
    if value in class_names or value.startswith(OLD + ".helper"):
        return value
    if value.startswith(OLD + ".") or value == OLD + "_app_shortcut":
        return NEW + value[len(OLD):]
    if value.startswith("content://" + OLD + "."):
        return value.replace("content://" + OLD + ".", "content://" + NEW + ".", 1)
    if "/data/data/" + OLD + "/" in value:
        return value.replace("/data/data/" + OLD + "/", "/data/data/" + NEW + "/")
    return value


def _length8(data, offset):
    number = data[offset]
    return (((number & 127) << 8) | data[offset + 1], offset + 2) if number & 128 else (number, offset + 1)


def _length16(data, offset):
    number = struct.unpack_from("<H", data, offset)[0]
    if number & 32768:
        return ((number & 32767) << 16) | struct.unpack_from("<H", data, offset + 2)[0], offset + 4
    return number, offset + 2


def patch_pool(data, start, class_names, label=False):
    _, header, size = struct.unpack_from("<HHI", data, start)
    count, _, flags, strings_at, _ = struct.unpack_from("<IIIII", data, start + 8)
    encoding = "utf-8" if flags & 256 else "utf-16le"
    changes = 0
    seen = set()
    for index in range(count):
        relative = struct.unpack_from("<I", data, start + header + index * 4)[0]
        pos = start + strings_at + relative
        if pos in seen:
            continue
        seen.add(pos)
        if flags & 256:
            _, pos = _length8(data, pos)
            length, pos = _length8(data, pos)
        else:
            length, pos = _length16(data, pos)
            length *= 2
        value = bytes(data[pos:pos + length]).decode(encoding)
        replacement = "Cage" if label and value == "GBox" else rename_literal(value, class_names)
        if replacement != value:
            encoded = replacement.encode(encoding)
            if len(encoded) != length:
                raise ValueError("Resource pool replacement changed byte length")
            data[pos:pos + length] = encoded
            changes += 1
    if changes and flags & 1:
        struct.pack_into("<I", data, start + 16, flags & ~1)
    return changes


def patch_resources(original, class_names, label=False):
    data = bytearray(original)
    changes = 0

    def walk(start, end):
        nonlocal changes
        pos = start
        while pos < end:
            kind, header, size = struct.unpack_from("<HHI", data, pos)
            if size < header or size < 8 or pos + size > end:
                raise ValueError("Invalid Android resource chunk")
            if kind == 1:
                changes += patch_pool(data, pos, class_names, label)
            elif kind in (2, 3, 0x200):
                if kind == 0x200:
                    raw = bytes(data[pos + 12:pos + 268])
                    package = raw.decode("utf-16le").split("\0", 1)[0]
                    if package == OLD:
                        replacement = NEW.encode("utf-16le")
                        data[pos + 12:pos + 12 + len(replacement)] = replacement
                        changes += 1
                walk(pos + header, pos + size)
            pos += size

    walk(0, len(data))
    return bytes(data), changes


def relocated_sources(decoded, class_names):
    changes = {}
    for path in decoded.glob("smali*/**/*.smali"):
        text = path.read_text(encoding="utf-8")
        if OLD not in text and SHARED_OLD not in text:
            continue
        lines = text.splitlines(keepends=True)
        modified = []
        for line in lines:
            if "const-string" in line or line.startswith(".field "):
                line = re.sub(r'"((?:\\.|[^"\\])*)"',
                              lambda m: '"' + rename_literal(m[1], class_names) + '"', line)
            modified.append(line)
        result = "".join(modified)
        if result != text:
            changes[path.relative_to(decoded)] = result
    return changes


def patch_once(path, old, new):
    text = path.read_text(encoding="utf-8")
    if text.count(old) != 1:
        raise ValueError("Expected exactly one relocation anchor: " + str(path))
    path.write_text(text.replace(old, new), encoding="utf-8", newline="\n")


def verify_coexist_manifest(source, candidate, tools):
    def authorities(path):
        xml = run(tools / "aapt2.exe", "dump", "xmltree", path, "--file", "AndroidManifest.xml")
        values = re.findall(r'android:authorities[^\n]*?="([^"\n]+)"', xml)
        return {authority for value in values for authority in value.split(";")}
    original, rebuilt = authorities(source), authorities(candidate)
    conflicts = original & rebuilt
    if conflicts:
        raise ValueError("Provider authorities still conflict with original: " + ", ".join(sorted(conflicts)))
    if len(original) != len(rebuilt):
        raise ValueError("Provider authority count changed during relocation")
    return len(rebuilt)


def add_provider_relocation(decoded, work, context):
    core = decoded / "smali_classes4/com/vlite/sdk"
    bridge = "Lio/github/leexeo/cage/gbox/HostRelocation;"
    anchor = "    check-cast v1, Ljava/lang/String;\n"
    patch_once(core / "client/hook/service/am/c$a0.smali", anchor, anchor +
               "\n    invoke-static {v1}, " + bridge + "->authority(Ljava/lang/String;)Ljava/lang/String;\n"
               "    move-result-object v1\n    aput-object v1, p3, v0\n")
    proxy = core / "ІӀӏ/j1.smali"
    text = proxy.read_text(encoding="utf-8")
    begin = text.index(".method public static B(ZLjava/lang/String;Landroid/os/IInterface;)Landroid/os/IInterface;")
    end = text.index(".end method", begin)
    method = text[begin:end]
    anchor = "    return-object p0\n"
    if method.count(anchor) != 2:
        raise ValueError("Provider wrapping return points changed")
    method = method.replace(anchor, "    invoke-static {p1, p0}, " + bridge +
                            "->provider(Ljava/lang/String;Landroid/os/IInterface;)Landroid/os/IInterface;\n"
                            "    move-result-object p0\n" + anchor)
    proxy.write_text(text[:begin] + method + text[end:], encoding="utf-8", newline="\n")
    classes = work / "relocation-classes"
    classes.mkdir()
    stub = work / "relocation-stubs/com/vlite/sdk/client/k.java"
    stub.parent.mkdir(parents=True)
    stub.write_text("package com.vlite.sdk.client; public class k { public static k getInst(){throw new UnsupportedOperationException();} public boolean hasInit(){throw new UnsupportedOperationException();} public String getVirtualClientPkgName(){throw new UnsupportedOperationException();}}", encoding="utf-8")
    run(context["jdk"] / "bin/javac.exe", "--release", "8", "-encoding", "UTF-8",
        "-cp", context["android_jar"], "-d", classes, stub,
        *sorted((MODULE / "java").rglob("*.java")))
    jar = work / "relocation.jar"
    with ZipFile(jar, "w") as archive:
        for path in (classes / "io").rglob("*.class"):
            archive.write(path, path.relative_to(classes).as_posix())
    output = work / "relocation-dex"
    output.mkdir()
    run(context["tools"] / "d8.bat", "--min-api", "21", "--lib", context["android_jar"],
        "--output", output, jar, env=context["env"])
    stub_apk = work / "relocation.apk"
    with ZipFile(context["input"]) as source, ZipFile(stub_apk, "w") as archive:
        archive.writestr("AndroidManifest.xml", source.read("AndroidManifest.xml"))
        archive.write(output / "classes.dex", "classes.dex")
    decoded_bridge = work / "relocation-decoded"
    run(context["jdk"] / "bin/java.exe", "-jar", context["apktool"], "d", "--no-res",
        "--no-assets", "-o", decoded_bridge, stub_apk)
    shutil.copytree(decoded_bridge / "smali", decoded / "smali_classes7")
    return {"smali_classes4", "smali_classes7"}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", type=Path, default=ROOT / "mobile/.build/gbox-test/GBox-1.8.4.02.apk")
    parser.add_argument("--decoded", type=Path, default=BUILD / "decoded-original")
    parser.add_argument("--jdk", type=Path, default=toolchain.default_jdk())
    parser.add_argument("--tools", type=Path, default=toolchain.default_tools(ROOT))
    parser.add_argument("--android-jar", type=Path, default=toolchain.default_android_jar(ROOT))
    parser.add_argument("--apktool", type=Path, default=toolchain.default_apktool(ROOT))
    parser.add_argument("--keystore", type=Path, default=ROOT / "mobile/.build/sandbox/development.p12")
    parser.add_argument("--identity", choices=("coexist", "original"), default="coexist")
    parser.add_argument("--privacy", action="store_true")
    parser.add_argument("--account-diag", action="store_true")
    parser.add_argument("--native-trace", action="store_true",
                        help="Record fixed initialization-stage labels without disabling hooks")
    parser.add_argument("--mumu-compat", action="store_true",
                        help="Add the guarded API31/32 ARM64 MuMu native compatibility candidate")
    parser.add_argument("--ndk", type=Path, default=toolchain.default_ndk(ROOT))
    parser.add_argument("--privacy-modules", default="sim,timezone,vpn",
                        help="Comma-separated scoped modules for staged validation")
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    if args.output.exists() or args.output.resolve() == args.input.resolve():
        raise ValueError("Choose a new output path; existing artifacts are never overwritten")
    env = dict(os.environ, JAVA_HOME=str(args.jdk.resolve()))
    if "CAGE_GBOX_KEYSTORE_PASSWORD" not in env:
        if args.keystore.resolve() != (ROOT / "mobile/.build/sandbox/development.p12").resolve():
            raise ValueError("Set CAGE_GBOX_KEYSTORE_PASSWORD for a custom keystore")
        env["CAGE_GBOX_KEYSTORE_PASSWORD"] = "android"
    BUILD.mkdir(parents=True, exist_ok=True)
    input_sha = sha(args.input)
    if not args.decoded.exists():
        print("Decoding input APK", flush=True)
        run(args.jdk / "bin/java.exe", "-jar", args.apktool, "d", "--no-res", "--no-assets",
            "-o", args.decoded, args.input)
    # Confirm the shared decode cache belongs to this exact input before copying it.
    marker = args.decoded / ".cage-input-sha256"
    if marker.exists() and marker.read_text().strip() != input_sha:
        raise ValueError("Decode cache belongs to another APK")
    if not marker.exists():
        with ZipFile(args.input) as source:
            if (args.decoded / "AndroidManifest.xml").read_bytes() != source.read("AndroidManifest.xml"):
                raise ValueError("Decode cache manifest does not match the input")
        marker.write_text(input_sha + "\n", encoding="ascii")
    # Keep this shorter than decoded-original: several upstream Kotlin class
    # filenames are already close to the ordinary Windows path-length limit.
    work = BUILD / ("w" + uuid.uuid4().hex[:7])
    work.mkdir()
    decoded = work / "d"
    with ZipFile(args.input) as source:
        dex_inputs = {n: source.read(n) for n in source.namelist()
                      if re.fullmatch(r"classes(?:\d+)?\.dex", n)}
    original_classes = set().union(*(dex_classes(d) for d in dex_inputs.values()))
    class_names = {name[1:-1].replace("/", ".") for name in original_classes}
    edits = relocated_sources(args.decoded, class_names) if args.identity == "coexist" else {}
    changed = {path.parts[0] for path in edits}
    if args.identity == "coexist" or args.privacy or args.native_trace or args.mumu_compat or args.account_diag:
        changed.add("smali_classes4")
    decoded.mkdir()
    print("Preparing " + str(len(changed)) + " editable DEX source groups", flush=True)
    for folder in sorted(changed):
        shutil.copytree(args.decoded / folder, decoded / folder)
    for name in dex_inputs:
        folder = "smali" if name == "classes.dex" else "smali_" + name[:-4]
        (decoded / folder).mkdir(exist_ok=True)
    shutil.copyfile(args.decoded / "AndroidManifest.xml", decoded / "AndroidManifest.xml")
    for relative, text in edits.items():
        (decoded / relative).write_text(text, encoding="utf-8", newline="\n")
    context = {"root": ROOT, "jdk": args.jdk, "tools": args.tools,
               "android_jar": args.android_jar, "apktool": args.apktool,
               "env": env, "run": run, "input": args.input,
               "host_package": NEW if args.identity == "coexist" else OLD,
               "native_trace": args.native_trace,
               "ndk": args.ndk,
               "privacy_modules": args.privacy_modules.split(",")}
    changed_sources = len(edits)
    if args.identity == "coexist":
        changed |= add_provider_relocation(decoded, work, context)
    profile_result = {}
    if args.privacy:
        spec = importlib.util.spec_from_file_location("gbox_privacy", MODULE / "privacy/apply.py")
        profile = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(profile)
        profile_result = profile.apply(decoded, work, context)
        for name in profile_result.get("changed_dex", []):
            changed.add("smali" if name == "classes.dex" else "smali_" + name[:-4])
    compat_result = {}
    if args.mumu_compat:
        spec = importlib.util.spec_from_file_location("gbox_compat", MODULE / "compat/apply.py")
        compat = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(compat)
        compat_result = compat.apply(decoded, work, context)
        for name in compat_result.get("changed_dex", []):
            changed.add("smali" if name == "classes.dex" else "smali_" + name[:-4])
    trace_result = {}
    if args.native_trace:
        from native_trace import apply as apply_trace
        trace_changed, trace_result = apply_trace(decoded, work, context["host_package"], asset_paths=args.mumu_compat)
        changed |= trace_changed
    diag_result = {}
    if args.account_diag:
        from account_diag import apply as apply_account_diag
        diag_changed, diag_result = apply_account_diag(decoded, work, context["host_package"])
        changed |= diag_changed
    dex_outputs = dict(dex_inputs)
    for folder in sorted(changed):
        name = "classes.dex" if folder == "smali" else folder[len("smali_"):] + ".dex"
        print("Assembling " + name, flush=True)
        path = work / name
        run(args.jdk / "bin/java.exe", "-cp", args.apktool, MODULE / "AssembleDex.java",
            decoded / folder, path, "28")
        dex_outputs[name] = path.read_bytes()
    actual_classes = set().union(*(dex_classes(d) for d in dex_outputs.values()))
    if not original_classes.issubset(actual_classes):
        raise ValueError("Rebuilt APK lost original classes")
    extra_classes = actual_classes - original_classes
    if any(not c.startswith("Lio/github/leexeo/cage/") for c in extra_classes):
        raise ValueError("Unexpected added classes: " + repr(sorted(extra_classes)[:8]))
    unsigned = work / "unsigned.apk"
    resource_changes = {}
    native_changes = {}
    native_host_changes = {}
    with ZipFile(args.input) as source, ZipFile(unsigned, "w") as output:
        for entry in source.infolist():
            name = entry.filename
            if signature_entry(name):
                continue
            data = dex_outputs.get(name, source.read(name))
            if args.identity == "coexist":
                if name in ("AndroidManifest.xml", "resources.arsc") or (name.startswith("res/") and name.endswith(".xml") and data[:2] == b"\x03\x00"):
                    data, count = patch_resources(data, class_names, label=name == "resources.arsc")
                    if count:
                        resource_changes[name] = count
                elif re.fullmatch(r"lib/[^/]+/libloader(?:32|64)\.so", name):
                    old = ("/data/data/" + OLD + "/").encode()
                    new = ("/data/data/" + NEW + "/").encode()
                    count = data.count(old)
                    if count != 1 or len(old) != len(new):
                        raise ValueError("Unexpected loader path layout: " + name)
                    data = data.replace(old, new)
                    native_changes[name] = count
                elif re.fullmatch(r"lib/[^/]+/libvlitecore(?:32|64)\.so", name):
                    if name not in NATIVE_HOST_TARGETS:
                        raise ValueError("Unknown native host constant location: " + name)
                    data, detail = relocate_native_host(name, data)
                    native_host_changes[name] = detail
            output.writestr(entry, data)
        for name, data in dex_outputs.items():
            if name not in dex_inputs:
                output.writestr(name, data)
        added_entries = set()
        for overlay in (profile_result, compat_result):
            for name, path in overlay.get("extra_entries", {}).items():
                if name in source.namelist() or name in added_entries:
                    raise ValueError("An overlay cannot overwrite existing assets")
                output.write(path, name)
                added_entries.add(name)
    preserved_presets = []
    with ZipFile(args.input) as source, ZipFile(unsigned) as output:
        for name in source.namelist():
            if name.startswith("assets/preset_apps/") and name.endswith(".apk"):
                if source.read(name) != output.read(name):
                    raise ValueError("A preset APK was modified: " + name)
                preserved_presets.append(name)
    if len(preserved_presets) != 4:
        raise ValueError("Expected four original preset APKs")
    if args.identity == "coexist" and set(native_host_changes) != set(NATIVE_HOST_TARGETS):
        raise ValueError("Expected all four known native host constants")
    print("Aligning and signing local artifact", flush=True)
    aligned, signed = work / "aligned.apk", work / "signed.apk"
    try:
        run(args.tools / "zipalign.exe", "-p", "-f", "4", unsigned, aligned)
    except RuntimeError:
        print("Assembly is retained at " + str(unsigned), flush=True)
        print("Use finalize.py --unsigned <that path> --output <new APK path> to retry only packaging.", flush=True)
        raise
    run(args.tools / "apksigner.bat", "sign", "--ks", args.keystore,
        "--ks-pass", "env:CAGE_GBOX_KEYSTORE_PASSWORD", "--out", signed, aligned, env=env)
    run(args.tools / "apksigner.bat", "verify", signed, env=env)
    badging = run(args.tools / "aapt2.exe", "dump", "badging", signed)
    if "package: name='" + context["host_package"] + "'" not in badging:
        raise ValueError("Unexpected output application identity")
    if args.identity == "coexist":
        verify_coexist_manifest(args.input, signed, args.tools)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(signed, args.output)
    evidence = {"schemaVersion": 1, "inputSha256": input_sha,
                "artifactSha256": sha(args.output), "package": context["host_package"],
                "identity": args.identity, "privacy": args.privacy,
                "originalClasses": len(original_classes), "addedClasses": len(extra_classes),
                "relocatedSmaliFiles": changed_sources, "assembledDex": sorted(changed),
                "resourceChanges": resource_changes, "nativePathChanges": native_changes,
                "nativeHostRelocations": native_host_changes,
                "presetsPreservedByteForByte": preserved_presets,
                "signatureVerified": True, "installed": False, "loginVerified": False,
                "privacyProfile": profile_result.get("metadata", {}),
                "nativeTrace": trace_result,
                "nativeCompat": compat_result.get("metadata", {}),
                "buildDirectory": str(work.relative_to(ROOT))}
    args.output.with_suffix(".json").write_text(json.dumps(evidence, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps({"artifact": str(args.output), "package": context["host_package"],
                      "classes": len(actual_classes), "privacy": args.privacy}), flush=True)


if __name__ == "__main__":
    main()
