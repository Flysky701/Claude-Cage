// Candidate transport for the existing windowsGuestTerminal JSON protocol.
// Executable and arguments come from the trusted local controller, never JSON.
using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading;
using System.Web.Script.Serialization;

internal static partial class BoundaryProbe {
    static Dictionary<string,object> ReadTerminalMessage(TextReader input) {
        var line=new System.Text.StringBuilder();
        for(;;) {
            int next=input.Read();
            if(next<0) { if(line.Length==0)return null;throw new EndOfStreamException("terminal_message_incomplete"); }
            if(next=='\n')break;
            if(line.Length>=100*1024)throw new InvalidDataException("terminal_message_limit");
            line.Append((char)next);
        }
        var parser=new JavaScriptSerializer{MaxJsonLength=100*1024,RecursionLimit=8};
        var message=parser.DeserializeObject(line.ToString()) as Dictionary<string,object>;
        if(message==null)throw new InvalidDataException("terminal_message_invalid");
        return message;
    }
    static string TerminalText(Dictionary<string,object> message,string key) {
        object value;return message.TryGetValue(key,out value)?value as string:null;
    }
    static short TerminalSize(Dictionary<string,object> message,string key) {
        object value;
        if(!message.TryGetValue(key,out value) || !(value is int))throw new InvalidDataException("terminal_size_invalid");
        int size=(int)value;
        if(size<1 || size>(key=="cols"?599:500))throw new InvalidDataException("terminal_size_invalid");
        return (short)size;
    }
    static int TerminalRpc(string mode,string fixture,string executable,string[] arguments,string ownedProfile=null,string sessionID=null,string workingDirectory=null) {
        Session session=null;CandidateTerminal terminal=null;
        Thread drain=null,sender=null,reader=null,waiter=null;
        var report=new Dictionary<string,object>{{"protocol","windowsGuestTerminal JSON"},{"scope","offline disposable candidate; home workspace only"}};
        // The console drain must not block on a viewer which stopped reading.
        // Bounded output protects the controller; overflow ends this session.
        using(var messages=new BlockingCollection<Dictionary<string,object>>(32))
        using(var ended=new ManualResetEvent(false)) {
            var gate=new object(); string failure=null; bool childExited=false; int childCode=1;
            // The input reader can remain blocked until its parent closes the
            // pipe after seeing exit. Late EOF must not crash a disposed session.
            Action Signal=()=>{try{ended.Set();}catch(ObjectDisposedException){}};
            Action<string> Fail=reason=>{lock(gate){if(failure==null)failure=reason;}Signal();};
            Action<Dictionary<string,object>> Send=value=>{
                try{if(!messages.TryAdd(value))Fail("terminal_output_backpressure");}
                catch(InvalidOperationException){Fail("terminal_transport_closed");}
            };
            try {
                if(sessionID!=null && (mode!="ac" || ownedProfile==null || !System.Text.RegularExpressions.Regex.IsMatch(sessionID,"\\A[a-f0-9]{32}\\z")))throw new InvalidDataException("persistent_session_invalid");
                var open=ReadTerminalMessage(Console.In);
                string name=Path.GetFileNameWithoutExtension(executable).ToLowerInvariant();
                string expected=name=="cmd"?"cmd":name=="claude"?"claude":name=="powershell" || name=="pwsh"?"powershell":null;
                if(open==null || TerminalText(open,"action")!="open" || TerminalText(open,"workspace")!="home" || expected==null || TerminalText(open,"shell")!=expected)
                    throw new InvalidDataException("terminal_open_invalid");
                short cols=TerminalSize(open,"cols"),rows=TerminalSize(open,"rows");
                session=new Session(mode,fixture,ownedProfile,sessionID==null);
                terminal=new CandidateTerminal(session,executable,arguments,cols,rows,null,workingDirectory);
                foreach(var value in terminal.Receipt)report[value.Key]=value.Value;
                sender=new Thread(()=>{
                    try {
                        var json=new JavaScriptSerializer();
                        foreach(var value in messages.GetConsumingEnumerable()) {
                            Console.WriteLine(json.Serialize(value));Console.Out.Flush();
                        }
                    }catch {Fail("terminal_transport_closed");}
                }){IsBackground=true};sender.Start();
                Send(new Dictionary<string,object>{{"ready",true}});
                drain=new Thread(()=>{
                    try {
                        var buffer=new byte[32*1024];int count;
                        while((count=terminal.Output.Read(buffer,0,buffer.Length))>0) {
                            lock(gate){if(failure!=null)continue;}
                            Send(new Dictionary<string,object>{{"data",Convert.ToBase64String(buffer,0,count)}});
                        }
                    }catch(ObjectDisposedException){}catch(IOException){}catch {Fail("terminal_output_failed");}
                }){IsBackground=true};drain.Start();
                reader=new Thread(()=>{
                    try {
                        Dictionary<string,object> message;
                        while((message=ReadTerminalMessage(Console.In))!=null) {
                            switch(TerminalText(message,"action")) {
                                case "input":
                                    string encoded=TerminalText(message,"data");
                                    if(encoded==null)throw new InvalidDataException("terminal_input_invalid");
                                    byte[] data=Convert.FromBase64String(encoded);
                                    if(data.Length>64*1024)throw new InvalidDataException("terminal_input_limit");
                                    terminal.Input.Write(data,0,data.Length);terminal.Input.Flush();break;
                                case "resize":terminal.Resize(TerminalSize(message,"cols"),TerminalSize(message,"rows"));break;
                                case "close":Signal();return;
                                default:throw new InvalidDataException("terminal_action_invalid");
                            }
                        }
                        Signal();
                    }catch {Fail("terminal_input_failed");}
                }){IsBackground=true};reader.Start();
                waiter=new Thread(()=>{
                    try {int code=terminal.Wait();lock(gate){childCode=code;childExited=true;}}
                    catch {Fail("terminal_wait_failed");}
                    finally {Signal();}
                }){IsBackground=true};waiter.Start();
                ended.WaitOne();
                terminal.Stop();
                if(!drain.Join(5000))Fail("terminal_drain_timeout");
                if(!waiter.Join(5000))Fail("terminal_wait_timeout");
                lock(gate) {
                    report["childExited"]=childExited;report["exitCode"]=childCode;
                    if(failure!=null) {report["error"]=failure;Send(new Dictionary<string,object>{{"error",failure}});}
                    else Send(new Dictionary<string,object>{{"exit",childExited?childCode:0}});
                }
                messages.CompleteAdding();
                if(!sender.Join(5000)) {lock(gate){failure="terminal_transport_timeout";}report["error"]=failure;}
                return failure==null?0:1;
            }catch(Exception ex) {
                report["error"]=ex.GetType().Name+": "+ex.Message;
                if(sender==null)Console.WriteLine("{\"error\":\"terminal_open_failed\"}");
                return 1;
            }finally {
                // Stop while the reader still drains ConPTY, then release the
                // disposable package. The controller's own stdio is not inherited.
                lock(gate){if(failure==null)failure="terminal_closed";}
                if(terminal!=null){terminal.Stop();if(drain!=null)drain.Join(5000);terminal.Dispose();}
                if(session!=null){
                    session.Dispose();if(session.OwnsProfile)report["profileDeleteResult"]=session.DeleteResult;else report["profileCleanupOwner"]="host controller";
                    string receipt=sessionID==null?session.Fixture:Path.Combine(session.Fixture,"out",sessionID);
                    Directory.CreateDirectory(receipt);Save(Path.Combine(receipt,"terminal-rpc.json"),report);
                }
            }
        }
    }
}
