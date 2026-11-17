// Optional process-local input compatibility followed by a bounded crash trace.
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Runtime.InteropServices;
using System.Web.Script.Serialization;
internal static class EdgeCompatDebugEntry {static int Main(string[] args){return BoundaryProbe.EdgeCompatDebugMain(args);}}
internal static partial class BoundaryProbe {
    [DllImport("kernel32",SetLastError=true)] static extern bool DebugActiveProcess(int process);
    internal static int EdgeCompatDebugMain(string[] args) {
        if(args.Length<3)return 2;
        Session session=null;var result=new Dictionary<string,object>();
        try {
            session=new Session("ac",args[0]);
            result=Launch(session,args[1],args.Skip(3).ToArray(),Int32.Parse(args[2]),"edge-debug",
                (process,pid)=>{InitializeBrowserInput(process,pid);Check(DebugActiveProcess(pid),"debug_attach_initialized_process");},null,
                (process,pid,job,seconds)=>DesktopDebug(process,pid,job,seconds,Path.Combine(session.Fixture,"out","edge-debug")));
        }catch(Exception ex){result["error"]=ex.GetType().Name+": "+ex.Message;}
        finally{if(session!=null){session.Dispose();result["profileDeleteResult"]=session.DeleteResult;Save(Path.Combine(session.Fixture,"edge-debug.json"),result);}}
        Console.WriteLine(new JavaScriptSerializer().Serialize(result));return result.ContainsKey("error")?1:0;
    }
}
