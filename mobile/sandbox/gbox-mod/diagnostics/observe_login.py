"""Read one explicitly selected Android device without retaining authentication data.

Raw logcat, UI XML and activity dumps stay in memory. Output contains only fixed
event labels, timestamps, counts and allowlisted component names, never log lines.
This observer neither starts login nor changes accounts, applications or VPN state.
"""
import argparse
import datetime
import json
import re
import subprocess
import uuid
import xml.etree.ElementTree as ET
from collections import Counter
from pathlib import Path


EVENTS = {
    "google_account_selection_started": r"AuthSignInActivity.*signIn:",
    "cached_google_token_expired": r"GmsAuthManager.*token present, but expired",
    "google_signin_account_returned": r"AssistedSignInActivity.*loginResult:.*GoogleSignInAccount",
    "claude_integrity_requested": r"PlayCore.*requestIntegrityToken\(.*cloudProjectNumber=90637372055",
    "mgc_integrity_service_connected": r"(?:ServiceConnectionImpl|onServiceConnected).*com\.android\.vending\.mgc.*IntegrityService",
    "droidguard_started": r"IntegrityService.*Running DroidGuard",
    "droidguard_bind_reported_true": r"GmsMultiConKeeper.*bind\(com\.google\.android\.gms\.droidguard\.service\.START.*bound=true",
    "droidguard_service_connected": r"GmsMultiConKeeper.*Connection\(com\.google\.android\.gms\.droidguard\.service\.START\).*onServiceConnected",
    "droidguard_service_disconnected": r"GmsMultiConKeeper.*Connection\(com\.google\.android\.gms\.droidguard\.service\.START\).*onServiceDisconnected",
    "service_connection_callback_exception": r"GmsMultiConKeeper.*ServiceConnection callback threw exception",
    "droidguard_get_client_timeout": r"(?:DroidGuard|GmsDroidGuard).*getClientTimeoutMillis\(\)",
    "droidguard_guard_called": r"(?:DroidGuard|GmsDroidGuard).*guard\(\)",
    "droidguard_guard_with_request_called": r"(?:DroidGuard|GmsDroidGuard).*guardWithRequest\(\)",
    "gms_client_service_connected": r"GmsClient.*ServiceConnection : onServiceConnected",
    "gms_client_post_init_complete": r"GmsClient.*GmsCallbacks : onPostInitComplete",
    "droidguard_open_handle_start": r"DroidGuardApiClient.*openHandle start on thread:",
    "droidguard_open_handle_handler": r"DroidGuardApiClient.*openHandle executing on handler thread:",
    "droidguard_get_handle": r"GmsGuardServiceImpl.*getHandle\(\)",
    "droidguard_get_client_timeout_impl": r"GmsGuardServiceImpl.*getClientTimeoutMillis\(\)",
    "droidguard_handle_init": r"GmsGuardHandleImpl.*init",
    "native_sigsegv": r"(?:DEBUG|libc).*\b(?:signal 11|Fatal signal 11)\b",
    "android_runtime_fatal_exception": r"AndroidRuntime.*FATAL EXCEPTION",
    "droidguard_handle_success": r"DroidGuardApiClient.*openHandle success",
    "droidguard_initialization_timeout": r"DroidGuardApiClient.*Initialization timeout after",
    "gms_failed_package_cache_retired": r"CageFrameworkPaths.*cache\.failedGmsPackage\.retired",
    "framework_context_created": r"CageFrameworkPaths.*context\.created packageMatches=",
    "framework_bind_failed": r"CageFrameworkPaths.*bind\.failed stage=",
    "claude_google_verify_http400": r"NetworkFailureReporting.*HTTP 400 /auth/verify_google_mobile",
    "droidguard_data_null": r"IntegrityService.*droidGuardData: null",
    "droidguard_failed": r"DroidGuard failed",
    "age_signals_error_minus6": r"AgeSignalsService.*onError\(-6\)",
}
TIMESTAMP = re.compile(r"^(\d\d-\d\d \d\d:\d\d:\d\d\.\d+)")
TAG = re.compile(r"^\d\d-\d\d \S+\s+\d+\s+\d+\s+[VDIWEF]\s+([^:]+):")
KNOWN_TAGS = {"GmsDroidGuard", "GmsDroidGuardService", "DroidGuardService", "DroidGuard",
              "GmsDroidGuardBroker", "IntegrityService", "GmsMultiConKeeper"}
KNOWN_PACKAGES = {"com.cage.android", "com.anthropic.claude", "com.google.android.gms",
                  "com.google.android.gms.unstable",
                  "com.android.vending", "com.android.vending.mgc",
                  "io.github.leexeo.cage.microdemo"}


def summarize_logs(raw):
    events, tags, times, connections, asset_failures, contexts = [], Counter(), [], [], [], []
    patterns = [(key, re.compile(value)) for key, value in EVENTS.items()]
    for line in raw.splitlines():
        stamp = TIMESTAMP.match(line)
        identity = re.match(r"^\d\d-\d\d \S+\s+(\d+)\s+\d+\s+", line)
        pid = int(identity[1]) if identity else None
        if stamp:
            times.append(stamp[1])
        tag = TAG.match(line)
        if tag and tag[1].strip() == "CageFrameworkPaths" and "context.created " in line:
            contexts.append({"time": stamp[1] if stamp else None, "pid": pid,
                             "states": {key: value == "true" for key, value in re.findall(r"\b(packageMatches|sourceInsideCode|dataInsideCe|credentialInsideCe|deviceInsideDe)=(true|false)", line)}})
        if "Failed to load asset path" in line or "failed to open" in line.lower():
            paths = re.findall(r"/(?:data|mnt|storage|system|apex|sdcard|virtual)/[A-Za-z0-9_./~=+-]+\.(?:apk|jar|frro)", line)
            for path in paths:
                if "com.google.android.gms" in path or path.startswith("/data/data/com.cage.android/"):
                    asset_failures.append({"time": stamp[1] if stamp else None, "pid": pid, "path": path,
                                           "insideContainerRoot": path.startswith("/data/data/com.cage.android/_root/")})
        if tag and tag[1].strip() == "CageServiceDiag":
            fixed = re.search(r"CageServiceDiag\s*:\s*(bind\.proxy\.registered|create\.(?:enter|return|throw|null\.(?:bindingNotReady|applicationNotReady|classNotFound))|service\.bind\.(?:enter|return|throw)|connected[34]\.(?:enter\.binder|return|throw))(?: resultNull=(true|false))?\s*$", line)
            if fixed:
                event = {"time": stamp[1] if stamp else None, "pid": pid, "event": "service_diag." + fixed[1]}
                if fixed[2]:
                    event["resultNull"] = fixed[2] == "true"
                events.append(event)
        if tag and tag[1].strip() in KNOWN_TAGS:
            tags[tag[1].strip()] += 1
        if tag and tag[1].strip() == "GmsMultiConKeeper":
            connections.append({"time": stamp[1] if stamp else None,
                                "droidguardActionMentioned": "com.google.android.gms.droidguard.service.START" in line,
                                "markers": [word for word in ("onServiceConnected", "onServiceDisconnected", "bindService", "callback threw exception") if word in line],
                                "states": {key: value == "true" for key, value in re.findall(r"\b(has|bound|connected|bindService)=(true|false)", line)}})
        for name, pattern in patterns:
            if pattern.search(line):
                events.append({"time": stamp[1] if stamp else None, "pid": pid, "event": name})
    return {"retainedBufferFirstTime": times[0] if times else None,
            "retainedBufferLastTime": times[-1] if times else None,
            "events": events, "knownTagCounts": dict(tags), "connectionDiagnostics": connections,
            "assetPathFailures": asset_failures, "frameworkContexts": contexts,
            "rawLogRetained": False}


def summarize_ui(raw):
    start, end = raw.find("<hierarchy"), raw.find("</hierarchy>")
    if start < 0 or end < start:
        return {"hierarchyAvailable": False}
    root = ET.fromstring(raw[start:end + len("</hierarchy>")])
    texts = [node.get("text", "") for node in root.iter("node")]
    return {"hierarchyAvailable": True,
            "packages": sorted({node.get("package") for node in root.iter("node") if re.fullmatch(r"[A-Za-z][A-Za-z0-9_.]+", node.get("package", ""))}),
            "couldNotSignInVisible": any(t in {"Couldn’t sign in", "Couldn't sign in", "Could not sign in"} for t in texts),
            "playVerificationFailureVisible": any("无法通过 Google Play 验证" in t for t in texts),
            "continueWithGoogleVisible": "Continue with Google" in texts,
            "googleAccountPickerVisible": "选择一个账号" in texts,
            "authenticatedUiEstablished": False}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--adb", required=True)
    parser.add_argument("--serial", required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--duration", type=int, default=0, help="Observe new logs for 1-60 seconds instead of reading the buffer")
    args = parser.parse_args()
    if args.output.exists():
        parser.error("Refusing to overwrite an existing observation")
    if not 0 <= args.duration <= 60:
        parser.error("Duration must be between 0 and 60 seconds")

    def adb(*parts):
        result = subprocess.run([args.adb, "-s", args.serial, *parts], capture_output=True, timeout=45)
        if result.returncode:
            raise RuntimeError("ADB read failed; command output suppressed")
        return result.stdout.decode("utf-8", errors="replace")

    report = {"schemaVersion": 1, "observedAt": datetime.datetime.now(datetime.timezone.utc).isoformat(),
              "scope": "Read-only observer for explicitly selected test emulator; UI actions, if any, are performed separately"}
    vpn = adb("shell", "settings", "get", "secure", "always_on_vpn_app").strip()
    report["gateway"] = {"expectedAlwaysOnPackage": vpn == "io.github.leexeo.cage.microdemo",
                         "lockdownEnabled": adb("shell", "settings", "get", "secure", "always_on_vpn_lockdown").strip() == "1",
                         "tun0Present": "tun0" in adb("shell", "ip", "link", "show")}
    ps = adb("shell", "ps", "-A", "-o", "UID,PID,NAME")
    report["processes"] = []
    for line in ps.splitlines():
        cols = line.split()
        if len(cols) == 3 and cols[0].isdigit() and cols[1].isdigit() and cols[2].split(":")[0] in KNOWN_PACKAGES:
            report["processes"].append({"uid": int(cols[0]), "pid": int(cols[1]), "name": cols[2]})
    if args.duration:
        process = subprocess.Popen([args.adb, "-s", args.serial, "logcat", "-v", "threadtime", "-T", "1"], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        try:
            raw, _ = process.communicate(timeout=args.duration)
        except subprocess.TimeoutExpired:
            process.terminate()
            raw, _ = process.communicate(timeout=10)
        report["logs"] = summarize_logs(raw.decode("utf-8", errors="replace"))
    else:
        report["logs"] = summarize_logs(adb("logcat", "-d", "-v", "threadtime"))
    # Some Android builds cannot open /dev/tty from uiautomator. The unique
    # scratch XML is removed even when parsing fails; it is never pulled locally.
    remote_xml = "/sdcard/cage-observe-" + uuid.uuid4().hex + ".xml"
    try:
        adb("shell", "uiautomator", "dump", remote_xml)
        report["ui"] = summarize_ui(adb("shell", "cat", remote_xml))
    finally:
        adb("shell", "rm", "-f", remote_xml)
    components = re.compile(r"\b((?:com\.cage\.android|com\.google\.android\.gms|com\.android\.vending(?:\.mgc)?|com\.anthropic\.claude)/[A-Za-z0-9_.$]+)")
    activities = adb("shell", "dumpsys", "activity", "activities")
    report["resumedComponents"] = sorted({c for line in activities.splitlines() if "resumedactivity" in line.lower() for c in components.findall(line)})
    services = adb("shell", "dumpsys", "activity", "services")
    report["serviceComponents"] = sorted(set(components.findall(services)))
    report["processesAfter"] = []
    for line in adb("shell", "ps", "-A", "-o", "UID,PID,NAME").splitlines():
        cols = line.split()
        base = cols[2].split(":")[0] if len(cols) == 3 else ""
        if len(cols) == 3 and cols[0].isdigit() and cols[1].isdigit() and (base in KNOWN_PACKAGES or base == "com.google.android.gms.unstable"):
            report["processesAfter"].append({"uid": int(cols[0]), "pid": int(cols[1]), "name": cols[2]})
    report["limitations"] = ["Log buffer can rotate; absent events are not proof of absence.",
                              "Google result and integrity failure do not establish the HTTP 400 cause.",
                              "UI flags alone do not establish an authenticated session."]
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(report, ensure_ascii=True, indent=2))


if __name__ == "__main__":
    main()
