"""Run a free-feature Sandboxie boundary probe using only synthetic data.

The caller authorizes one new persistent test box and global WFP enablement.
Files and box data are retained. The new registry fixture is removed on exit.
"""
import argparse
import ctypes
from datetime import datetime
import hashlib
import json
import os
from pathlib import Path
import shutil
import socket
import subprocess
import threading
import time
import uuid
import winreg

ROOT = Path(__file__).resolve().parents[3]
NO_WINDOW = subprocess.CREATE_NO_WINDOW


def save(path, data):
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")


def command(args, timeout=30):
    proc = subprocess.run([str(x) for x in args], stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                          timeout=timeout, creationflags=NO_WINDOW)
    raw = proc.stdout
    output = raw.decode("utf-16-le" if b"\0" in raw else "mbcs", "replace").lstrip("\ufeff")
    if proc.returncode:
        raise RuntimeError(f"{Path(args[0]).name} exited {proc.returncode}: {output[:400]}")
    return output.strip().splitlines()


class Sbie:
    def __init__(self, directory):
        self.directory = directory
        self.ini = directory / "SbieIni.exe"
        self.start = directory / "Start.exe"
        self.dll = ctypes.WinDLL(str(directory / "SbieDll.dll"))
        self.dll.SbieApi_QueryDrvInfo.argtypes = [ctypes.c_int, ctypes.c_void_p, ctypes.c_ulong]
        self.dll.SbieApi_QueryDrvInfo.restype = ctypes.c_long
        self.dll.SbieApi_ReloadConf.argtypes = [ctypes.c_ulong, ctypes.c_ulong]
        self.dll.SbieApi_ReloadConf.restype = ctypes.c_long

    def query(self, section, key=None):
        return command([self.ini, "query", section, *([key] if key else [])])

    def set(self, box, key, value):
        command([self.ini, "set", box, key, value])
        actual = self.query(box, key)
        if actual != [value]:
            raise RuntimeError(f"Setting was not applied: {box}/{key}: {actual!r}")

    def flags(self):
        flags = ctypes.c_ulong()
        status = self.dll.SbieApi_QueryDrvInfo(0, ctypes.byref(flags), 4)
        return {"status": status, "flags": flags.value, "wfp": status == 0 and bool(flags.value & 1)}

    def pids(self, box):
        lines = command([self.start, "/box:"+box, "/listpids"])
        if not lines or not lines[0].isdigit():
            raise RuntimeError("Cannot enumerate sandbox processes")
        return [int(line) for line in lines[1:] if line.isdigit()]


class Echo:
    def __init__(self, family, kind):
        self.socket = socket.socket(family, kind)
        if family == socket.AF_INET6:
            self.socket.setsockopt(socket.IPPROTO_IPV6, socket.IPV6_V6ONLY, 1)
        self.socket.bind(("127.0.0.1" if family == socket.AF_INET else "::1", 0))
        self.port = self.socket.getsockname()[1]
        self.kind, self.count, self.running = kind, 0, True
        self.socket.settimeout(.2)
        if kind == socket.SOCK_STREAM:
            self.socket.listen(16)
        self.thread = threading.Thread(target=self.work, daemon=True)
        self.thread.start()

    def work(self):
        while self.running:
            try:
                if self.kind == socket.SOCK_STREAM:
                    client, _ = self.socket.accept()
                    self.count += 1
                    client.close()
                else:
                    data, peer = self.socket.recvfrom(256)
                    self.count += 1
                    self.socket.sendto(data, peer)
            except (TimeoutError, OSError):
                pass

    def close(self):
        self.running = False
        self.socket.close()
        self.thread.join(timeout=1)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--sbie", type=Path, default=Path(r"C:\Program Files\Sandboxie-Plus"))
    parser.add_argument("--output", type=Path)
    ns = parser.parse_args()
    tag = datetime.now().strftime("%Y%m%d-%H%M%S") + "-" + uuid.uuid4().hex[:8]
    run = (ns.output or ROOT / "_output/windows-lite" / ("boundary-"+tag)).resolve()
    if run.exists():
        raise RuntimeError("Output must be a new unique directory")
    run.mkdir(parents=True)
    box = "CageProbe_" + uuid.uuid4().hex[:16]
    sbie = Sbie(ns.sbie)
    report = {"run": str(run), "box": box, "started": datetime.now().isoformat(), "checks": {},
              "scope": "Synthetic data; classic free settings; no real application admission"}
    save(run/"report.json", report)
    boxes = sbie.query("*")
    active = {b:sbie.pids(b) for b in command([sbie.ini,"query","/boxes","*"])}
    if any(active.values()):
        raise RuntimeError("Existing sandbox processes are running; refusing global reconfiguration")
    candidates = [Path(os.environ["SystemRoot"])/"Sandboxie.ini", ns.sbie/"Sandboxie.ini"]
    backups = []
    for original in candidates:
        row = {"path": str(original), "existed": original.exists()}
        if original.exists():
            backup = run/("before-"+str(len(backups))+"-Sandboxie.ini")
            shutil.copy2(original, backup)
            row.update(backup=str(backup), sha256=hashlib.sha256(backup.read_bytes()).hexdigest())
        backups.append(row)
    before = {"files": backups, "sections": boxes, "activePids": active,
              "globalSettings": sbie.query("GlobalSettings"), "wfpSetting": sbie.query("GlobalSettings","NetworkEnableWFP"),
              "driver": sbie.flags()}
    save(run/"configuration-before.json", before)
    print(json.dumps({"stage":"backup","run":str(run),"box":box,"before":before},ensure_ascii=False),flush=True)
    sbie.set("GlobalSettings", "NetworkEnableWFP", "y")
    # Official SBIE_CONF_FLAG_RECONFIGURE updates WFP without unloading the driver.
    report["driverReconfigureStatus"] = sbie.dll.SbieApi_ReloadConf(0xFFFFFFFF, 1)
    report["wfpAfter"] = sbie.flags()
    save(run/"report.json", report)
    if not report["wfpAfter"]["wfp"]:
        raise RuntimeError("WFP is configured but runtime flag is off; service/driver restart is required")
    for folder in ["host-hidden","host-closed","boxdata","results"]:
        (run/folder).mkdir()
    token=uuid.uuid4().hex
    for folder in ["host-hidden","host-closed"]:
        (run/folder/"host-marker.txt").write_text("synthetic-host-"+token,encoding="utf-8")
    reg="Software\\CageBoundaryProbe\\"+box
    with winreg.CreateKey(winreg.HKEY_CURRENT_USER, reg) as key:
        winreg.SetValueEx(key, "HostOnly", 0, winreg.REG_SZ, "synthetic-host-"+token)
    servers={}
    try:
        settings={"Enabled":"n", "FileRootPath":str(run/"boxdata"), "ConfigLevel":"10",
            "AutoDelete":"n", "AutoRecover":"n", "NeverDelete":"y", "DropAdminRights":"y",
            "UsePrivacyMode":"n", "UseSecurityMode":"n", "UseRuleSpecificity":"n", "RestrictDevices":"n",
            "NetworkAccess":"*,Block", "WriteFilePath":str(run/"host-hidden"),
            "ClosedFilePath":str(run/"host-closed"), "WriteKeyPath":"HKEY_CURRENT_USER\\"+reg,
            "OpenFilePath":str(run/"results")}
        for key,value in settings.items():
            sbie.set(box,key,value)
        sbie.set(box,"Enabled","y")
        save(run/"probe-settings.json",settings)
        exe=run/"BoundaryProbe.exe"
        compiler=Path(os.environ["SystemRoot"])/"Microsoft.NET/Framework64/v4.0.30319/csc.exe"
        command([compiler,"/nologo","/target:exe","/platform:x64","/r:System.Web.Extensions.dll",
                 "/out:"+str(exe),Path(__file__).with_name("BoundaryProbe.cs")])
        for label,family,kind in [("tcp4",socket.AF_INET,socket.SOCK_STREAM),("tcp6",socket.AF_INET6,socket.SOCK_STREAM),
                                  ("udp4",socket.AF_INET,socket.SOCK_DGRAM),("udp6",socket.AF_INET6,socket.SOCK_DGRAM)]:
            servers[label]=Echo(family,kind)
        cfg={"box":box,"hidden":str(run/"host-hidden"),"closed":str(run/"host-closed"),
             "registry":reg,"output":str(run/"results"),"token":token,**{k:s.port for k,s in servers.items()}}
        report["hostControl"]={}
        for label,server in servers.items():
            family=socket.AF_INET6 if label.endswith("6") else socket.AF_INET
            try:
                with socket.socket(family,server.kind) as control:
                    control.settimeout(2)
                    control.connect(("::1" if label.endswith("6") else "127.0.0.1",server.port))
                    if server.kind==socket.SOCK_DGRAM:
                        control.send(b"positive-control")
                        assert control.recv(64)==b"positive-control"
                    report["hostControl"][label]={"ok":True}
            except OSError as exc:
                report["hostControl"][label]={"ok":False,"error":type(exc).__name__,"winerror":exc.winerror}
        time.sleep(.3)
        controls={k:s.count for k,s in servers.items()}
        for phase in ["first","second"]:
            cfg["phase"]=phase
            config=run/(phase+".json")
            save(config,cfg)
            command([sbie.start,"/box:"+box,"/silent","/wait",exe,config,"parent"],timeout=60)
            results=[]
            for role in ["parent","child"]:
                data=json.loads((run/"results"/(phase+"-"+role+".json")).read_text(encoding="utf-8-sig"))
                results.append(data)
            report[phase]=results
            # Close Sandboxie's per-box helper services before starting the next session.
            # This exercises a complete stop/reopen without deleting the box data.
            command([sbie.start,"/box:"+box,"/terminate"])
            deadline=time.monotonic()+8
            while sbie.pids(box):
                if time.monotonic()>deadline:raise RuntimeError("Probe box did not stop")
                time.sleep(.2)
            report[phase+"PidsAfter"]=sbie.pids(box)
            save(run/"report.json",report)
            print(json.dumps({"stage":phase,"identities":[r["identity"] for r in results]},ensure_ascii=False),flush=True)
        report["listenerCountsBefore"]=controls
        report["listenerCountsAfter"]={k:s.count for k,s in servers.items()}
        checks=report["checks"]
        all_results=report["first"]+report["second"]
        checks["sameBoxParentChild"]=all(r["identity"]["ok"] and r["identity"]["value"]["box"]==box for r in all_results)
        checks["runtimeWfp"]=all(r["identity"]["value"]["wfp"] for r in all_results)
        checks["hostFilesHidden"]=all(not r["hiddenFile"]["ok"] and not r["closedFile"]["ok"] for r in all_results)
        checks["hostRegistryHidden"]=all(r["hiddenRegistry"]["ok"] and r["hiddenRegistry"]["value"] is None for r in all_results)
        checks["closedWriteDenied"]=all(not r["closedWrite"]["ok"] for r in all_results)
        checks["persistentFiles"]=all(r["persistFileBefore"].get("value")==token for r in report["second"])
        checks["persistentRegistry"]=all(r["persistRegistryBefore"].get("value")==token for r in report["second"])
        verified_protocols=[k for k,v in report["hostControl"].items() if v["ok"]]
        report["verifiedNetworkProtocols"]=verified_protocols
        checks["networkDeniedForVerifiedProtocols"]=bool(verified_protocols) and all(not r[k]["ok"] for r in all_results for k in verified_protocols)
        checks["publicTcp4Denied"]=all(not r["publicTcp4"]["ok"] for r in all_results)
        checks["noPacketsReachedListeners"]=controls==report["listenerCountsAfter"]
        checks["noLiveProbeProcesses"]=not report["firstPidsAfter"] and not report["secondPidsAfter"]
        checks["hostFilesUnchanged"]=all((run/f/"host-marker.txt").read_text()=="synthetic-host-"+token for f in ["host-hidden","host-closed"])
        checks["noHostPersistenceWrites"]=not any((run/"host-hidden").glob("persist-*.txt")) and not any((run/"host-closed").glob("should-not-exist-*.txt"))
        with winreg.OpenKey(winreg.HKEY_CURRENT_USER,reg) as key:
            checks["hostRegistryUnchanged"]=winreg.QueryInfoKey(key)[1]==1 and winreg.QueryValueEx(key,"HostOnly")[0]=="synthetic-host-"+token
        report["passed"]=all(checks.values())
        report["limitations"]=["Synthetic paths only: not a full privacy-mode equivalent", "TCP/UDP tests do not certify every raw networking or IPC escape path", "No real application/proxy/exit-IP admission tested", "x64 parent and child only", "Windows only",
            "Protocols failing the unboxed positive control are unverified: "+", ".join(k for k,v in report["hostControl"].items() if not v["ok"])]
    finally:
        for server in servers.values():server.close()
        if box in sbie.query("*"):
            sbie.set(box,"NetworkAccess","*,Block")
            if sbie.pids(box):command([sbie.start,"/box:"+box,"/terminate"])
        # Only this newly generated fixture key is removed; persistent boxed registry stays.
        winreg.DeleteKey(winreg.HKEY_CURRENT_USER,reg)
        report["syntheticHostRegistryRemoved"]=True
        report["finished"]=datetime.now().isoformat()
        save(run/"report.json",report)
    print(json.dumps({"stage":"done","report":str(run/"report.json"),"passed":report.get("passed"),"checks":report["checks"]},ensure_ascii=False),flush=True)
    return 0 if report.get("passed") else 1


if __name__=="__main__":
    raise SystemExit(main())
