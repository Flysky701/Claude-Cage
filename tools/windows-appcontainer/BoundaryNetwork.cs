// Temporary package-scoped WFP experiment. Never applies an account-wide rule.
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.IO;
using System.Linq;
using System.Net;
using System.Net.Sockets;
using System.Runtime.InteropServices;
using System.Security.Principal;
using System.Text;
using System.Threading;
using System.Threading.Tasks;

internal static partial class BoundaryProbe {
    // Layouts and package condition mirror RemoteNetworkPolicy/RemoteBrokerPolicy.
    sealed unsafe class TestNetwork : IDisposable {
        [StructLayout(LayoutKind.Sequential,CharSet=CharSet.Unicode)] struct Display { public string Name,Description; }
        [StructLayout(LayoutKind.Sequential)] struct Blob { public uint Size; public IntPtr Data; }
        [StructLayout(LayoutKind.Sequential)] struct Value { public uint Type; public ulong Data; }
        [StructLayout(LayoutKind.Sequential)] struct Condition { public Guid Field; public uint Match; public Value Value; }
        [StructLayout(LayoutKind.Sequential)] struct ActionValue { public uint Type; public Guid Key; }
        [StructLayout(LayoutKind.Explicit,Size=16)] struct Context { [FieldOffset(0)] public ulong Raw; }
        [StructLayout(LayoutKind.Sequential)] struct Sublayer { public Guid Key; public Display Display; public uint Flags; public IntPtr Provider; public Blob Data; public ushort Weight; }
        [StructLayout(LayoutKind.Sequential)] struct Filter {
            public Guid Key; public Display Display; public uint Flags; public IntPtr Provider; public Blob Data;
            public Guid Layer,Sublayer; public Value Weight; public uint Count; public IntPtr Conditions;
            public ActionValue Action; public Context Context; public IntPtr Reserved; public ulong ID; public Value EffectiveWeight;
        }
        [StructLayout(LayoutKind.Sequential)] struct WfpSession {
            public Guid Key; public Display Display; public uint Flags,Timeout,Process; public IntPtr Sid;
            [MarshalAs(UnmanagedType.LPWStr)] public string Username; [MarshalAs(UnmanagedType.Bool)] public bool Kernel;
        }
        [StructLayout(LayoutKind.Sequential)] struct SidEntry { public IntPtr SID; public uint Attributes; }
        [DllImport("fwpuclnt.dll",CharSet=CharSet.Unicode)] static extern uint FwpmEngineOpen0(string server,uint auth,IntPtr identity,ref WfpSession session,out IntPtr engine);
        [DllImport("fwpuclnt.dll")] static extern uint FwpmEngineClose0(IntPtr engine);
        [DllImport("fwpuclnt.dll")] static extern uint FwpmSubLayerAdd0(IntPtr engine,ref Sublayer value,IntPtr sd);
        [DllImport("fwpuclnt.dll")] static extern uint FwpmFilterAdd0(IntPtr engine,ref Filter value,IntPtr sd,out ulong id);
        [DllImport("fwpuclnt.dll")] static extern uint FwpmFilterDeleteById0(IntPtr engine,ulong id);
        [DllImport("fwpuclnt.dll")] static extern uint FwpmFilterGetById0(IntPtr engine,ulong id,out IntPtr filter);
        [DllImport("fwpuclnt.dll")] static extern void FwpmFreeMemory0(ref IntPtr value);
        [DllImport("FirewallAPI.dll")] static extern uint NetworkIsolationGetAppContainerConfig(out uint count,out IntPtr entries);
        [DllImport("FirewallAPI.dll")] static extern uint NetworkIsolationSetAppContainerConfig(uint count,IntPtr entries);
        [DllImport("kernel32.dll")] static extern IntPtr GetProcessHeap();
        [DllImport("kernel32.dll")] static extern bool HeapFree(IntPtr heap,uint flags,IntPtr value);
        static readonly Guid Package=new Guid("71bc78fa-f17c-4997-a602-6abb261f351c");
        static readonly Guid Address=new Guid("b235ae9a-1d64-49b8-a44c-5ff3d9095045");
        static readonly Guid Port=new Guid("c35a604d-d22b-4e1a-91b4-68f674ee674b");
        static readonly Guid Protocol=new Guid("3971ef2b-623e-4f9a-8cb1-6e79b806b9a7");
        static readonly Guid Connect4=new Guid("c38d57d1-05a7-4c33-904f-7fbceee60e82");
        static readonly Guid Connect6=new Guid("4a72393b-319f-44bc-84c3-ba54dcb3b6b4");
        static readonly Guid Receive4=new Guid("e1cd9fe7-f4b5-4273-96c0-592e487b8650");
        static readonly Guid Receive6=new Guid("a3b42c97-9f04-4672-b87e-cee9c483257f");
        static void CheckError(uint code) { if(code!=0)throw new Win32Exception(unchecked((int)code)); }
        IntPtr engine,package; Guid sublayer; ulong permit; bool exceptionAdded;
        internal bool LoopbackRemoved,EngineClosed; internal int VerifiedFilters;

        internal TestNetwork(IntPtr sid,int port) {
            if(!new WindowsPrincipal(WindowsIdentity.GetCurrent()).IsInRole(WindowsBuiltInRole.Administrator))
                throw new InvalidOperationException("This temporary package-only WFP test requires Windows administrator consent.");
            package=sid;sublayer=Guid.NewGuid();
            try {
                var session=new WfpSession { Key=Guid.NewGuid(),Display=new Display{Name="Cage temporary package network test"},Flags=1 };
                CheckError(FwpmEngineOpen0(null,10,IntPtr.Zero,ref session,out engine)); // FWPM_SESSION_FLAG_DYNAMIC
                var layer=new Sublayer{Key=sublayer,Display=new Display{Name="Cage temporary package only"},Weight=0x8000};
                CheckError(FwpmSubLayerAdd0(engine,ref layer,IntPtr.Zero));
                var onlyPackage=new[]{new Condition{Field=Package,Value=new Value{Type=13,Data=(ulong)package}}};
                foreach(Guid direction in new[]{Connect4,Connect6,Receive4,Receive6}) Add(direction,onlyPackage,false);
                foreach(Guid bind in new[]{new Guid("1247d66d-0b60-4a15-8d44-7155d0f53a0c"),new Guid("55a650e1-5f0a-4eca-a653-88f53b26aa8c")})
                    Add(bind,onlyPackage.Concat(new[]{new Condition{Field=Protocol,Value=new Value{Type=1,Data=17}}}).ToArray(),false);
                permit=Add(Connect4,onlyPackage.Concat(new[]{
                    new Condition{Field=Address,Value=new Value{Type=3,Data=0x7f000001}},
                    new Condition{Field=Port,Value=new Value{Type=2,Data=(ulong)port}},
                    new Condition{Field=Protocol,Value=new Value{Type=1,Data=6}}
                }).ToArray(),true);
                // All filters are installed and read back before allowing loopback.
                exceptionAdded=true; SetLoopback(true);
            } catch { Dispose(); throw; }
        }
        ulong Add(Guid layer,Condition[] conditions,bool allowed) {
            ulong weight=allowed?ulong.MaxValue:ulong.MaxValue-1,id;
            fixed(Condition* data=conditions) {
                var filter=new Filter{Key=Guid.NewGuid(),Display=new Display{Name="Cage test package rule"},Layer=layer,Sublayer=sublayer,
                    Weight=new Value{Type=4,Data=(ulong)&weight},Count=(uint)conditions.Length,Conditions=(IntPtr)data,
                    Action=new ActionValue{Type=allowed?0x1002u:0x1001u}};
                CheckError(FwpmFilterAdd0(engine,ref filter,IntPtr.Zero,out id));
                IntPtr actual;CheckError(FwpmFilterGetById0(engine,id,out actual));
                try {
                    var copy=(Filter)Marshal.PtrToStructure(actual,typeof(Filter));
                    if(copy.Key!=filter.Key || copy.Layer!=layer || copy.Sublayer!=sublayer || copy.Count!=conditions.Length || copy.Action.Type!=filter.Action.Type ||
                       (copy.Flags & ~0x40u)!=0 || copy.Weight.Type!=4 || copy.Weight.Data==0 || *(ulong*)copy.Weight.Data!=weight)
                        throw new InvalidDataException("Temporary package filter readback mismatch");
                    for(int i=0;i<conditions.Length;i++) {
                        var found=((Condition*)copy.Conditions)[i];var expected=conditions[i];
                        if(found.Field!=expected.Field || found.Match!=0 || found.Value.Type!=expected.Value.Type ||
                           (found.Field==Package?!new SecurityIdentifier((IntPtr)found.Value.Data).Equals(new SecurityIdentifier(package)):found.Value.Data!=expected.Value.Data))
                            throw new InvalidDataException("Temporary package condition readback mismatch");
                    }
                    VerifiedFilters++;
                } finally {FwpmFreeMemory0(ref actual);}
            }
            return id;
        }
        void SetLoopback(bool allow) {
            uint count;IntPtr values;CheckError(NetworkIsolationGetAppContainerConfig(out count,out values));
            var old=new List<SidEntry>();
            try {
                for(int i=0;i<count;i++)old.Add(((SidEntry*)values)[i]);
                var sid=new SecurityIdentifier(package);
                var next=old.Where(v=>!new SecurityIdentifier(v.SID).Equals(sid)).ToList();
                if(allow)next.Add(new SidEntry{SID=package});
                if(next.Count!=old.Count) {
                    var array=next.ToArray();fixed(SidEntry* ptr=array)CheckError(NetworkIsolationSetAppContainerConfig((uint)array.Length,(IntPtr)ptr));
                }
            } finally {
                foreach(var value in old)HeapFree(GetProcessHeap(),0,value.SID);
                if(values!=IntPtr.Zero)HeapFree(GetProcessHeap(),0,values);
            }
        }
        internal void ClosePermit() { if(permit!=0){CheckError(FwpmFilterDeleteById0(engine,permit));permit=0;} }
        public void Dispose() {
            try {if(exceptionAdded){SetLoopback(false);exceptionAdded=false;}LoopbackRemoved=true;}
            finally {if(engine!=IntPtr.Zero){uint rc=FwpmEngineClose0(engine);engine=IntPtr.Zero;EngineClosed=rc==0;CheckError(rc);}}
        }
    }

    static Dictionary<string,object> NetworkSuite(string mode) {
        var result=new Dictionary<string,object>{{"mode",mode},{"scope","temporary package, loopback TCP only; DNS and real upstream unverified"}};
        if(!new WindowsPrincipal(WindowsIdentity.GetCurrent()).IsInRole(WindowsBuiltInRole.Administrator)) {
            result["passed"]=false;result["requiresAdministrator"]=true;return result;
        }
        string fixture=Path.Combine(BuildRoot,"network-"+mode+"-"+Guid.NewGuid().ToString("N"));
        Session session=null;TestNetwork policy=null;
        try {
            session=new Session(mode,fixture);
            string exe=Path.Combine(fixture,"tools","BoundaryProbe.exe");File.Copy(typeof(BoundaryProbe).Assembly.Location,exe);
            using(var gateway=new Socket(AddressFamily.InterNetwork,SocketType.Stream,ProtocolType.Tcp))
            using(var other=new Socket(AddressFamily.InterNetwork,SocketType.Stream,ProtocolType.Tcp)) {
                gateway.Bind(new IPEndPoint(IPAddress.Loopback,0));gateway.Listen(4);
                other.Bind(new IPEndPoint(IPAddress.Loopback,0));other.Listen(4);
                int port=((IPEndPoint)gateway.LocalEndPoint).Port,privatePort=((IPEndPoint)other.LocalEndPoint).Port;
                policy=new TestNetwork(session.sid,port);result["verifiedFilters"]=policy.VerifiedFilters;
                var online=Launch(session,exe,new[]{"worker",session.Sid,mode,"tcp","127.0.0.1",port.ToString()},8,"allowed-gateway");
                bool reached=gateway.Poll(100000,SelectMode.SelectRead);if(reached)using(var accepted=gateway.Accept()){}
                result["allowedGatewayReached"]=reached;result["online"]=online;
                var blocked=Launch(session,exe,new[]{"worker",session.Sid,mode,"tcp","127.0.0.1",privatePort.ToString()},8,"other-host-port");
                result["otherHostPortReached"]=other.Poll(100000,SelectMode.SelectRead);result["otherHostPort"]=blocked;
                policy.ClosePermit();
                var offline=Launch(session,exe,new[]{"worker",session.Sid,mode,"tcp","127.0.0.1",port.ToString()},8,"revoked-gateway");
                result["revokedGatewayReached"]=gateway.Poll(100000,SelectMode.SelectRead);result["revoked"]=offline;
                result["passed"]=reached && online.ContainsKey("exitCode") && Convert.ToUInt32(online["exitCode"])==0 &&
                    !(bool)result["otherHostPortReached"] && !(bool)result["revokedGatewayReached"] &&
                    new[]{blocked,offline}.All(v=>!v.ContainsKey("error") && v.ContainsKey("exitCode") && (Convert.ToUInt32(v["exitCode"])==10013 || Convert.ToUInt32(v["exitCode"])==10060));
            }
        } catch(Exception ex){result["passed"]=false;result["error"]=ex.GetType().Name+": "+ex.Message;}
        finally {
            if(policy!=null){try{policy.Dispose();result["loopbackExceptionRemoved"]=policy.LoopbackRemoved;result["dynamicEngineClosed"]=policy.EngineClosed;}catch(Exception ex){result["cleanupError"]=ex.Message;result["passed"]=false;}}
            if(session!=null){session.Dispose();result["profileDeleteResult"]=session.DeleteResult;if(session.DeleteResult!=0)result["passed"]=false;}
            if(Directory.Exists(fixture))Save(Path.Combine(fixture,"network-result.json"),result);
        }
        return result;
    }

    // A real HTTP request/response through a deliberately tiny local proxy.
    // The sole hostname is mapped directly to this process's loopback origin;
    // neither the worker nor the proxy asks the system resolver for it.
    const string ProxyFixtureHost="cage-fixture.invalid";
    static void ProxySend(Socket socket,byte[] bytes) {
        int sent=0;
        while(sent<bytes.Length) {int n=socket.Send(bytes,sent,bytes.Length-sent,SocketFlags.None);if(n==0)throw new EndOfStreamException("socket_closed_on_send");sent+=n;}
    }
    static string ProxyHeader(Socket socket) {
        var bytes=new List<byte>();var one=new byte[1];
        while(bytes.Count<8192) {
            if(socket.Receive(one)==0)throw new EndOfStreamException("socket_closed_before_header");
            bytes.Add(one[0]);int n=bytes.Count;
            if(n>=4 && bytes[n-4]==13 && bytes[n-3]==10 && bytes[n-2]==13 && bytes[n-1]==10)return Encoding.ASCII.GetString(bytes.ToArray());
        }
        throw new InvalidDataException("fixture_header_too_large");
    }
    static string ProxyResponse(Socket socket) {
        string header=ProxyHeader(socket);
        if(!header.StartsWith("HTTP/1.1 200 ",StringComparison.Ordinal))throw new InvalidDataException("fixture_http_status");
        string size=header.Split(new[]{"\r\n"},StringSplitOptions.None).Single(v=>v.StartsWith("Content-Length:",StringComparison.OrdinalIgnoreCase)).Substring(15).Trim();
        int length;if(!Int32.TryParse(size,out length)||length<0||length>4096)throw new InvalidDataException("fixture_body_length");
        var bytes=new byte[length];int received=0;
        while(received<length) {int n=socket.Receive(bytes,received,length-received,SocketFlags.None);if(n==0)throw new EndOfStreamException("socket_closed_before_body");received+=n;}
        return Encoding.ASCII.GetString(bytes);
    }
    static void ProxyReply(Socket socket,string body) {
        ProxySend(socket,Encoding.ASCII.GetBytes("HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: "+Encoding.ASCII.GetByteCount(body)+"\r\nConnection: keep-alive\r\n\r\n"+body));
    }
    static void ProxyConnect(Socket socket,int port) {
        var pending=socket.BeginConnect(IPAddress.Loopback,port,null,null);
        using(var ready=pending.AsyncWaitHandle) {if(!ready.WaitOne(1500))throw new SocketException(10060);socket.EndConnect(pending);}
        socket.ReceiveTimeout=1800;socket.SendTimeout=1800;
    }
    static void ProxyRequest(Socket socket,string phase,string nonce) {
        ProxySend(socket,Encoding.ASCII.GetBytes("GET http://"+ProxyFixtureHost+"/"+phase+"/"+nonce+" HTTP/1.1\r\nHost: "+ProxyFixtureHost+"\r\nConnection: keep-alive\r\n\r\n"));
    }
    static Dictionary<string,object> ProxyConnectObservation(int port) {
        var result=new Dictionary<string,object>();
        try {using(var socket=new Socket(AddressFamily.InterNetwork,SocketType.Stream,ProtocolType.Tcp)){ProxyConnect(socket,port);result["connected"]=true;}}
        catch(SocketException ex){result["connected"]=false;result["socketError"]=ex.NativeErrorCode;}
        return result;
    }
    static void ProxyWaitFile(string path,int milliseconds,Task workload=null) {
        var deadline=DateTime.UtcNow.AddMilliseconds(milliseconds);
        while(!File.Exists(path)) {
            if(DateTime.UtcNow>=deadline || (workload!=null && workload.IsCompleted))throw new TimeoutException("fixture_phase_not_reached: "+Path.GetFileName(path));
            Thread.Sleep(30);
        }
    }
    sealed class ProxyOrigin:IDisposable {
        readonly Socket listener;readonly Thread server;readonly ManualResetEvent stopping=new ManualResetEvent(false);readonly string nonce;
        internal readonly int Port;internal int Requests;internal string Error;
        internal ProxyOrigin(string value) {
            nonce=value;listener=new Socket(AddressFamily.InterNetwork,SocketType.Stream,ProtocolType.Tcp);
            listener.Bind(new IPEndPoint(IPAddress.Loopback,0));listener.Listen(4);Port=((IPEndPoint)listener.LocalEndPoint).Port;
            server=new Thread(Serve);server.IsBackground=true;server.Start();
        }
        void Serve() {
            try {
                while(!stopping.WaitOne(0)) {
                    if(!listener.Poll(100000,SelectMode.SelectRead))continue;
                    using(var socket=listener.Accept()) {
                        socket.ReceiveTimeout=1800;socket.SendTimeout=1800;
                        string first=ProxyHeader(socket).Split(new[]{"\r\n"},StringSplitOptions.None)[0];
                        string phase=first=="GET /first/"+nonce+" HTTP/1.1"?"first":first=="GET /after/"+nonce+" HTTP/1.1"?"after":null;
                        if(phase==null)throw new InvalidDataException("origin_route_mismatch");
                        Interlocked.Increment(ref Requests);ProxyReply(socket,"origin:"+phase+":"+nonce);
                    }
                }
            } catch(Exception ex){if(!stopping.WaitOne(0))Error=ex.GetType().Name+": "+ex.Message;}
        }
        public void Dispose(){stopping.Set();listener.Close();if(server.Join(4000))stopping.Dispose();else Error="origin_thread_did_not_stop";}
    }
    static void ProxyForward(Socket client,ProxyOrigin origin,string phase,string nonce) {
        string first=ProxyHeader(client).Split(new[]{"\r\n"},StringSplitOptions.None)[0];
        string expected="GET http://"+ProxyFixtureHost+"/"+phase+"/"+nonce+" HTTP/1.1";
        if(first!=expected)throw new InvalidDataException("proxy_route_mismatch");
        using(var upstream=new Socket(AddressFamily.InterNetwork,SocketType.Stream,ProtocolType.Tcp)) {
            // Explicit IPEndPoint: no DNS lookup and no arbitrary destination.
            ProxyConnect(upstream,origin.Port);
            ProxySend(upstream,Encoding.ASCII.GetBytes("GET /"+phase+"/"+nonce+" HTTP/1.1\r\nHost: "+ProxyFixtureHost+"\r\nConnection: close\r\n\r\n"));
            string body=ProxyResponse(upstream);if(body!="origin:"+phase+":"+nonce)throw new InvalidDataException("origin_response_mismatch");
            ProxyReply(client,body);
        }
    }

    // Main routes the dedicated worker command here. The worker is executed
    // using Launch's suspended-token verification and kill-on-close job.
    static int NetworkProxyWorker(string[] args) {
        if(args.Length!=7)throw new InvalidDataException("proxy_worker_arguments");
        var result=new Dictionary<string,object>();string work=args[5],nonce=args[6];
        try {
            string[] token=Token(System.Diagnostics.Process.GetCurrentProcess().Handle);
            if(token[0]!="1"||token[1]!="0"||token[2]!=args[1]||token[3]!=(args[2]=="lpac"?"1":"0"))throw new InvalidDataException("proxy_worker_token_mismatch");
            result["tokenVerifiedInsideWorker"]=true;
            int port=Int32.Parse(args[3]),privatePort=Int32.Parse(args[4]);
            using(var socket=new Socket(AddressFamily.InterNetwork,SocketType.Stream,ProtocolType.Tcp)) {
                ProxyConnect(socket,port);ProxyRequest(socket,"first",nonce);
                result["firstRoundTrip"]=ProxyResponse(socket)=="origin:first:"+nonce;
                if(!(bool)result["firstRoundTrip"])throw new InvalidDataException("first_response_mismatch");
                File.WriteAllText(Path.Combine(work,"first.received"),"ok");
                ProxyWaitFile(Path.Combine(work,"cut.signal"),6500);
                var watch=System.Diagnostics.Stopwatch.StartNew();
                try {
                    ProxyRequest(socket,"after",nonce);string body=ProxyResponse(socket);result["sameConnectionResponseAfterCut"]=true;
                    if(body!="origin:after:"+nonce)result["unexpectedAfterCutResponse"]=true;
                } catch(Exception ex) {
                    result["sameConnectionResponseAfterCut"]=false;result["afterCutError"]=ex.GetType().Name;
                    if(ex is SocketException)result["afterCutSocketError"]=((SocketException)ex).NativeErrorCode;
                }
                result["afterCutElapsedMilliseconds"]=watch.ElapsedMilliseconds;
            }
            result["newProxyConnection"]=ProxyConnectObservation(port);
            result["directOtherHostConnection"]=ProxyConnectObservation(privatePort);
            return 0;
        } catch(Exception ex){result["error"]=ex.GetType().Name+": "+ex.Message;return 1;}
        finally {Save(Path.Combine(work,"proxy-worker.json"),result);}
    }

    static Dictionary<string,object> NetworkProxyCase(string mode,bool revokeOnly) {
        string scenario=revokeOnly?"revoke-permit-only":"stop-proxy-and-close-active-connections";
        var result=new Dictionary<string,object>{{"scenario",scenario},{"mode",mode},{"passed",false}};
        string fixture=Path.Combine(BuildRoot,"network-proxy-"+mode+"-"+Guid.NewGuid().ToString("N"));
        Session session=null;TestNetwork policy=null;Socket accepted=null;Task<Dictionary<string,object>> workload=null;
        try {
            session=new Session(mode,fixture);string nonce=Guid.NewGuid().ToString("N");
            string exe=Path.Combine(fixture,"tools","BoundaryProbe.exe");File.Copy(typeof(BoundaryProbe).Assembly.Location,exe);
            string work=Path.Combine(fixture,"work");
            using(var gateway=new Socket(AddressFamily.InterNetwork,SocketType.Stream,ProtocolType.Tcp))
            using(var other=new Socket(AddressFamily.InterNetwork,SocketType.Stream,ProtocolType.Tcp))
            using(var origin=new ProxyOrigin(nonce)) {
                gateway.Bind(new IPEndPoint(IPAddress.Loopback,0));gateway.Listen(4);other.Bind(new IPEndPoint(IPAddress.Loopback,0));other.Listen(4);
                int port=((IPEndPoint)gateway.LocalEndPoint).Port,privatePort=((IPEndPoint)other.LocalEndPoint).Port;
                policy=new TestNetwork(session.sid,port);result["verifiedFilters"]=policy.VerifiedFilters;
                workload=Task.Run(()=>Launch(session,exe,new[]{"network-proxy-worker",session.Sid,mode,port.ToString(),privatePort.ToString(),work,nonce},15,"proxy-workload"));
                if(!gateway.Poll(6000000,SelectMode.SelectRead))throw new TimeoutException("proxy_worker_did_not_connect");
                accepted=gateway.Accept();accepted.ReceiveTimeout=2200;accepted.SendTimeout=1800;
                ProxyForward(accepted,origin,"first",nonce);
                ProxyWaitFile(Path.Combine(work,"first.received"),5000,workload);
                result["firstResponseAcknowledged"]=true;
                if(revokeOnly) {
                    policy.ClosePermit();result["permitRevoked"]=true;
                } else {
                    // A production broker must track all accepted streams;
                    // closing only its listening socket leaves them alive.
                    try {accepted.Shutdown(SocketShutdown.Both);}catch(SocketException){}
                    accepted.Close();accepted=null;gateway.Close();
                    result["acceptedConnectionsActivelyClosed"]=1;result["listenerClosed"]=true;
                    // Leave permit present during observation so this case
                    // measures broker shutdown independently of WFP policy.
                    result["permitPresentDuringActiveClose"]=true;
                }
                File.WriteAllText(Path.Combine(work,"cut.signal"),"go");
                if(revokeOnly) {
                    try {ProxyForward(accepted,origin,"after",nonce);result["proxyForwardedAfterRevocation"]=true;}
                    catch(Exception ex){result["proxyForwardedAfterRevocation"]=false;result["postRevocationReadError"]=ex.GetType().Name;}
                }
                if(!workload.Wait(12000))throw new TimeoutException("proxy_worker_did_not_finish");
                var launched=workload.Result;result["launch"]=launched;
                var worker=new System.Web.Script.Serialization.JavaScriptSerializer().Deserialize<Dictionary<string,object>>(File.ReadAllText(Path.Combine(work,"proxy-worker.json")));
                result["worker"]=worker;result["localOriginRequests"]=origin.Requests;
                result["otherHostPortReached"]=other.Poll(100000,SelectMode.SelectRead);
                result["originError"]=origin.Error;
                bool first=worker.ContainsKey("firstRoundTrip")&&(bool)worker["firstRoundTrip"];
                bool after=worker.ContainsKey("sameConnectionResponseAfterCut")&&(bool)worker["sameConnectionResponseAfterCut"];
                var reconnect=worker.ContainsKey("newProxyConnection")?(Dictionary<string,object>)worker["newProxyConnection"]:null;
                var direct=worker.ContainsKey("directOtherHostConnection")?(Dictionary<string,object>)worker["directOtherHostConnection"]:null;
                bool newDenied=reconnect!=null&&!(bool)reconnect["connected"]&&reconnect.ContainsKey("socketError")&&(revokeOnly?new[]{10013,10060}:new[]{10013,10060,10061}).Contains(Convert.ToInt32(reconnect["socketError"]));
                bool fallbackDenied=direct!=null&&!(bool)direct["connected"]&&direct.ContainsKey("socketError")&&new[]{10013,10060}.Contains(Convert.ToInt32(direct["socketError"]));
                result["existingExchangeStopped"]=!after;
                result["passed"]=first&&origin.Requests>=1&&origin.Error==null&&!worker.ContainsKey("error")&&!worker.ContainsKey("unexpectedAfterCutResponse")&&
                    launched.ContainsKey("exitCode")&&Convert.ToUInt32(launched["exitCode"])==0&&newDenied&&fallbackDenied&&!(bool)result["otherHostPortReached"]&&
                    (revokeOnly||!after);
                // revokeOnly is an observation, not an assertion that deleting
                // an ALE filter synchronously terminates every existing flow.
            }
        } catch(Exception ex){result["passed"]=false;result["error"]=ex.GetType().Name+": "+ex.Message;}
        finally {
            if(accepted!=null)accepted.Close();
            if(workload!=null&&!workload.IsCompleted) {
                try {if(!workload.Wait(17000)){result["cleanupError"]="workload_did_not_stop";result["passed"]=false;}}
                catch(Exception ex){result["cleanupError"]=ex.GetType().Name;result["passed"]=false;}
            }
            if(policy!=null){try{policy.Dispose();result["loopbackExceptionRemoved"]=policy.LoopbackRemoved;result["dynamicEngineClosed"]=policy.EngineClosed;}catch(Exception ex){result["cleanupError"]=ex.Message;result["passed"]=false;}}
            if(session!=null){session.Dispose();result["profileDeleteResult"]=session.DeleteResult;if(session.DeleteResult!=0)result["passed"]=false;}
            if(Directory.Exists(fixture))Save(Path.Combine(fixture,"network-proxy-result.json"),result);
        }
        return result;
    }
    static Dictionary<string,object> NetworkProxySuite(string mode) {
        var result=new Dictionary<string,object>{{"mode",mode},{"scope","temporary packages; fixed-name HTTP proxy to local fake origin; no system DNS or external upstream"},{"passed",false}};
        if(!new WindowsPrincipal(WindowsIdentity.GetCurrent()).IsInRole(WindowsBuiltInRole.Administrator)){result["requiresAdministrator"]=true;return result;}
        var revoke=NetworkProxyCase(mode,true);var stop=NetworkProxyCase(mode,false);
        result["revocationObservation"]=revoke;result["activeProxyShutdown"]=stop;
        result["passed"]=(bool)revoke["passed"]&&(bool)stop["passed"];
        Save(Path.Combine(BuildRoot,"network-proxy-last.json"),result);return result;
    }
}
