"""Local-only checks for the browser proxy; no saved configuration or internet."""
from contextlib import contextmanager
import ipaddress
import os
from pathlib import Path
import socket
import sys
import threading
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parent / "dns.zip"))
import browser_proxy


class FakeDNS:
    route = object()

    def __init__(self, addresses=("1.1.1.1",)):
        self.names = []
        self.addresses = addresses

    def resolve(self, name):
        self.names.append(name)
        rows = [ipaddress.ip_address(value) for value in self.addresses]
        return bytes([0, len(rows)]) + b"".join(bytes([row.version]) + row.packed for row in rows)


class FakeBox:
    def __init__(self, owner=True):
        self.owner = owner

    def pids(self):
        return [os.getpid()] if self.owner else []


def read_response(sock):
    payload = bytearray()
    while b"\r\n\r\n" not in payload:
        data = sock.recv(4096)
        if not data:
            break
        payload.extend(data)
    return bytes(payload)


@contextmanager
def client(server):
    with socket.socket() as sock:
        sock.settimeout(3)
        sock.connect(server.server_address)
        yield sock


@contextmanager
def running(box=None, dns=None):
    with browser_proxy.BrowserProxy(box or FakeBox(), dns or FakeDNS()) as server:
        thread = threading.Thread(target=server.serve_forever, daemon=True)
        thread.start()
        try:
            yield server
        finally:
            server.shutdown()
            thread.join(3)


class TargetTests(unittest.TestCase):
    def test_dns_and_ipv6_authorities(self):
        self.assertEqual(browser_proxy.connect_target(b"CONNECT EXAMPLE.COM.:443 HTTP/1.1\r\nHost: example.com"),
                         ("example.com", 443))
        self.assertEqual(browser_proxy.connect_target(b"CONNECT [2606:4700:4700::1111]:8443 HTTP/1.0"),
                         ("2606:4700:4700::1111", 8443))

    def test_malformed_authorities_and_body_headers(self):
        for target in (b"example.com", b"user:pass@example.com:443", b"example.com:0", b"example.com:65536",
                       b"[1.1.1.1]:443", b"[fe80::1%2]:443", b"https://example.com:443", b"a b:443"):
            with self.subTest(target=target), self.assertRaises(browser_proxy.RequestError):
                browser_proxy.connect_target(b"CONNECT " + target + b" HTTP/1.1")
        for header in (b"Transfer-Encoding: chunked", b"Content-Length: 2", b" Folded: bad", b"X: a\nb"):
            with self.subTest(header=header), self.assertRaises(browser_proxy.RequestError):
                browser_proxy.connect_target(b"CONNECT example.com:443 HTTP/1.1\r\n" + header)

    def test_public_address_filter(self):
        for address in ("127.0.0.1", "::1", "10.0.0.1", "192.168.1.1", "169.254.169.254", "224.0.0.1", "ff02::1"):
            with self.subTest(address=address):
                self.assertFalse(browser_proxy.public_address(ipaddress.ip_address(address)))
        self.assertTrue(browser_proxy.public_address(ipaddress.ip_address("1.1.1.1")))


@unittest.skipUnless(sys.platform == "win32", "Windows TCP ownership lookup")
class ListenerTests(unittest.TestCase):
    def test_owned_connect_uses_broker_and_never_forwards_headers(self):
        calls, received = [], []

        @contextmanager
        def session(route, address, port):
            calls.append((route, str(address), port))
            local, remote = socket.socketpair()
            with local, remote:
                remote.settimeout(3)

                def echo():
                    data = remote.recv(4096)
                    received.append(data)
                    remote.sendall(b"reply:" + data)
                    remote.shutdown(socket.SHUT_WR)

                thread = threading.Thread(target=echo, daemon=True)
                thread.start()
                yield local
                thread.join(3)

        dns = FakeDNS()
        with patch.object(browser_proxy, "session_tcp", session), running(dns=dns) as server, client(server) as sock:
            sock.sendall(b"CONNECT example.com:443 HTTP/1.1\r\nHost: example.com:443\r\n"
                         b"Proxy-Authorization: Basic dummy-secret\r\n\r\ntunnel-data")
            response = read_response(sock)
            self.assertTrue(response.startswith(b"HTTP/1.1 200 "), response)
            body = response.split(b"\r\n\r\n", 1)[1]
            while len(body) < len(b"reply:tunnel-data"):
                body += sock.recv(4096)
            self.assertEqual(body, b"reply:tunnel-data")
        self.assertEqual(dns.names, ["example.com"])
        self.assertEqual(calls, [(dns.route, "1.1.1.1", 443)])
        self.assertEqual(received, [b"tunnel-data"])

    def test_non_box_process_cannot_reach_dns_or_upstream(self):
        dns = FakeDNS()
        with patch.object(browser_proxy, "session_tcp") as session, running(FakeBox(False), dns) as server, client(server) as sock:
            try:
                sock.sendall(b"CONNECT example.com:443 HTTP/1.1\r\n\r\n")
                self.assertEqual(sock.recv(1024), b"")
            except (ConnectionResetError, ConnectionAbortedError):
                pass
        self.assertEqual(dns.names, [])
        session.assert_not_called()

    def test_plain_http_is_explicitly_unsupported(self):
        with patch.object(browser_proxy, "session_tcp") as session, running() as server, client(server) as sock:
            sock.sendall(b"GET http://example.com/ HTTP/1.1\r\nHost: example.com\r\n\r\n")
            self.assertTrue(read_response(sock).startswith(b"HTTP/1.1 405 "))
        session.assert_not_called()

    def test_private_dns_result_is_rejected(self):
        dns = FakeDNS(("127.0.0.1", "192.168.1.1", "::1"))
        with patch.object(browser_proxy, "session_tcp") as session, running(dns=dns) as server, client(server) as sock:
            sock.sendall(b"CONNECT example.com:443 HTTP/1.1\r\n\r\n")
            self.assertTrue(read_response(sock).startswith(b"HTTP/1.1 403 "))
        session.assert_not_called()

    def test_route_failure_returns_502_without_retrying_directly(self):
        dns = FakeDNS()
        with patch.object(browser_proxy, "session_tcp", side_effect=OSError("offline")) as session, running(dns=dns) as server, client(server) as sock:
            sock.sendall(b"CONNECT example.com:443 HTTP/1.1\r\n\r\n")
            self.assertTrue(read_response(sock).startswith(b"HTTP/1.1 502 "))
        self.assertEqual(session.call_count, 1)

    def test_dns_failure_returns_502_without_upstream(self):
        dns = FakeDNS()
        with patch.object(dns, "resolve", side_effect=browser_proxy.dns.exception.DNSException("offline")), \
                patch.object(browser_proxy, "session_tcp") as session, running(dns=dns) as server, client(server) as sock:
            sock.sendall(b"CONNECT example.com:443 HTTP/1.1\r\n\r\n")
            self.assertTrue(read_response(sock).startswith(b"HTTP/1.1 502 "))
        session.assert_not_called()

    def test_oversized_header_rejected_before_dns(self):
        dns = FakeDNS()
        with patch.object(browser_proxy, "session_tcp") as session, running(dns=dns) as server, client(server) as sock:
            sock.sendall(b"CONNECT example.com:443 HTTP/1.1\r\nX:" + b"x" * browser_proxy.MAX_HEADER)
            self.assertTrue(read_response(sock).startswith(b"HTTP/1.1 431 "))
        self.assertEqual(dns.names, [])
        session.assert_not_called()

    def test_shutdown_cuts_an_established_tunnel(self):
        entered, closed = threading.Event(), threading.Event()

        @contextmanager
        def session(route, address, port):
            local, remote = socket.socketpair()
            with local, remote:
                entered.set()
                try:
                    yield local
                finally:
                    closed.set()

        with patch.object(browser_proxy, "session_tcp", session), running() as server, client(server) as sock:
            sock.sendall(b"CONNECT 1.1.1.1:443 HTTP/1.1\r\n\r\n")
            self.assertTrue(read_response(sock).startswith(b"HTTP/1.1 200 "))
            self.assertTrue(entered.is_set())
            server.shutdown()
            self.assertEqual(sock.recv(1024), b"")
            self.assertTrue(closed.wait(2))


if __name__ == "__main__":
    unittest.main()
