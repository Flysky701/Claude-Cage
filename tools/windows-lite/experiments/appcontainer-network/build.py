"""Build only the independent socket probe; do not change system/network state."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess

HERE = Path(__file__).resolve().parent


def build(output):
    output.mkdir(parents=True, exist_ok=True)
    program = Path(os.environ.get("ProgramFiles(x86)", r"C:\Program Files (x86)"))
    locator = program / "Microsoft Visual Studio/Installer/vswhere.exe"
    found = subprocess.check_output([
        str(locator), "-latest", "-products", "*", "-requires",
        "Microsoft.VisualStudio.Component.VC.Tools.x86.x64", "-find",
        r"VC\Tools\MSVC\**\bin\Hostx64\x64\cl.exe",
    ], text=True)
    compiler = Path(found.strip().splitlines()[0])
    msvc = compiler.parents[3]
    sdk = program / "Windows Kits/10"
    version = max((sdk / "Include").glob("10.*"), key=lambda path: tuple(map(int, path.name.split(".")))).name
    includes = [msvc / "include", *(sdk / "Include" / version / item for item in ("ucrt", "shared", "um", "winrt"))]
    libs = [msvc / "lib/x64", *(sdk / "Lib" / version / item / "x64" for item in ("ucrt", "um"))]
    environment = dict(os.environ, INCLUDE=os.pathsep.join(map(str, includes)), LIB=os.pathsep.join(map(str, libs)))
    environment["PATH"] = str(compiler.parent) + os.pathsep + environment.get("PATH", "")
    executable = output / "NetworkProbe.exe"
    with (output / "build.log").open("w", encoding="utf-8") as log:
        subprocess.run([
            str(compiler), "/nologo", "/W4", "/O2", "/MT", "/D_CRT_SECURE_NO_WARNINGS",
            str(HERE / "network_probe.c"), "/Fe:" + str(executable), "/link",
            "/SUBSYSTEM:WINDOWS", "/ENTRY:wmainCRTStartup", "ws2_32.lib", "advapi32.lib",
        ], cwd=output, env=environment, stdout=log, stderr=subprocess.STDOUT, check=True)
    manifest = {"executable": str(executable), "sha256": hashlib.sha256(executable.read_bytes()).hexdigest(),
                "sourceSha256": hashlib.sha256((HERE / "network_probe.c").read_bytes()).hexdigest()}
    (output / "manifest.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    return manifest


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, required=True)
    print(json.dumps(build(parser.parse_args().output.resolve())))
