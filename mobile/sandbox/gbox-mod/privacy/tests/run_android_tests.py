"""Compile and optionally run synthetic policy tests in Android's real framework.

No APK installation, UI operations, account access, sockets or system settings.
Device mode uses one uniquely named temporary DEX jar and removes only that file.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import uuid
from zipfile import ZipFile

HERE = Path(__file__).resolve().parent
MOD = HERE.parents[1]
ROOT = MOD.parents[2]
sys.path.insert(0, str(MOD))
import toolchain


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--compile-only", action="store_true")
    parser.add_argument("--adb", type=Path)
    parser.add_argument("--serial")
    parser.add_argument("--port", type=int)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    if args.output.exists():
        raise FileExistsError("Choose a new test result path")
    if not args.compile_only and (not args.adb or not args.serial or args.serial.startswith("-")
                                 or args.port is None or not 1 <= args.port <= 65535):
        raise ValueError("Device mode requires explicit adb, serial and valid port")
    work = ROOT / "mobile/.build/gbox-mod" / ("policy-tests-" + uuid.uuid4().hex[:10])
    classes, dex = work / "classes", work / "dex"
    classes.mkdir(parents=True)
    dex.mkdir()
    jdk, tools = toolchain.default_jdk(), toolchain.default_tools(ROOT)
    android = toolchain.default_android_jar(ROOT)
    env = dict(os.environ, JAVA_HOME=str(jdk))

    def run(command, timeout=60):
        process = subprocess.run([str(x) for x in command], capture_output=True,
                                 timeout=timeout, env=env)
        if process.returncode:
            # Fixtures are non-sensitive, but do not echo a command containing a serial.
            stages = re.findall(r"SYNTHETIC_STAGE\|[a-z.]+", process.stdout.decode("utf-8", "replace"))
            raise RuntimeError("Synthetic test operation failed; stages=" + str(stages) + ": "
                               + process.stderr.decode("utf-8", "replace")[-1800:])
        return process.stdout.decode("utf-8", "replace")

    sources = [MOD / "privacy/java/io/github/leexeo/cage/privacy/LinkPropertiesPrivacy.java",
               MOD / "android-shell/java/io/github/leexeo/cage/preflight/NetworkMetadata.java",
               HERE / "LinkPropertiesPrivacyTest.java"]
    run([jdk / "bin/javac.exe", "--release", "8", "-encoding", "UTF-8", "-cp", android,
         "-d", classes, *sources])
    jar = work / "tests.jar"
    with ZipFile(jar, "w") as archive:
        for file in sorted(classes.rglob("*.class")):
            archive.write(file, file.relative_to(classes).as_posix())
    run([jdk / "bin/java.exe", "-cp", tools / "lib/d8.jar", "com.android.tools.r8.D8",
         "--min-api", "28", "--lib", android, "--output", dex, jar])
    artifact = work / "tests-dex.jar"
    with ZipFile(artifact, "w") as archive:
        archive.write(dex / "classes.dex", "classes.dex")
    result = {"status": "COMPILED_RUNTIME_NOT_RUN", "networkOperations": 0,
              "sourceSha256": {str(p.relative_to(ROOT)): hashlib.sha256(p.read_bytes()).hexdigest() for p in sources},
              "testDexSha256": hashlib.sha256(artifact.read_bytes()).hexdigest(),
              "buildDirectory": str(work.relative_to(ROOT))}
    if not args.compile_only:
        adb = [args.adb, "-P", str(args.port), "-s", args.serial]
        if run([*adb, "get-state"]).strip() != "device":
            raise RuntimeError("Explicit test device unavailable")
        remote = "/data/local/tmp/cage-policy-tests-" + uuid.uuid4().hex + ".jar"
        try:
            run([*adb, "push", artifact, remote])
            output = run([*adb, "shell", "env", "CLASSPATH=" + remote, "app_process", "/system/bin",
                          "io.github.leexeo.cage.privacy.LinkPropertiesPrivacyTest"])
            lines = [line for line in output.splitlines() if line.startswith('{"status":')]
            if len(lines) != 1:
                raise RuntimeError("Missing unique synthetic result")
            measured = json.loads(lines[0])
            if measured.get("status") != "PASS_SYNTHETIC_ANDROID_RUNTIME" or measured.get("checks") != 14:
                metadata = [line for line in output.splitlines() if line.startswith("SYNTHETIC_METADATA|")]
                raise RuntimeError("Synthetic policy test did not pass: " + lines[0] + " " + str(metadata))
            result.update(measured)
            result["sdk"] = int(run([*adb, "shell", "getprop", "ro.build.version.sdk"]).strip())
        finally:
            if not re.fullmatch(r"/data/local/tmp/cage-policy-tests-[0-9a-f]{32}\.jar", remote):
                raise RuntimeError("Unexpected temporary cleanup target")
            run([*adb, "shell", "rm", "-f", remote])
    args.output.parent.mkdir(parents=True, exist_ok=True)
    with args.output.open("x", encoding="utf-8") as stream:
        json.dump(result, stream, indent=2)
        stream.write("\n")
    print(json.dumps({key: result[key] for key in ("status", "networkOperations")}))


if __name__ == "__main__":
    main()
