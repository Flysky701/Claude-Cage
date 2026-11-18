using System;
using System.Collections.Generic;
using System.IO;
using System.Net;
using System.Net.Sockets;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;

namespace CageLocalTool
{
    internal static partial class CageLocal
    {
        private const int AfInet = 2;
        private const int TcpTableOwnerPidConnections = 4;

        [DllImport("iphlpapi.dll", SetLastError = true)]
        private static extern uint GetExtendedTcpTable(
            IntPtr pTcpTable,
            ref int pdwSize,
            bool bOrder,
            int ulAf,
            int TableClass,
            uint Reserved);

        [StructLayout(LayoutKind.Sequential)]
        private struct MibTcpRowOwnerPid
        {
            public uint dwState;
            public uint dwLocalAddr;
            public uint dwLocalPort;
            public uint dwRemoteAddr;
            public uint dwRemotePort;
            public uint dwOwningPid;
        }

        internal static int NetworkPortToHost(uint rawPort)
        {
            int low = (int)(rawPort & 0xFFFFu);
            return ((low & 0xFF) << 8) | ((low >> 8) & 0xFF);
        }

        internal static int LookupLoopbackClientPid(int clientPort, int serverPort)
        {
            const uint loopbackNetOrder = 0x0100007Fu;
            int size = 0;
            uint rc = GetExtendedTcpTable(IntPtr.Zero, ref size, false, AfInet, TcpTableOwnerPidConnections, 0);
            if (rc != 122 /* ERROR_INSUFFICIENT_BUFFER */ && rc != 0)
            {
                return 0;
            }
            if (size < 4)
            {
                return 0;
            }
            IntPtr buffer = Marshal.AllocHGlobal(size);
            try
            {
                rc = GetExtendedTcpTable(buffer, ref size, false, AfInet, TcpTableOwnerPidConnections, 0);
                if (rc != 0)
                {
                    return 0;
                }
                int count = Marshal.ReadInt32(buffer);
                int rowSize = Marshal.SizeOf(typeof(MibTcpRowOwnerPid));
                IntPtr rowPtr = IntPtr.Add(buffer, 4);
                for (int i = 0; i < count; i++)
                {
                    MibTcpRowOwnerPid row = (MibTcpRowOwnerPid)Marshal.PtrToStructure(rowPtr, typeof(MibTcpRowOwnerPid));
                    if (row.dwLocalAddr == loopbackNetOrder &&
                        row.dwRemoteAddr == loopbackNetOrder &&
                        NetworkPortToHost(row.dwLocalPort) == clientPort &&
                        NetworkPortToHost(row.dwRemotePort) == serverPort)
                    {
                        return unchecked((int)row.dwOwningPid);
                    }
                    rowPtr = IntPtr.Add(rowPtr, rowSize);
                }
                return 0;
            }
            finally
            {
                Marshal.FreeHGlobal(buffer);
            }
        }

        internal sealed class LocalProxyBroker : IDisposable
        {
            private readonly TcpListener listener;
            private readonly Func<int, bool> callerPidAllowed;
            private readonly Dictionary<string, IPEndPoint> syntheticTargets;
            private readonly object gateLock = new object();
            private readonly List<Socket> activeSockets = new List<Socket>();
            private readonly Thread acceptThread;
            private volatile bool stopping;
            private volatile bool gateOpen = true;

            private int acceptedCount;
            private int rejectedCallerCount;
            private int blockedByGateCount;
            private int proxiedRequestCount;
            private int deniedDestinationCount;

            internal int Port
            {
                get { return ((IPEndPoint)listener.LocalEndpoint).Port; }
            }

            internal LocalProxyBroker(
                int listenPort,
                Func<int, bool> callerPidValidator,
                Dictionary<string, IPEndPoint> syntheticTargetMap)
            {
                callerPidAllowed = callerPidValidator;
                syntheticTargets = new Dictionary<string, IPEndPoint>(StringComparer.OrdinalIgnoreCase);
                if (syntheticTargetMap != null)
                {
                    foreach (KeyValuePair<string, IPEndPoint> kv in syntheticTargetMap)
                    {
                        syntheticTargets[kv.Key] = kv.Value;
                    }
                }
                listener = new TcpListener(IPAddress.Loopback, listenPort);
                listener.Start(64);
                acceptThread = new Thread(AcceptLoop);
                acceptThread.IsBackground = true;
                acceptThread.Start();
            }

            internal void SetGateOpen(bool open)
            {
                gateOpen = open;
                if (!open)
                {
                    CloseActiveSockets();
                }
            }

            internal Dictionary<string, object> StatsSnapshot()
            {
                Dictionary<string, object> stats = new Dictionary<string, object>();
                stats["port"] = Port;
                stats["gateOpen"] = gateOpen;
                stats["acceptedCount"] = Thread.VolatileRead(ref acceptedCount);
                stats["rejectedCallerCount"] = Thread.VolatileRead(ref rejectedCallerCount);
                stats["blockedByGateCount"] = Thread.VolatileRead(ref blockedByGateCount);
                stats["proxiedRequestCount"] = Thread.VolatileRead(ref proxiedRequestCount);
                stats["deniedDestinationCount"] = Thread.VolatileRead(ref deniedDestinationCount);
                return stats;
            }

            private void TrackSocket(Socket s)
            {
                lock (gateLock)
                {
                    activeSockets.Add(s);
                }
            }

            private void UntrackSocket(Socket s)
            {
                lock (gateLock)
                {
                    activeSockets.Remove(s);
                }
            }

            private void CloseActiveSockets()
            {
                Socket[] snapshot;
                lock (gateLock)
                {
                    snapshot = activeSockets.ToArray();
                    activeSockets.Clear();
                }
                for (int i = 0; i < snapshot.Length; i++)
                {
                    try { snapshot[i].Close(); } catch { }
                }
            }

            private void AcceptLoop()
            {
                while (!stopping)
                {
                    TcpClient client = null;
                    try
                    {
                        client = listener.AcceptTcpClient();
                    }
                    catch (SocketException)
                    {
                        if (stopping)
                        {
                            break;
                        }
                        continue;
                    }
                    catch (ObjectDisposedException)
                    {
                        break;
                    }
                    TcpClient captured = client;
                    ThreadPool.QueueUserWorkItem(delegate { HandleClient(captured); });
                }
            }

            private void HandleClient(TcpClient client)
            {
                Socket clientSock = client.Client;
                TrackSocket(clientSock);
                Socket upstreamSock = null;
                try
                {
                    client.ReceiveTimeout = 8000;
                    client.SendTimeout = 8000;
                    IPEndPoint remote = clientSock.RemoteEndPoint as IPEndPoint;
                    if (remote == null || !IPAddress.IsLoopback(remote.Address))
                    {
                        Interlocked.Increment(ref rejectedCallerCount);
                        return;
                    }
                    int ownerPid = LookupLoopbackClientPid(remote.Port, Port);
                    if (ownerPid <= 0 || callerPidAllowed == null || !callerPidAllowed(ownerPid))
                    {
                        // Close immediately before reading any bytes from untrusted host callers.
                        Interlocked.Increment(ref rejectedCallerCount);
                        return;
                    }
                    Interlocked.Increment(ref acceptedCount);

                    byte[] headBytes;
                    byte[] trailingBytes;
                    if (!ReadHttpHead(clientSock, out headBytes, out trailingBytes))
                    {
                        return;
                    }

                    if (!gateOpen)
                    {
                        Interlocked.Increment(ref blockedByGateCount);
                        SendSimpleHttpReply(clientSock, 503, "Proxy Gate Closed", "CAGE_PROXY_GATE_CLOSED\n");
                        return;
                    }

                    string headText = Encoding.ASCII.GetString(headBytes);
                    string[] lines = headText.Split(new string[] { "\r\n" }, StringSplitOptions.None);
                    if (lines.Length == 0)
                    {
                        SendSimpleHttpReply(clientSock, 400, "Bad Request", "Bad Request\n");
                        return;
                    }
                    string[] parts = lines[0].Split(' ');
                    if (parts.Length != 3 || !parts[2].StartsWith("HTTP/1.", StringComparison.Ordinal))
                    {
                        SendSimpleHttpReply(clientSock, 400, "Bad Request", "Bad Request\n");
                        return;
                    }

                    string method = parts[0].ToUpperInvariant();
                    string target = parts[1];

                    if (method == "CONNECT")
                    {
                        HandleConnect(clientSock, target, trailingBytes, out upstreamSock);
                    }
                    else
                    {
                        HandleHttpForward(clientSock, method, target, parts[2], lines, trailingBytes, out upstreamSock);
                    }
                }
                catch
                {
                }
                finally
                {
                    UntrackSocket(clientSock);
                    try { client.Close(); } catch { }
                    if (upstreamSock != null)
                    {
                        UntrackSocket(upstreamSock);
                        try { upstreamSock.Close(); } catch { }
                    }
                }
            }

            private void HandleConnect(Socket clientSock, string authority, byte[] trailingBytes, out Socket upstreamSock)
            {
                upstreamSock = null;
                IPEndPoint upstreamEndPoint;
                if (!syntheticTargets.TryGetValue(authority, out upstreamEndPoint))
                {
                    Interlocked.Increment(ref deniedDestinationCount);
                    SendSimpleHttpReply(clientSock, 403, "Forbidden", "Destination not allowed in offline broker\n");
                    return;
                }
                if (!gateOpen)
                {
                    Interlocked.Increment(ref blockedByGateCount);
                    SendSimpleHttpReply(clientSock, 503, "Proxy Gate Closed", "CAGE_PROXY_GATE_CLOSED\n");
                    return;
                }

                upstreamSock = new Socket(AddressFamily.InterNetwork, SocketType.Stream, ProtocolType.Tcp);
                upstreamSock.ReceiveTimeout = 8000;
                upstreamSock.SendTimeout = 8000;
                upstreamSock.Connect(upstreamEndPoint);
                TrackSocket(upstreamSock);
                Interlocked.Increment(ref proxiedRequestCount);

                byte[] established = Encoding.ASCII.GetBytes("HTTP/1.1 200 Connection Established\r\n\r\n");
                SendAll(clientSock, established, 0, established.Length);
                if (trailingBytes != null && trailingBytes.Length > 0)
                {
                    SendAll(upstreamSock, trailingBytes, 0, trailingBytes.Length);
                }
                PumpBidirectional(clientSock, upstreamSock);
            }

            private void HandleHttpForward(
                Socket clientSock,
                string method,
                string rawUri,
                string httpVersion,
                string[] headerLines,
                byte[] trailingBytes,
                out Socket upstreamSock)
            {
                upstreamSock = null;
                Uri parsed;
                if (!Uri.TryCreate(rawUri, UriKind.Absolute, out parsed) || !string.Equals(parsed.Scheme, "http", StringComparison.OrdinalIgnoreCase))
                {
                    Interlocked.Increment(ref deniedDestinationCount);
                    SendSimpleHttpReply(clientSock, 400, "Bad Request", "Expected absolute http:// proxy URI\n");
                    return;
                }
                int port = parsed.Port > 0 ? parsed.Port : 80;
                string authority = string.Format("{0}:{1}", parsed.Host, port);
                IPEndPoint upstreamEndPoint;
                if (!syntheticTargets.TryGetValue(authority, out upstreamEndPoint))
                {
                    Interlocked.Increment(ref deniedDestinationCount);
                    SendSimpleHttpReply(clientSock, 403, "Forbidden", "Destination not allowed in offline broker\n");
                    return;
                }
                if (!gateOpen)
                {
                    Interlocked.Increment(ref blockedByGateCount);
                    SendSimpleHttpReply(clientSock, 503, "Proxy Gate Closed", "CAGE_PROXY_GATE_CLOSED\n");
                    return;
                }

                StringBuilder sb = new StringBuilder();
                sb.Append(method).Append(' ').Append(parsed.PathAndQuery).Append(' ').Append(httpVersion).Append("\r\n");
                for (int i = 1; i < headerLines.Length; i++)
                {
                    string line = headerLines[i];
                    if (string.IsNullOrEmpty(line))
                    {
                        continue;
                    }
                    if (line.StartsWith("Proxy-Connection:", StringComparison.OrdinalIgnoreCase) ||
                        line.StartsWith("Connection:", StringComparison.OrdinalIgnoreCase))
                    {
                        continue;
                    }
                    sb.Append(line).Append("\r\n");
                }
                sb.Append("Connection: close\r\n\r\n");
                byte[] forwardedHead = Encoding.ASCII.GetBytes(sb.ToString());

                upstreamSock = new Socket(AddressFamily.InterNetwork, SocketType.Stream, ProtocolType.Tcp);
                upstreamSock.ReceiveTimeout = 8000;
                upstreamSock.SendTimeout = 8000;
                upstreamSock.Connect(upstreamEndPoint);
                TrackSocket(upstreamSock);
                Interlocked.Increment(ref proxiedRequestCount);

                SendAll(upstreamSock, forwardedHead, 0, forwardedHead.Length);
                if (trailingBytes != null && trailingBytes.Length > 0)
                {
                    SendAll(upstreamSock, trailingBytes, 0, trailingBytes.Length);
                }
                PumpBidirectional(clientSock, upstreamSock);
            }

            private void PumpBidirectional(Socket a, Socket b)
            {
                ManualResetEvent done = new ManualResetEvent(false);
                int remaining = 2;
                WaitCallback pumpOne = delegate(object state)
                {
                    Socket[] pair = (Socket[])state;
                    Socket src = pair[0];
                    Socket dst = pair[1];
                    byte[] buf = new byte[32768];
                    try
                    {
                        while (!stopping && gateOpen)
                        {
                            int n = src.Receive(buf);
                            if (n <= 0)
                            {
                                break;
                            }
                            SendAll(dst, buf, 0, n);
                        }
                        try { dst.Shutdown(SocketShutdown.Send); } catch { }
                    }
                    catch
                    {
                    }
                    finally
                    {
                        if (Interlocked.Decrement(ref remaining) == 0)
                        {
                            try { done.Set(); } catch { }
                        }
                    }
                };
                ThreadPool.QueueUserWorkItem(pumpOne, new Socket[] { a, b });
                ThreadPool.QueueUserWorkItem(pumpOne, new Socket[] { b, a });
                done.WaitOne(15000);
                done.Close();
            }

            private static bool ReadHttpHead(Socket sock, out byte[] head, out byte[] trailing)
            {
                head = null;
                trailing = null;
                byte[] buffer = new byte[16384];
                int total = 0;
                while (total < buffer.Length)
                {
                    int n = sock.Receive(buffer, total, buffer.Length - total, SocketFlags.None);
                    if (n <= 0)
                    {
                        return false;
                    }
                    total += n;
                    for (int i = 0; i <= total - 4; i++)
                    {
                        if (buffer[i] == '\r' && buffer[i + 1] == '\n' && buffer[i + 2] == '\r' && buffer[i + 3] == '\n')
                        {
                            head = new byte[i];
                            Array.Copy(buffer, 0, head, 0, i);
                            int rem = total - (i + 4);
                            trailing = new byte[rem];
                            if (rem > 0)
                            {
                                Array.Copy(buffer, i + 4, trailing, 0, rem);
                            }
                            return true;
                        }
                    }
                }
                return false;
            }

            private static void SendAll(Socket sock, byte[] data, int offset, int length)
            {
                int sent = 0;
                while (sent < length)
                {
                    int n = sock.Send(data, offset + sent, length - sent, SocketFlags.None);
                    if (n <= 0)
                    {
                        throw new SocketException();
                    }
                    sent += n;
                }
            }

            private static void SendSimpleHttpReply(Socket sock, int code, string reason, string body)
            {
                byte[] bodyBytes = Utf8NoBom.GetBytes(body);
                string header = string.Format(
                    "HTTP/1.1 {0} {1}\r\nConnection: close\r\nContent-Type: text/plain; charset=utf-8\r\nContent-Length: {2}\r\n\r\n",
                    code,
                    reason,
                    bodyBytes.Length);
                byte[] headerBytes = Encoding.ASCII.GetBytes(header);
                try
                {
                    SendAll(sock, headerBytes, 0, headerBytes.Length);
                    SendAll(sock, bodyBytes, 0, bodyBytes.Length);
                    try { sock.Shutdown(SocketShutdown.Send); } catch { }
                }
                catch
                {
                }
            }

            public void Dispose()
            {
                stopping = true;
                gateOpen = false;
                try { listener.Stop(); } catch { }
                CloseActiveSockets();
            }
        }

        internal sealed class SyntheticOriginServer : IDisposable
        {
            private readonly TcpListener httpListener;
            private readonly TcpListener tunnelListener;
            private readonly Thread httpThread;
            private readonly Thread tunnelThread;
            private volatile bool stopping;

            internal int HttpPort { get { return ((IPEndPoint)httpListener.LocalEndpoint).Port; } }
            internal int TunnelPort { get { return ((IPEndPoint)tunnelListener.LocalEndpoint).Port; } }

            internal SyntheticOriginServer()
            {
                httpListener = new TcpListener(IPAddress.Loopback, 0);
                httpListener.Start(16);
                tunnelListener = new TcpListener(IPAddress.Loopback, 0);
                tunnelListener.Start(16);

                httpThread = new Thread(RunHttp);
                httpThread.IsBackground = true;
                httpThread.Start();

                tunnelThread = new Thread(RunTunnel);
                tunnelThread.IsBackground = true;
                tunnelThread.Start();
            }

            private void RunHttp()
            {
                while (!stopping)
                {
                    TcpClient client;
                    try { client = httpListener.AcceptTcpClient(); }
                    catch { break; }
                    TcpClient captured = client;
                    ThreadPool.QueueUserWorkItem(delegate { HandleHttpClient(captured); });
                }
            }

            private static void HandleHttpClient(TcpClient client)
            {
                try
                {
                    using (client)
                    using (NetworkStream stream = client.GetStream())
                    {
                        client.ReceiveTimeout = 5000;
                        byte[] buf = new byte[8192];
                        int total = 0;
                        while (total < buf.Length)
                        {
                            int n = stream.Read(buf, total, buf.Length - total);
                            if (n <= 0) break;
                            total += n;
                            string soFar = Encoding.ASCII.GetString(buf, 0, total);
                            if (soFar.Contains("\r\n\r\n")) break;
                        }
                        string req = total > 0 ? Encoding.ASCII.GetString(buf, 0, total) : "";
                        string body;
                        string contentType;
                        if (req.StartsWith("GET /probe.html ", StringComparison.Ordinal))
                        {
                            contentType = "text/html; charset=utf-8";
                            body = "<!doctype html><html><head><meta charset=\"utf-8\"><title>CageLocal Edge Probe</title></head><body>" +
                                   "<div id=\"out\"></div><script>" +
                                   "var tz = Intl.DateTimeFormat().resolvedOptions().timeZone;" +
                                   "document.getElementById('out').textContent = 'CAGE_LOCAL_EDGE_PROXY_OK|TZ=' + tz;" +
                                   "</script></body></html>";
                        }
                        else
                        {
                            contentType = "text/plain; charset=utf-8";
                            body = "CAGE_LOCAL_HTTP_ORIGIN_OK\n";
                        }
                        byte[] bodyBytes = Utf8NoBom.GetBytes(body);
                        string resp = string.Format(
                            "HTTP/1.1 200 OK\r\nContent-Type: {0}\r\nContent-Length: {1}\r\nConnection: close\r\n\r\n",
                            contentType,
                            bodyBytes.Length);
                        byte[] headBytes = Encoding.ASCII.GetBytes(resp);
                        stream.Write(headBytes, 0, headBytes.Length);
                        stream.Write(bodyBytes, 0, bodyBytes.Length);
                        stream.Flush();
                        try { client.Client.Shutdown(SocketShutdown.Send); } catch { }
                    }
                }
                catch
                {
                }
            }

            private void RunTunnel()
            {
                while (!stopping)
                {
                    TcpClient client;
                    try { client = tunnelListener.AcceptTcpClient(); }
                    catch { break; }
                    TcpClient captured = client;
                    ThreadPool.QueueUserWorkItem(delegate { HandleTunnelClient(captured); });
                }
            }

            private static void HandleTunnelClient(TcpClient client)
            {
                try
                {
                    using (client)
                    using (NetworkStream stream = client.GetStream())
                    {
                        client.ReceiveTimeout = 5000;
                        byte[] buf = new byte[1024];
                        int n = stream.Read(buf, 0, buf.Length);
                        string incoming = n > 0 ? Utf8NoBom.GetString(buf, 0, n) : "";
                        byte[] reply = Utf8NoBom.GetBytes("CAGE_TUNNEL_OK:" + incoming);
                        stream.Write(reply, 0, reply.Length);
                        stream.Flush();
                    }
                }
                catch
                {
                }
            }

            public void Dispose()
            {
                stopping = true;
                try { httpListener.Stop(); } catch { }
                try { tunnelListener.Stop(); } catch { }
            }
        }
    }
}
