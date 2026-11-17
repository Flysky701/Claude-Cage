"""Run the real offline sandbox with disposable files, a registry key, and a TCP listener.

No proxy configuration or real account data is read. Results contain booleans and
fixture values only. Each invocation keeps its files under workspace/tmp for review.
"""
import json
import os
from pathlib import Path
import socketserver
import subprocess
import sys
import threading
import uuid
import winreg

ROOT = Path(__file__).resolve().parent


class Sink(socketserver.BaseRequestHandler):
    def handle(self):
        self.server.connections += 1


def main():
    token = uuid.uuid4().hex[:12]
    work = ROOT.parents[1] / "tmp" / "windows-lite-isolation" / token
    program_dir = work / "program"
    fixtures = work / "fixtures"
    ro, rw = fixtures / "read-only", fixtures / "shared"
    for path in (program_dir, ro, rw):
        path.mkdir(parents=True)
    for path in (ro / "read.txt", rw / "read.txt", fixtures / "ordinary.txt"):
        path.write_text("host", encoding="utf-8")
    secret = fixtures / "connection.json"
    secret.write_text('{"testCredential":"synthetic-only"}', encoding="utf-8")
    other_box_secret = work / "data/boxes/other-fixture/secret.txt"
    other_box_secret.parent.mkdir(parents=True)
    other_box_secret.write_text("synthetic-other-box", encoding="utf-8")
    exe = program_dir / "IsolationProbe.exe"
    compiler = Path(os.environ["SystemRoot"]) / "Microsoft.NET/Framework64/v4.0.30319/csc.exe"
    subprocess.run([str(compiler), "/nologo", "/target:exe", "/platform:x64",
                    "/reference:System.Web.Extensions.dll", "/out:" + str(exe),
                    str(ROOT / "samples/IsolationProbe.cs")], check=True, timeout=30)
    key_name = "Software\\CageLiteFixture_" + token
    results = []
    key_created = False
    with socketserver.ThreadingTCPServer(("127.0.0.1", 0), Sink) as server:
        server.connections = 0
        threading.Thread(target=server.serve_forever, daemon=True).start()
        try:
            with winreg.CreateKey(winreg.HKEY_CURRENT_USER, key_name) as key:
                key_created = True
                winreg.SetValueEx(key, "value", 0, winreg.REG_SZ, "host")
            for phase in ("first", "restart"):
                spec = {
                    "program": str(exe),
                    "sharedFolders": [{"path": str(ro), "access": "read-only"},
                                      {"path": str(rw), "access": "read-write"}],
                    "arguments": ["{output}", str(secret), str(fixtures / "ordinary.txt"),
                                  str(ro), str(rw), key_name, phase, str(server.server_address[1]),
                                  str(other_box_secret)],
                }
                config = work / "config.json"
                config.write_text(json.dumps({"selected": "fixture", "connectionFile": str(secret),
                                              "dataDirectory": str(work / "data"),
                                              "applications": {"fixture": spec}}), encoding="utf-8")
                env = dict(os.environ, CAGE_TEST_HOST_SECRET="synthetic-host-value")
                run = subprocess.run([sys.executable, "-B", str(ROOT / "shell.py"),
                                      "--offline", "--config", str(config)], env=env,
                                     stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=65)
                if run.returncode:
                    print(run.stdout.decode("utf-8", "replace"))
                    raise RuntimeError("Offline fixture launch failed")
                reports = list((work / "data/output").glob("*/" + phase + ".json"))
                if len(reports) != 1:
                    raise RuntimeError("The sandbox did not publish its result")
                row = json.loads(reports[0].read_text(encoding="utf-8-sig"))
                row["hostFileUnchanged"] = (fixtures / "ordinary.txt").read_text() == "host"
                row["readOnlyHostUnchanged"] = not (ro / "write.txt").exists()
                row["sharedHostUpdated"] = (rw / "write.txt").read_text() == "shared-" + phase
                row["boxedChildHostOutputPublished"] = (rw / "child.txt").read_text() == "boxed-child"
                row["boxedChildExecutableStayedInBox"] = not (fixtures / "boxed-bin").exists()
                with winreg.OpenKey(winreg.HKEY_CURRENT_USER, key_name) as key:
                    row["hostRegistryUnchanged"] = winreg.QueryValueEx(key, "value")[0] == "host"
                row["persistenceMatches"] = row["ordinaryBefore"] == ("host" if phase == "first" else "boxed")
                row["registryPersistenceMatches"] = row["registryBefore"] == (None if phase == "first" else "boxed")
                results.append(row)
            checks = [value for row in results for value in row.values() if isinstance(value, bool)]
            passed = all(checks) and server.connections == 0
            report = {"scenario": "offline-local-isolation", "passed": passed,
                      "hostListenerConnections": server.connections, "runs": results}
            (work / "result.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
            print(json.dumps(report, indent=2))
            print("Result:", work / "result.json")
            return 0 if passed else 1
        finally:
            server.shutdown()
            # Delete only the unique disposable key created by this invocation.
            if key_created:
                winreg.DeleteKey(winreg.HKEY_CURRENT_USER, key_name)


if __name__ == "__main__":
    sys.exit(main())
