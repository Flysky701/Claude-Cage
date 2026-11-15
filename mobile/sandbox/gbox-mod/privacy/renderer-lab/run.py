"""Run only the installed disposable timezonelab; never operate on Cage or system settings."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import time
import uuid

PACKAGE = "io.github.leexeo.cage.timezonelab"
MODES = ("baseline", "monitor", "gate", "gate-reload", "gate-newview", "gate-recreate",
         "gate-disabled", "gate-mismatch")


def assess(measurement, start_ms, end_ms):
    """Check native readings, coverage and freshness; a Java callback alone never passes."""
    mode = measurement["mode"]
    if mode == "gate-disabled" and measurement.get("failureStage") == "Missing blank document result" \
            and measurement.get("completedPages") == 0:
        return "OBSERVED_JS_DISABLED_NO_RESULT"
    if mode == "gate-mismatch":
        return "PASS_BLOCKED" if (
            measurement.get("failureStage") == "Timezone confirmation deadline"
            and measurement.get("completedPages") == 0
            and all(not s.get("pages") and not s.get("gateConfirmed")
                    for s in measurement.get("stages", []))
        ) else "FAIL_DID_NOT_BLOCK"
    if measurement.get("error"):
        return "FAIL_RUNTIME"
    stages = measurement.get("stages", [])
    pages = [p for s in stages for p in s.get("pages", [])]
    wanted_pages = 2 if mode in ("gate-reload", "gate-newview", "gate-recreate") else 1
    if len(pages) != wanted_pages or measurement.get("completedPages") != wanted_pages:
        return "FAIL_MISSING_PAGES"
    wanted_stages = 2 if mode in ("gate-newview", "gate-recreate") else 1
    if len(stages) != wanted_stages:
        return "FAIL_MISSING_GENERATIONS"
    if mode == "gate-recreate" and not measurement.get("rendererGone"):
        return "FAIL_NO_RENDERER_LOSS"
    if mode.startswith("gate") and not all(s.get("gateConfirmed") is True and s.get("gateReadings") for s in stages):
        return "FAIL_UNCONFIRMED_RELEASE"
    for page in pages:
        if not all(key in page for key in ("first", "frame", "worker", "later")):
            return "FAIL_INCOMPLETE_READINGS"
        for key in ("first", "frame", "worker", "later"):
            value = page[key]
            zone, offset = ("Asia/Shanghai", 480) if mode == "baseline" else ("Asia/Tokyo", 540)
            if value.get("zone") != zone or value.get("offset") != offset:
                return "OBSERVED_RACE" if mode == "monitor" else "FAIL_TIMEZONE"
            if not start_ms - 3000 <= value.get("epoch", 0) <= end_ms + 3000:
                return "FAIL_UTC_RANGE"
    return "PASS_MEASURED" if mode != "monitor" else "OBSERVED_NO_RACE"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--adb", type=Path, required=True)
    parser.add_argument("--serial", required=True)
    parser.add_argument("--port", type=int, required=True)
    parser.add_argument("--apk", type=Path, required=True, help="Installed artifact, checked against phone")
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--modes", choices=MODES, nargs="+", default=list(MODES))
    parser.add_argument("--repeat", type=int, default=1)
    args = parser.parse_args()
    if args.output.exists():
        raise FileExistsError("Do not overwrite earlier measurements")
    if not 1 <= args.repeat <= 10 or not 1 <= args.port <= 65535 or args.serial.startswith("-"):
        raise ValueError("Invalid explicit device or run count")
    adb = [str(args.adb), "-P", str(args.port), "-s", args.serial]

    def command(*parts, check=True):
        p = subprocess.run([*adb, *parts], capture_output=True, timeout=30)
        if check and p.returncode:
            raise RuntimeError("Lab operation failed: " + p.stderr.decode("utf-8", "replace")[-800:])
        return p.stdout

    paths = command("shell", "pm", "path", PACKAGE).decode().strip().splitlines()
    if len(paths) != 1 or not paths[0].startswith("package:/data/app/"):
        raise ValueError("Unexpected installed lab package layout")
    device_apk = command("exec-out", "cat", paths[0][8:])
    artifact_sha = hashlib.sha256(args.apk.read_bytes()).hexdigest()
    if hashlib.sha256(device_apk).hexdigest() != artifact_sha:
        raise ValueError("Installed lab does not match the selected artifact")
    result = {"artifactSha256": artifact_sha, "networkOperations": 0, "cageOperations": 0, "runs": []}
    args.output.parent.mkdir(parents=True, exist_ok=True)
    for _ in range(args.repeat):
        for mode in args.modes:
            run_id = uuid.uuid4().hex
            start_ms = int(time.time() * 1000)
            command("shell", "am", "force-stop", PACKAGE)
            command("shell", "am", "start", "-n", PACKAGE + "/.Probe", "--es", "mode", mode,
                    "--es", "runId", run_id)
            deadline = time.monotonic() + 24
            measurement = None
            while time.monotonic() < deadline:
                raw = command("shell", "run-as", PACKAGE, "cat", "files/result.json", check=False)
                try:
                    candidate = json.loads(raw)
                    if candidate.get("runId") == run_id and candidate.get("complete") is True:
                        measurement = candidate
                        break
                except (ValueError, UnicodeError):
                    pass
                time.sleep(0.25)
            if measurement is None:
                measurement = {"mode": mode, "runId": run_id, "error": "REPORT_TIMEOUT"}
            measurement["assessment"] = assess(measurement, start_ms, int(time.time() * 1000))
            result["runs"].append(measurement)
            args.output.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
            first = [p.get("first", {}).get("zone") for s in measurement.get("stages", [])
                     for p in s.get("pages", [])]
            print(json.dumps({"mode": mode, "firstZones": first, "assessment": measurement["assessment"],
                              "error": measurement.get("error")}), flush=True)
            if measurement["assessment"].startswith("FAIL"):
                break
        if result["runs"][-1]["assessment"].startswith("FAIL"):
            break
    if any(run["assessment"].startswith("FAIL") for run in result["runs"]):
        raise SystemExit(1)


if __name__ == "__main__":
    main()
