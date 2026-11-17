"""Exercise Edge against a local-only TLS/SOCKS fixture inside a disposable box.

Requires Windows, Sandboxie, Edge, and cryptography (only to create a temporary
fixture certificate). It never reads a saved proxy configuration or dials the
internet. Run from an ordinary host process so Windows TCP ownership is visible.
"""
import argparse
import base64
from contextlib import ExitStack
from datetime import datetime, timedelta, timezone
import hashlib
import http.server
import ipaddress
import json
import os
from pathlib import Path
import platform
import secrets
import select
import socket
import socketserver
import ssl
import struct
import subprocess
import sys
import threading
from types import SimpleNamespace

ROOT = Path(__file__).resolve().parent
REPO = ROOT.parent.parent
sys.path.insert(0, str(ROOT / "dns.zip"))
from broker import DNSBroker, read_exact
from browser_proxy import BrowserProxy
from policy import build_policy, safe_environment
from shell import Sandbox


def certificate(work):
    from cryptography import x509
    from cryptography.hazmat.primitives import hashes, serialization
    from cryptography.hazmat.primitives.asymmetric import rsa
    from cryptography.x509.oid import NameOID

    key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
    name = x509.Name([x509.NameAttribute(NameOID.COMMON_NAME, "Cage local browser fixture")])
    now = datetime.now(timezone.utc)
    cert = (x509.CertificateBuilder().subject_name(name).issuer_name(name).public_key(key.public_key())
            .serial_number(x509.random_serial_number()).not_valid_before(now - timedelta(minutes=5))
            .not_valid_after(now + timedelta(days=1))
            .add_extension(x509.SubjectAlternativeName([x509.IPAddress(ipaddress.ip_address("1.1.1.1"))]), critical=False)
            .add_extension(x509.BasicConstraints(ca=False, path_length=None), critical=True)
            .sign(key, hashes.SHA256()))
    certfile, keyfile = work / "fixture.pem", work / "fixture-key.pem"
    certfile.write_bytes(cert.public_bytes(serialization.Encoding.PEM))
    keyfile.write_bytes(key.private_bytes(serialization.Encoding.PEM,
                                        serialization.PrivateFormat.TraditionalOpenSSL,
                                        serialization.NoEncryption()))
    spki = key.public_key().public_bytes(serialization.Encoding.DER,
                                        serialization.PublicFormat.SubjectPublicKeyInfo)
    return certfile, keyfile, base64.b64encode(hashlib.sha256(spki).digest()).decode("ascii")


class FixturePage(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path != "/cage-fixture":
            self.send_error(404)
            return
        self.server.hits += 1
        payload = ("<!doctype html><html><head><title>Cage local TLS</title></head>"
                   f"<body><main id=\"cage-fixture\">{self.server.marker}</main></body></html>").encode()
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(payload)))
        self.send_header("Connection", "close")
        self.end_headers()
        self.wfile.write(payload)

    def log_message(self, format, *args):
        pass


class FixtureSocks(socketserver.BaseRequestHandler):
    def handle(self):
        self.request.settimeout(8)
        try:
            if read_exact(self.request, 3) != b"\x05\x01\x02":
                return
            self.request.sendall(b"\x05\x02")
            version, size = read_exact(self.request, 2)
            user = read_exact(self.request, size)
            password = read_exact(self.request, read_exact(self.request, 1)[0])
            if version != 1 or user != self.server.user or password != self.server.password:
                return
            self.request.sendall(b"\x01\x00")
            head = read_exact(self.request, 4)
            if head != b"\x05\x01\x00\x01":
                self.request.sendall(b"\x05\x02\x00\x01" + b"\0" * 6)
                return
            address = ipaddress.ip_address(read_exact(self.request, 4))
            port, = struct.unpack("!H", read_exact(self.request, 2))
            if str(address) != "1.1.1.1" or port != 443:
                self.server.rejected += 1
                self.request.sendall(b"\x05\x02\x00\x01" + b"\0" * 6)
                return
            # The requested public address is only a fixture identifier.
            # This is the sole destination this fake SOCKS server can dial.
            with socket.create_connection(self.server.tls_endpoint, timeout=8) as upstream:
                self.server.accepted += 1
                self.request.sendall(b"\x05\x00\x00\x01" + b"\0" * 6)
                peers = {self.request: upstream, upstream: self.request}
                while peers:
                    ready, _, _ = select.select(list(peers), [], [], .5)
                    if self.server.stopping.is_set():
                        return
                    for sock in ready:
                        data = sock.recv(65536)
                        if data:
                            peers[sock].sendall(data)
                        else:
                            peers.pop(sock).shutdown(socket.SHUT_WR)
        except (OSError, EOFError, ValueError):
            return


def serve(stack, server):
    stack.enter_context(server)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    stack.callback(server.shutdown)
    return server


def outsider_denied(proxy):
    with socket.socket() as sock:
        sock.settimeout(3)
        sock.connect(proxy.server_address)
        try:
            sock.sendall(b"CONNECT 1.1.1.1:443 HTTP/1.1\r\n\r\n")
            return sock.recv(64) == b""
        except (ConnectionResetError, ConnectionAbortedError):
            return True


def run_edge(box, edge, env, profile, proxy_port, spki, work, phase):
    screenshot = work / "data" / "output" / "browser" / (phase + ".png")
    edge_args = ["--headless", "--no-first-run", "--no-default-browser-check", "--disable-gpu",
            "--disable-background-networking", "--disable-component-update", "--disable-sync",
            "--disable-quic", "--proxy-bypass-list=<-loopback>",
            f"--proxy-server=http://127.0.0.1:{proxy_port}", "--user-data-dir=" + str(profile),
            "--ignore-certificate-errors-spki-list=" + spki, "--window-size=900,500",
            "--screenshot=" + str(screenshot),
            "https://1.1.1.1/cage-fixture"]
    # Start.exe does not forward the child's standard handles, so use Edge's
    # screenshot output directly. Inspect the saved image for the served marker.
    args = [box.start, "/box:" + box.name, "/silent", "/wait", str(edge), *edge_args]
    try:
        result = subprocess.run(args, env=env, cwd=edge.parent, stdout=subprocess.PIPE,
                                stderr=subprocess.PIPE, timeout=35, creationflags=subprocess.CREATE_NO_WINDOW)
        (work / (phase + "-stdout.txt")).write_bytes(result.stdout)
        (work / (phase + "-stderr.txt")).write_bytes(result.stderr)
        return result.returncode, screenshot.is_file() and screenshot.read_bytes().startswith(b"\x89PNG\r\n\x1a\n")
    finally:
        box.control("/terminate")


def verify(work, edge, sbie):
    work.mkdir(parents=True, exist_ok=False)
    result = {"environment": {"windows": platform.version(), "python": platform.python_version()},
              "transport": "local-only SOCKS maps a public fixture identifier to loopback TLS",
              "credentials": "generated fixture credentials only", "status": "failed"}
    try:
        certfile, keyfile, spki = certificate(work)
        home = work / "data"
        output = home / "output" / "browser"
        output.mkdir(parents=True)
        box = Sandbox(sbie, "CageLite_BrowserTest_" + secrets.token_hex(5))
        original_wfp = box.settings("query", "GlobalSettings", "NetworkEnableWFP")
        result["wfpConfigured"] = "y" in [value.lower() for value in original_wfp]
        policy = build_policy(edge, [], home, output, None, sbie, {}, work, ROOT)
        env = safe_environment(edge, [])
        with ExitStack() as stack:
            tls = http.server.ThreadingHTTPServer(("127.0.0.1", 0), FixturePage)
            context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
            context.load_cert_chain(str(certfile), str(keyfile))
            tls.socket = context.wrap_socket(tls.socket, server_side=True)
            tls.hits, tls.marker = 0, "CAGE_LOCAL_TLS_" + secrets.token_hex(8)
            serve(stack, tls)
            socks = socketserver.ThreadingTCPServer(("127.0.0.1", 0), FixtureSocks)
            socks.daemon_threads = True
            socks.stopping = threading.Event()
            socks.tls_endpoint = tls.server_address
            socks.user, socks.password = b"fixture", secrets.token_hex(16).encode()
            socks.accepted = socks.rejected = 0
            serve(stack, socks)
            stack.callback(socks.stopping.set)
            route = SimpleNamespace(port=socks.server_address[1], user=socks.user.decode(), password=socks.password.decode())
            broker = serve(stack, DNSBroker(None, secrets.token_hex(32)))
            # Numerical fixture target means no DNS is needed. Any incidental
            # browser lookup fails closed instead of leaving this local test.
            adapter_dns = SimpleNamespace(route=route, resolve=broker.resolve)
            proxy = serve(stack, BrowserProxy(box, adapter_dns))
            stack.enter_context(box.configure(edge, [], home / "private", home / "boxes" / "browser",
                                              output, None, None, broker,
                                              {"browser": proxy.server_address[1]}, policy=policy))
            result["outsiderDenied"] = outsider_denied(proxy)
            result["outsiderOpenedUpstream"] = socks.accepted != 0
            code, captured = run_edge(box, edge, env, home / "profiles" / "online", proxy.server_address[1], spki, work, "online")
            result["online"] = {"launcherExitCode": code, "tlsRequests": tls.hits,
                                "socksSessions": socks.accepted, "screenshotWritten": captured,
                                "expectedMarker": tls.marker}
            if code != 0 or tls.hits < 1 or not captured:
                raise RuntimeError("Edge did not render the local TLS fixture")
            proxy.shutdown()
            proxy.server_close()
            before = tls.hits
            code, captured = run_edge(box, edge, env, home / "profiles" / "offline", proxy.server_address[1], spki, work, "offline")
            result["proxyStopped"] = {"launcherExitCode": code, "newTlsRequests": tls.hits - before,
                                      "screenshotWritten": captured,
                                      "scope": "no successful fixture fetch; direct sockets were not independently traced"}
            if tls.hits != before:
                raise RuntimeError("Stopped proxy unexpectedly reached fixture")
        result["temporaryBoxRemoved"] = box.name not in box.settings("query", "*")
        result["globalWfpUnchanged"] = box.settings("query", "GlobalSettings", "NetworkEnableWFP") == original_wfp
        result["status"] = "pending-image-review" if all((result["outsiderDenied"], not result["outsiderOpenedUpstream"],
                                            result["temporaryBoxRemoved"], result["globalWfpUnchanged"])) else "failed"
    except Exception as exc:
        result["errorType"] = type(exc).__name__
        result["error"] = str(exc) if isinstance(exc, RuntimeError) else "Local browser fixture could not complete"
    (work / "result.json").write_text(json.dumps(result, indent=2), encoding="utf-8")
    print(json.dumps(result, indent=2))
    return 0 if result["status"] == "pending-image-review" else 1


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--work", type=Path, default=REPO / "tmp" / ("windows-lite-browser-" + secrets.token_hex(5)))
    parser.add_argument("--dependencies", type=Path, help="optional directory containing cryptography")
    parser.add_argument("--edge", type=Path, default=Path(os.environ["ProgramFiles(x86)"]) / "Microsoft/Edge/Application/msedge.exe")
    parser.add_argument("--sandboxie", type=Path, default=Path(os.environ["ProgramFiles"]) / "Sandboxie-Plus")
    args = parser.parse_args()
    if args.dependencies:
        sys.path.insert(0, str(args.dependencies.resolve()))
    return verify(args.work.resolve(), args.edge.resolve(), args.sandboxie.resolve())


if __name__ == "__main__":
    sys.exit(main())
