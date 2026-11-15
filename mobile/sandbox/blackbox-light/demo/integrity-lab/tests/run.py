"""Compile and run the focused check on the connected Android device, without accounts/network."""
import argparse
import os
from pathlib import Path
import subprocess
import tempfile
from zipfile import ZipFile


def run(*args, env=None):
    result = subprocess.run([str(a) for a in args], env=env, capture_output=True)
    output = result.stdout.decode("utf-8", errors="replace") + result.stderr.decode("utf-8", errors="replace")
    if result.returncode:
        raise RuntimeError(output)
    return output


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--jdk", type=Path, required=True)
    parser.add_argument("--sdk", type=Path, required=True)
    args = parser.parse_args()
    here = Path(__file__).resolve().parent
    module = here.parents[1]
    root = module.parents[3]
    build = root / "mobile/.build/integrity-flow"
    build.mkdir(parents=True, exist_ok=True)
    env = dict(os.environ, JAVA_HOME=str(args.jdk))
    adb = args.sdk / "platform-tools/adb.exe"
    android = args.sdk / "platforms/android-35/android.jar"
    tools = args.sdk / "build-tools/34.0.0"
    remote = "/data/local/tmp/cage-integrity-transport-check.jar"
    with tempfile.TemporaryDirectory(dir=build) as directory:
        work = Path(directory)
        classes, dex = work / "classes", work / "dex"
        classes.mkdir()
        dex.mkdir()
        sources = [*sorted((module / "java").rglob("*.java")),
                   *sorted((module / "integrity-lab/java").rglob("*.java")), here / "TransportCheck.java"]
        run(args.jdk / "bin/javac.exe", "--release", "8", "-encoding", "UTF-8", "-g", "-cp", android,
            "-d", classes, *sources)
        jar = work / "classes.jar"
        with ZipFile(jar, "w") as out:
            for file in classes.rglob("*.class"):
                out.write(file, file.relative_to(classes).as_posix())
        run(tools / "d8.bat", "--min-api", "28", "--lib", android, "--output", dex, jar, env=env)
        dexjar = work / "check.jar"
        with ZipFile(dexjar, "w") as out:
            out.write(dex / "classes.dex", "classes.dex")
        run(adb, "-d", "push", dexjar, remote)
        try:
            output = run(adb, "-d", "shell", "CLASSPATH=" + remote, "app_process", "/system/bin",
                "io.github.leexeo.cage.space.TransportCheck")
            if "PASS Android route/transport checks=" not in output:
                raise RuntimeError("Android check did not complete")
            print(output.strip())
        finally:
            run(adb, "-d", "shell", "rm", "-f", remote)


if __name__ == "__main__":
    main()
