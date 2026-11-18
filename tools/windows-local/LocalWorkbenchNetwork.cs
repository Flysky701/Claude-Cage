using System;
using System.Collections.Generic;
using System.IO;
using System.IO.Pipes;
using System.Net;
using System.Net.Sockets;
using System.Runtime.InteropServices;
using System.Security.Principal;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Win32.SafeHandles;

namespace CageLocalTool
{
    internal static partial class CageLocal
    {
        [DllImport("kernel32.dll", SetLastError = true)]
        private static extern bool GetNamedPipeServerProcessId(SafePipeHandle pipe, out uint processId);

        // Reserve the only WFP-permitted port before logging in the worker.
        // The controller keeps its proxy closed until the chosen route verifies.
        private sealed class WorkbenchAppNetwork : IDisposable
        {
            private readonly TcpListener listener;
            private readonly string pipeName;
            private readonly byte[] pipeKey;
            private readonly uint controllerPid;
            private readonly HashSet<TcpClient> clients = new HashSet<TcpClient>();
            private readonly Thread acceptThread;
            private readonly int brokerPort;
            private LocalWorkerSession session;
            private bool stopped;

            internal WorkbenchAppNetwork(LocalProfileModel profile)
            {
                pipeName = Environment.GetEnvironmentVariable("CAGE_LOCAL_APP_NETWORK_PIPE");
                string key = Environment.GetEnvironmentVariable("CAGE_LOCAL_APP_NETWORK_KEY");
                if (String.IsNullOrEmpty(pipeName) || !System.Text.RegularExpressions.Regex.IsMatch(pipeName, @"\ACage\.LocalEgress\.[a-f0-9]{64}\z") ||
                    String.IsNullOrEmpty(key) || !System.Text.RegularExpressions.Regex.IsMatch(key, @"\A[a-f0-9]{64}\z") ||
                    !UInt32.TryParse(Environment.GetEnvironmentVariable("CAGE_LOCAL_APP_NETWORK_PID"), out controllerPid))
                    pipeName = null;
                else
                    pipeKey = System.Text.Encoding.ASCII.GetBytes(key);
                brokerPort = profile.brokerPort;
                listener = new TcpListener(IPAddress.Loopback, brokerPort);
                listener.ExclusiveAddressUse = true;
                listener.Start(64);
                acceptThread = new Thread(Accept) { IsBackground = true };
                acceptThread.Start();
            }

            internal IDisposable Attach(LocalWorkerSession worker)
            {
                lock (clients) session = worker;
                return new Binding(this);
            }

            // The worker is disposed between the binding and the listener.
            // Keep the reserved port throughout job termination.
            private sealed class Binding : IDisposable
            {
                private readonly WorkbenchAppNetwork owner;
                internal Binding(WorkbenchAppNetwork owner) { this.owner = owner; }
                public void Dispose() { owner.Detach(); }
            }

            private void Detach()
            {
                TcpClient[] open;
                lock (clients)
                {
                    session = null;
                    open = new TcpClient[clients.Count];
                    clients.CopyTo(open);
                }
                foreach (TcpClient client in open) client.Close();
            }

            private void Accept()
            {
                while (true)
                {
                    TcpClient client;
                    try { client = listener.AcceptTcpClient(); }
                    catch (SocketException) { return; }
                    catch (ObjectDisposedException) { return; }
                    try
                    {
                        IPEndPoint peer = client.Client.RemoteEndPoint as IPEndPoint;
                        int pid = peer == null || !IPAddress.IsLoopback(peer.Address) ? 0 :
                            LookupLoopbackClientPid(peer.Port, brokerPort);
                        lock (clients)
                        {
                            if (stopped || clients.Count >= 64 || session == null || pid <= 0 || !session.OwnsPid(pid))
                            {
                                client.Close();
                                continue;
                            }
                            clients.Add(client);
                        }
                        Relay(client);
                    }
                    catch { client.Close(); }
                }
            }

            // The account never learns an upstream address or proxy credential.
            // The controller-owned pipe also excludes network logons and worker SIDs.
            private async void Relay(TcpClient client)
            {
                try
                {
                    if (pipeName == null) return;
                    using (NetworkStream socket = client.GetStream())
                    using (NamedPipeClientStream pipe = new NamedPipeClientStream(".", pipeName, PipeDirection.InOut,
                        PipeOptions.Asynchronous, TokenImpersonationLevel.Identification))
                    {
                        await pipe.ConnectAsync(2500).ConfigureAwait(false);
                        uint pid;
                        if (!GetNamedPipeServerProcessId(pipe.SafePipeHandle, out pid) || pid != controllerPid) return;
                        await pipe.WriteAsync(pipeKey, 0, pipeKey.Length).ConfigureAwait(false);
                        Task upload = socket.CopyToAsync(pipe);
                        Task download = pipe.CopyToAsync(socket);
                        await Task.WhenAny(upload, download).ConfigureAwait(false);
                        client.Close();
                        pipe.Close();
                        await Task.WhenAll(upload, download).ConfigureAwait(false);
                    }
                }
                catch (Exception) { /* EOF, cancellation and expired routes all close this client. */ }
                finally
                {
                    lock (clients) clients.Remove(client);
                    client.Close();
                }
            }

            public void Dispose()
            {
                lock (clients)
                {
                    if (stopped) return;
                    stopped = true;
                }
                Detach();
                listener.Stop();
                acceptThread.Join();
            }
        }
    }
}
