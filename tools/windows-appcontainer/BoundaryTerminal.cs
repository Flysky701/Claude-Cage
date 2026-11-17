// Local candidate terminal. Host ConPTY pipes are not inherited by the child.
// Keep reading Output until after Stop: ClosePseudoConsole can flush output.
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.IO;
using System.Linq;
using System.Runtime.InteropServices;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading;
using Microsoft.Win32.SafeHandles;

internal static partial class BoundaryProbe {
    [StructLayout(LayoutKind.Sequential)] struct TerminalCoord {
        internal short X,Y;
        internal TerminalCoord(short x,short y) { X=x;Y=y; }
    }
    [DllImport("kernel32",SetLastError=true)] static extern bool CreatePipe(out SafeFileHandle read,out SafeFileHandle write,IntPtr attributes,uint size);
    [DllImport("kernel32")] static extern int CreatePseudoConsole(TerminalCoord size,SafeFileHandle input,SafeFileHandle output,uint flags,out IntPtr console);
    [DllImport("kernel32")] static extern int ResizePseudoConsole(IntPtr console,TerminalCoord size);
    [DllImport("kernel32")] static extern void ClosePseudoConsole(IntPtr console);

    sealed class CandidateTerminal:IDisposable {
        internal FileStream Input { get; private set; }
        internal FileStream Output { get; private set; }
        internal readonly Dictionary<string,object> Receipt=new Dictionary<string,object>();
        IntPtr console,process,job;
        readonly object gate=new object();
        int stopped,disposed;

        internal CandidateTerminal(Session session,string exe,string[] args,short cols,short rows,Dictionary<string,string> extraEnvironment=null,string workingDirectory=null) {
            if(cols<1 || cols>599 || rows<1 || rows>500)throw new InvalidDataException("terminal_size_invalid");
            string workRoot=Path.Combine(session.Fixture,"work"),projectRoot=Path.Combine(session.Fixture,"projects");
            string directory=workingDirectory==null?workRoot:Path.GetFullPath(workingDirectory);
            if(!(directory.Equals(workRoot,StringComparison.OrdinalIgnoreCase) || Inside(directory,workRoot) || directory.Equals(projectRoot,StringComparison.OrdinalIgnoreCase) || Inside(directory,projectRoot)) || !Directory.Exists(directory))throw new InvalidDataException("terminal_directory_not_granted");
            exe=Path.GetFullPath(exe);
            var installedRoots=new[]{Environment.GetFolderPath(Environment.SpecialFolder.Windows),Environment.GetEnvironmentVariable("ProgramFiles"),Environment.GetEnvironmentVariable("ProgramFiles(x86)")};
            if(!Inside(exe,Path.Combine(session.Fixture,"tools")) && !installedRoots.Any(p=>!String.IsNullOrEmpty(p) && Inside(exe,Path.GetFullPath(p))))throw new InvalidDataException("terminal_executable_not_staged_or_system_installed");
            if(!File.Exists(exe))throw new FileNotFoundException("terminal_executable_missing");
            SafeFileHandle inputRead=null,inputWrite=null,outputRead=null,outputWrite=null;
            IntPtr attributes=IntPtr.Zero,cap=IntPtr.Zero,policy=IntPtr.Zero,env=IntPtr.Zero;
            bool ready=false;Pi pi=new Pi();
            try {
                Check(CreatePipe(out inputRead,out inputWrite,IntPtr.Zero,0),"terminal_input_pipe");
                Check(CreatePipe(out outputRead,out outputWrite,IntPtr.Zero,0),"terminal_output_pipe");
                Marshal.ThrowExceptionForHR(CreatePseudoConsole(new TerminalCoord(cols,rows),inputRead,outputWrite,0,out console));
                int count=session.Mode=="lpac"?3:2;IntPtr bytes=IntPtr.Zero;
                InitializeProcThreadAttributeList(IntPtr.Zero,count,0,ref bytes);
                attributes=Marshal.AllocHGlobal(bytes);Check(InitializeProcThreadAttributeList(attributes,count,0,ref bytes),"terminal_initialize_attributes");ready=true;
                // PSEUDOCONSOLE expects HPCON itself, not a pointer to HPCON.
                Check(UpdateProcThreadAttribute(attributes,0,(IntPtr)0x20016,console,(IntPtr)IntPtr.Size,IntPtr.Zero,IntPtr.Zero),"terminal_pseudoconsole_attribute");
                var caps=new Capabilities{sid=session.sid};cap=Marshal.AllocHGlobal(Marshal.SizeOf(caps));Marshal.StructureToPtr(caps,cap,false);
                Check(UpdateProcThreadAttribute(attributes,0,(IntPtr)0x20009,cap,(IntPtr)Marshal.SizeOf(caps),IntPtr.Zero,IntPtr.Zero),"terminal_security_capabilities");
                if(session.Mode=="lpac") {policy=Marshal.AllocHGlobal(4);Marshal.WriteInt32(policy,1);Check(UpdateProcThreadAttribute(attributes,0,(IntPtr)0x2000f,policy,(IntPtr)4,IntPtr.Zero,IntPtr.Zero),"terminal_lpac_policy");}
                string work=Path.Combine(session.Fixture,"work"),windows=Environment.GetFolderPath(Environment.SpecialFolder.Windows);
                var vars=new SortedDictionary<string,string>(StringComparer.OrdinalIgnoreCase) {
                    {"SystemRoot",windows},{"WINDIR",windows},{"COMSPEC",Path.Combine(Environment.SystemDirectory,"cmd.exe")},
                    {"PATH",Path.Combine(session.Fixture,"tools")+";"+Path.GetDirectoryName(exe)+";"+Environment.SystemDirectory+";"+Path.Combine(Environment.SystemDirectory,"WindowsPowerShell","v1.0")},
                    {"PATHEXT",".COM;.EXE;.BAT;.CMD"},{"USERPROFILE",work},{"HOME",work},{"APPDATA",work},{"LOCALAPPDATA",work},
                    {"TEMP",Path.Combine(work,"Temp")},{"TMP",Path.Combine(work,"Temp")},{"TERM","xterm-256color"},
                    {"PYTHONUTF8","1"},{"PYTHONDONTWRITEBYTECODE","1"},
                    // Synthetic markers ensure typed command echo cannot pass checks.
                    {"CAGE_TERMINAL_IO","INPUT_OUTPUT_PASS"},{"CAGE_TERMINAL_AFTER","AFTER_INTERRUPT_PASS"}
                };
                // Only trusted local callers can supply app-specific settings.
                // The RPC has no environment input, and the clean base cannot be
                // replaced with a host profile, PATH or temporary directory.
                if(extraEnvironment!=null)foreach(var pair in extraEnvironment) {
                    if(String.IsNullOrEmpty(pair.Key) || pair.Key.IndexOfAny(new[]{'\0','='})>=0 || pair.Value==null || pair.Value.IndexOf('\0')>=0 || vars.ContainsKey(pair.Key))throw new InvalidDataException("terminal_environment_invalid");
                    vars.Add(pair.Key,pair.Value);
                }
                env=Marshal.StringToHGlobalUni(String.Join("\0",vars.Select(v=>v.Key+"="+v.Value))+"\0\0");
                var startup=new StartupEx{attributes=attributes};startup.si.cb=Marshal.SizeOf(typeof(StartupEx));
                // Request fresh console std handles even if the parent is redirected.
                startup.si.flags=0x100;
                job=CreateJobObject(IntPtr.Zero,null);Check(job!=IntPtr.Zero,"terminal_create_job");
                IntPtr limits=Marshal.AllocHGlobal(144);
                try {Marshal.Copy(new byte[144],0,limits,144);Marshal.WriteInt32(limits,16,0x2000);Check(SetInformationJobObject(job,9,limits,144),"terminal_kill_on_close_job");}
                finally {Marshal.FreeHGlobal(limits);}
                Check(CreateProcess(exe,new StringBuilder(String.Join(" ",new[]{exe}.Concat(args).Select(Quote))),IntPtr.Zero,IntPtr.Zero,false,Extended|UnicodeEnv|Suspended,env,directory,ref startup,out pi),"terminal_CreateProcess");
                process=pi.process;
                string[] token=Token(process);
                if(token[0]!="1" || token[1]!="0" || token[2]!=session.Sid || token[3]!=(session.Mode=="lpac"?"1":"0"))throw new InvalidDataException("terminal_unexpected_child_token");
                Receipt["tokenVerified"]=true;Receipt["isAppContainer"]=true;Receipt["capabilityCount"]=0;Receipt["isLPAC"]=token[3]=="1";
                Receipt["tokenLpacClass46Supported"]=token[4]=="supported";Receipt["lpacVerification"]="synthetic AccessCheck: exact package and ALL APPLICATION PACKAGES";
                Check(AssignProcessToJobObject(job,process),"terminal_assign_job");
                Check(ResumeThread(pi.thread)!=UInt32.MaxValue,"terminal_resume_child");
                Input=new FileStream(inputWrite,FileAccess.Write,4096,false);inputWrite=null;
                Output=new FileStream(outputRead,FileAccess.Read,4096,false);outputRead=null;
            } catch {
                if(process!=IntPtr.Zero)TerminateProcess(process,1);
                // Constructor failures occur before a caller can start its drain.
                // Consume final console bytes while closing it here.
                Thread drain=null;
                if(outputRead!=null && !outputRead.IsInvalid) {
                    var stream=new FileStream(outputRead,FileAccess.Read,4096,false);outputRead=null;
                    drain=new Thread(()=>{try {var b=new byte[4096];while(stream.Read(b,0,b.Length)>0){}}catch(IOException){}finally{stream.Dispose();}});drain.IsBackground=true;drain.Start();
                }
                Dispose();if(drain!=null)drain.Join(5000);throw;
            } finally {
                if(pi.thread!=IntPtr.Zero)CloseHandle(pi.thread);
                if(inputRead!=null)inputRead.Dispose();if(inputWrite!=null)inputWrite.Dispose();
                if(outputRead!=null)outputRead.Dispose();if(outputWrite!=null)outputWrite.Dispose();
                if(ready)DeleteProcThreadAttributeList(attributes);
                foreach(var p in new[]{attributes,cap,policy,env})if(p!=IntPtr.Zero)Marshal.FreeHGlobal(p);
            }
        }
        internal void Resize(short cols,short rows) {
            if(cols<1 || cols>599 || rows<1 || rows>500)throw new InvalidDataException("terminal_size_invalid");
            lock(gate) {if(console==IntPtr.Zero)throw new ObjectDisposedException("CandidateTerminal");Marshal.ThrowExceptionForHR(ResizePseudoConsole(console,new TerminalCoord(cols,rows)));}
        }
        internal bool Wait(int milliseconds) {
            if(milliseconds<0)throw new ArgumentOutOfRangeException("milliseconds");
            uint result=WaitForSingleObject(process,(uint)milliseconds);
            if(result!=0 && result!=258)throw new Win32Exception(Marshal.GetLastWin32Error(),"terminal_wait_failed");
            return result==0;
        }
        internal int Wait() {
            if(WaitForSingleObject(process,UInt32.MaxValue)!=0)throw new Win32Exception(Marshal.GetLastWin32Error(),"terminal_wait_failed");
            uint code;Check(GetExitCodeProcess(process,out code),"terminal_exit_code");return unchecked((int)code);
        }
        internal void Stop() {
            if(Interlocked.Exchange(ref stopped,1)!=0)return;
            lock(gate) {
                if(job!=IntPtr.Zero) {CloseHandle(job);job=IntPtr.Zero;}
                if(Input!=null)Input.Dispose();
                if(console!=IntPtr.Zero) {ClosePseudoConsole(console);console=IntPtr.Zero;}
            }
        }
        public void Dispose() {
            if(Interlocked.Exchange(ref disposed,1)!=0)return;
            Stop();if(Output!=null)Output.Dispose();
            if(process!=IntPtr.Zero) {WaitForSingleObject(process,5000);CloseHandle(process);process=IntPtr.Zero;}
        }
    }

    // A continuously draining capture is deliberately separate from the terminal.
    sealed class TerminalCapture {
        readonly CandidateTerminal terminal;readonly string path;
        readonly object gate=new object();readonly StringBuilder text=new StringBuilder();
        readonly Thread reader;internal string Error;internal bool Drained;
        internal TerminalCapture(CandidateTerminal terminal,string path) {
            this.terminal=terminal;this.path=path;
            reader=new Thread(Read);reader.IsBackground=true;reader.Start();
        }
        void Read() {
            try {
                using(var log=new FileStream(path,FileMode.Create,FileAccess.Write,FileShare.ReadWrite)) {
                    var bytes=new byte[8192];var chars=new char[8192];var decoder=Encoding.UTF8.GetDecoder();int count;
                    while((count=terminal.Output.Read(bytes,0,bytes.Length))!=0) {
                        log.Write(bytes,0,count);log.Flush();int used=decoder.GetChars(bytes,0,count,chars,0,false);
                        lock(gate) {if(text.Length+used>4*1024*1024)throw new InvalidDataException("terminal_capture_limit");text.Append(chars,0,used);Monitor.PulseAll(gate);}
                    }
                }
            } catch(IOException ex) {if((ex.HResult&65535)!=109)Error=ex.GetType().Name+": "+ex.Message;}
              catch(Exception ex) {Error=ex.GetType().Name+": "+ex.Message;}
            finally {lock(gate){Drained=true;Monitor.PulseAll(gate);}}
        }
        internal bool Contains(string expected,int timeout) {
            var deadline=DateTime.UtcNow.AddMilliseconds(timeout);
            lock(gate) {
                while(true) {
                    // ConPTY may encode spaces as horizontal cursor movement.
                    // Preserve those spaces before stripping other CSI controls.
                    string spaced=Regex.Replace(text.ToString(),"\x1b\\[([0-9]*)C",m=>new string(' ',m.Groups[1].Value.Length==0?1:Math.Min(599,Int32.Parse(m.Groups[1].Value))));
                    string clean=Regex.Replace(spaced,"\x1b\\[[0-?]*[ -/]*[@-~]","");
                    if(clean.Contains(expected))return true;
                    if(Drained || Error!=null || DateTime.UtcNow>=deadline)return false;
                    Monitor.Wait(gate,Math.Max(1,Math.Min(100,(int)(deadline-DateTime.UtcNow).TotalMilliseconds)));
                }
            }
        }
        internal bool Join(int timeout) {return reader.Join(timeout);}
    }
    static void TerminalInput(CandidateTerminal terminal,string text) {
        var bytes=Encoding.UTF8.GetBytes(text);terminal.Input.Write(bytes,0,bytes.Length);terminal.Input.Flush();
    }
    static void TerminalRequire(Dictionary<string,object> result,string name,bool passed) {
        result[name]=passed;if(!passed)throw new InvalidDataException("terminal_check_failed: "+name);
    }
    static Dictionary<string,object> TerminalSuite(string mode) {
        string fixture=Path.Combine(BuildRoot,"terminal-"+mode+"-"+Guid.NewGuid().ToString("N"));
        var result=new Dictionary<string,object>{{"mode",mode},{"scope","offline cmd ConPTY input/output, native child identity, Ctrl+C, resize and teardown"}};
        Session session=null;CandidateTerminal terminal=null;TerminalCapture capture=null;
        try {
            session=new Session(mode,fixture);
            foreach(string file in new[]{"CompatibilityHelper.exe","TerminalWorker.exe"})File.Copy(Path.Combine(BuildRoot,file),Path.Combine(fixture,"tools",file));
            terminal=new CandidateTerminal(session,Path.Combine(Environment.SystemDirectory,"cmd.exe"),new[]{"/d","/q"},100,30);
            foreach(var item in terminal.Receipt)result[item.Key]=item.Value;
            capture=new TerminalCapture(terminal,Path.Combine(fixture,"out","terminal.txt"));
            TerminalInput(terminal,"echo CAGE_%CAGE_TERMINAL_IO%\r");
            TerminalRequire(result,"inputOutputPassed",capture.Contains("CAGE_INPUT_OUTPUT_PASS",6000));
            TerminalInput(terminal,Quote(Path.Combine(fixture,"tools","CompatibilityHelper.exe"))+" token "+mode+"\r");
            TerminalRequire(result,"childSamePackagePassed",capture.Contains("CAGE_TOKEN_VERIFIED:"+mode+":"+session.Sid,6000));
            TerminalInput(terminal,Quote(Path.Combine(fixture,"tools","TerminalWorker.exe"))+" size\r");
            TerminalRequire(result,"initialSizePassed",capture.Contains("CAGE_CONSOLE_SIZE:100x30",6000));
            terminal.Resize(117,41);
            TerminalInput(terminal,Quote(Path.Combine(fixture,"tools","TerminalWorker.exe"))+" size\r");
            TerminalRequire(result,"resizePassed",capture.Contains("CAGE_CONSOLE_SIZE:117x41",6000));
            TerminalInput(terminal,Quote(Path.Combine(fixture,"tools","TerminalWorker.exe"))+" interrupt\r");
            TerminalRequire(result,"interruptWorkerReady",capture.Contains("CAGE_INTERRUPT_READY",6000));
            TerminalInput(terminal,"\x03");
            TerminalRequire(result,"ctrlCPassed",capture.Contains("CAGE_CTRL_C_RECEIVED",6000));
            TerminalInput(terminal,"echo CAGE_%CAGE_TERMINAL_AFTER%\r");
            TerminalRequire(result,"inputAfterInterruptPassed",capture.Contains("CAGE_AFTER_INTERRUPT_PASS",6000));
            TerminalInput(terminal,"exit 0\r");
            TerminalRequire(result,"normalExitPassed",terminal.Wait(6000));result["exitCode"]=terminal.Wait();
        } catch(Exception ex) {result["error"]=ex.GetType().Name+": "+ex.Message;}
        finally {
            if(terminal!=null) {
                terminal.Stop();
                if(capture!=null) {result["outputDrained"]=capture.Join(5000);if(capture.Error!=null)result["outputError"]=capture.Error;}
                terminal.Dispose();
            }
            if(session!=null) {session.Dispose();result["profileDeleteResult"]=session.DeleteResult;}
        }
        result["passed"]=!result.ContainsKey("error") && !result.ContainsKey("outputError") && result.ContainsKey("outputDrained") && (bool)result["outputDrained"] && Convert.ToInt32(result["exitCode"])==0 && Convert.ToInt32(result["profileDeleteResult"])==0;
        Directory.CreateDirectory(fixture);Save(Path.Combine(fixture,"terminal-result.json"),result);return result;
    }
}
