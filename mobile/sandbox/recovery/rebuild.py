"""Rebuild recovered DEMO code against the exact APK recovered from the phone.

The Smali overlays are executable sources recovered from DEX, not the lost Java
files. Native libraries, guest APKs, resources and assets are never reconstructed.
The default output is unsigned. Signed test copies use separate application IDs.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
from zipfile import ZipFile


ROOT = Path(__file__).resolve().parents[3]
BUILD = ROOT / "mobile/.build/source-recovery"
RENAMES = {
    "top.niunaijun.microdem": "top.niunaijun.microrec",
    "io.github.leexeo.cage.microdemo": "io.github.leexeo.cage.microtest",
    "Cage 轻量 DEMO": "Cage 恢复 DEMO",
    "Cage 空间网关": "Cage 恢复网关",
}


def run(*args, env=None):
    result = subprocess.run([os.fspath(a) for a in args], env=env,
                            stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    if result.returncode:
        raise RuntimeError(Path(args[0]).name + " exited " + str(result.returncode) + ": "
                           + result.stdout.decode("utf-8", errors="replace"))
    return result.stdout.decode("utf-8", errors="replace")


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def signature_entry(name):
    upper = name.upper()
    return upper.startswith("META-INF/") and upper.endswith(
        (".SF", ".RSA", ".DSA", ".EC", "/MANIFEST.MF"))


def rename_text(text):
    for old, new in RENAMES.items():
        text = text.replace(old, new).replace(old.replace(".", "/"), new.replace(".", "/"))
    return text


def rename_manifest(data, package):
    # Equal UTF-8 AND UTF-16 lengths preserve binary XML string-pool offsets.
    found = False
    for old, new in RENAMES.items():
        for encoding in ("utf-8", "utf-16le"):
            before, after = old.encode(encoding), new.encode(encoding)
            if len(before) != len(after):
                raise ValueError("Manifest replacements must have equal lengths")
            if old == package and before in data:
                found = True
            data = data.replace(before, after)
    if not found:
        raise ValueError("Expected application ID absent from binary manifest")
    return data


def dex_api(data):
    versions = {b"035": 23, b"037": 25, b"038": 27, b"039": 28, b"040": 30, b"041": 35}
    if data[:4] != b"dex\n" or data[4:7] not in versions:
        raise ValueError("Unsupported DEX header")
    return versions[data[4:7]]


def source_map(directory):
    """Index by actual DEX class descriptor, including renamed test classes."""
    result = {}
    for path in directory.glob("smali*/**/*.smali"):
        text = path.read_text(encoding="utf-8")
        lines = [line.strip() for line in text.splitlines()
                 if line.strip() and not line.lstrip().startswith("#")]
        descriptor = next(line.split()[-1] for line in lines if line.startswith(".class "))
        if descriptor in result:
            raise ValueError("Duplicate DEX class: " + descriptor)
        result[descriptor] = normalize_labels(lines)
    return result


def normalize_labels(lines):
    """Compare branch destinations rather than names assigned by the disassembler.

    Labels can be renamed or coalesced during assembly. Each destination is
    represented by its instruction position; strings, directives, registers and
    instructions are still compared. No executable changes are ignored.
    """
    output = []
    pos = 0
    while pos < len(lines):
        if not lines[pos].startswith(".method "):
            output.append(lines[pos])
            pos += 1
            continue
        end = lines.index(".end method", pos) + 1
        method = lines[pos:end]
        labels, definitions, instruction, payload = {}, set(), 0, False
        for index, line in enumerate(method):
            if line.startswith((".packed-switch ", ".sparse-switch", ".array-data ")):
                payload = True
            elif line.startswith((".end packed-switch", ".end sparse-switch", ".end array-data")):
                payload = False
            elif line.startswith(":") and not payload:
                labels[line] = ":offset_" + str(instruction)
                definitions.add(index)
            elif not line.startswith("."):
                instruction += 1
        for index, line in enumerate(method):
            if index in definitions:
                continue
            # Match string literals first so a string containing ':cond_0' stays literal.
            output.append(re.sub(r'"(?:\\.|[^"\\])*"|:[A-Za-z0-9_$]+',
                                 lambda match: labels.get(match[0], match[0]), line))
        pos = end
    return "\n".join(output)


def compile_overrides(module, decoded, work, java, jdk, tools, sdk, apktool, source, env,
                      extra_sources=()):
    sources = sorted((module / "java").rglob("*.java")) + list(extra_sources)
    if not sources:
        return 0
    android = sdk / "platforms/android-35/android.jar"
    classes = work / "java-classes"
    classes.mkdir()
    run(jdk / "bin/javac.exe", "--release", "8", "-encoding", "UTF-8", "-g",
        "-cp", android, "-d", classes, *sources)
    jar = work / "overrides.jar"
    with ZipFile(jar, "w") as out:
        for path in classes.rglob("*.class"):
            out.write(path, path.relative_to(classes).as_posix())
    dex = work / "java-dex"
    dex.mkdir()
    run(tools / "d8.bat", "--min-api", "28", "--lib", android,
        "--output", dex, jar, env=env)
    stub_apk = work / "overrides.apk"
    with ZipFile(source) as base, ZipFile(stub_apk, "w") as out:
        out.writestr("AndroidManifest.xml", base.read("AndroidManifest.xml"))
        out.writestr("classes.dex", (dex / "classes.dex").read_bytes())
    new_sources = work / "java-smali"
    run(java, "-jar", apktool, "d", "--no-res", "--no-assets", "-o", new_sources, stub_apk)
    # Remove the old class family before replacing it, including obsolete lambdas.
    for source_file in sources:
        package = re.search(r"^package\s+([\w.]+);", source_file.read_text(encoding="utf-8"), re.M)[1]
        for folder in decoded.glob("smali*"):
            directory = folder / package.replace(".", "/")
            for old in directory.glob(source_file.stem + "*.smali"):
                if old.stem == source_file.stem or old.stem.startswith(source_file.stem + "$"):
                    if not old.resolve().is_relative_to(decoded.resolve()):
                        raise ValueError("Class replacement escaped the build directory")
                    old.unlink()
    for path in (new_sources / "smali").rglob("*.smali"):
        dest = decoded / "smali_classes3" / path.relative_to(new_sources / "smali")
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(path, dest)
    return len(sources)


def main(target, module):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--jdk", type=Path, required=True)
    parser.add_argument("--sdk", type=Path, required=True)
    parser.add_argument("--build-tools", default="34.0.0",
                        help="SDK Build Tools version or absolute Build Tools directory")
    parser.add_argument("--apktool", type=Path,
                        default=ROOT / "mobile/.build/blackbox-source/apktool.jar")
    parser.add_argument("--input", type=Path)
    parser.add_argument("--output", type=Path)
    parser.add_argument("--mode", choices=("unsigned", "test-copy"), default="unsigned")
    parser.add_argument("--integrity-lab-apk", type=Path,
                        help="Build a separate MGC integration lab from the supplied GBox APK")
    parser.add_argument("--owned-integrity-test-apk", type=Path,
                        help="Allow the owner's signed Integrity test app in the recovery copy")
    parser.add_argument("--keystore", type=Path,
                        default=ROOT / "mobile/.build/sandbox/development.p12")
    args = parser.parse_args()
    manifest = json.loads((module / "recovery.json").read_text(encoding="utf-8"))
    source = (args.input or ROOT / manifest["input"]).resolve()
    if not source.is_file() or digest(source) != manifest["sha256"]:
        raise ValueError("The exact recovered input APK is required; see recovery.json")
    BUILD.mkdir(parents=True, exist_ok=True)
    test_copy = args.mode == "test-copy"
    owned_test = None
    if args.owned_integrity_test_apk:
        if target != "space" or not test_copy or args.integrity_lab_apk:
            parser.error("--owned-integrity-test-apk requires the recovery space test copy without the MGC lab")
        import runpy
        owned_test = runpy.run_path(str(ROOT / "mobile/integrity-test/recovery/profile.py"))
    lab = None
    if args.integrity_lab_apk:
        if target != "space" or not test_copy:
            parser.error("--integrity-lab-apk requires the space target and --mode test-copy")
        import runpy
        lab = runpy.run_path(str(module / "integrity-lab/profile.py"))
        RENAMES["top.niunaijun.microdem"] = "top.niunaijun.mgclab00"
        RENAMES["Cage 轻量 DEMO"] = "Cage 验证 DEMO"
    suffix = "Test.apk" if test_copy else "Unsigned.apk"
    default_name = "Cage-Integrity-Lab.apk" if lab else "Cage-Recovered-" + target.title() + "-" + suffix
    output = (args.output or ROOT / "dist" / default_name).resolve()
    if output == source:
        raise ValueError("Output must not replace the recovery input")
    if output.exists():
        raise FileExistsError("Choose a new output path; existing artifacts are retained: " + str(output))
    java = args.jdk / "bin/java.exe"
    tools = args.sdk / "build-tools" / args.build_tools
    env = dict(os.environ, JAVA_HOME=str(args.jdk.resolve()))
    if test_copy:
        if not args.keystore.is_file():
            raise FileNotFoundError("A development keystore is required for a separate test copy")
        if "CAGE_RECOVERY_KEYSTORE_PASSWORD" not in env:
            if args.keystore.resolve() != (ROOT / "mobile/.build/sandbox/development.p12").resolve():
                raise ValueError("Set CAGE_RECOVERY_KEYSTORE_PASSWORD for a custom keystore")
            env["CAGE_RECOVERY_KEYSTORE_PASSWORD"] = "android"

    with tempfile.TemporaryDirectory(prefix=target + "-", dir=BUILD) as tmp:
        work = Path(tmp)
        decoded = work / "decoded"
        # Keep debug metadata: the second decode verifies executable sources as well
        # as their metadata, instead of merely counting classes or trusting javac.
        print("Decoding the verified input", flush=True)
        run(java, "-jar", args.apktool, "d", "--no-res", "--no-assets",
            "-o", decoded, source)
        overlays = sorted(module.glob("smali*/**/*.smali"))
        if not overlays:
            raise ValueError("Recovered sources are missing")
        for path in overlays:
            dest = decoded / path.relative_to(module)
            dest.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(path, dest)
        lab_assets = {}
        extra_sources = []
        if lab:
            lab_assets = lab["prepare"](module, decoded, work, args, tools, env, run)
            extra_sources = sorted((module / "integrity-lab/java").rglob("*.java"))
        if owned_test:
            lab_assets = owned_test["prepare"](decoded, args, tools, env, run)
            extra_sources = sorted((ROOT / "mobile/integrity-test/recovery/java").rglob("*.java"))
        java_sources = compile_overrides(module, decoded, work, java, args.jdk, tools,
                                         args.sdk, args.apktool, source, env, extra_sources)
        if test_copy:
            for path in decoded.glob("smali*/**/*.smali"):
                path.write_text(rename_text(path.read_text(encoding="utf-8")),
                                encoding="utf-8", newline="\n")

        original_dex = {}
        rebuilt_dex = {}
        with ZipFile(source) as apk:
            for name in apk.namelist():
                if name.startswith("classes") and name.endswith(".dex") and "/" not in name:
                    original_dex[name] = apk.read(name)
        for name, data in original_dex.items():
            folder = "smali" if name == "classes.dex" else "smali_" + name[:-4]
            rebuilt = work / name
            print("Assembling " + name, flush=True)
            run(java, "-cp", args.apktool,
                ROOT / "mobile/sandbox/blackbox-light/AssembleSpaceDex.java",
                decoded / folder, rebuilt, str(dex_api(data)))
            rebuilt_dex[name] = rebuilt.read_bytes()

        unsigned = work / "unsigned.apk"
        with ZipFile(source) as old, ZipFile(unsigned, "w") as new:
            for entry in old.infolist():
                if signature_entry(entry.filename):
                    continue
                data = rebuilt_dex.get(entry.filename)
                if data is None:
                    data = old.read(entry)
                if test_copy and entry.filename == "AndroidManifest.xml":
                    data = rename_manifest(data, manifest["package"])
                new.writestr(entry, data)
            for name, path in lab_assets.items():
                new.write(path, name)

        print("Verifying rebuilt code and preserved resources", flush=True)
        check = work / "check"
        run(java, "-jar", args.apktool, "d", "--no-res", "--no-assets", "-o", check, unsigned)
        expected, actual = source_map(decoded), source_map(check)
        differences = sorted(k for k in expected.keys() | actual.keys()
                             if expected.get(k) != actual.get(k))
        if differences:
            # Leave a compact report; do not publish a partially verified artifact.
            (BUILD / (target + "-roundtrip-differences.json")).write_text(
                json.dumps(differences, indent=2), encoding="utf-8")
            (BUILD / (target + "-roundtrip-detail.json")).write_text(json.dumps(
                {k: {"expected": expected.get(k), "actual": actual.get(k)} for k in differences},
                indent=2), encoding="utf-8")
            raise ValueError("DEX round-trip differences: " + ", ".join(differences[:8]))
        with ZipFile(source) as old, ZipFile(unsigned) as new:
            preserved = 0
            for entry in old.infolist():
                name = entry.filename
                if signature_entry(name) or name in rebuilt_dex:
                    continue
                if test_copy and name == "AndroidManifest.xml":
                    continue
                if old.read(name) != new.read(name):
                    raise ValueError("Unexpected change to a resource or library: " + name)
                preserved += 1

        aligned = work / "aligned.apk"
        try:
            run(tools / "zipalign.exe", "-p", "-f", "4", unsigned, aligned)
        except RuntimeError:
            shutil.copyfile(unsigned, BUILD / (target + "-alignment-input.apk"))
            raise
        artifact = aligned
        if test_copy:
            artifact = work / "signed.apk"
            run(tools / "apksigner.bat", "sign", "--ks", args.keystore,
                "--ks-pass", "env:CAGE_RECOVERY_KEYSTORE_PASSWORD",
                "--out", artifact, aligned, env=env)
            run(tools / "apksigner.bat", "verify", artifact, env=env)
        badging = run(tools / "aapt2.exe", "dump", "badging", artifact)
        package = RENAMES[manifest["package"]] if test_copy else manifest["package"]
        if "package: name='" + package + "'" not in badging:
            raise ValueError("Unexpected output application ID")
        output.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(artifact, output)
        evidence = {
            "target": target, "mode": args.mode, "package": package,
            "inputSha256": manifest["sha256"], "outputSha256": digest(output),
            "recoveredSourceFiles": len(overlays), "verifiedDexClasses": len(actual),
            "javaOverrideSources": java_sources,
            "dexSourceRoundTrip": True, "preservedResourceAndLibraryEntries": preserved,
            "signed": test_copy, "installed": False,
            "originalJavaSourceRecovered": False,
            "originalSigningKeyRecovered": False,
            "integrityLab": bool(lab),
            "ownedIntegrityTest": bool(owned_test),
            "integrityVerdictsVerified": False,
        }
        output.with_suffix(".json").write_text(json.dumps(evidence, indent=2), encoding="utf-8")
        print(json.dumps(evidence, indent=2), flush=True)
        print(output, flush=True)


if __name__ == "__main__":
    raise SystemExit("Use blackbox-light/demo/build.py or light-gateway/build.py")
