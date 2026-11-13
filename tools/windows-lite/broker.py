"""The boxed resolver's A/AAAA broker. No system resolver or direct upstream."""
import hmac
from concurrent.futures import Future
from contextlib import contextmanager
import http.client
import ipaddress
import socket
import socketserver
import ssl
import struct
import threading

import dns.message
import dns.rcode
import dns.rdatatype


def read_exact(sock, length):
    parts = bytearray()
    while len(parts) < length:
        chunk = sock.recv(length - len(parts))
        if not chunk:
            raise EOFError("SOCKS connection closed")
        parts.extend(chunk)
    return bytes(parts)


@contextmanager
def session_tcp(route, destination, port):
    """Connect through the authenticated session to one numerical endpoint."""
    addr = ipaddress.ip_address(destination)
    with socket.create_connection(("127.0.0.1", route.port), timeout=7) as sock:
        sock.sendall(b"\x05\x01\x02")
        if read_exact(sock, 2) != b"\x05\x02":
            raise OSError("Session SOCKS authentication unavailable")
        user, password = route.user.encode(), route.password.encode()
        sock.sendall(b"\x01" + bytes([len(user)]) + user + bytes([len(password)]) + password)
        if read_exact(sock, 2) != b"\x01\x00":
            raise OSError("Session SOCKS authentication failed")
        sock.sendall(b"\x05\x01\x00" + bytes([1 if addr.version == 4 else 4]) +
                     addr.packed + struct.pack("!H", port))
        reply = read_exact(sock, 4)
        if reply[:3] != b"\x05\x00\x00":
            raise OSError("Upstream unavailable")
        if reply[3] == 3:
            size = read_exact(sock, 1)[0]
        else:
            size = {1: 4, 4: 16}[reply[3]]
        read_exact(sock, size + 2)
        yield sock


def dns_over_https(question, route):
    with session_tcp(route, route.doh.hostname, route.doh.port or 443) as sock:
        with route.tls.wrap_socket(sock, server_hostname=route.doh.hostname) as tls:
            wire = question.to_wire()
            path = route.doh.path or "/dns-query"
            if route.doh.query:
                path += "?" + route.doh.query
            header = (f"POST {path} HTTP/1.1\r\nHost: {route.doh.netloc}\r\n"
                      "Content-Type: application/dns-message\r\nAccept: application/dns-message\r\n"
                      f"Content-Length: {len(wire)}\r\nConnection: close\r\n\r\n")
            tls.sendall(header.encode("ascii") + wire)
            with http.client.HTTPResponse(tls) as response:
                response.begin()
                if response.status != 200 or response.headers.get_content_type() != "application/dns-message":
                    raise OSError("Unexpected DoH response")
                payload = response.read(65536)
            if len(payload) > 65535:
                raise ValueError("Oversize DNS response")
            answer = dns.message.from_wire(payload)
            if not question.is_response(answer):
                raise ValueError("DNS response mismatch")
            return answer


class Resolver(socketserver.StreamRequestHandler):
    def handle(self):
        self.connection.settimeout(8)
        try:
            if not hmac.compare_digest(self.rfile.read(64), self.server.ticket):
                return
            raw = self.rfile.readline(256)
            if not raw.endswith(b"\n"):
                return
            name = raw[:-1].decode("ascii").lower().rstrip(".")
            labels = name.split(".")
            if not name or any(not 1 <= len(label) <= 63 or label.startswith("-") or
                               label.endswith("-") or not all(c.isalnum() or c == "-" for c in label)
                               for label in labels):
                self.wfile.write(bytes([3, 0]))
                return
            reply = self.server.resolve(name)
        except (OSError, EOFError, ValueError, KeyError, http.client.HTTPException, dns.exception.DNSException) as exc:
            if self.server.trace and 'name' in locals():
                print(f"DNS {name}: {type(exc).__name__}: {exc}", flush=True)
            reply = bytes([2, 0])
        try:
            self.wfile.write(reply)
        except OSError:
            pass


class DNSBroker(socketserver.ThreadingTCPServer):
    daemon_threads = True

    def __init__(self, route, ticket, trace=False):
        self.route = route
        self.ticket = ticket.encode("ascii")
        self.trace = trace
        self.lock = threading.Lock()
        self.pending = {}
        super().__init__(("127.0.0.1", 0), Resolver)

    def resolve(self, name):
        # Only share overlapping requests. A completed response never survives a cut.
        with self.lock:
            existing = self.pending.get(name)
            if existing is None:
                future = self.pending[name] = Future()
        if existing is not None:
            return existing.result(timeout=30)
        try:
            result = self.lookup(name)
            future.set_result(result)
            return result
        except Exception as exc:
            future.set_exception(exc)
            raise
        finally:
            with self.lock:
                self.pending.pop(name, None)

    def lookup(self, name):
        records = []
        for family, kind in ((4, dns.rdatatype.A), (6, dns.rdatatype.AAAA)):
            question = dns.message.make_query(name + ".", kind)
            try:
                answer = dns_over_https(question, self.route)
            except (OSError, EOFError, http.client.HTTPException):
                answer = dns_over_https(question, self.route)
            if self.trace:
                print(f"DNS {name} {kind.name}: DoH rcode={answer.rcode()}", flush=True)
            if answer.rcode() == dns.rcode.NXDOMAIN:
                return bytes([3, 0])
            if answer.rcode() != dns.rcode.NOERROR:
                raise OSError("DoH lookup failed")
            rrset = answer.resolve_chaining().answer
            if rrset:
                records.extend(bytes([family]) + rr.to_wire() for rr in rrset)
        if len(records) > 64:
            raise ValueError("Too many records")
        return bytes([0, len(records)]) + b"".join(records)
