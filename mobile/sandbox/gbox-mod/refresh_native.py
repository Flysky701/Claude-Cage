"""Apply the verified host-constant relocation to an existing version 02 APK.

This path reuses every DEX, manifest, resource and preset byte, and verifies the
signed artifact differs only in the four known native data regions.
"""
import argparse
import json
import os
from pathlib import Path
import shutil
import uuid
from zipfile import ZipFile

from build import BUILD, ROOT, NEW, run, sha, signature_entry
from native_relocation import TARGETS, relocate


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--base", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--tools", type=Path, default=ROOT / "mobile/.build/client-integration/build-tools35/android-15")
    parser.add_argument("--jdk", type=Path, default=Path("D:/Code/DevEnv/JAVA/jdk-17"))
    parser.add_argument("--keystore", type=Path, default=ROOT / "mobile/.build/sandbox/development.p12")
    args = parser.parse_args()
    if args.output.exists() or args.output.resolve() == args.base.resolve():
        raise ValueError("Choose a new output path")
    metadata = json.loads(args.base.with_suffix(".json").read_text("utf-8"))
    base_sha = sha(args.base)
    if metadata["artifactSha256"] != base_sha or metadata["package"] != NEW or metadata["identity"] != "coexist":
        raise ValueError("The selected base is not the recorded coexist artifact")
    env = dict(os.environ, JAVA_HOME=str(args.jdk.resolve()))
    if "CAGE_GBOX_KEYSTORE_PASSWORD" not in env:
        if args.keystore.resolve() != (ROOT / "mobile/.build/sandbox/development.p12").resolve():
            raise ValueError("Set CAGE_GBOX_KEYSTORE_PASSWORD for a custom keystore")
        env["CAGE_GBOX_KEYSTORE_PASSWORD"] = "android"
    work = BUILD / ("r" + uuid.uuid4().hex[:7])
    work.mkdir(parents=True)
    unsigned, aligned, signed = (work / name for name in ("unsigned.apk", "aligned.apk", "signed.apk"))
    native = {}
    expected = {}
    with ZipFile(args.base) as source, ZipFile(unsigned, "w") as output:
        for entry in source.infolist():
            name = entry.filename
            if signature_entry(name):
                continue
            data = source.read(name)
            if name in TARGETS:
                data, native[name] = relocate(name, data)
                expected[name] = data
            output.writestr(entry, data)
    if set(native) != set(TARGETS):
        raise ValueError("Expected all four native host constants")
    run(args.tools / "zipalign.exe", "-p", "-f", "4", unsigned, aligned)
    run(args.tools / "apksigner.bat", "sign", "--ks", args.keystore,
        "--ks-pass", "env:CAGE_GBOX_KEYSTORE_PASSWORD", "--out", signed, aligned, env=env)
    run(args.tools / "apksigner.bat", "verify", signed, env=env)
    with ZipFile(args.base) as base, ZipFile(signed) as candidate:
        base_entries = {name for name in base.namelist() if not signature_entry(name)}
        final_entries = {name for name in candidate.namelist() if not signature_entry(name)}
        if base_entries != final_entries:
            raise ValueError("Non-signature entry set changed")
        changed = []
        for name in sorted(base_entries):
            before, after = base.read(name), candidate.read(name)
            if before != after:
                if name not in expected or after != expected[name]:
                    raise ValueError("Unexpected incremental change: " + name)
                changed.append(name)
        if set(changed) != set(TARGETS):
            raise ValueError("Native patch was not preserved by packaging")
    args.output.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(signed, args.output)
    metadata.update({
        "artifactSha256": sha(args.output), "nativeHostRelocations": native,
        "changedInputEntries": sorted(set(metadata.get("changedInputEntries", [])) | set(TARGETS)),
        "assembledDex": [], "signatureVerified": True, "installed": False,
        "privacyVerified": False, "loginVerified": False,
        "buildDirectory": str(work.relative_to(ROOT)),
        "incrementalDelta": {
            "base": str(args.base), "baseSha256": base_sha,
            "changed": changed, "added": [], "removed": [],
            "allOtherNonSignatureEntriesIdentical": True,
            "manifestDexResourcesAndPresetsReused": True,
            "baseClassAndAuthorityChecksInheritedWithoutChanges": True,
        },
        "runtimeStatus": "NOT_TESTED; Trace-03 verified the same native host relocation, but ART initialization remains blocked",
    })
    args.output.with_suffix(".json").write_text(json.dumps(metadata, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps({"artifact": str(args.output), "privacy": metadata["privacy"],
                      "changedNativeEntries": len(changed), "assembledDex": 0,
                      "signatureVerified": True}, ensure_ascii=False))


if __name__ == "__main__":
    main()
