// Local candidate only. Shares no existing user profile or tool-tree ACLs.
// Based on the repository's RemoteSandbox/TerminalRpc Win32 boundary.
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Net;
using System.Net.Sockets;
using System.Runtime.InteropServices;
using System.Security.AccessControl;
using System.Security.Principal;
using System.Text;
using System.Threading;
using System.Web.Script.Serialization;
using Microsoft.Win32;

internal static partial class BoundaryProbe {
    const uint NoWindow=0x08000000, Extended=0x80000, UnicodeEnv=0x400, Suspended=4;
    static readonly string BuildRoot=Path.GetFullPath(AppDomain.CurrentDomain.BaseDirectory).TrimEnd('\\');
    [StructLayout(LayoutKind.Sequential)] struct Startup {
        public int cb; public IntPtr reserved,desktop,title;
        public int x,y,width,height,charsX,charsY,fill,flags;
        public short show,reserved2; public IntPtr reservedPtr,stdin,stdout,stderr;
    }
    [StructLayout(LayoutKind.Sequential)] struct StartupEx { public Startup si; public IntPtr attributes; }
    [StructLayout(LayoutKind.Sequential)] struct Capabilities { public IntPtr sid,capabilities; public uint count,reserved; }
    [StructLayout(LayoutKind.Sequential)] struct Pi { public IntPtr process,thread; public int pid,tid; }
    [StructLayout(LayoutKind.Sequential)] struct GenericMapping { public uint read,write,execute,all; }
    [DllImport("userenv",CharSet=CharSet.Unicode)] static extern int CreateAppContainerProfile(string n,string d,string desc,IntPtr caps,uint count,out IntPtr sid);
    [DllImport("userenv",CharSet=CharSet.Unicode)] static extern int DeleteAppContainerProfile(string name);
    [DllImport("userenv",CharSet=CharSet.Unicode)] static extern int DeriveAppContainerSidFromAppContainerName(string name,out IntPtr sid);
    [DllImport("userenv")] static extern int GetAppContainerRegistryLocation(uint access,out IntPtr key);
    [DllImport("advapi32")] static extern IntPtr FreeSid(IntPtr sid);
    [DllImport("kernel32",SetLastError=true)] static extern bool InitializeProcThreadAttributeList(IntPtr list,int count,int flags,ref IntPtr size);
    [DllImport("kernel32",SetLastError=true)] static extern bool UpdateProcThreadAttribute(IntPtr list,uint flags,IntPtr attribute,IntPtr value,IntPtr size,IntPtr previous,IntPtr ret);
    [DllImport("kernel32")] static extern void DeleteProcThreadAttributeList(IntPtr list);
    [DllImport("kernel32",CharSet=CharSet.Unicode,SetLastError=true)] static extern bool CreateProcess(string exe,StringBuilder cmd,IntPtr ps,IntPtr ts,bool inherit,uint flags,IntPtr env,string cwd,ref StartupEx si,out Pi pi);
    [DllImport("kernel32")] static extern bool CloseHandle(IntPtr h);
    [DllImport("kernel32",SetLastError=true)] static extern bool SetHandleInformation(IntPtr handle,uint mask,uint flags);
    [DllImport("kernel32")] static extern uint WaitForSingleObject(IntPtr h,uint ms);
    [DllImport("kernel32",SetLastError=true)] static extern bool GetExitCodeProcess(IntPtr h,out uint code);
    [DllImport("kernel32",SetLastError=true)] static extern uint ResumeThread(IntPtr h);
    [DllImport("kernel32",SetLastError=true)] static extern bool TerminateProcess(IntPtr h,uint code);
    [DllImport("kernel32",CharSet=CharSet.Unicode,SetLastError=true)] static extern IntPtr CreateJobObject(IntPtr sa,string name);
    [DllImport("kernel32",SetLastError=true)] static extern bool SetInformationJobObject(IntPtr job,int kind,IntPtr data,uint size);
    [DllImport("kernel32",SetLastError=true)] static extern bool AssignProcessToJobObject(IntPtr job,IntPtr process);
    [DllImport("advapi32",SetLastError=true)] static extern bool OpenProcessToken(IntPtr process,uint access,out IntPtr token);
    [DllImport("advapi32",SetLastError=true)] static extern bool GetTokenInformation(IntPtr token,int kind,IntPtr value,int size,out int used);
    [DllImport("advapi32",SetLastError=true)] static extern bool DuplicateToken(IntPtr token,int level,out IntPtr duplicate);
    [DllImport("advapi32",SetLastError=true)] static extern bool AccessCheck(IntPtr sd,IntPtr token,uint access,ref GenericMapping mapping,IntPtr privileges,ref uint size,out uint granted,out bool allowed);
    [DllImport("advapi32",CharSet=CharSet.Unicode,SetLastError=true)] static extern bool ConvertStringSecurityDescriptorToSecurityDescriptor(string s,uint revision,out IntPtr sd,out uint size);
    [DllImport("advapi32",CharSet=CharSet.Unicode,SetLastError=true)] static extern bool SetFileSecurity(string path,uint info,IntPtr sd);
    [DllImport("kernel32")] static extern IntPtr LocalFree(IntPtr p);
    [DllImport("advapi32",CharSet=CharSet.Unicode)] static extern int RegSetValueEx(IntPtr key,string name,int reserved,uint type,byte[] value,uint size);
    [DllImport("advapi32")] static extern int RegCloseKey(IntPtr key);

    static void Check(bool ok,string op) { if(!ok) {int error=Marshal.GetLastWin32Error();throw new Win32Exception(error,op+" ("+error+")");} }
    static bool Inside(string path,string parent) { return path.StartsWith(parent.TrimEnd('\\')+"\\",StringComparison.OrdinalIgnoreCase); }
    static string Quote(string s) {
        var b=new StringBuilder("\""); int slashes=0;
        foreach(char c in s) { if(c=='\\') { slashes++; continue; } if(c=='\"') { b.Append('\\',slashes*2+1); b.Append(c); } else { b.Append('\\',slashes); b.Append(c); } slashes=0; }
        b.Append('\\',slashes*2); return b.Append('"').ToString();
    }
    static void Save(string path,object value) { File.WriteAllText(path,new JavaScriptSerializer().Serialize(value),new UTF8Encoding(false)); }
    static bool TokenAccess(IntPtr token,string principal) {
        IntPtr duplicate,descriptor; uint length;
        Check(DuplicateToken(token,2,out duplicate),"DuplicateToken");
        try {
            string user=WindowsIdentity.GetCurrent().User.Value;
            Check(ConvertStringSecurityDescriptorToSecurityDescriptor("O:"+user+"G:"+user+"D:(A;;0x1;;;"+user+")(A;;0x1;;;"+principal+")",1,out descriptor,out length),"test_security_descriptor");
            try {
                var mapping=new GenericMapping{read=1,write=2,execute=4,all=7}; uint size=1024,granted; bool allowed;
                IntPtr privileges=Marshal.AllocHGlobal(1024);
                try { Check(AccessCheck(descriptor,duplicate,1,ref mapping,privileges,ref size,out granted,out allowed),"AccessCheck"); return allowed && (granted&1)==1; }
                finally { Marshal.FreeHGlobal(privileges); }
            } finally { LocalFree(descriptor); }
        } finally { CloseHandle(duplicate); }
    }
    static string[] Token(IntPtr process) {
        IntPtr token; Check(OpenProcessToken(process,10,out token),"OpenProcessToken");
        var result=new string[5]; IntPtr b=Marshal.AllocHGlobal(4096);
        try { int used;
            foreach(int kind in new[]{29,30,31}) {
                Check(GetTokenInformation(token,kind,b,4096,out used),"GetTokenInformation("+kind+")");
                int index=kind==29?0:kind==30?1:kind==31?2:3;
                result[index]=kind==31?(Marshal.ReadIntPtr(b)==IntPtr.Zero?"":new SecurityIdentifier(Marshal.ReadIntPtr(b)).Value):Marshal.ReadInt32(b).ToString();
            }
            // Class 46 is listed by Windows but is not queryable on every
            // supported host. Verify the actual ALL APPLICATION PACKAGES
            // opt-out with AccessCheck against synthetic descriptors instead.
            bool class46=GetTokenInformation(token,46,b,4096,out used);
            int classValue=class46?Marshal.ReadInt32(b):-1;
            result[4]=class46?"supported":"unsupported";
            if(result[0]=="1") {
                if(!TokenAccess(token,result[2])) throw new InvalidDataException("exact_package_access_check_failed");
                result[3]=TokenAccess(token,"S-1-15-2-1")?"0":"1";
                if(class46 && classValue!=(result[3]=="1"?1:0)) throw new InvalidDataException("lpac_checks_disagree");
            } else result[3]="0";
        } finally { Marshal.FreeHGlobal(b); CloseHandle(token); }
        return result;
    }
    static void Acl(string path,SecurityIdentifier package,bool writable) {
        var acl=new DirectorySecurity(); acl.SetAccessRuleProtection(true,false);
        var inherit=InheritanceFlags.ContainerInherit|InheritanceFlags.ObjectInherit;
        acl.AddAccessRule(new FileSystemAccessRule(WindowsIdentity.GetCurrent().User,FileSystemRights.FullControl,inherit,PropagationFlags.None,AccessControlType.Allow));
        acl.AddAccessRule(new FileSystemAccessRule(new SecurityIdentifier("S-1-5-18"),FileSystemRights.FullControl,inherit,PropagationFlags.None,AccessControlType.Allow));
        // A browser must be able to grant its own nested sandbox access to
        // its cache. This permission is confined to this disposable work tree.
        if(package!=null) acl.AddAccessRule(new FileSystemAccessRule(package,writable?FileSystemRights.Modify|FileSystemRights.Synchronize|FileSystemRights.ChangePermissions:FileSystemRights.ReadAndExecute,inherit,PropagationFlags.None,AccessControlType.Allow));
        Directory.SetAccessControl(path,acl);
        if(writable) {
            IntPtr descriptor; uint size;
            Check(ConvertStringSecurityDescriptorToSecurityDescriptor("S:(ML;OICI;NW;;;LW)",1,out descriptor,out size),"low label descriptor");
            try { Check(SetFileSecurity(path,0x10,descriptor),"low label fixture"); } finally { LocalFree(descriptor); }
        }
    }
    static void ValidateFixture(string fixture) {
        if(!Inside(fixture,BuildRoot) || fixture.Equals(BuildRoot,StringComparison.OrdinalIgnoreCase)) throw new InvalidDataException("fixture_must_be_below_build_directory");
        for(var p=new DirectoryInfo(fixture);p!=null && Inside(p.FullName,BuildRoot);p=p.Parent)
            if(p.Exists && (p.Attributes&FileAttributes.ReparsePoint)!=0) throw new InvalidDataException("fixture_redirected");
        if(Directory.Exists(fixture)) foreach(string p in Directory.EnumerateFileSystemEntries(fixture,"*",SearchOption.AllDirectories))
            if((File.GetAttributes(p)&FileAttributes.ReparsePoint)!=0) throw new InvalidDataException("fixture_child_redirected");
    }
    sealed class Session:IDisposable {
        internal readonly string Fixture,Name,Sid,Mode; internal readonly bool OwnsProfile; internal IntPtr sid; internal int DeleteResult;
        internal Session(string mode,string fixture,string ownedProfile=null,bool initialize=true) {
            if(mode!="ac" && mode!="lpac") throw new InvalidDataException("mode_must_be_ac_or_lpac");
            Fixture=Path.GetFullPath(fixture); Mode=mode; ValidateFixture(Fixture);
            OwnsProfile=ownedProfile==null;
            Name=ownedProfile??("Cage.Boundary."+Guid.NewGuid().ToString("N"));
            if(!OwnsProfile && !System.Text.RegularExpressions.Regex.IsMatch(Name,"\\ACage\\.TerminalCandidate\\.[a-f0-9]{32}\\z"))throw new InvalidDataException("host_profile_name_invalid");
            if(OwnsProfile)Marshal.ThrowExceptionForHR(CreateAppContainerProfile(Name,Name,"Temporary local isolation candidate",IntPtr.Zero,0,out sid));
            else Marshal.ThrowExceptionForHR(DeriveAppContainerSidFromAppContainerName(Name,out sid));
            Sid=new SecurityIdentifier(sid).Value;
            try {
                if(!initialize) {
                    if(OwnsProfile)throw new InvalidDataException("persistent_profile_must_be_owned_by_host");
                    foreach(string part in new[]{"tools","work","out","private"})if(!Directory.Exists(Path.Combine(Fixture,part)))throw new InvalidDataException("environment_not_initialized");
                    return;
                }
                Directory.CreateDirectory(Fixture); Acl(Fixture,null,false);
                foreach(string p in new[]{"tools","work","out","private"}) Directory.CreateDirectory(Path.Combine(Fixture,p));
                Acl(Path.Combine(Fixture,"tools"),new SecurityIdentifier(sid),false);
                Acl(Path.Combine(Fixture,"work"),new SecurityIdentifier(sid),true);
                Acl(Path.Combine(Fixture,"out"),null,false); Acl(Path.Combine(Fixture,"private"),null,false);
                Directory.CreateDirectory(Path.Combine(Fixture,"work","Temp"));
            } catch { Dispose(); throw; }
        }
        public void Dispose() { if(sid!=IntPtr.Zero) { FreeSid(sid); sid=IntPtr.Zero; if(OwnsProfile)DeleteResult=DeleteAppContainerProfile(Name); } }
    }
    static Dictionary<string,object> Launch(Session session,string exe,string[] args,int timeout,string label,Action<IntPtr,int> initializeProcess=null,Action<IntPtr,int> onTimeout=null,Func<IntPtr,int,IntPtr,int,Dictionary<string,object>> monitor=null) {
        exe=Path.GetFullPath(exe);
        var installedRoots=new[]{Environment.GetFolderPath(Environment.SpecialFolder.Windows),Environment.GetEnvironmentVariable("ProgramFiles"),Environment.GetEnvironmentVariable("ProgramFiles(x86)")};
        if(!Inside(exe,Path.Combine(session.Fixture,"tools")) && !installedRoots.Any(p=>!String.IsNullOrEmpty(p) && Inside(exe,Path.GetFullPath(p)))) throw new InvalidDataException("executable_must_be_staged_under_fixture_tools_or_system_installation");
        if(!File.Exists(exe) || timeout<1 || timeout>300) throw new InvalidDataException("invalid_launch_request");
        string logs=Path.Combine(session.Fixture,"out",label); Directory.CreateDirectory(logs);
        string empty=Path.Combine(logs,"stdin.txt"); File.WriteAllText(empty,"");
        IntPtr attributes=IntPtr.Zero,cap=IntPtr.Zero,policy=IntPtr.Zero,handles=IntPtr.Zero,env=IntPtr.Zero,job=IntPtr.Zero;
        Pi pi=new Pi(); bool ready=false; var result=new Dictionary<string,object>();
        using(var input=new FileStream(empty,FileMode.Open,FileAccess.Read,FileShare.ReadWrite))
        using(var output=new FileStream(Path.Combine(logs,"stdout.txt"),FileMode.Create,FileAccess.Write,FileShare.ReadWrite))
        using(var error=new FileStream(Path.Combine(logs,"stderr.txt"),FileMode.Create,FileAccess.Write,FileShare.ReadWrite)) {
            try {
                int count=session.Mode=="lpac"?3:2; IntPtr bytes=IntPtr.Zero;
                InitializeProcThreadAttributeList(IntPtr.Zero,count,0,ref bytes);
                attributes=Marshal.AllocHGlobal(bytes); Check(InitializeProcThreadAttributeList(attributes,count,0,ref bytes),"initialize_attributes"); ready=true;
                var caps=new Capabilities{sid=session.sid}; cap=Marshal.AllocHGlobal(Marshal.SizeOf(caps)); Marshal.StructureToPtr(caps,cap,false);
                Check(UpdateProcThreadAttribute(attributes,0,(IntPtr)0x20009,cap,(IntPtr)Marshal.SizeOf(caps),IntPtr.Zero,IntPtr.Zero),"security_capabilities");
                if(session.Mode=="lpac") { policy=Marshal.AllocHGlobal(4); Marshal.WriteInt32(policy,1); Check(UpdateProcThreadAttribute(attributes,0,(IntPtr)0x2000f,policy,(IntPtr)4,IntPtr.Zero,IntPtr.Zero),"lpac_policy"); }
                var streams=new[]{input.SafeFileHandle.DangerousGetHandle(),output.SafeFileHandle.DangerousGetHandle(),error.SafeFileHandle.DangerousGetHandle()};
                handles=Marshal.AllocHGlobal(IntPtr.Size*3);
                for(int i=0;i<3;i++) { Check(SetHandleInformation(streams[i],1,1),"inherit_explicit_stdio"); Marshal.WriteIntPtr(handles,i*IntPtr.Size,streams[i]); }
                Check(UpdateProcThreadAttribute(attributes,0,(IntPtr)0x20002,handles,(IntPtr)(IntPtr.Size*3),IntPtr.Zero,IntPtr.Zero),"explicit_handle_list");
                string work=Path.Combine(session.Fixture,"work"),windows=Environment.GetFolderPath(Environment.SpecialFolder.Windows);
                var vars=new SortedDictionary<string,string>(StringComparer.OrdinalIgnoreCase) {
                    {"SystemRoot",windows},{"WINDIR",windows},{"COMSPEC",Path.Combine(Environment.SystemDirectory,"cmd.exe")},
                    {"PATH",Path.GetDirectoryName(exe)+";"+Environment.SystemDirectory+";"+Path.Combine(Environment.SystemDirectory,"WindowsPowerShell","v1.0")},
                    {"PATHEXT",".COM;.EXE;.BAT;.CMD"},{"USERPROFILE",work},{"HOME",work},{"APPDATA",work},{"LOCALAPPDATA",work},
                    {"TEMP",Path.Combine(work,"Temp")},{"TMP",Path.Combine(work,"Temp")},{"PYTHONUTF8","1"},{"PYTHONDONTWRITEBYTECODE","1"}
                };
                env=Marshal.StringToHGlobalUni(String.Join("\0",vars.Select(v=>v.Key+"="+v.Value))+"\0\0");
                var si=new StartupEx{attributes=attributes}; si.si.cb=Marshal.SizeOf(typeof(StartupEx)); si.si.flags=0x100; si.si.stdin=streams[0]; si.si.stdout=streams[1]; si.si.stderr=streams[2];
                job=CreateJobObject(IntPtr.Zero,null); Check(job!=IntPtr.Zero,"create_job");
                IntPtr limits=Marshal.AllocHGlobal(144); try { Marshal.Copy(new byte[144],0,limits,144); Marshal.WriteInt32(limits,16,0x2000); Check(SetInformationJobObject(job,9,limits,144),"kill_on_close_job"); } finally { Marshal.FreeHGlobal(limits); }
                Check(CreateProcess(exe,new StringBuilder(String.Join(" ",new[]{exe}.Concat(args).Select(Quote))),IntPtr.Zero,IntPtr.Zero,true,Extended|UnicodeEnv|NoWindow|Suspended,env,work,ref si,out pi),"CreateProcess");
                string[] token=Token(pi.process);
                result["tokenLpacClass46Supported"]=token[4]=="supported";result["lpacVerification"]="synthetic AccessCheck: exact package and ALL APPLICATION PACKAGES";
                if(token[0]!="1" || token[1]!="0" || token[2]!=session.Sid || token[3]!=(session.Mode=="lpac"?"1":"0")) throw new InvalidDataException("unexpected_child_token");
                result["tokenVerified"]=true; result["isAppContainer"]=true; result["capabilityCount"]=0; result["isLPAC"]=token[3]=="1";
                Check(AssignProcessToJobObject(job,pi.process),"assign_job");
                if(initializeProcess!=null)initializeProcess(pi.process,pi.pid);
                Check(ResumeThread(pi.thread)!=UInt32.MaxValue,"resume_child"); CloseHandle(pi.thread); pi.thread=IntPtr.Zero;
                if(monitor!=null) {
                    foreach(var observation in monitor(pi.process,pi.pid,job,timeout))if(observation.Key!="events")result[observation.Key]=observation.Value;
                } else {
                uint wait=WaitForSingleObject(pi.process,(uint)timeout*1000);
                if(wait!=0 && wait!=258) throw new Win32Exception(Marshal.GetLastWin32Error(),"wait_child_failed");
                bool timedOut=wait==258;
                if(timedOut && onTimeout!=null)onTimeout(pi.process,pi.pid);
                if(timedOut) { CloseHandle(job); job=IntPtr.Zero; WaitForSingleObject(pi.process,5000); }
                uint code; Check(GetExitCodeProcess(pi.process,out code),"exit_code"); result["exitCode"]=code; result["timedOut"]=timedOut;
                }
            } catch(Exception ex) {
                result["error"]=ex.GetType().Name+": "+ex.Message;
                if(pi.process!=IntPtr.Zero) TerminateProcess(pi.process,1);
            } finally {
                if(job!=IntPtr.Zero) CloseHandle(job);
                if(pi.thread!=IntPtr.Zero) CloseHandle(pi.thread);
                if(pi.process!=IntPtr.Zero) { WaitForSingleObject(pi.process,5000); CloseHandle(pi.process); }
                if(ready) DeleteProcThreadAttributeList(attributes);
                foreach(var ptr in new[]{attributes,cap,policy,handles,env}) if(ptr!=IntPtr.Zero) Marshal.FreeHGlobal(ptr);
            }
        }
        result["mode"]=session.Mode; result["label"]=label;
        Save(Path.Combine(logs,"result.json"),result); return result;
    }
    static int Worker(string[] a) {
        string[] token=Token(Process.GetCurrentProcess().Handle);
        if(token[0]!="1" || token[1]!="0" || token[2]!=a[1] || token[3]!=(a[2]=="lpac"?"1":"0")) return 70002;
        string action=a[3];
        try {
            if(action=="read") return File.ReadAllText(a[4])=="fixture"?0:70003;
            if(action=="write") { File.WriteAllText(a[4],"child"); return 0; }
            if(action=="registry-read") { using(var key=Registry.CurrentUser.OpenSubKey(a[4])) return key==null?2:(string)key.GetValue("marker")=="fixture"?0:70003; }
            if(action=="registry-write") { using(var key=Registry.CurrentUser.OpenSubKey(a[4],true)) { if(key==null)return 2; key.SetValue("marker","child"); return 0; } }
            if(action=="registry-own") { IntPtr key; int hr=GetAppContainerRegistryLocation(0x2001f,out key); if(hr<0)return hr&65535; try { byte[] val=Encoding.Unicode.GetBytes("isolated\0"); return RegSetValueEx(key,"CageFixture",0,1,val,(uint)val.Length); } finally { RegCloseKey(key); } }
            if(action=="environment") return Environment.GetEnvironmentVariable("CAGE_FAKE_HOST_SECRET")==null && Environment.GetEnvironmentVariable("ANTHROPIC_API_KEY")==null?0:70004;
            if(action=="child") { var p=Process.Start(new ProcessStartInfo(typeof(BoundaryProbe).Assembly.Location,String.Join(" ",new[]{"worker",a[1],a[2],"environment"}.Select(Quote))){UseShellExecute=false,CreateNoWindow=true}); if(!p.WaitForExit(5000))return 70005; return p.ExitCode; }
            if(action=="tcp" || action=="udp") {
                var address=IPAddress.Parse(a[4]); using(var sock=new Socket(address.AddressFamily,action=="tcp"?SocketType.Stream:SocketType.Dgram,action=="tcp"?ProtocolType.Tcp:ProtocolType.Udp)) {
                    if(action=="udp") { sock.SendTo(new byte[]{67,65,71,69},new IPEndPoint(address,Int32.Parse(a[5]))); return 0; }
                    var pending=sock.BeginConnect(address,Int32.Parse(a[5]),null,null); if(!pending.AsyncWaitHandle.WaitOne(1200))return 10060; sock.EndConnect(pending); return 0;
                }
            }
            return 70006;
        } catch(SocketException ex) { return ex.NativeErrorCode; }
          catch(UnauthorizedAccessException) { return 5; }
          catch(System.Security.SecurityException) { return 5; }
          catch(IOException ex) { return ex.HResult&65535; }
    }
    static Dictionary<string,object> Suite(string mode,bool native=false) {
        string fixture=Path.Combine(BuildRoot,"boundary-"+mode+"-"+Guid.NewGuid().ToString("N"));
        var report=new Dictionary<string,object>{{"mode",mode},{"scope","offline fixtures only"},{"worker",native?"native Go":".NET Framework"}};
        var results=new List<Dictionary<string,object>>(); Session session=null; bool registryCreated=false;
        Directory.CreateDirectory(fixture);
        string reg="Software\\CageAppContainerProbe\\"+Guid.NewGuid().ToString("N");
        try {
            session=new Session(mode,fixture); string exe=Path.Combine(fixture,"tools",native?"BoundaryWorker.exe":"BoundaryProbe.exe"); File.Copy(native?Path.Combine(BuildRoot,"BoundaryWorker.exe"):typeof(BoundaryProbe).Assembly.Location,exe);
            string ro=Path.Combine(fixture,"tools","readonly.txt"),priv=Path.Combine(fixture,"private","private.txt"),rw=Path.Combine(fixture,"work","writable.txt");
            File.WriteAllText(ro,"fixture");File.WriteAllText(priv,"fixture");File.WriteAllText(rw,"fixture");
            using(var key=Registry.CurrentUser.CreateSubKey(reg)) key.SetValue("marker","fixture");
            registryCreated=true;
            var cases=new[]{new[]{"read",ro},new[]{"write",ro},new[]{"read",priv},new[]{"write",priv},new[]{"write",rw},new[]{"registry-read",reg},new[]{"registry-write",reg},new[]{"registry-own"},new[]{"environment"},new[]{"child"}};
            foreach(string[] test in cases) {
                string label="case-"+results.Count.ToString("D2")+"-"+test[0];
                var result=Launch(session,exe,new[]{"worker",session.Sid,mode}.Concat(test).ToArray(),12,label);
                bool blocked=(test[0]=="write" && test[1]==ro) || test.Contains(priv) || test[0]=="registry-read" || test[0]=="registry-write";
                result["expected"]=blocked?"denied":"success";
                uint code=result.ContainsKey("exitCode")?Convert.ToUInt32(result["exitCode"]):UInt32.MaxValue;
                result["passed"]=!result.ContainsKey("error") && (blocked?(code==5 || (test[0].StartsWith("registry") && code==2)):code==0);
                results.Add(result);
                if(test[0]=="read" && test[1]==ro && code!=0) {
                    report["firstProbeFailed"]=true;
                    report["workloadStartupFailed"]=!native && code==0x80131702;
                    break;
                }
            }
            if(!report.ContainsKey("firstProbeFailed")) foreach(var addr in new[]{IPAddress.Loopback,IPAddress.IPv6Loopback}) {
                using(var tcp=new Socket(addr.AddressFamily,SocketType.Stream,ProtocolType.Tcp))
                using(var udp=new Socket(addr.AddressFamily,SocketType.Dgram,ProtocolType.Udp)) {
                    tcp.Bind(new IPEndPoint(addr,0));tcp.Listen(4);udp.Bind(new IPEndPoint(addr,0));
                    foreach(bool stream in new[]{true,false}) {
                        var server=stream?tcp:udp; string action=stream?"tcp":"udp";
                        // Positive host control for the very same local listener.
                        using(var host=new Socket(addr.AddressFamily,stream?SocketType.Stream:SocketType.Dgram,stream?ProtocolType.Tcp:ProtocolType.Udp)) {
                            if(stream) { host.Connect(server.LocalEndPoint); using(var accepted=server.Accept()){} }
                            else {host.SendTo(new byte[]{1},server.LocalEndPoint); byte[] buf=new byte[8]; EndPoint from=new IPEndPoint(addr,0);server.ReceiveFrom(buf,ref from);}
                        }
                        var result=Launch(session,exe,new[]{"worker",session.Sid,mode,action,addr.ToString(),((IPEndPoint)server.LocalEndPoint).Port.ToString()},8,action+"-"+addr.AddressFamily);
                        Thread.Sleep(80); bool reached=server.Poll(1000,SelectMode.SelectRead);
                        uint code=result.ContainsKey("exitCode")?Convert.ToUInt32(result["exitCode"]):UInt32.MaxValue;
                        result["hostControlPassed"]=true;result["listenerReached"]=reached;
                        result["passed"]=!result.ContainsKey("error") && !reached && (code==10013 || code==10060 || (!stream && code==0)); results.Add(result);
                    }
                }
            }
            report["privateUnchanged"]=File.ReadAllText(priv)=="fixture";report["readOnlyUnchanged"]=File.ReadAllText(ro)=="fixture";
            using(var key=Registry.CurrentUser.OpenSubKey(reg)) report["hostRegistryUnchanged"]=(string)key.GetValue("marker")=="fixture";
        } catch(Exception ex) { report["error"]=ex.GetType().Name+": "+ex.Message; }
        finally {
            if(session!=null) {session.Dispose();report["profileDeleteResult"]=session.DeleteResult;}
            if(registryCreated) Registry.CurrentUser.DeleteSubKeyTree(reg,false);
        }
        report["cases"]=results;report["passed"]=results.Count==14 && results.All(x=>x.ContainsKey("passed") && (bool)x["passed"]) && !report.ContainsKey("error") && (int)report["profileDeleteResult"]==0 && (bool)report["privateUnchanged"] && (bool)report["readOnlyUnchanged"] && (bool)report["hostRegistryUnchanged"];
        Save(Path.Combine(fixture,"boundary-result.json"),report);return report;
    }
    static int Main(string[] args) {
        try {
            if(args.Length>0 && args[0]=="worker")return Worker(args);
            if(args.Length>0 && args[0]=="network-proxy-worker")return NetworkProxyWorker(args);
            if(args.Length==2 && args[0]=="network-proxy") {var result=NetworkProxySuite(args[1]);Console.WriteLine(new JavaScriptSerializer().Serialize(result));return (bool)result["passed"]?0:1;}
            if(args.Length==2 && args[0]=="terminal-suite") {var result=TerminalSuite(args[1]);Console.WriteLine(new JavaScriptSerializer().Serialize(result));return (bool)result["passed"]?0:1;}
            if(args.Length>=4 && args[0]=="terminal-rpc")return TerminalRpc(args[1],args[2],args[3],args.Skip(4).ToArray());
            if(args.Length>=5 && args[0]=="terminal-rpc-owned")return TerminalRpc(args[1],args[2],args[3],args.Skip(5).ToArray(),args[4]);
            if(args.Length>=7 && args[0]=="terminal-rpc-persistent")return TerminalRpc(args[1],args[2],args[3],args.Skip(7).ToArray(),args[4],args[5],args[6]);
            if(args.Length==3 && args[0]=="environment-init") {
                using(var session=new Session("ac",args[1],args[2]))Console.WriteLine(new JavaScriptSerializer().Serialize(new { initialized=true, sid=session.Sid, profileCleanupOwner="host controller" }));
                return 0;
            }
            if(args.Length==2 && args[0]=="network") {var result=NetworkSuite(args[1]);Console.WriteLine(new JavaScriptSerializer().Serialize(result));return (bool)result["passed"]?0:1;}
            if(args.Length==2 && args[0]=="suite") { Environment.SetEnvironmentVariable("CAGE_FAKE_HOST_SECRET","fixture-only"); var result=Suite(args[1]);Console.WriteLine(new JavaScriptSerializer().Serialize(result));return (bool)result["passed"]?0:1; }
            if(args.Length==2 && args[0]=="native-suite") {Environment.SetEnvironmentVariable("CAGE_FAKE_HOST_SECRET","fixture-only");var result=Suite(args[1],true);Console.WriteLine(new JavaScriptSerializer().Serialize(result));return (bool)result["passed"]?0:1;}
            if(args.Length>=5 && args[0]=="launch") {
                Session s=null;var result=new Dictionary<string,object>();
                try {s=new Session(args[1],args[2]);result=Launch(s,args[3],args.Skip(5).ToArray(),Int32.Parse(args[4]),"launch");}
                finally {if(s!=null){s.Dispose();result["profileDeleteResult"]=s.DeleteResult;Save(Path.Combine(s.Fixture,"launch.json"),result);}}
                Console.WriteLine(new JavaScriptSerializer().Serialize(result));return result.ContainsKey("error")?1:0;
            }
            Console.Error.WriteLine("suite|native-suite|network|network-proxy|terminal-suite ac|lpac | launch ac|lpac <fixture> <exe> <seconds> [args...] | terminal-rpc ac|lpac <fixture> <shell-exe> [args...]");return 2;
        } catch(Exception ex){Console.Error.WriteLine(ex.GetType().Name+": "+ex.Message);return 1;}
    }
}
