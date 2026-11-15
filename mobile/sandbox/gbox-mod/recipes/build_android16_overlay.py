"""Build a minimal, same-version privacy overlay of the logged-in Privacy15 APK.

Offline only. No device operation, package uninstall, data initialization or release.
The original signing key and exact baseline are required; all non-policy entries
remain byte-identical, including the manifest, container engine and preset apps.
"""
import argparse
import importlib.util
import json
import os
from pathlib import Path
import re
import shutil
import sys
import uuid
from zipfile import ZipFile, ZIP_DEFLATED

MODULE = Path(__file__).resolve().parents[1]
ROOT = MODULE.parents[2]
sys.path.insert(0, str(MODULE))
from build import dex_classes, run, sha, signature_entry
import toolchain

BASE_SHA = "8c2125b8a0bb20221a7b36c5ab8d1fc8ceb42e7578785d80f3db9128db36ff93"
PRIVACY_PREFIX = "Lio/github/leexeo/cage/privacy/"


def entries(path):
    with ZipFile(path) as archive:
        if len(archive.namelist()) != len(set(archive.namelist())):
            raise ValueError("Duplicate APK entries")
        return {name: archive.read(name) for name in archive.namelist() if not signature_entry(name)}


def certificate(path, java, tools, env):
    output = run(java, "-jar", tools / "lib/apksigner.jar", "verify", "--print-certs", path, env=env)
    digests = re.findall(r"Signer #\d+ certificate SHA-256 digest: ([0-9a-f]+)", output)
    if len(digests) != 1:
        raise ValueError("Expected one verified signing certificate")
    return digests[0]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--base", type=Path, default=MODULE / "dist/Cage-GBox-Privacy-15.apk")
    parser.add_argument("--base-sha256", help="Exact reviewed base hash when preserving a newer same-signature home overlay")
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--ndk", type=Path, default=toolchain.default_ndk(ROOT))
    args = parser.parse_args()
    if args.output.exists() or args.output.with_suffix(".json").exists():
        raise FileExistsError("Output exists; choose a new local test artifact")
    expected_base = args.base_sha256 or BASE_SHA
    if not re.fullmatch(r"[0-9a-f]{64}", expected_base):
        raise ValueError("Expected base SHA-256 must be 64 lowercase hexadecimal characters")
    base_sha = sha(args.base)
    if base_sha != expected_base:
        raise ValueError("Baseline does not match the exact reviewed APK hash")
    before = entries(args.base)
    privacy_dex = []
    baseline_classes = set()
    for name, data in before.items():
        if re.fullmatch(r"classes(?:\d+)?\.dex", name):
            classes = dex_classes(data)
            if PRIVACY_PREFIX + "GuestPrivacy;" in classes:
                if not all(c.startswith(PRIVACY_PREFIX) for c in classes):
                    raise ValueError("Privacy DEX also contains unrelated classes")
                privacy_dex.append(name)
                baseline_classes = classes
    if privacy_dex != ["classes8.dex"]:
        raise ValueError("Unexpected baseline privacy DEX: " + str(privacy_dex))
    work = ROOT / "mobile/.build/gbox-mod" / ("android16-" + uuid.uuid4().hex[:8])
    work.mkdir(parents=True)
    jdk, tools = toolchain.default_jdk(), toolchain.default_tools(ROOT)
    android = toolchain.default_android_jar(ROOT)
    java = jdk / "bin/java.exe"
    env = dict(os.environ, JAVA_HOME=str(jdk), CAGE_GBOX_KEYSTORE_PASSWORD="android")
    original_cert = certificate(args.base, java, tools, env)
    context = dict(root=ROOT, run=run, env=env, ndk=args.ndk)
    replacements, components = {}, {}
    for name in ("native", "child"):
        spec = importlib.util.spec_from_file_location("android16_" + name, MODULE / "privacy" / name / "build.py")
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        result = module.build(work, context)
        replacements.update({entry: path.read_bytes() for entry, path in result["extra_entries"].items()
                             if not entry.startswith("assets/cage-child/x86_64/")})
        components[name] = result["metadata"]
    classes, dex = work / "classes", work / "dex"
    classes.mkdir(); dex.mkdir()
    profile = work / "Profile.java"
    profile.write_text('package io.github.leexeo.cage.privacy;\nfinal class Profile {\n'
                       ' static final boolean SIM=true, TIMEZONE=true, VPN=true;\n'
                       ' static final String ZONE="Asia/Tokyo";\n}\n', encoding="utf-8")
    sources = sorted((MODULE / "privacy/java").rglob("*.java"))
    run(jdk / "bin/javac.exe", "--release", "8", "-encoding", "UTF-8", "-g", "-cp", android,
        "-d", classes, *sources, profile, env=env)
    jar = work / "privacy.jar"
    with ZipFile(jar, "w") as archive:
        for file in sorted(classes.rglob("*.class")):
            archive.write(file, file.relative_to(classes).as_posix())
    run(java, "-cp", tools / "lib/d8.jar", "com.android.tools.r8.D8", "--min-api", "28", "--lib", android,
        "--output", dex, jar, env=env)
    new_dex = (dex / "classes.dex").read_bytes()
    new_classes = dex_classes(new_dex)
    if not baseline_classes.issubset(new_classes) or not all(c.startswith(PRIVACY_PREFIX) for c in new_classes):
        raise ValueError("Privacy class preservation/scope check failed")
    replacements[privacy_dex[0]] = new_dex
    allowed = {"classes8.dex", "lib/arm64-v8a/libcage_privacy.so",
               "lib/arm64-v8a/libbytehook.so", "lib/arm64-v8a/libshadowhook.so",
               "lib/arm64-v8a/libshadowhook_nothing.so", "assets/cage-privacy/THIRD-PARTY-NOTICES.txt",
               "assets/cage-child/arm64-v8a/libcage_child_properties.so"}
    if set(replacements) != allowed:
        raise ValueError("Unexpected replacement entry")
    unsigned, aligned, signed = work / "unsigned.apk", work / "aligned.apk", work / "signed.apk"
    with ZipFile(args.base) as source, ZipFile(unsigned, "w") as output:
        for entry in source.infolist():
            if not signature_entry(entry.filename):
                output.writestr(entry, replacements.get(entry.filename, before[entry.filename]))
        for name in sorted(allowed - before.keys()):
            output.writestr(name, replacements[name], compress_type=ZIP_DEFLATED)
    run(tools / "zipalign.exe", "-p", "-f", "4", unsigned, aligned)
    run(java, "-jar", tools / "lib/apksigner.jar", "sign", "--ks", ROOT / "mobile/.build/sandbox/development.p12",
        "--ks-pass", "env:CAGE_GBOX_KEYSTORE_PASSWORD", "--out", signed, aligned, env=env)
    signed_cert = certificate(signed, java, tools, env)
    if signed_cert != original_cert:
        raise ValueError("Signing certificate changed")
    after = entries(signed)
    removed = set(before) - set(after)
    added = set(after) - set(before)
    changed = {name for name in before.keys() & after.keys() if before[name] != after[name]}
    if removed or added != allowed - before.keys() or not changed.issubset(allowed):
        raise ValueError("Unexpected signed APK delta")
    if any(after[name] != raw for name, raw in replacements.items()):
        raise ValueError("Replacement bytes changed during packaging")
    badging = run(tools / "aapt2.exe", "dump", "badging", signed)
    if "package: name='com.cage.android' versionCode='1080402' versionName='1.8.4.02'" not in badging:
        raise ValueError("Package or version changed")
    result = {
        "base": str(args.base.resolve()), "baseSha256": base_sha, "artifactSha256": sha(signed),
        "package": "com.cage.android", "versionCode": 1080402, "versionName": "1.8.4.02",
        "certificateSha256": signed_cert, "sameCertificate": True, "signedEntryDeltaVerified": True,
        "changedEntries": sorted(changed), "addedEntries": sorted(added), "removedEntries": sorted(removed),
        "allOtherEntriesByteIdentical": True, "components": components,
        "x86ChildAssetReusedByteForByte": True,
        "sourceHashes": {str(p.relative_to(ROOT)): sha(p) for p in sources},
        "buildDirectory": str(work.relative_to(ROOT)), "deviceValidation": "NOT_RUN",
        "loginStateValidation": "NOT_RUN", "release": False,
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(signed, args.output)
    args.output.with_suffix(".json").write_text(json.dumps(result, indent=2), encoding="utf-8")
    print(json.dumps({k: result[k] for k in ("artifactSha256", "changedEntries", "addedEntries", "sameCertificate", "buildDirectory")}))


if __name__ == "__main__":
    main()
