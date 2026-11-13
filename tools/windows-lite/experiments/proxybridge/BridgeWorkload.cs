using System;
using System.Diagnostics;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Net;
using System.Net.Sockets;
using System.Net.Security;
using System.Runtime.InteropServices;
using System.Security.Authentication;
using System.Text;
using System.Threading;
using System.Web.Script.Serialization;

internal static class BridgeWorkload {
    [StructLayout(LayoutKind.Sequential)] struct ST { public ushort year,month,dow,day,h,m,s,ms; public DateTime Value{get{return new DateTime(year,month,day,h,m,s,ms);}} }
    [DllImport("kernel32")] static extern uint GetDynamicTimeZoneInformation(IntPtr p);
    [DllImport("kernel32")] static extern void GetLocalTime(out ST t);
    [DllImport("kernel32")] static extern void GetSystemTime(out ST t);
    static readonly JavaScriptSerializer json=new JavaScriptSerializer();
    static string ExitIP(string host,int port) {
        using(var tcp=new TcpClient()){
            var op=tcp.BeginConnect(IPAddress.Parse(host),port,null,null);
            if(!op.AsyncWaitHandle.WaitOne(7000))throw new TimeoutException("connect timeout");
            tcp.EndConnect(op); tcp.ReceiveTimeout=8000;tcp.SendTimeout=5000;
            using(var tls=new SslStream(tcp.GetStream(),false)){
                tls.ReadTimeout=8000;tls.WriteTimeout=5000;tls.AuthenticateAsClient("1.1.1.1",null,SslProtocols.Tls12,false);
                var data=Encoding.ASCII.GetBytes("GET /cdn-cgi/trace HTTP/1.1\r\nHost: 1.1.1.1\r\nConnection: close\r\n\r\n");tls.Write(data,0,data.Length);
                using(var r=new StreamReader(tls,Encoding.ASCII)){
                    string status=r.ReadLine();if(status==null||!status.StartsWith("HTTP/1.1 200 "))throw new IOException("no HTTP 200");
                    for(int i=0;i<100;i++){string l=r.ReadLine();if(l==null)break;if(l.StartsWith("ip=")){IPAddress ip;if(IPAddress.TryParse(l.Substring(3).Trim(),out ip))return ip.ToString();}}
                    throw new IOException("no exit IP in trace response");
                }
            }
        }
    }
    static void Emit(string path,object value){File.WriteAllText(path+".tmp",json.Serialize(value));File.Move(path+".tmp",path);}
    static int Run(string dir,string role){
        var process=Process.GetCurrentProcess();
        Emit(Path.Combine(dir,role+".pid"),process.Id);
        var expiry=Stopwatch.StartNew();
        for(int i=0;i<48;i++){
            string file=Path.Combine(dir,role+"-"+i+".cmd");
            while(!File.Exists(file)){if(File.Exists(Path.Combine(dir,"done"))||expiry.Elapsed.TotalMinutes>12)return 0;Thread.Sleep(80);}
            string[] p=File.ReadAllText(file).Trim().Split(' ');
            var row=new Dictionary<string,object>();row["pid"]=process.Id;row["role"]=role;row["image"]=process.MainModule.FileName;
            ST utc,local;GetSystemTime(out utc);GetLocalTime(out local);row["utc"]=utc.Value.ToString("s");row["local"]=local.Value.ToString("s");row["offset"]=Math.Round((local.Value-utc.Value).TotalMinutes);
            IntPtr tz=Marshal.AllocHGlobal(1024);try {if(GetDynamicTimeZoneInformation(tz)!=UInt32.MaxValue)row["zone"]=Marshal.PtrToStringUni(IntPtr.Add(tz,172));}finally{Marshal.FreeHGlobal(tz);}
            try{
                if(p[0]=="dns"){string name=p[1];row["name"]=name;row["addresses"]=String.Join<IPAddress>(",",Dns.GetHostAddresses(name));}
                else{int port=int.Parse(p[1]);string host=p[0]=="original"?"1.1.1.1":"127.0.0.1";row["target"]=host+":"+port;row["exit"]=ExitIP(host,port);row["https"]=200;}
            }catch(Exception e){var x=e.GetBaseException();row["error"]=x.GetType().Name+": "+x.Message;}
            Emit(Path.Combine(dir,role+"-"+i+".json"),row);
        }
        return 0;
    }
    static int Main(string[] a){if(a.Length!=1)return 2;string dir=a[0];Directory.CreateDirectory(dir);
#if PARENT
        var info=new ProcessStartInfo(Path.Combine(AppDomain.CurrentDomain.BaseDirectory,"CagePBCheckChild.exe"),"\""+dir+"\""){UseShellExecute=false};using(var child=Process.Start(info)){int rc=Run(dir,"parent");return child.WaitForExit(15000)?rc:4;}
#else
        return Run(dir,"child");
#endif
    }
}
