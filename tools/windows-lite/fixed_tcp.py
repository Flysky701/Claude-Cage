"""Fixed TCP service endpoints for applications that can select a server and port."""
import ctypes
import ipaddress
import re
import select
import socket
import socketserver
import struct
import subprocess
import threading
from contextlib import ExitStack
from ctypes import wintypes

from broker import session_tcp


def service_specs(value):
    if not isinstance(value, dict):
        raise ValueError("tcpServices 必须是以服务名为键的对象")
    result = {}
    for name, entry in value.items():
        if not re.fullmatch(r"[A-Za-z0-9_-]{1,48}", name) or not isinstance(entry, dict):
            raise ValueError("无效的 TCP 服务名或配置")
        host, port = entry.get("host"), entry.get("port")
        listen_port = entry.get("listenPort", 0)
        if type(port) is not int or not 1 <= port <= 65535:
            raise ValueError(f"{name} 的目标端口无效")
        if type(listen_port) is not int or not 0 <= listen_port <= 65535:
            raise ValueError(f"{name} 的监听端口无效")
        if not isinstance(host, str):
            raise ValueError(f"{name} 缺少目标地址")
        try:
            host = str(ipaddress.ip_address(host))
        except ValueError:
            host = host.rstrip(".").encode("idna").decode("ascii").lower()
            if len(host) > 253 or not all(re.fullmatch(r"(?!-)[a-z0-9-]{1,63}(?<!-)", p)
                                          for p in host.split(".")):
                raise ValueError(f"{name} 的目标域名无效")
        result[name] = (host, port, listen_port)
    return result


def loopback_client_pid(source, listener):
    """Look up the client side of this specific accepted IPv4 TCP connection."""
    get_table = ctypes.WinDLL("iphlpapi").GetExtendedTcpTable
    get_table.argtypes = [ctypes.c_void_p, ctypes.POINTER(wintypes.DWORD), wintypes.BOOL,
                          wintypes.ULONG, ctypes.c_int, wintypes.ULONG]
    size = wintypes.DWORD(0)
    table = None
    for _ in range(4):
        error = get_table(table, ctypes.byref(size), False, socket.AF_INET, 4, 0)
        if error == 0 and table is not None:
            break
        if error != 122:  # ERROR_INSUFFICIENT_BUFFER
            return None
        table = ctypes.create_string_buffer(size.value)
    else:
        return None
    data = memoryview(table).cast("B")
    count, = struct.unpack_from("<I", data)
    for state, src, sport, dst, dport, pid in struct.iter_unpack("<I4sI4sII", data[4:4+24*count]):
        if (src == dst == b"\x7f\x00\x00\x01" and socket.ntohs(sport & 0xffff) == source
                and socket.ntohs(dport & 0xffff) == listener):
            return pid
    return None


def target_addresses(dns, host):
    try:
        yield ipaddress.ip_address(host)
        return
    except ValueError:
        pass
    response = dns.resolve(host)
    if response[0] != 0:
        raise OSError("服务域名未能通过指定代理解析")
    index = 2
    for _ in range(response[1]):
        size = {4: 4, 6: 16}[response[index]]
        yield ipaddress.ip_address(response[index+1:index+1+size])
        index += 1 + size


class FixedStream(socketserver.BaseRequestHandler):
    def handle(self):
        server = self.server
        try:
            owner = loopback_client_pid(self.client_address[1], server.server_address[1])
            if not owner or owner not in server.box.pids():
                return
            with ExitStack() as stack:
                for address in target_addresses(server.dns, server.host):
                    try:
                        upstream = stack.enter_context(session_tcp(server.dns.route, address, server.port))
                        break
                    except (OSError, EOFError):
                        continue
                else:
                    return
                upstream.settimeout(None)
                peers = {self.request: upstream, upstream: self.request}
                while peers and not server.stopping.is_set():
                    ready, _, _ = select.select(list(peers), [], [], 1)
                    for sock in ready:
                        payload = sock.recv(65536)
                        if payload:
                            peers[sock].sendall(payload)
                        else:
                            peers.pop(sock).shutdown(socket.SHUT_WR)
        except (OSError, EOFError, ValueError, KeyError, RuntimeError, subprocess.SubprocessError):
            # Closing the client connection is the sole failure path. Never dial the target directly.
            return


class FixedService(socketserver.ThreadingTCPServer):
    daemon_threads = True

    def __init__(self, box, dns, spec):
        self.box, self.dns = box, dns
        self.host, self.port, listen = spec
        self.stopping = threading.Event()
        super().__init__(("127.0.0.1", listen), FixedStream)

    def server_bind(self):
        self.socket.setsockopt(socket.SOL_SOCKET, socket.SO_EXCLUSIVEADDRUSE, 1)
        super().server_bind()

    def shutdown(self):
        self.stopping.set()
        super().shutdown()
