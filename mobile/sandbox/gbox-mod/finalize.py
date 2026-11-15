"""Finish alignment/signing of a completed build without reassembling its DEX."""
import argparse
import json
import os
from pathlib import Path
import re
import shutil
from zipfile import ZipFile

from build import ROOT, BUILD, OLD, NEW, dex_classes, run, sha, signature_entry, verify_coexist_manifest
from native_relocation import TARGETS as NATIVE_HOST_TARGETS, relocate as relocate_native_host


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--unsigned", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--input", type=Path, default=ROOT / "mobile/.build/gbox-test/GBox-1.8.4.02.apk")
    parser.add_argument("--tools", type=Path, default=ROOT / "mobile/.build/client-integration/build-tools35/android-15")
    parser.add_argument("--jdk", type=Path, default=Path("D:/Code/DevEnv/JAVA/jdk-17"))
    parser.add_argument("--keystore", type=Path, default=ROOT / "mobile/.build/sandbox/development.p12")
    parser.add_argument("--identity", choices=("coexist", "original"), default="coexist")
    args = parser.parse_args()
    if args.output.exists():
        raise FileExistsError("Output already exists")
    work = args.unsigned.resolve().parent
    if not work.is_relative_to(BUILD.resolve()):
        raise ValueError("Only a build output in this project's build directory can be finalized")
    changed, presets = [], []
    native_host_changes = {}
    original_classes, rebuilt_classes = set(), set()
    with ZipFile(args.input) as source, ZipFile(args.unsigned) as candidate:
        for name in source.namelist():
            if signature_entry(name):
                continue
            before, after = source.read(name), candidate.read(name)
            if before != after:
                changed.append(name)
                allowed = (re.fullmatch(r"classes(?:\d+)?\.dex", name)
                           or name in ("AndroidManifest.xml", "resources.arsc")
                           or (name.startswith("res/") and name.endswith(".xml"))
                           or re.fullmatch(r"lib/[^/]+/libloader(?:32|64)\.so", name))
                if name in NATIVE_HOST_TARGETS and args.identity == "coexist":
                    expected, detail = relocate_native_host(name, before)
                    if after != expected:
                        raise ValueError("Unexpected native changes beyond host constant: " + name)
                    native_host_changes[name] = detail
                    allowed = True
                if not allowed:
                    raise ValueError("Unexpected changed input: " + name)
            if name.startswith("assets/preset_apps/") and name.endswith(".apk"):
                if before != after:
                    raise ValueError("Preset APK changed: " + name)
                presets.append(name)
            if re.fullmatch(r"classes(?:\d+)?\.dex", name):
                original_classes.update(dex_classes(before))
        for name in candidate.namelist():
            if re.fullmatch(r"classes(?:\d+)?\.dex", name):
                rebuilt_classes.update(dex_classes(candidate.read(name)))
    added = rebuilt_classes - original_classes
    if not original_classes.issubset(rebuilt_classes) or len(presets) != 4:
        raise ValueError("Missing original classes or preset APKs")
    if any(not c.startswith("Lio/github/leexeo/cage/") for c in added):
        raise ValueError("Unexpected extra class")
    env = dict(os.environ, JAVA_HOME=str(args.jdk.resolve()))
    if "CAGE_GBOX_KEYSTORE_PASSWORD" not in env:
        if args.keystore.resolve() != (ROOT / "mobile/.build/sandbox/development.p12").resolve():
            raise ValueError("Set CAGE_GBOX_KEYSTORE_PASSWORD for this custom keystore")
        env["CAGE_GBOX_KEYSTORE_PASSWORD"] = "android"
    aligned, signed = work / "aligned-final.apk", work / "signed-final.apk"
    run(args.tools / "zipalign.exe", "-p", "-f", "4", args.unsigned, aligned)
    run(args.tools / "apksigner.bat", "sign", "--ks", args.keystore,
        "--ks-pass", "env:CAGE_GBOX_KEYSTORE_PASSWORD", "--out", signed, aligned, env=env)
    run(args.tools / "apksigner.bat", "verify", signed, env=env)
    package = NEW if args.identity == "coexist" else OLD
    if "package: name='" + package + "'" not in run(args.tools / "aapt2.exe", "dump", "badging", signed):
        raise ValueError("Application ID does not match requested build identity")
    authority_count = verify_coexist_manifest(args.input, signed, args.tools) if args.identity == "coexist" else None
    args.output.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(signed, args.output)
    privacy_metadata = work / "privacy/metadata.json"
    trace_metadata = work / "native-trace.json"
    compat_metadata = work / "compat/metadata.json"
    evidence = {"schemaVersion": 1, "inputSha256": sha(args.input),
                "artifactSha256": sha(args.output), "package": package,
                "identity": args.identity, "privacy": privacy_metadata.exists(),
                "originalClasses": len(original_classes), "addedClasses": len(added),
                "changedInputEntries": changed, "presetsPreservedByteForByte": presets,
                "signatureVerified": True, "installed": False, "loginVerified": False,
                "coexistProviderAuthorities": authority_count, "providerConflicts": [],
                "privacyProfile": json.loads(privacy_metadata.read_text("utf-8")) if privacy_metadata.exists() else {},
                "nativeTrace": json.loads(trace_metadata.read_text("utf-8")) if trace_metadata.exists() else {},
                "nativeCompat": json.loads(compat_metadata.read_text("utf-8")) if compat_metadata.exists() else {},
                "nativeHostRelocations": native_host_changes,
                "buildDirectory": str(work.relative_to(ROOT))}
    args.output.with_suffix(".json").write_text(json.dumps(evidence, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps({"artifact": str(args.output), "package": package,
                      "classes": len(rebuilt_classes), "privacy": privacy_metadata.exists()}))


if __name__ == "__main__":
    main()
