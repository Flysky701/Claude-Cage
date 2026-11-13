"""One local stdio connection to the configured Cage SOCKS proxy. Credentials stay on Windows."""
import ipaddress
import json
import os
import socket
import ssl
import sys
import threading
from http.client import HTTPResponse
from pathlib import Path
from urllib.parse import unquote, urlsplit

HOST="ipv4.icanhazip.com"
def read_exact(read, n):
    data=bytearray()
    while len(data)<n:
        part=read(n-len(data))
        if not part: raise EOFError()
        data.extend(part)
    return bytes(data)

def cage():
    cfg=json.loads((Path.home()/".claude-cage/config.json").read_text(encoding="utf-8-sig"))
    u=urlsplit(cfg["proxy_url"])
    if u.scheme!="socks5" or u.hostname not in ("127.0.0.1","localhost"): raise ValueError("expected local Cage proxy")
    s=socket.create_connection((u.hostname,u.port),timeout=7)
    s.sendall(b"\x05\x02\x00\x02"); method=read_exact(s.recv,2)
    if method==b"\x05\x02":
        user=unquote(u.username or "").encode(); pw=unquote(u.password or "").encode()
        s.sendall(b"\x01"+bytes([len(user)])+user+bytes([len(pw)])+pw)
        if read_exact(s.recv,2)!=b"\x01\x00": raise ConnectionError("upstream rejected authentication")
    elif method!=b"\x05\x00": raise ConnectionError("upstream rejected negotiation")
    return s

def stdio():
    import msvcrt
    msvcrt.setmode(0, os.O_BINARY)
    msvcrt.setmode(1, os.O_BINARY)
    inp=lambda n:os.read(0,n)
    ver,count=read_exact(inp,2)
    if ver!=5 or 0 not in read_exact(inp,count):return
    with cage() as s:
        os.write(1,b"\x05\x00")
        # All bytes following the greeting belong to this isolated client's SOCKS session.
        def send():
            try:
                while data:=inp(65536): s.sendall(data)
            except OSError:pass
            finally:
                try:s.shutdown(socket.SHUT_WR)
                except OSError:pass
        threading.Thread(target=send,daemon=True).start()
        s.settimeout(20)
        while data:=s.recv(65536):
            stream=memoryview(data)
            while stream: stream=stream[os.write(1,stream):]

def reference(resolve=False):
    with cage() as s:
        host="cloudflare-dns.com" if resolve else HOST
        dest=host.encode()
        s.sendall(b"\x05\x01\x00\x03"+bytes([len(dest)])+dest+b"\x01\xbb")
        v,rep,_,kind=read_exact(s.recv,4)
        if v!=5 or rep: raise ConnectionError("reference connection failed")
        size=read_exact(s.recv,1)[0] if kind==3 else {1:4,4:16}[kind]
        read_exact(s.recv,size+2)
        with ssl.create_default_context().wrap_socket(s,server_hostname=host) as tls:
            path=f"/dns-query?name={HOST}&type=A" if resolve else "/"
            tls.sendall(f"GET {path} HTTP/1.1\r\nHost: {host}\r\nAccept: application/dns-json\r\nConnection: close\r\n\r\n".encode())
            r=HTTPResponse(tls);r.begin()
            if r.status!=200: raise ConnectionError("reference HTTP status")
            if resolve:
                for item in json.load(r).get("Answer",[]):
                    if item["type"]==1 and ipaddress.IPv4Address(item["data"]).is_global:
                        print(item["data"]);return
                raise ValueError("no public A record")
            else: print(ipaddress.IPv4Address(r.read(128).decode().strip()))

if __name__=="__main__":
    try:
        if sys.argv[1] in ("reference","resolve"): reference(sys.argv[1]=="resolve")
        else: stdio()
    except (OSError,EOFError):
        sys.exit(1)
