// Offline Desktop diagnostics. This is compiled to a separate executable.
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Runtime.InteropServices;
using System.Text;
using System.Web.Script.Serialization;

internal static class DesktopCompatEntry {
    static int Main(string[] args) { return BoundaryProbe.DesktopCompatMain(args); }
}

internal static partial class BoundaryProbe {
    [DllImport("kernel32",SetLastError=true)] static extern bool WaitForDebugEvent(IntPtr value,uint milliseconds);
    [DllImport("kernel32",SetLastError=true)] static extern bool ContinueDebugEvent(int process,int thread,uint status);
    [DllImport("kernel32",SetLastError=true)] static extern bool ReadProcessMemory(IntPtr process,IntPtr address,byte[] value,IntPtr size,out IntPtr read);
    [DllImport("kernel32",SetLastError=true)] static extern bool GetThreadContext(IntPtr thread,IntPtr context);
    [DllImport("kernel32",SetLastError=true)] static extern IntPtr OpenThread(uint access,bool inherit,int thread);
    [DllImport("kernel32",CharSet=CharSet.Unicode,SetLastError=true)] static extern uint GetFinalPathNameByHandle(IntPtr file,StringBuilder path,uint size,uint flags);
    [DllImport("dbghelp",SetLastError=true)] static extern bool MiniDumpWriteDump(IntPtr process,int pid,IntPtr file,uint kind,IntPtr exception,IntPtr stream,IntPtr callback);
    [DllImport("kernel32",SetLastError=true)] static extern bool TerminateJobObject(IntPtr job,uint code);
    sealed class DesktopModule { internal long Address; internal string Name; }
    static string DesktopModuleName(IntPtr file) {
        if(file==IntPtr.Zero || file.ToInt64()==-1)return "unknown";
        var text=new StringBuilder(32768);
        return GetFinalPathNameByHandle(file,text,(uint)text.Capacity,0)>0?Path.GetFileName(text.ToString()):"unknown";
    }
    static string DesktopAddress(long address,List<DesktopModule> modules) {
        DesktopModule module=modules.Where(x=>x.Address<=address).OrderByDescending(x=>x.Address).FirstOrDefault();
        return module!=null && address-module.Address<0x20000000?module.Name+"+0x"+(address-module.Address).ToString("x"):"0x"+address.ToString("x");
    }
    static Dictionary<string,object> DesktopDebug(IntPtr root,int rootPid,IntPtr job,int seconds,string logs) {
        var result=new Dictionary<string,object>();var events=new List<Dictionary<string,object>>();
        var processes=new Dictionary<int,IntPtr>();var modules=new Dictionary<int,List<DesktopModule>>();
        var initialBreak=new HashSet<int>();var dumped=new HashSet<int>();var output=new StringBuilder();
        IntPtr buffer=Marshal.AllocHGlobal(512);bool exited=false;uint exitCode=259;
        var timer=Stopwatch.StartNew();
        try {
            while(timer.Elapsed.TotalSeconds<seconds && !exited) {
                if(!WaitForDebugEvent(buffer,200)) {if(Marshal.GetLastWin32Error()==121)continue;throw new Win32Exception(Marshal.GetLastWin32Error(),"debug_wait");}
                int kind=Marshal.ReadInt32(buffer),pid=Marshal.ReadInt32(buffer,4),tid=Marshal.ReadInt32(buffer,8);uint status=0x10002;
                if(!modules.ContainsKey(pid))modules[pid]=new List<DesktopModule>();
                var row=new Dictionary<string,object>{{"kind",kind},{"process",pid==rootPid?"main":"child"}};
                if(kind==3) {
                    IntPtr file=Marshal.ReadIntPtr(buffer,16),process=Marshal.ReadIntPtr(buffer,24),thread=Marshal.ReadIntPtr(buffer,32);
                    processes[pid]=process;string name=DesktopModuleName(file);row["image"]=name;
                    modules[pid].Add(new DesktopModule{Address=Marshal.ReadIntPtr(buffer,40).ToInt64(),Name=name});
                    try {var token=Token(process);row["isAppContainer"]=token[0];row["capabilityCount"]=token[1];row["samePackage"]=token[2]==Token(root)[2];}catch(Exception ex){row["tokenReadError"]=ex.GetType().Name;}
                    if(file!=IntPtr.Zero)CloseHandle(file);if(thread!=IntPtr.Zero)CloseHandle(thread);
                } else if(kind==6) {
                    IntPtr file=Marshal.ReadIntPtr(buffer,16);string name=DesktopModuleName(file);row["image"]=name;
                    modules[pid].Add(new DesktopModule{Address=Marshal.ReadIntPtr(buffer,24).ToInt64(),Name=name});if(file!=IntPtr.Zero)CloseHandle(file);
                } else if(kind==2) {IntPtr thread=Marshal.ReadIntPtr(buffer,16);if(thread!=IntPtr.Zero)CloseHandle(thread);}
                else if(kind==8) {
                    int length=(ushort)Marshal.ReadInt16(buffer,26);bool unicode=Marshal.ReadInt16(buffer,24)!=0;IntPtr process;
                    if(length>0 && processes.TryGetValue(pid,out process)) {var bytes=new byte[Math.Min(65536,length*(unicode?2:1))];IntPtr read;
                        if(ReadProcessMemory(process,Marshal.ReadIntPtr(buffer,16),bytes,(IntPtr)bytes.Length,out read)) {
                            string text=(unicode?Encoding.Unicode:Encoding.UTF8).GetString(bytes,0,read.ToInt32()).TrimEnd('\0');output.AppendLine(text);row["text"]=text;
                        }
                    }
                } else if(kind==1) {
                    uint code=unchecked((uint)Marshal.ReadInt32(buffer,16));long address=Marshal.ReadIntPtr(buffer,32).ToInt64();bool first=Marshal.ReadInt32(buffer,168)!=0;
                    row["exception"]="0x"+code.ToString("x8");row["address"]=DesktopAddress(address,modules[pid]);row["firstChance"]=first;
                    bool loader=code==0x80000003 && !initialBreak.Contains(pid);
                    if(loader){initialBreak.Add(pid);row["loaderBreakpoint"]=true;}
                    else {
                        status=0x80010001;
                        if(code==0x80000003 || !first) {
                            IntPtr process;if(processes.TryGetValue(pid,out process)) {
                                IntPtr thread=OpenThread(0x48,false,tid),allocation=Marshal.AllocHGlobal(1248);
                                IntPtr context=(IntPtr)((allocation.ToInt64()+15)&~15L);
                                try {for(int i=0;i<1232;i+=4)Marshal.WriteInt32(context,i,0);Marshal.WriteInt32(context,48,0x100003);
                                    if(thread!=IntPtr.Zero && GetThreadContext(thread,context)) {
                                        long stack=Marshal.ReadInt64(context,152);var bytes=new byte[2048];IntPtr read;
                                        if(ReadProcessMemory(process,(IntPtr)stack,bytes,(IntPtr)bytes.Length,out read)) {
                                            var frames=new List<string>();for(int i=0;i+8<=read.ToInt32();i+=8){string frame=DesktopAddress(BitConverter.ToInt64(bytes,i),modules[pid]);if(!frame.StartsWith("0x"))frames.Add(frame);}
                                            row["stackAddressCandidates"]=frames.Take(64).ToArray();
                                        }
                                    }
                                }finally{if(thread!=IntPtr.Zero)CloseHandle(thread);Marshal.FreeHGlobal(allocation);}
                                if(dumped.Add(pid))using(var dump=new FileStream(Path.Combine(logs,pid==rootPid?"main.dmp":"child-"+dumped.Count+".dmp"),FileMode.Create,FileAccess.Write)) {
                                    row["dumpWritten"]=MiniDumpWriteDump(process,pid,dump.SafeFileHandle.DangerousGetHandle(),0x140,IntPtr.Zero,IntPtr.Zero,IntPtr.Zero);
                                }
                            }
                        }
                    }
                } else if(kind==5) {row["exitCode"]=unchecked((uint)Marshal.ReadInt32(buffer,16));if(pid==rootPid){exitCode=unchecked((uint)Marshal.ReadInt32(buffer,16));exited=true;}}
                if(events.Count<4096)events.Add(row);
                Check(ContinueDebugEvent(pid,tid,status),"debug_continue");
            }
            if(!exited) {
                var snapshots=new List<Dictionary<string,object>>();int index=0;
                foreach(var entry in processes) {
                    uint current;if(!GetExitCodeProcess(entry.Value,out current) || current!=259)continue;
                    string filename=entry.Key==rootPid?"timeout-main.dmp":"timeout-child-"+(++index)+".dmp";
                    using(var dump=new FileStream(Path.Combine(logs,filename),FileMode.Create,FileAccess.Write)) {
                        bool ok=MiniDumpWriteDump(entry.Value,entry.Key,dump.SafeFileHandle.DangerousGetHandle(),0x1140,IntPtr.Zero,IntPtr.Zero,IntPtr.Zero);
                        snapshots.Add(new Dictionary<string,object>{{"file",filename},{"written",ok},{"error",ok?0:Marshal.GetLastWin32Error()}});
                    }
                }
                result["timeoutDumps"]=snapshots;
            }
            result["exitCode"]=exitCode;result["timedOut"]=!exited;result["events"]=events;
            File.WriteAllText(Path.Combine(logs,"debug-strings.txt"),output.ToString(),new UTF8Encoding(false));
            Save(Path.Combine(logs,"debug-events.json"),result);
            return result;
        }finally {
            // This observer never leaves the debuggee alive after the test.
            TerminateJobObject(job,1);TerminateProcess(root,1);
            var stop=Stopwatch.StartNew();while(stop.ElapsedMilliseconds<3000 && WaitForDebugEvent(buffer,100))ContinueDebugEvent(Marshal.ReadInt32(buffer,4),Marshal.ReadInt32(buffer,8),0x10002);
            foreach(var process in processes.Values)CloseHandle(process);
            Marshal.FreeHGlobal(buffer);
        }
    }
    internal static int DesktopCompatMain(string[] args) {
        if(args.Length==4 && args[0]=="--station-broker")return DesktopStationBroker(args[1],args[2],args[3]);
        if(args.Length==2 && args[0]=="--broker-station-test")return DesktopBrokerStationTest(args[1]);
        if(args.Length==2 && args[0]=="--broker-station-duplicate-test")return DesktopBrokerStationTest(args[1],true);
        if(args.Length==3 && args[0]=="--broker-station-worker")return DesktopBrokerStationWorker(args[1],args[2]);
        if(args.Length==3 && args[0]=="--broker-station-handle-worker")return DesktopBrokerStationWorker(args[1],args[2],true);
        if(args.Length==2 && args[0]=="--winstation-worker")return DesktopStationWorker(args[1]);
        if(args.Length==2 && args[0]=="--winstation-test")return DesktopStationTest(args[1]);
        Session session=null;var report=new Dictionary<string,object>();
        try {
            if(args.Length<3)throw new InvalidDataException("fixture executable seconds [args]");
            session=new Session("ac",args[0]);
            report=DesktopCompatLaunch(session,args[1],args.Skip(3).ToArray(),Int32.Parse(args[2]),"desktop-debug");
        }catch(Exception ex){report["error"]=ex.GetType().Name+": "+ex.Message;}
        finally {if(session!=null){session.Dispose();report["profileDeleteResult"]=session.DeleteResult;Save(Path.Combine(session.Fixture,"desktop-compat.json"),report);}}
        Console.WriteLine(new JavaScriptSerializer().Serialize(report));return report.ContainsKey("error")?1:0;
    }
    static Dictionary<string,object> DesktopCompatLaunch(Session session,string exe,string[] args,int timeout,string label) {
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
                Check(CreateProcess(exe,new StringBuilder(String.Join(" ",new[]{exe}.Concat(args).Select(Quote))),IntPtr.Zero,IntPtr.Zero,true,Extended|UnicodeEnv|NoWindow|Suspended|1,env,work,ref si,out pi),"CreateProcess");
                string[] token=Token(pi.process);
                result["tokenLpacClass46Supported"]=token[4]=="supported";result["lpacVerification"]="synthetic AccessCheck: exact package and ALL APPLICATION PACKAGES";
                if(token[0]!="1" || token[1]!="0" || token[2]!=session.Sid || token[3]!=(session.Mode=="lpac"?"1":"0")) throw new InvalidDataException("unexpected_child_token");
                result["tokenVerified"]=true; result["isAppContainer"]=true; result["capabilityCount"]=0; result["isLPAC"]=token[3]=="1";
                Check(AssignProcessToJobObject(job,pi.process),"assign_job");
                Check(ResumeThread(pi.thread)!=UInt32.MaxValue,"resume_child"); CloseHandle(pi.thread); pi.thread=IntPtr.Zero;
                var diagnostics=DesktopDebug(pi.process,pi.pid,job,timeout,logs);
                foreach(var entry in diagnostics)if(entry.Key!="events")result[entry.Key]=entry.Value;
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

}
