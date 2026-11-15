"""Capture this app's recovery test privately, optionally decoding one real token."""
import argparse
import base64
import hashlib
import json
from pathlib import Path
import re
import shutil
import subprocess
import sys

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))
import decode


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--adb", type=Path, required=True)
    parser.add_argument("--serial", required=True)
    parser.add_argument("--credentials", type=Path)
    parser.add_argument("--name", default="recovery-20261115")
    args = parser.parse_args()
    if not re.fullmatch(r"[A-Za-z0-9_-]+", args.name):
        parser.error("Use a simple output name")
    folder = decode.BUILD / "comparison"
    folder.mkdir(exist_ok=True)
    summary_file = folder / (args.name + "-summary.json")
    if summary_file.exists():
        parser.error("Choose a new output name; prior evidence is retained")
    command = [str(args.adb), "-s", args.serial, "shell", "am", "instrument", "-w", "-r",
               "-e", "action", "run", "io.github.flysky701.recoveryprobe/.RecoveryProbe"]
    print("Running one classic request in the recovery copy; tokens stay in local files.", flush=True)
    process = subprocess.run(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=120)
    output = process.stdout.decode("utf-8", errors="replace")
    values = {key: value.rstrip("\r") for key, value in
              re.findall(r"^INSTRUMENTATION_RESULT: ([A-Za-z0-9]+)=(.*)$", output, re.M)}
    private = values.pop("privateResultBase64", None)
    summary = {"environment": "top.niunaijun.microrec", "mode": "classic", "probe": values}
    if values.get("testApkSha256"):
        expected = hashlib.sha256((decode.BUILD / "Flysky701-Integrity-Test.apk").read_bytes()).hexdigest()
        if values["testApkSha256"] != expected:
            raise ValueError("Recovery APK differs from the personal-area comparison APK")
        summary["identicalApk"] = True
    if private:
        data = json.loads(base64.b64decode(private, validate=True))
        kind = "request" if values.get("resultFile") == "request.json" else "status"
        (folder / (args.name + "-" + kind + ".json")).write_text(
            json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
        summary["outcome"] = "token_received" if kind == "request" else "api_error"
        if kind == "status":
            summary["status"] = data
        else:
            if not summary.get("identicalApk"):
                raise ValueError("Recovery APK identity was not returned")
            decode.validate_request(data)
            if args.credentials:
                try:
                    verdict = decode.Decoder(args.credentials).decode(data)
                    shutil.copyfile(decode.BUILD / "latest-google-response.json", folder / (args.name + "-google-response.json"))
                    (folder / (args.name + "-verdict.json")).write_text(
                        json.dumps(verdict, ensure_ascii=False, indent=2), encoding="utf-8")
                    summary["outcome"] = "google_verdict_verified"
                    summary["verdict"] = {k: v for k, v in verdict.items() if k != "tokenPayloadExternal"}
                except Exception as error:
                    summary["decodeError"] = str(error)
    else:
        summary["outcome"] = "probe_error"
        # No result token was present; keep diagnostic output in a local evidence file.
        (folder / (args.name + "-probe.txt")).write_text(output, encoding="utf-8")
    summary_file.write_text(json.dumps(summary, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps(summary, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
