import http.client
import ipaddress
import json
import os
import socket
import ssl
import subprocess
import sys
import uuid
from pathlib import Path

name="ipv4.icanhazip.com"
stage, pinfile=sys.argv[1:]
url="https://"+name+"/?cage="+uuid.uuid4().hex
env={k:v for k,v in os.environ.items() if not k.lower().endswith("_proxy")}
if stage=="online":
    pinned=str(ipaddress.IPv4Address(socket.gethostbyname(name)))
    if not ipaddress.ip_address(pinned).is_global: raise ValueError("numeric control is not a public IPv4")
    Path(pinfile).write_text(pinned)
pinned=Path(pinfile).read_text().strip()
def parent(host):
    with socket.create_connection((host,443),timeout=5) as raw:
        with ssl.create_default_context().wrap_socket(raw,server_hostname=name) as tls:
            tls.sendall(f"GET /?cage={uuid.uuid4().hex} HTTP/1.1\r\nHost: {name}\r\nConnection: close\r\n\r\n".encode())
            r=http.client.HTTPResponse(tls); r.begin()
            if r.status!=200: return "http-"+str(r.status)
            return str(ipaddress.IPv4Address(r.read(128).decode().strip()))
def child(pin):
    args=["curl","-q","--noproxy","*","-4","--connect-timeout","4","--max-time","7","-fsS"]
    if pin: args+=["--resolve",f"{name}:443:{pinned}"]
    proc=subprocess.run(args+[url],capture_output=True,env=env)
    return "curl-"+str(proc.returncode) if proc.returncode else str(ipaddress.IPv4Address(proc.stdout.decode().strip()))
out={}
for path,call in [("main-name",lambda:parent(name)),("main-address",lambda:parent(pinned)),("child-name",lambda:child(False)),("child-address",lambda:child(True))]:
    try:out[path]=call()
    except (OSError, http.client.HTTPException, ValueError) as e: out[path]=type(e).__name__
print(json.dumps(out))
