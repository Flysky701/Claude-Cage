"""Live, fail-closed single-space runtime. Evidence is generated each session.

No developer report grants admission. The owner process holds the gateway Job,
frontends and terminal Jobs; process death closes their handles and sockets.
"""
from contextlib import ExitStack
import ctypes
from ctypes import wintypes as w
from datetime import datetime, timezone, timedelta
import hashlib
import hmac
import http.client
import ipaddress
import json
import os
import re
from pathlib import Path
import secrets
import select
import socket
import socketserver
import ssl
import struct
import subprocess
import sys
import threading
import time
from urllib.parse import urlsplit

ROOT=Path(__file__).resolve().parent
sys.path.insert(0,str(ROOT/"dns.zip"))
from broker import DNSBroker, read_exact, session_tcp
from shell import data_gateway, validate_endpoints
from fixed_tcp import loopback_client_pid, target_addresses
from setup import WindowsBackend

NO_WINDOW=getattr(subprocess,"CREATE_NO_WINDOW",0)

def utc(value=None):
    return (value or datetime.now(timezone.utc)).isoformat().replace("+00:00","Z")

def save(path,value):
    temp=path.with_suffix(path.suffix+".tmp")
    temp.write_text(json.dumps(value,ensure_ascii=False,indent=2),encoding="utf-8")
    os.replace(temp,path)

def free_port():
    with socket.socket() as sock:
        sock.bind(("127.0.0.1",0));return sock.getsockname()[1]

class Job:
    def __init__(self):
        self.api=ctypes.WinDLL("kernel32",use_last_error=True)
        self.api.CreateJobObjectW.argtypes=[ctypes.c_void_p,w.LPCWSTR];self.api.CreateJobObjectW.restype=w.HANDLE
        self.api.SetInformationJobObject.argtypes=[w.HANDLE,ctypes.c_int,ctypes.c_void_p,w.DWORD]
        self.api.AssignProcessToJobObject.argtypes=[w.HANDLE,w.HANDLE]
        self.api.OpenProcess.argtypes=[w.DWORD,w.BOOL,w.DWORD];self.api.OpenProcess.restype=w.HANDLE
        self.api.CloseHandle.argtypes=[w.HANDLE]
        self.handle=self.api.CreateJobObjectW(None,None)
        if not self.handle:raise ctypes.WinError(ctypes.get_last_error())
        limits=ctypes.create_string_buffer(144);struct.pack_into("<I",limits,16,0x2000)
        if not self.api.SetInformationJobObject(self.handle,9,limits,len(limits)):
            self.close();raise ctypes.WinError(ctypes.get_last_error())
    def assign(self,pid):
        process=self.api.OpenProcess(0x0100|0x0001|0x0400,False,pid)
        if not process:raise RuntimeError("无法接管终端进程，未允许启动。")
        try:
            if not self.api.AssignProcessToJobObject(self.handle,process):raise ctypes.WinError(ctypes.get_last_error())
        finally:self.api.CloseHandle(process)
    def close(self):
        if self.handle:self.api.CloseHandle(self.handle);self.handle=None

class Native:
    def __init__(self,directory):
        self.backend=WindowsBackend(directory)
        self.dll=self.backend.dll
        self.dll.SbieApi_QueryProcess.argtypes=[w.HANDLE,w.LPWSTR,w.LPWSTR,w.LPWSTR,ctypes.POINTER(w.ULONG)]
        self.dll.SbieApi_QueryProcess.restype=ctypes.c_long
    def box(self,pid):
        name=ctypes.create_unicode_buffer(128)
        if self.dll.SbieApi_QueryProcess(w.HANDLE(pid),name,None,None,None):return ""
        return name.value
    def pids(self,box):
        values=(w.ULONG*2048)();count=w.ULONG(2048)
        rc=self.dll.SbieApi_EnumProcessEx(box,1,0,values,ctypes.byref(count))
        if rc or count.value>=2048:raise RuntimeError("无法完整读取空间进程。")
        return list(values[:count.value])

class ProxyStream(socketserver.StreamRequestHandler):
    rbufsize=0
    def handle(self):
        server=self.server;owner=server.owner
        peer=None
        try:
            self.connection.settimeout(8)
            pid=loopback_client_pid(self.client_address[1],server.server_address[1])
            if not pid or owner.native.box(pid)!=owner.box:return
            if server.cut.is_set():return
            server.add(self.connection)
            first=self.rfile.read(1)
            with ExitStack() as stack:
                if first==b"\x05":
                    methods=self.rfile.read(self.rfile.read(1)[0])
                    if 2 not in methods:return
                    self.wfile.write(b"\x05\x02");self.wfile.flush()
                    if self.rfile.read(1)!=b"\x01":return
                    user=self.rfile.read(self.rfile.read(1)[0]);password=self.rfile.read(self.rfile.read(1)[0])
                    if not hmac.compare_digest(user,server.user.encode()) or not hmac.compare_digest(password,server.password.encode()):return
                    self.wfile.write(b"\x01\x00");self.wfile.flush()
                    header=self.rfile.read(4)
                    if len(header)!=4 or header[:3]!=b"\x05\x01\x00":return
                    if header[3]==1:host=socket.inet_ntop(socket.AF_INET,self.rfile.read(4))
                    elif header[3]==4:host=socket.inet_ntop(socket.AF_INET6,self.rfile.read(16))
                    elif header[3]==3:host=self.rfile.read(self.rfile.read(1)[0]).decode("ascii")
                    else:return
                    port=struct.unpack("!H",self.rfile.read(2))[0]
                    peer=stack.enter_context(server.connect(host,port))
                    self.wfile.write(b"\x05\x00\x00\x01\x7f\x00\x00\x01\x00\x00");self.wfile.flush()
                else:
                    line=first+self.rfile.readline(8192)
                    method,target,version=line.decode("ascii").strip().split(" ",2)
                    headers=[];size=len(line)
                    while True:
                        line=self.rfile.readline(8192);size+=len(line)
                        if size>65536 or not line:return
                        if line==b"\r\n":break
                        headers.append(line)
                    if method=="GET" and target=="http://cage-session.invalid/"+server.challenge and owner.probing:
                        payload=server.challenge.encode();self.wfile.write(b"HTTP/1.1 200 OK\r\nConnection: close\r\nContent-Length: "+str(len(payload)).encode()+b"\r\n\r\n"+payload);return
                    if method=="GET" and target=="http://cage-session.invalid/hold/"+server.challenge and owner.probing:
                        self.wfile.write(b"HTTP/1.1 200 OK\r\nConnection: keep-alive\r\n\r\n"+server.challenge.encode());self.wfile.flush()
                        while not server.cut.is_set():
                            data=self.connection.recv(64)
                            if not data:return
                            self.connection.sendall(data)
                        return
                    if method=="CONNECT":
                        url=urlsplit("//"+target);host=url.hostname;port=url.port or 443
                        if url.username or url.path or not host:raise ValueError("bad target")
                        peer=stack.enter_context(server.connect(host,port))
                        self.wfile.write(b"HTTP/1.1 200 Connection Established\r\n\r\n");self.wfile.flush()
                    else:
                        url=urlsplit(target)
                        if url.scheme!="http" or not url.hostname or url.username:raise ValueError("bad target")
                        peer=stack.enter_context(server.connect(url.hostname,url.port or 80))
                        path=(url.path or "/")+("?"+url.query if url.query else "")
                        filtered=[line for line in headers if line.split(b":",1)[0].lower() not in (b"proxy-authorization",b"proxy-connection",b"connection")]
                        peer.sendall(f"{method} {path} HTTP/1.1\r\n".encode("ascii")+b"".join(filtered)+b"Connection: close\r\n\r\n")
                server.add(peer)
                # StreamRequestHandler buffers may contain body bytes already.
                self.connection.settimeout(None);peer.settimeout(None)
                sockets=[self.connection,peer]
                while not server.cut.is_set():
                    ready,_,_=select.select(sockets,[],[],.25)
                    for source in ready:
                        data=source.recv(65536)
                        if not data:return
                        (peer if source is self.connection else self.connection).sendall(data)
        except (OSError,EOFError,ValueError,RuntimeError,IndexError,struct.error,http.client.HTTPException) as exc:
            if owner.probing:server.events.append({"type":type(exc).__name__,"error":str(exc)[:200]})
            return
        finally:
            server.remove(self.connection)
            if peer is not None:server.remove(peer)

class Frontend(socketserver.ThreadingTCPServer):
    daemon_threads=True
    allow_reuse_address=False
    def __init__(self,owner):
        self.owner=owner;self.user="runtime";self.password=secrets.token_hex(24);self.challenge=secrets.token_hex(24)
        self.cut=threading.Event();self.lock=threading.Lock();self.connections=set()
        self.events=[]
        super().__init__(("127.0.0.1",0),ProxyStream)
        self.thread=threading.Thread(target=self.serve_forever,daemon=True);self.thread.start()
    def server_bind(self):
        self.socket.setsockopt(socket.SOL_SOCKET,socket.SO_EXCLUSIVEADDRUSE,1);super().server_bind()
    def add(self,sock):
        with self.lock:self.connections.add(sock)
    def remove(self,sock):
        with self.lock:self.connections.discard(sock)
    def pause(self):
        self.cut.set()
        with self.lock:connections=list(self.connections)
        for sock in connections:
            try:sock.shutdown(socket.SHUT_RDWR)
            except OSError:pass
            sock.close()
    def connect(self,host,port):
        if self.cut.is_set() or not 1<=port<=65535:raise OSError("gateway unavailable")
        addresses=list(target_addresses(self.owner.dns,host))
        if not addresses or any(not address.is_global for address in addresses):raise OSError("non-public destination denied")
        # Literal public addresses only reach Mihomo: no host DNS or rebinding.
        return session_tcp(self.owner.route,str(sorted(addresses,key=lambda a:a.version)[0]),port)
    def close(self):
        self.pause();self.shutdown();self.server_close()

class Runtime:
    def __init__(self,worker):
        self.worker=worker;self.profile=worker.profile;self.box=worker.box_name;self.settings=worker.settings
        self.session=secrets.token_hex(16);self.root=self.profile/"runtime"/self.session;self.root.mkdir(parents=True)
        self.binary=ROOT/"runtime-bin";self.stack=ExitStack();self.native=Native(Path(self.settings["sandboxieDirectory"]))
        self.control=worker._control();self.lock=threading.RLock();self.finished=threading.Event()
        self.failed="";self.probing=True;self.front=None;self.relay=None;self.leases={};self.browser=None;self.browser_job=None
        self.monitor={"phase":"checking","sessionId":self.session,"configHash":"","lastCheckedAt":None,"validUntil":None,"reason":"正在执行本次空间主动检查。","checks":[]}
        self.policy={};self.config_hash=self.fingerprint();self.monitor["configHash"]=self.config_hash
        self.ini=None;self.ini_hash=None;self.verified_at=0.;self.last_tls=0.
    def fingerprint(self):
        encoded=json.dumps(self.worker.settings,sort_keys=True,ensure_ascii=False,separators=(",",":")).encode()
        return hashlib.sha256(encoded+b"\0"+Path(self.settings["connectionFile"]).read_bytes()+b"\0"+self.worker.record_path.read_bytes()).hexdigest()
    def setting(self,key,values):
        if isinstance(values,str):values=[values]
        if not values:self.control.settings("delete",self.box,key)
        for index,value in enumerate(values):self.control.settings("set" if index==0 else "append",self.box,key,value)
        actual=self.control.settings("query",self.box,key)
        if actual!=values:raise RuntimeError("隔离规则未保存："+key)
        self.policy[key]=values
    def verify_resources(self):
        manifest=json.loads((self.binary/"manifest.json").read_text(encoding="utf-8"))
        for name in ("CageRuntime.exe","CageConnect.dll"):
            if hashlib.sha256((self.binary/name).read_bytes()).hexdigest()!=manifest["sha256"][name]:raise RuntimeError("运行组件完整性校验失败。")
    def build_policy(self):
        owned=self.worker._owned_box(self.control)
        if owned and self.native.pids(self.box):raise RuntimeError("上次空间进程尚未退出，请先停止。")
        if self.box in self.control.settings("query","*") and not owned:raise RuntimeError("空间身份不匹配。")
        pairs={"Enabled":"n","CageLiteSpaceId":self.worker.identity,"FileRootPath":str(self.profile/"state/files"),
            "ConfigLevel":"10","AutoDelete":"n","AutoRecover":"n","NeverDelete":"y","DropAdminRights":"y",
            "UsePrivacyMode":"n","UseSecurityMode":"n","UseRuleSpecificity":"n","NetworkAccess":"*,Block",
            "CageRuntimeSession":"y","InjectDll64":str(self.binary/"CageConnect.dll"),
            "ClosedIpcPath":r"\RPC Control\DNSResolver","CageSyncProxyPort":str(self.front.server_address[1]),
            "CageSyncProxyUser":self.front.user,"CageSyncProxyPassword":self.front.password,
            "CageLiteDnsPort":str(self.dns.server_address[1]),"CageLiteDnsTicket":self.dns.ticket.decode()}
        for key,value in pairs.items():self.setting(key,value)
        self.hidden=self.root/"host-hidden";self.hidden.mkdir();self.marker=self.hidden/"sentinel.txt";self.marker.write_text(secrets.token_hex(24))
        # Owned synthetic markers exercise the actual home and HKCU policies.
        # They contain no user data and are removed only after exact ownership
        # and contents checks when this session has completely stopped.
        import winreg
        self.home_probe=Path.home()/".cage-monitor"/self.session;self.home_probe.mkdir(parents=True,exist_ok=False)
        self.home_marker=self.home_probe/"host-sentinel.txt";self.home_token=secrets.token_hex(32);self.home_marker.write_text(self.home_token)
        self.persist_probe=self.home_probe/"boxed.txt";self.registry_probe="Software\\CageMonitor\\"+self.session
        with winreg.CreateKey(winreg.HKEY_CURRENT_USER,self.registry_probe) as key:winreg.SetValueEx(key,"HostOnly",0,winreg.REG_SZ,self.home_token)
        self.evidence=self.root/"evidence";self.evidence.mkdir()
        self.browser_data=self.profile/"browser-data";self.browser_data.mkdir(exist_ok=True)
        self.setting("WriteKeyPath",[r"HKEY_CURRENT_USER\Software"])
        closed={str(Path(self.settings["connectionFile"]).resolve()),str(self.profile/"space.json"),str(self.profile/"runtime")}
        # Evidence is the only open host path beneath runtime. Keep it separate
        # from the closed tree because classic deny rules override exceptions.
        self.evidence=self.profile/("evidence-"+self.session);self.evidence.mkdir()
        self.setting("ClosedFilePath",sorted(closed))
        opens=[str(self.evidence),str(self.browser_data)]
        project=self.settings.get("projectDirectory")
        if project:opens.append(project)
        allowed=[self.evidence,self.browser_data,ROOT,*[Path(app["program"]).parent for app in self.settings["applications"].values() if app.get("program")]]
        if project:allowed.append(Path(project))
        hidden,hidden_files=private_home_rules(Path.home(),allowed)
        self.setting("WriteFilePath",[*map(str,hidden),str(self.hidden)])
        closed.update(map(str,hidden_files))
        self.setting("ClosedFilePath",sorted(closed))
        self.setting("OpenFilePath",opens)
        self.setting("NetworkAccess",["*,Block",*[f"*,Allow;Address=127.0.0.1;Port={p};Protocol=TCP" for p in (self.front.server_address[1],self.dns.server_address[1])]])
        self.setting("Enabled","y")
        self.ini=self.native.backend.ini_path();self.capture_policy()
    def capture_policy(self):
        self.ini_hash=scoped_policy_hash(self.ini,self.box,Path(self.settings["sandboxieDirectory"])/"Templates.ini")
    def environment(self):
        env=self.worker.launch_spec("shell")["environment"]
        # These guest paths are virtualized under this fixed box; host profiles
        # and startup scripts are never inherited.
        home=r"C:\CageHome";proxy=f"http://127.0.0.1:{self.front.server_address[1]}"
        env.update(USERPROFILE=home,HOME=home,HOMEDRIVE="C:",HOMEPATH=r"\CageHome",APPDATA=home+r"\AppData\Roaming",LOCALAPPDATA=home+r"\AppData\Local",TEMP=home+r"\Temp",TMP=home+r"\Temp",HTTP_PROXY=proxy,HTTPS_PROXY=proxy,ALL_PROXY=proxy,NO_PROXY="",http_proxy=proxy,https_proxy=proxy,all_proxy=proxy,no_proxy="")
        return env
    def launch_command(self,program,args):
        return [str(Path(self.settings["sandboxieDirectory"])/"Start.exe"),"/box:"+self.box,"/silent","/hide_window","/wait",str(program),*args]
    def probe(self,label,blocked_port,expect):
        output=self.evidence/(label+".json")
        command=self.launch_command(self.binary/"CageRuntime.exe",["--probe-tree",str(output),self.box,str(self.home_marker),str(blocked_port),str(self.front.server_address[1]),self.front.challenge,self.registry_probe,str(self.persist_probe),"0" if label=="online" else "1"])
        proc=subprocess.Popen(command,env=self.environment(),stdin=subprocess.DEVNULL,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL,creationflags=NO_WINDOW)
        try:proc.wait(timeout=55)
        except subprocess.TimeoutExpired:raise RuntimeError("空间主动探针超时，未准许运行。")
        evidence=[]
        for file in (output,Path(str(output)+".child")):
            row=json.loads(file.read_text(encoding="utf-8"));evidence.append(row)
            expected_prior=label!="online" or file==output
            if not row["boxed"] or row["hostReadable"] or row["hostRegistryReadable"] or row["directConnected"] or row["proxyResponded"]!=expect or row["businessResponded"]!=expect or not row["fileWrite"] or not row["registryWrite"] or row["fileBefore"]!=expected_prior or row["registryBefore"]!=expected_prior:
                raise RuntimeError("空间主动检查未通过："+label)
        self.check_host_markers()
        return evidence
    def check_host_markers(self):
        import winreg
        if self.home_marker.read_text()!=self.home_token or self.persist_probe.exists():raise RuntimeError("宿主合成文件边界未通过。")
        with winreg.OpenKey(winreg.HKEY_CURRENT_USER,self.registry_probe) as key:
            if winreg.QueryValueEx(key,"HostOnly")[0]!=self.home_token:raise RuntimeError("宿主合成注册表边界未通过。")
            try:winreg.QueryValueEx(key,"BoxOnly")
            except FileNotFoundError:return
            raise RuntimeError("空间写入触及宿主注册表。")
    def holding_probe(self):
        report=self.evidence/"established.json"
        proc=subprocess.Popen(self.launch_command(self.binary/"CageRuntime.exe",["--hold",str(report),self.box,str(self.front.server_address[1]),self.front.challenge]),env=self.environment(),stdin=subprocess.DEVNULL,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL,creationflags=NO_WINDOW)
        deadline=time.monotonic()+8
        while time.monotonic()<deadline:
            try:
                result=json.loads(report.read_text())
                if result.get("connected") and result.get("boxed"):return proc,report
            except (OSError,ValueError):pass
            if proc.poll() is not None:break
            time.sleep(.05)
        raise RuntimeError("未建立断线检查的盒内持续连接（探针状态 "+str(proc.poll())+"）。")
    def tls_health(self):
        if self.relay.poll() is not None:raise RuntimeError("专用出口进程已退出。")
        with session_tcp(self.route,"1.1.1.1",443) as raw:
            with ssl.create_default_context().wrap_socket(raw,server_hostname="1.1.1.1") as secure:
                secure.sendall(b"GET /cdn-cgi/trace HTTP/1.1\r\nHost: 1.1.1.1\r\nConnection: close\r\n\r\n")
                with http.client.HTTPResponse(secure) as response:
                    response.begin();body=response.read(8192)
                    if response.status!=200 or b"ip=" not in body:raise RuntimeError("本次出口业务检查失败。")
    def start(self):
        self.verify_resources();self.native.backend.validate_home()
        if not self.native.backend.wfp_enabled():raise RuntimeError("内核网络过滤未启用。")
        upstream,doh=validate_endpoints(json.loads(Path(self.settings["connectionFile"]).read_text(encoding="utf-8-sig")))
        self.route,self.relay=self.stack.enter_context(data_gateway(Path(self.settings["proxyCore"]),self.root,upstream,doh))
        self.tls_health()
        self.dns=self.stack.enter_context(DNSBroker(self.route,secrets.token_hex(32)))
        thread=threading.Thread(target=self.dns.serve_forever,daemon=True);thread.start();self.stack.callback(self.dns.shutdown)
        self.front=Frontend(self);self.stack.callback(self.front.close)
        self.build_policy()
        with socket.socket() as target:
            target.bind(("127.0.0.1",0));target.listen(16);target.settimeout(2)
            host=socket.create_connection(target.getsockname(),2);accepted,_=target.accept();host.close();accepted.close()
            checks={"hostPositive":True,"online":self.probe("online",target.getsockname()[1],True)}
            holding,held_report=self.holding_probe()
            self.front.pause();holding.wait(timeout=8)
            checks["establishedCut"]=json.loads(held_report.read_text())
            if not checks["establishedCut"].get("disconnected"):raise RuntimeError("已有连接在断线后仍然存活。")
            host=socket.create_connection(target.getsockname(),2);accepted,_=target.accept();host.close();accepted.close();checks["hostAfterCut"]=True
            checks["disconnected"]=self.probe("disconnected",target.getsockname()[1],False)
            if self.native.pids(self.box):raise RuntimeError("检查探针未完全退出。")
            self.setting("Enabled","n");self.setting("Enabled","y");self.capture_policy()
            self.front.cut.clear();checks["restored"]=self.probe("restored",target.getsockname()[1],True)
        self.probing=False;self.tls_health();self.last_tls=time.monotonic()
        self.record={"sessionId":self.session,"configHash":self.config_hash,"boxName":self.box,"createdAt":utc(),"checks":checks}
        save(self.root/"admission.json",self.record)
        self.publish_healthy()
        self.thread=threading.Thread(target=self.watch,daemon=True);self.thread.start()
    def publish_healthy(self):
        now=datetime.now(timezone.utc);self.verified_at=time.monotonic()
        self.monitor.update(phase="healthy",lastCheckedAt=utc(now),validUntil=utc(now+timedelta(seconds=45)),reason="应用监控已通过，正在持续检查。",checks=[{"id":key,"ok":True} for key in ("home-privacy","registry-privacy","reopen-persistence","active-boundary-probes","wfp","configuration","owned-processes","dedicated-gateway","tls-business")])
    def guard(self,business=False):
        if self.failed or self.finished.is_set():raise RuntimeError(self.failed or "空间已停止。")
        if self.relay.poll() is not None or not self.front.thread.is_alive() or self.front.cut.is_set():raise RuntimeError("专用网络通道已中断。")
        if not self.native.backend.wfp_enabled():raise RuntimeError("内核网络过滤状态已改变。")
        if self.fingerprint()!=self.config_hash or scoped_policy_hash(self.ini,self.box,Path(self.settings["sandboxieDirectory"])/"Templates.ini")!=self.ini_hash:raise RuntimeError("空间或出口配置已改变，需要重新检查。")
        if not self.worker._owned_box(self.control):raise RuntimeError("空间归属已改变。")
        pids=self.native.pids(self.box)
        if any(self.native.box(pid)!=self.box for pid in pids):raise RuntimeError("所属进程证据已失效。")
        for lease,row in list(self.leases.items()):
            if row.get("pid") and row["pid"] not in pids:self.release(lease)
            elif not row.get("pid") and time.monotonic()>row["deadline"]:self.release(lease)
        if business:self.tls_health();self.last_tls=time.monotonic()
        if time.monotonic()-self.last_tls>45:raise RuntimeError("出口业务监控结果已过期。")
        return pids
    def watch(self):
        while not self.finished.wait(5):
            try:
                with self.lock:self.guard(time.monotonic()-self.last_tls>=20);self.publish_healthy()
            except Exception as exc:self.fail_closed(str(exc));return
    def healthy(self):
        if self.failed or self.finished.is_set() or time.monotonic()-self.verified_at>45 or time.monotonic()-self.last_tls>45:return False
        return self.monitor["phase"]=="healthy"
    def fail_closed(self,reason):
        with self.lock:
            if self.failed:return
            self.failed=reason;self.finished.set();self.monitor.update(phase="blocked",reason=reason,validUntil=utc())
            if self.front:self.front.pause()
            if self.front and self.probing:save(self.root/"frontend-diagnostics.json",self.front.events)
            if self.relay and self.relay.poll() is None:self.relay.kill()
            if self.browser_job:self.browser_job.close()
            try:
                if self.worker._owned_box(self.control):
                    self.setting("NetworkAccess","*,Block")
                    if self.native.pids(self.box):self.control.terminate()
            except Exception:pass
            for row in self.leases.values():
                if row.get("job"):row["job"].close()
    def state(self):
        if not self.healthy() and not self.failed and not self.probing:self.fail_closed("实时监控证据已过期，停止本次空间。")
        try:pids=self.native.pids(self.box)
        except Exception:pids=None
        return {"monitor":dict(self.monitor),"processCount":len(pids) if pids is not None else -1,"healthy":self.healthy()}
    def ensure(self):
        if not self.healthy():raise RuntimeError(self.failed or "空间本次监控未通过或已过期。")
        try:self.guard()
        except Exception as exc:self.fail_closed(str(exc));raise
    def browser_launch(self):
        with self.lock:
            self.ensure()
            if self.browser and self.native.box(self.browser["pid"])==self.box:return {"browser":dict(self.browser)}
            program=self.settings["applications"]["browser"]["program"]
            if Path(program).name.lower() not in ("msedge.exe","chrome.exe"):raise RuntimeError("内嵌浏览器目前需要已安装的 x64 Edge 或 Chrome。")
            port=free_port();profile=self.browser_data/"Profile"
            args=["--headless=new","--disable-gpu","--disable-quic","--disable-features=OptimizationGuideModelDownloading,OptimizationHints,MediaRouter","--disable-background-networking","--disable-component-update","--disable-sync","--no-first-run","--no-default-browser-check","--disable-extensions","--disable-breakpad","--disable-dev-shm-usage","--disable-background-timer-throttling","--disable-renderer-backgrounding","--force-webrtc-ip-handling-policy=disable_non_proxied_udp","--proxy-server=http://127.0.0.1:"+str(self.front.server_address[1]),"--proxy-bypass-list=<-loopback>","--host-resolver-rules=MAP * ~NOTFOUND, EXCLUDE localhost","--remote-debugging-address=127.0.0.1","--remote-debugging-port="+str(port),"--user-data-dir="+str(profile),"about:blank"]
            before=set(self.native.pids(self.box));token=secrets.token_hex(16)
            report=self.evidence/("browser-"+token+".json");gate=self.evidence/("browser-"+token+".gate")
            wrapper=["--terminal",str(report),str(gate),self.box,subprocess.list2cmdline([program,*args])]
            proc=subprocess.Popen(self.launch_command(self.binary/"CageRuntime.exe",wrapper),env=self.environment(),stdin=subprocess.DEVNULL,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL,creationflags=NO_WINDOW)
            deadline=time.monotonic()+10
            while not report.exists():
                if time.monotonic()>deadline or proc.poll() is not None:raise RuntimeError("浏览器启动包装器未报告受控身份。")
                time.sleep(.05)
            identity=json.loads(report.read_text());pid=identity.get("pid")
            if not identity.get("boxed") or self.native.box(pid)!=self.box:raise RuntimeError("浏览器启动包装器归属不匹配。")
            job=Job()
            try:job.assign(pid)
            except Exception:job.close();raise
            self.browser_job=job;gate.write_text(token)
            deadline=time.monotonic()+25
            while time.monotonic()<deadline:
                self.ensure()
                try:
                    connection=http.client.HTTPConnection("127.0.0.1",port,timeout=.8);connection.request("GET","/json/version");response=connection.getresponse();info=json.loads(response.read(65536));connection.close()
                    if response.status==200 and info.get("webSocketDebuggerUrl"):
                        # Listener PID must itself belong to this box; a racing
                        # host listener cannot become the browser controller.
                        pid=listener_pid(port)
                        if not pid or self.native.box(pid)!=self.box:raise RuntimeError("浏览器控制端口归属不匹配。")
                        self.browser={"cdpURL":f"http://127.0.0.1:{port}","proxyURL":f"http://127.0.0.1:{self.front.server_address[1]}","dataDirectory":str(self.browser_data),"profile":str(profile),"pid":pid,"sessionId":self.session,"configHash":self.config_hash}
                        return {"browser":dict(self.browser)}
                except (OSError,ValueError,http.client.HTTPException):pass
                if proc.poll() is not None and not(set(self.native.pids(self.box))-before):break
                time.sleep(.15)
            raise RuntimeError("盒内浏览器未能启动控制连接，未使用宿主浏览器。")
    def prepare_terminal(self,request):
        with self.lock:
            self.ensure()
            kind=request.get("kind","shell")
            if kind not in ("shell","claude"):raise ValueError("终端类型无效。")
            port=request.get("bridgePort");token=request.get("bridgeToken","")
            if type(port) is not int or not 1024<=port<=65535 or len(token)!=64 or any(c not in "0123456789abcdef" for c in token):raise ValueError("终端桥接会话无效。")
            workspace=request.get("workspace","")
            if workspace and os.path.normcase(str(Path(workspace).resolve()))!=os.path.normcase(self.settings.get("projectDirectory","")):raise ValueError("终端工作目录未获本空间共享授权。")
            manifest=json.loads((self.binary/"manifest.json").read_text())
            helper=self.binary/"CageTerminal.exe"
            if hashlib.sha256(helper.read_bytes()).hexdigest()!=manifest["sha256"].get(helper.name):raise RuntimeError("终端组件完整性检查失败。")
            app=self.settings["applications"][kind]
            from space import check_x64
            if not check_x64(app["program"]):raise RuntimeError("终端应用尚未配置有效程序。")
            command=[app["program"],*app.get("arguments",[])]
            supplied=request.get("claudeCommand")
            if kind=="claude" and supplied:
                if not isinstance(supplied,list) or not all(isinstance(s,str) and "\0" not in s for s in supplied) or os.path.normcase(supplied[0])!=os.path.normcase(app["program"]):raise ValueError("Claude 启动程序与已登记应用不一致。")
                command=supplied
            lease=secrets.token_hex(16);report=self.evidence/("terminal-"+lease+".json")
            self.setting("NetworkAccess",[*self.policy["NetworkAccess"],f"*,Allow;Address=127.0.0.1;Port={port};Protocol=TCP"]);self.capture_policy()
            args=["--box",self.box,"--lease",lease,"--token",token,"--port",str(port),"--report",str(report),"--cols",str(max(1,min(500,int(request.get("cols",120))))),"--rows",str(max(1,min(300,int(request.get("rows",30))))),"--",*command]
            plan={"leaseId":lease,"command":self.launch_command(helper,args),"environment":self.environment(),"cwd":workspace or str(Path(os.environ.get("SystemRoot",r"C:\Windows"))/"System32"),"boxName":self.box,"profile":str(self.profile),"kind":kind,"workspace":workspace,"sessionId":self.session,"configurationHash":self.config_hash,"configHash":self.config_hash}
            self.leases[lease]={"plan":plan,"report":report,"token":token,"port":port,"deadline":time.monotonic()+20,"pid":None,"job":None}
            return plan
    def attach_terminal(self,request):
        with self.lock:
            self.ensure();lease=request.get("leaseId");row=self.leases.get(lease)
            if request.get("sessionId")!=self.session or request.get("configurationHash")!=self.config_hash:raise RuntimeError("终端准入代次已改变。")
            if not row or time.monotonic()>row["deadline"] or row["pid"]:raise RuntimeError("终端启动票据已失效。")
            report=json.loads(row["report"].read_text(encoding="utf-8"));pid=report.get("pid")
            if type(pid) is not int or report.get("boxName")!=self.box or report.get("leaseId")!=lease or not hmac.compare_digest(report.get("token",""),row["token"]) or self.native.box(pid)!=self.box:raise RuntimeError("终端进程归属校验失败。")
            if request.get("pid") not in (None,pid):raise RuntimeError("终端握手PID不一致。")
            job=Job()
            try:job.assign(pid)
            except Exception:job.close();raise
            row.update(pid=pid,job=job)
            return {"leaseId":lease,"pid":pid,"boxName":self.box,"profile":str(self.profile),"sessionId":self.session,"configurationHash":self.config_hash,"configHash":self.config_hash}
    def release(self,lease):
        row=self.leases.pop(lease,None)
        if row and row.get("job"):row["job"].close()
        if row and not self.finished.is_set():
            rule=f"*,Allow;Address=127.0.0.1;Port={row['port']};Protocol=TCP"
            self.setting("NetworkAccess",[entry for entry in self.policy["NetworkAccess"] if entry!=rule]);self.capture_policy()
    def close(self):
        self.finished.set()
        with self.lock:
            if self.front:self.front.pause()
            if self.browser_job:self.browser_job.close()
            for row in self.leases.values():
                if row.get("job"):row["job"].close()
            error=None
            try:
                if self.worker._owned_box(self.control):
                    self.setting("NetworkAccess","*,Block")
                    if self.native.pids(self.box):self.control.terminate()
                    deadline=time.monotonic()+5
                    while self.native.pids(self.box):
                        if time.monotonic()>deadline:raise RuntimeError("空间仍有进程，网络已阻断。")
                        time.sleep(.1)
                    self.setting("Enabled","n")
            except Exception as exc:error=exc
            finally:self.stack.close()
            if not error and hasattr(self,"home_marker"):
                try:
                    self.check_host_markers()
                    import winreg
                    with winreg.OpenKey(winreg.HKEY_CURRENT_USER,self.registry_probe) as key:
                        values=winreg.QueryInfoKey(key)[1]
                    if values==1:
                        winreg.DeleteKey(winreg.HKEY_CURRENT_USER,self.registry_probe)
                    if sorted(p.name for p in self.home_probe.iterdir())==["host-sentinel.txt"]:
                        self.home_marker.unlink();self.home_probe.rmdir()
                except (OSError,RuntimeError):pass
            self.monitor.update(phase="stopped" if not error else "blocked",validUntil=utc(),reason="空间已停止，持久数据保留。" if not error else str(error))
            if error:raise error

def listener_pid(port):
    get=ctypes.WinDLL("iphlpapi").GetExtendedTcpTable
    get.argtypes=[ctypes.c_void_p,ctypes.POINTER(w.DWORD),w.BOOL,w.ULONG,ctypes.c_int,w.ULONG]
    size=w.DWORD();get(None,ctypes.byref(size),False,socket.AF_INET,3,0)
    data=ctypes.create_string_buffer(size.value)
    if get(data,ctypes.byref(size),False,socket.AF_INET,3,0):return None
    raw=data.raw;count=struct.unpack_from("<I",raw)[0]
    for state,src,sport,dst,dport,pid in struct.iter_unpack("<I4sI4sII",raw[4:4+24*count]):
        if state==2 and src==b"\x7f\x00\x00\x01" and socket.ntohs(sport&65535)==port:return pid
    return None

def private_home_rules(home,allowed):
    """Hide existing host home data without an exception beneath a deny rule.

    Classic free rules prioritize deny, so partition only the ancestor paths of
    explicitly shared data and installed binaries, instead of opening the home.
    """
    allowed=[Path(p).resolve() for p in allowed]
    hidden,files=[],[]
    def walk(folder):
        if folder in allowed:return
        for child in folder.iterdir():
            if child in allowed:continue
            if any(child in path.parents for path in allowed):
                if child.is_dir():walk(child)
                else:files.append(child)
            elif child.is_dir():hidden.append(child)
            else:files.append(child)
    walk(home.resolve())
    return hidden,files

def scoped_policy_hash(path,box,templates):
    raw=path.read_bytes()
    decoded=raw.decode("utf-16" if raw[:2] in (b"\xff\xfe",b"\xfe\xff") else "utf-8-sig")
    section="";selected=[]
    for line in decoded.splitlines():
        match=re.match(r"\s*\[([^\]]+)\]\s*$",line)
        if match:section=match[1].casefold()
        if section in ("",box.casefold(),"globalsettings","defaulttemplates") or section.startswith("template_"):
            selected.append(line.strip())
    material="\n".join(selected).encode()
    if templates.exists():material+=b"\0"+templates.read_bytes()
    return hashlib.sha256(material).hexdigest()
