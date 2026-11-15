"""Validate the probe against host loopback; do not change network policy."""
import argparse
import json
from pathlib import Path
import subprocess
import time
import uuid


def run(executable, output):
    output.mkdir(parents=True, exist_ok=False)
    results = {}
    for address in ("127.0.0.1", "::1"):
        name = "ipv6" if ":" in address else "ipv4"
        server_result = output / (name + "-server.json")
        ready_file = server_result.with_suffix(server_result.suffix + ".ready")
        client_result = output / (name + "-client.json")
        nonce = "CageProbe-" + uuid.uuid4().hex
        server = subprocess.Popen([str(executable), "tcp-listen", address, "0", nonce, str(server_result)],
                                  creationflags=getattr(subprocess, "CREATE_NO_WINDOW", 0))
        client_exit = None
        try:
            deadline = time.monotonic() + 5
            while time.monotonic() < deadline and not ready_file.is_file() and server.poll() is None:
                time.sleep(0.05)
            if ready_file.is_file():
                ready = json.loads(ready_file.read_text())
                client_exit = subprocess.run([
                    str(executable), "tcp-client", address, str(ready["port"]), nonce, str(client_result),
                ], timeout=12, creationflags=getattr(subprocess, "CREATE_NO_WINDOW", 0)).returncode
            server.wait(timeout=12)
            results[name] = {
                "serverExit": server.returncode, "clientExit": client_exit,
                "server": json.loads(server_result.read_text()) if server_result.is_file() else None,
                "client": json.loads(client_result.read_text()) if client_result.is_file() else None,
            }
        finally:
            if server.poll() is None:
                server.terminate()
                server.wait(timeout=5)
    report = {"scope": "Host transport control only; no AppContainer claim; no network policy changes.", "results": results}
    (output / "report.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
    return report


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--executable", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    print(json.dumps(run(args.executable.resolve(), args.output.resolve())))
