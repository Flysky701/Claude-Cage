using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Globalization;
using System.IO;
using System.Net;
using System.Net.Security;
using System.Net.Sockets;
using System.Runtime.InteropServices;
using System.Security.Authentication;
using System.Text;
using System.Threading;
using System.Web.Script.Serialization;

internal static class RawPair {
    [StructLayout(LayoutKind.Sequential)] private struct ST {
        public ushort y,m,dow,d,h,min,s,ms;
        public DateTime Value { get {return new DateTime(y,m,d,h,min,s,ms);} }
    }
    [DllImport("kernel32")] static extern uint GetDynamicTimeZoneInformation(IntPtr buffer);
    [DllImport("kernel32")] static extern void GetLocalTime(out ST value);
    [DllImport("kernel32")] static extern void GetSystemTime(out ST value);

    static string Attempt(Func<string> call) {
        try{return call();}catch(Exception e){return "ERROR "+e.GetBaseException().Message;}
    }
    static TcpClient Connect(string address,int port) {
        var tcp=new TcpClient();
        try {
            var op=tcp.BeginConnect(IPAddress.Parse(address),port,null,null);
            if(!op.AsyncWaitHandle.WaitOne(3500)) throw new TimeoutException("connect timeout");
            tcp.EndConnect(op);tcp.ReceiveTimeout=15000;tcp.SendTimeout=5000;return tcp;
        }catch{tcp.Close();throw;}
    }
    static string Exchange(int servicePort) {
        // No HTTP client, proxy option, proxy discovery, or read of proxy environment variables.
        using(var tcp=Connect("127.0.0.1",servicePort))
        using(var tls=new SslStream(tcp.GetStream(),false)){
            tls.ReadTimeout=15000;tls.WriteTimeout=5000;
            tls.AuthenticateAsClient("1.1.1.1",null,SslProtocols.Tls12,false);
            byte[] query=Encoding.ASCII.GetBytes("GET /dns-query?dns=EjQBAAABAAAAAAAAB2V4YW1wbGUDY29tAAABAAE HTTP/1.1\r\nHost: 1.1.1.1\r\nAccept: application/dns-message\r\nConnection: close\r\n\r\n");
            tls.Write(query,0,query.Length);
            using(var data=new MemoryStream()){
                byte[] buf=new byte[4096];int n;
                while((n=tls.Read(buf,0,buf.Length))>0){data.Write(buf,0,n);if(data.Length>65536)throw new IOException("oversize");}
                byte[] wire=data.ToArray();string latin=Encoding.GetEncoding(28591).GetString(wire);int start=latin.IndexOf("\r\n\r\n",StringComparison.Ordinal);
                if(start<0||!latin.StartsWith("HTTP/1.1 200 "))throw new IOException("invalid HTTP response");
                string hdr=latin.Substring(0,start);start+=4;
                if(hdr.IndexOf("application/dns-message",StringComparison.OrdinalIgnoreCase)<0)throw new IOException("wrong content type");
                if(hdr.IndexOf("Transfer-Encoding: chunked",StringComparison.OrdinalIgnoreCase)>=0){
                    int end=latin.IndexOf("\r\n",start,StringComparison.Ordinal);
                    int size=int.Parse(latin.Substring(start,end-start).Split(';')[0],NumberStyles.HexNumber);
                    if(size<12)throw new IOException("short first DNS chunk");start=end+2;
                }
                if(wire.Length<start+12||wire[start]!=0x12||wire[start+1]!=0x34||(wire[start+2]&128)==0||(wire[start+3]&15)!=0)throw new IOException("invalid DNS reply");
                int count=wire[start+6]*256+wire[start+7];if(count<1)throw new IOException("no answers");
                return "TLS verified; HTTP 200; DNS ID 4660; answers "+count;
            }
        }
    }
    static string Direct(string ip,int port){using(var c=Connect(ip,port)){return "CONNECTED";}}
    static void Write(string dir,string role,string phase,int port) {
        var row=new Dictionary<string,object>();
        row["pid"]=Process.GetCurrentProcess().Id;row["image"]=Process.GetCurrentProcess().MainModule.FileName;
        row["role"]=role;row["phase"]=phase;row["servicePort"]=port;
        var zone=Marshal.AllocHGlobal(1024);
        try {row["zone"]=GetDynamicTimeZoneInformation(zone)==UInt32.MaxValue?"error":Marshal.PtrToStringUni(IntPtr.Add(zone,172));}finally{Marshal.FreeHGlobal(zone);}
        ST utc,local;GetSystemTime(out utc);GetLocalTime(out local);
        row["utc"]=utc.Value.ToString("s");row["local"]=local.Value.ToString("s");row["offsetMinutes"]=Math.Round((local.Value-utc.Value).TotalMinutes);
        string fresh="raw"+Guid.NewGuid().ToString("N").Substring(0,16)+".cage.test.";
        row["freshName"]=fresh;row["fresh"]=Attempt(()=>String.Join<IPAddress>(",",Dns.GetHostAddresses(fresh)));
        row["dns"]=Attempt(()=>String.Join<IPAddress>(",",Dns.GetHostAddresses(phase=="online"?"example.com.":"example.org.")));
        row["exchange"]=Attempt(()=>Exchange(port));row["directControl"]=Attempt(()=>Direct("127.0.0.1",39583));
        row["directOriginal"]=Attempt(()=>Direct("1.1.1.1",443));
        string path=Path.Combine(dir,role+"-"+phase+".json");
        File.WriteAllText(path+".tmp",new JavaScriptSerializer().Serialize(row));File.Move(path+".tmp",path);
    }
    static int Main(string[] args) {
        if(args.Length<2 || args.Length>3 || (args.Length==3 && args[2]!="--wait-cut"))return 2;
        string dir=args[0];Directory.CreateDirectory(dir);int port=int.Parse(args[1]);bool waitForCut=args.Length==3;
#if PARENT
        const string role="parent";
        string child=Path.Combine(AppDomain.CurrentDomain.BaseDirectory,"RawChild.exe");
        var childInfo=new ProcessStartInfo(child,"\""+dir+"\" "+port+(waitForCut?" --wait-cut":"")){UseShellExecute=false};
        using(var worker=Process.Start(childInfo)){
#else
        const string role="child";
#endif
        Write(dir,role,"online",port);
        if(waitForCut){
        var watch=Stopwatch.StartNew();
        while(!File.Exists(Path.Combine(dir,"cut.signal"))){if(watch.Elapsed.TotalSeconds>75)return 3;Thread.Sleep(100);}
        Write(dir,role,"off",port);}
#if PARENT
        return worker.WaitForExit(45000)?worker.ExitCode:4;}
#else
        return 0;
#endif
    }
}
