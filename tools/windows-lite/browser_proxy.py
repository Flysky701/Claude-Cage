"""A box-owned HTTPS CONNECT listener backed only by the session SOCKS route.

Chromium accepts this loopback proxy without learning the session credentials.
Plain HTTP and private-network destinations are deliberately unsupported here.
"""
from contextlib import ExitStack
import ipaddress
import re
import select
import socket
import socketserver
import subprocess
import threading

import dns.exception

from broker import session_tcp
from fixed_tcp import loopback_client_pid, target_addresses


MAX_HEADER = 16384
HEADER_NAME = re.compile(rb"[!#$%&'*+.^_`|~0-9A-Za-z-]+")


class RequestError(ValueError):
    def __init__(self, status, reason):
        self.status, self.reason = status, reason
        super().__init__(reason)


def connect_target(header):
    """Parse an authority-form CONNECT request; never forward proxy headers."""
    lines = header.split(b"\r\n")
    parts = lines[0].split(b" ")
    if len(parts) != 3 or parts[2] not in (b"HTTP/1.0", b"HTTP/1.1"):
        raise RequestError(400, "Bad Request")
    if parts[0] != b"CONNECT":
        raise RequestError(405, "HTTPS CONNECT Required")
    try:
        authority = parts[1].decode("ascii")
    except UnicodeError as exc:
        raise RequestError(400, "Bad Request") from exc
    match = re.fullmatch(r"(?:\[([0-9A-Fa-f:.]+)\]|([^:\[\]]+)):([0-9]{1,5})", authority)
    if not match:
        raise RequestError(400, "Bad Request")
    host, port = match[1] or match[2], int(match[3])
    if not 1 <= port <= 65535:
        raise RequestError(400, "Bad Request")
    try:
        address = ipaddress.ip_address(host)
        if match[1] and address.version != 6:
            raise ValueError("IPv6 brackets required")
        host = str(address)
    except ValueError as exc:
        if match[1]:
            raise RequestError(400, "Bad Request") from exc
        host = host.lower().rstrip(".")
        if (len(host) > 253 or not all(re.fullmatch(r"(?!-)[a-z0-9-]{1,63}(?<!-)", label)
                                      for label in host.split("."))):
            raise RequestError(400, "Bad Request") from exc
    for line in lines[1:]:
        if not line:
            continue
        name, separator, value = line.partition(b":")
        if not separator or not HEADER_NAME.fullmatch(name) or any(c < 32 and c != 9 or c == 127 for c in value):
            raise RequestError(400, "Bad Request")
        if name.lower() == b"transfer-encoding":
            raise RequestError(400, "Bad Request")
        if name.lower() == b"content-length" and value.strip() != b"0":
            raise RequestError(400, "Bad Request")
    return host, port


def read_head(sock):
    data = bytearray()
    while True:
        marker = data.find(b"\r\n\r\n")
        if marker >= 0:
            return bytes(data[:marker]), bytes(data[marker + 4:])
        if len(data) >= MAX_HEADER:
            raise RequestError(431, "Request Header Fields Too Large")
        chunk = sock.recv(min(4096, MAX_HEADER - len(data)))
        if not chunk:
            raise EOFError("Proxy request closed")
        data.extend(chunk)


def public_address(address):
    # is_global alone also accepts multicast addresses on supported Python versions.
    return address.is_global and not address.is_multicast


def reply(sock, status, reason):
    body = (reason + "\n").encode("ascii")
    head = (f"HTTP/1.1 {status} {reason}\r\nConnection: close\r\n"
            f"Content-Length: {len(body)}\r\nContent-Type: text/plain\r\n\r\n")
    sock.sendall(head.encode("ascii") + body)


class ConnectStream(socketserver.BaseRequestHandler):
    def handle(self):
        server = self.server
        established = False
        upstream = None
        self.request.settimeout(8)
        try:
            server.track(self.request)
            owner = loopback_client_pid(self.client_address[1], server.server_address[1])
            if not owner or owner not in server.box.pids():
                # No header parsing or upstream activity for an unknown caller.
                return
            header, pending = read_head(self.request)
            host, port = connect_target(header)
            with ExitStack() as stack:
                public = False
                for address in target_addresses(server.dns, host):
                    if not public_address(address):
                        continue
                    public = True
                    if server.stopping.is_set():
                        return
                    try:
                        upstream = stack.enter_context(session_tcp(server.dns.route, address, port))
                        break
                    except (OSError, EOFError):
                        continue
                else:
                    if not public:
                        raise RequestError(403, "Public Destination Required")
                    raise OSError("Session route unavailable")
                server.track(upstream)
                upstream.settimeout(8)
                self.request.sendall(b"HTTP/1.1 200 Connection Established\r\n\r\n")
                established = True
                if pending:
                    upstream.sendall(pending)
                peers = {self.request: upstream, upstream: self.request}
                while peers and not server.stopping.is_set():
                    ready, _, _ = select.select(list(peers), [], [], .5)
                    for sock in ready:
                        data = sock.recv(65536)
                        if data:
                            peers[sock].sendall(data)
                        else:
                            peers.pop(sock).shutdown(socket.SHUT_WR)
        except RequestError as exc:
            if not established:
                self.error(exc.status, exc.reason)
        except (OSError, EOFError, ValueError, KeyError, IndexError, RuntimeError,
                subprocess.SubprocessError, dns.exception.DNSException):
            if not established:
                self.error(502, "Session Route Unavailable")
        finally:
            server.untrack(self.request)
            if upstream is not None:
                server.untrack(upstream)

    def error(self, status, reason):
        try:
            reply(self.request, status, reason)
        except OSError:
            pass


class BrowserProxy(socketserver.ThreadingTCPServer):
    daemon_threads = True
    request_queue_size = 32

    def __init__(self, box, dns):
        self.box, self.dns = box, dns
        self.stopping = threading.Event()
        self._lock = threading.Lock()
        self._sockets = set()
        super().__init__(("127.0.0.1", 0), ConnectStream)

    def server_bind(self):
        self.socket.setsockopt(socket.SOL_SOCKET, socket.SO_EXCLUSIVEADDRUSE, 1)
        super().server_bind()

    def track(self, sock):
        with self._lock:
            if self.stopping.is_set():
                raise OSError("Browser proxy stopped")
            self._sockets.add(sock)

    def untrack(self, sock):
        with self._lock:
            self._sockets.discard(sock)

    def _stop_connections(self):
        self.stopping.set()
        with self._lock:
            sockets = list(self._sockets)
        for sock in sockets:
            try:
                sock.shutdown(socket.SHUT_RDWR)
            except OSError:
                pass
            sock.close()

    def shutdown(self):
        self._stop_connections()
        super().shutdown()

    def server_close(self):
        self._stop_connections()
        super().server_close()
