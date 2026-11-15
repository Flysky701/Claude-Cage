using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Net;
using System.Net.Sockets;
using System.Runtime.InteropServices;
using System.Text;
using System.Web.Script.Serialization;
using Microsoft.Win32;

// Synthetic inputs only. No discovery or reading of real user data.
class BoundaryProbe {
    [DllImport("SbieDll.dll", CharSet=CharSet.Unicode)]
    static extern int SbieApi_QueryProcess(IntPtr pid, StringBuilder box, StringBuilder image,
                                         StringBuilder sid, out uint session);
    [DllImport("SbieDll.dll")]
    static extern int SbieApi_QueryDrvInfo(int kind, out uint flags, uint length);
    static readonly JavaScriptSerializer Json = new JavaScriptSerializer();
    static object Try(Func<object> fn) {
        try { return new Dictionary<string,object>{{"ok",true},{"value",fn()}}; }
        catch(Exception ex) {
            var se=ex as SocketException;
            return new Dictionary<string,object>{{"ok",false},{"error",ex.GetType().Name},
                {"socketError",se==null?0:se.NativeErrorCode}};
        }
    }
    static object Tcp(string ip,int port) {
        using(var s=new Socket(IPAddress.Parse(ip).AddressFamily,SocketType.Stream,ProtocolType.Tcp)) {
            var op=s.BeginConnect(IPAddress.Parse(ip),port,null,null);
            if(!op.AsyncWaitHandle.WaitOne(1800)) throw new TimeoutException();
            s.EndConnect(op); return "connected";
        }
    }
    static object Udp(string ip,int port) {
        using(var s=new Socket(IPAddress.Parse(ip).AddressFamily,SocketType.Dgram,ProtocolType.Udp)) {
            s.ReceiveTimeout=1800; s.Connect(IPAddress.Parse(ip),port);
            s.Send(Encoding.ASCII.GetBytes("CageSyntheticProbe"));
            var data=new byte[80]; return s.Receive(data);
        }
    }
    static void Main(string[] args) {
        var cfg=Json.Deserialize<Dictionary<string,object>>(File.ReadAllText(args[0]));
        string role=args[1], phase=(string)cfg["phase"], hidden=(string)cfg["hidden"],
            closed=(string)cfg["closed"], reg=(string)cfg["registry"], output=(string)cfg["output"];
        var data=new Dictionary<string,object>{{"role",role},{"phase",phase},
            {"pid",Process.GetCurrentProcess().Id}};
        data["identity"]=Try(()=> {
            var box=new StringBuilder(128);var image=new StringBuilder(512);var sid=new StringBuilder(256);
            uint session;int rc=SbieApi_QueryProcess(new IntPtr(Process.GetCurrentProcess().Id),box,image,sid,out session);
            uint flags; int frc=SbieApi_QueryDrvInfo(0,out flags,4);
            return new Dictionary<string,object>{{"rc",rc},{"box",box.ToString()},
                {"session",session},{"driverFlagsRc",frc},{"driverFlags",flags},{"wfp",(flags&1)!=0}};
        });
        data["hiddenFile"]=Try(()=>File.ReadAllText(Path.Combine(hidden,"host-marker.txt")));
        data["closedFile"]=Try(()=>File.ReadAllText(Path.Combine(closed,"host-marker.txt")));
        data["hiddenRegistry"]=Try(()=> {
            using(var key=Registry.CurrentUser.OpenSubKey(reg)) return key==null?null:key.GetValue("HostOnly");
        });
        string file=Path.Combine(hidden,"persist-"+role+".txt");
        string value="BoxOnly-"+role;
        data["persistFileBefore"]=Try(()=>File.ReadAllText(file));
        data["persistRegistryBefore"]=Try(()=> {
            using(var key=Registry.CurrentUser.OpenSubKey(reg)) return key==null?null:key.GetValue(value);
        });
        if(phase=="first") {
            data["persistFileWrite"]=Try(()=> {Directory.CreateDirectory(hidden);File.WriteAllText(file,(string)cfg["token"]);return true;});
            data["persistRegistryWrite"]=Try(()=> {using(var key=Registry.CurrentUser.CreateSubKey(reg))key.SetValue(value,(string)cfg["token"]);return true;});
        }
        data["closedWrite"]=Try(()=> {File.WriteAllText(Path.Combine(closed,"should-not-exist-"+role+".txt"),"synthetic");return true;});
        foreach(string family in new[]{"4","6"}) {
            string ip=family=="4"?"127.0.0.1":"::1";
            data["tcp"+family]=Try(()=>Tcp(ip,Convert.ToInt32(cfg["tcp"+family])));
            data["udp"+family]=Try(()=>Udp(ip,Convert.ToInt32(cfg["udp"+family])));
        }
        data["publicTcp4"]=Try(()=>Tcp("1.1.1.1",443));
        if(role=="parent") {
            var start=new ProcessStartInfo(Process.GetCurrentProcess().MainModule.FileName,
                "\""+args[0]+"\" child") {UseShellExecute=false,CreateNoWindow=true};
            using(var child=Process.Start(start)) {
                data["childPid"]=child.Id;
                data["childExited"]=child.WaitForExit(25000);
                if(child.HasExited)data["childExitCode"]=child.ExitCode;
            }
        }
        File.WriteAllText(Path.Combine(output,phase+"-"+role+".json"),Json.Serialize(data));
    }
}
