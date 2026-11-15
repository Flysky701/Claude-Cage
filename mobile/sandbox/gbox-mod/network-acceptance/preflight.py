"""Read-only Android preflight; never toggles VPN, starts apps or changes settings.

Requires one explicit device and the expected installed Cage artifact. Raw ADB
output, serial numbers, addresses and installed paths are never saved or printed.
"""
import argparse
import datetime
import hashlib
import json
from pathlib import Path
import re
import subprocess

PACKAGE = "com.cage.android"
DIGEST = re.compile(r"[0-9a-f]{64}\Z")
PACKAGE_NAME = re.compile(r"[A-Za-z][A-Za-z0-9_]*(?:\.[A-Za-z][A-Za-z0-9_]*)+\Z")


def inspect(adb, serial, port, expected_artifact, expected_vpn):
    if not DIGEST.fullmatch(expected_artifact) or not PACKAGE_NAME.fullmatch(expected_vpn):
        raise ValueError("Expected artifact digest and VPN package are required")
    def run(*parts):
        try:
            completed = subprocess.run([str(adb), "-P", str(port), "-s", serial, *parts],
                                       capture_output=True, timeout=20)
        except (subprocess.TimeoutExpired, OSError):
            raise RuntimeError("Read-only device inspection unavailable; raw command withheld") from None
        if completed.returncode:
            raise RuntimeError("Read-only device inspection failed; raw output withheld")
        return completed.stdout.decode("utf-8", "replace").strip()
    if run("get-state") != "device":
        raise RuntimeError("Selected device is not available")
    sdk = run("shell", "getprop", "ro.build.version.sdk")
    if not sdk.isdecimal():
        raise RuntimeError("Invalid SDK response")
    paths = run("shell", "pm", "path", "--user", "0", PACKAGE).splitlines()
    # This tested container is a single APK. Do not guess or silently skip splits.
    if len(paths) != 1 or not paths[0].startswith("package:"):
        raise RuntimeError("Expected one installed container APK")
    installed_path = paths[0][len("package:"):]
    if not re.fullmatch(r"/data/app/[A-Za-z0-9_+~=/.-]+/base\.apk", installed_path):
        raise RuntimeError("Unexpected installed path; refused shell argument")
    apk_hash = run("shell", "sha256sum", installed_path).split()[0]
    if not DIGEST.fullmatch(apk_hash):
        raise RuntimeError("Invalid installed artifact digest")
    configured = run("shell", "settings", "--user", "0", "get", "secure", "always_on_vpn_app")
    lockdown = run("shell", "settings", "--user", "0", "get", "secure", "always_on_vpn_lockdown")
    if configured not in ("", "null") and not PACKAGE_NAME.fullmatch(configured):
        raise RuntimeError("Unexpected VPN package setting")
    if lockdown not in ("0", "1", "null", ""):
        raise RuntimeError("Unexpected lockdown setting")
    # Dumps can contain stale networks. This is deliberately only a mention,
    # never proof of active routing, readiness or fail-closed enforcement.
    network_dump = run("shell", "dumpsys", "connectivity")
    vpn_mentioned = bool(re.search(r"\bTRANSPORT_VPN\b|Transports:[^\n]*\bVPN\b", network_dump))
    public_config = {"alwaysOnVpnPackage": configured or None, "lockdownSetting": lockdown == "1"}
    config_hash = hashlib.sha256(json.dumps(public_config, sort_keys=True).encode()).hexdigest()
    guards = {"installedArtifactMatches": apk_hash == expected_artifact,
              "expectedAlwaysOnVpnConfigured": configured == expected_vpn,
              "lockdownSettingEnabled": lockdown == "1"}
    return {"schemaVersion": 1, "capturedAt": datetime.datetime.now(datetime.timezone.utc).isoformat(),
            "status": "REQUIRES_ONLINE_CONTROL" if all(guards.values()) else "BLOCKED_PRECONDITION",
            "containerPackage": PACKAGE, "artifactSha256": apk_hash, "sdk": int(sdk),
            "expectedVpnPackage": expected_vpn, "configurationFingerprintSha256": config_hash,
            "guards": guards, "vpnMentionInConnectivityDump": vpn_mentioned,
            "activeVpnVerified": False, "guestExecutionVerified": False,
            "networkEnforcementVerified": False, "deviceMutations": 0, "networkTest": "NOT_RUN"}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--adb", type=Path, required=True)
    parser.add_argument("--serial", required=True)
    parser.add_argument("--port", type=int, required=True)
    parser.add_argument("--expected-artifact-sha256", required=True)
    parser.add_argument("--expected-vpn-package", required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    if not 1 <= args.port <= 65535 or not args.serial or args.serial.startswith("-"):
        raise ValueError("Explicit valid device serial and port are required")
    if args.output.exists():
        raise FileExistsError("Output exists; choose a new evidence filename")
    result = inspect(args.adb, args.serial, args.port, args.expected_artifact_sha256, args.expected_vpn_package)
    with args.output.open("x", encoding="utf-8") as stream:
        json.dump(result, stream, indent=2)
        stream.write("\n")
    print(json.dumps({"status": result["status"], "guards": result["guards"], "networkTest": "NOT_RUN"}))
    return 0 if result["status"] == "REQUIRES_ONLINE_CONTROL" else 2


if __name__ == "__main__":
    raise SystemExit(main())
