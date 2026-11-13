using System;
using System.Net;
using System.Net.Sockets;
using System.Text;
using System.Diagnostics;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.IO;
using System.Threading.Tasks;
using System.Windows.Forms;
using System.Web.Script.Serialization;

class Probe {
    [StructLayout(LayoutKind.Sequential)] struct ST { public ushort year,month,dayOfWeek,day,hour,minute,second,ms; public DateTime Value { get {return new DateTime(year,month,day,hour,minute,second);} } }
    [DllImport("kernel32",CharSet=CharSet.Unicode)] static extern uint GetDynamicTimeZoneInformation(IntPtr zone);
    [DllImport("kernel32")] static extern void GetLocalTime(out ST t);
    [DllImport("kernel32")] static extern void GetSystemTime(out ST t);
    static string[] args;
    static readonly JavaScriptSerializer json=new JavaScriptSerializer();
    static void Save(string role, object data) { string f=Path.Combine(args[1],args[0]+"-"+role+".json"); File.WriteAllText(f+".tmp",json.Serialize(data)); File.Move(f+".tmp",f); }
    static string Obs(Func<string> call) {try {return call();} catch(Exception e) {var n=e as SocketException;return n==null?e.GetType().Name+" "+e.Message:"SocketError "+n.NativeErrorCode;}}
    static string Tcp(string ip) {var a=IPAddress.Parse(ip);using(var s=new Socket(a.AddressFamily,SocketType.Stream,ProtocolType.Tcp)){var op=s.BeginConnect(a,39483,null,null);if(!op.AsyncWaitHandle.WaitOne(2500))return "timeout";s.EndConnect(op);return "connected";}}
    static string Udp(string ip) {
        byte[] query={0x52,0x21,1,0,0,1,0,0,0,0,0,0,7,101,120,97,109,112,108,101,3,111,114,103,0,0,1,0,1};
        var addr=IPAddress.Parse(ip);using(var s=new Socket(addr.AddressFamily,SocketType.Dgram,ProtocolType.Udp)){s.ReceiveTimeout=2500;s.Connect(addr,39484);s.Send(query);var buf=new byte[1200];int n=s.Receive(buf);return "reply "+n+" bytes";}
    }
    static string ViaProxy(string proxy) {var r=(HttpWebRequest)WebRequest.Create("https://api.ipify.org/?format=json"); r.Timeout=7000;r.Proxy=new WebProxy(proxy,false);using(var res=r.GetResponse()) using(var reader=new StreamReader(res.GetResponseStream())){return reader.ReadToEnd();}}
    [DllImport("dnsapi.dll")] static extern uint DnsSetApplicationSettings(uint n,IntPtr server,IntPtr settings);
    static uint Exclusive() {
        var server=Marshal.AllocHGlobal(256);var settings=Marshal.AllocHGlobal(16);
        try {Marshal.Copy(new byte[256],0,server,256);Marshal.Copy(new byte[16],0,settings,16);
            Marshal.WriteInt32(server,1);Marshal.WriteInt16(server,24,2);Marshal.WriteInt16(server,26,(short)0);Marshal.Copy(new byte[]{127,77,88,99},0,IntPtr.Add(server,28),4);
            Marshal.WriteInt32(settings,1);Marshal.WriteInt64(settings,8,1);
            return DnsSetApplicationSettings(1,server,settings);
        }finally{Marshal.FreeHGlobal(server);Marshal.FreeHGlobal(settings);}
    }
    [StructLayout(LayoutKind.Sequential)] struct AI { public int flags,family,stype,protocol; public UIntPtr length;public IntPtr canon,addr,next; }
    [DllImport("ws2_32",CharSet=CharSet.Unicode,ExactSpelling=true)] static extern int GetAddrInfoW(string node,string svc,IntPtr hints,out IntPtr data);
    [DllImport("ws2_32",ExactSpelling=true)] static extern void FreeAddrInfoW(IntPtr ptr);
    static string NativeResolve(string name) {
        IntPtr first;int error=GetAddrInfoW(name,null,IntPtr.Zero,out first);if(error!=0)return "WSA "+error;
        try {var ips=new List<string>();for(var p=first;p!=IntPtr.Zero;){var ai=(AI)Marshal.PtrToStructure(p,typeof(AI));int n=ai.family==2?4:ai.family==23?16:0;
            if(n!=0){var ip=new byte[n];Marshal.Copy(IntPtr.Add(ai.addr,n==4?4:8),ip,0,n);ips.Add(new IPAddress(ip).ToString());}p=ai.next;}return String.Join(",",ips);}
        finally{FreeAddrInfoW(first);}
    }
    static void Test(string role) {
        var d=new Dictionary<string,object>();d["role"]=role;d["pid"]=Process.GetCurrentProcess().Id;d["boxed"]=GetModuleHandle("SbieDll.dll")!=IntPtr.Zero;
        IntPtr b=Marshal.AllocHGlobal(1024);try {var ret=GetDynamicTimeZoneInformation(b);d["zoneKey"]=ret==uint.MaxValue?"ERROR":Marshal.PtrToStringUni(IntPtr.Add(b,172));}finally{Marshal.FreeHGlobal(b);}
        ST local,utc;GetLocalTime(out local);GetSystemTime(out utc);d["offsetMinutes"]=Math.Round((local.Value-utc.Value).TotalMinutes);
        d["utc"]=utc.Value.ToString("yyyy-MM-dd HH:mm:ss");d["local"]=local.Value.ToString("yyyy-MM-dd HH:mm:ss");
        d["registryZone"]=Microsoft.Win32.Registry.GetValue(@"HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\TimeZoneInformation","TimeZoneKeyName","missing");
        d["registryBias"]=Microsoft.Win32.Registry.GetValue(@"HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\TimeZoneInformation","Bias",0);
        string label="c"+Guid.NewGuid().ToString("N").Substring(0,15)+".cage.test";d["dnsName"]=label;
        if(args[2]=="explicit" || (args[2]=="parentOnly" && role=="parent")) d["dnsSetup"]=Obs(()=>Exclusive().ToString());
        using(var wsaInit=new Socket(AddressFamily.InterNetwork,SocketType.Stream,ProtocolType.Tcp)){} d["fresh"]=Obs(()=>NativeResolve(label+"."));
        string pos=args[0].StartsWith("off")?"example.net":args[0].StartsWith("bad")?"example.org":"example.com";
        d["positiveName"]=pos;d["positive"]=Obs(()=>NativeResolve(pos+"."));
        d["tcp4"]=Obs(()=>Tcp("127.0.0.1"));d["tcp6"]=Obs(()=>Tcp("::1"));d["udp4"]=Obs(()=>Udp("127.0.0.1"));
        Save(role,d);
    }
    [DllImport("kernel32",CharSet=CharSet.Unicode)] static extern IntPtr GetModuleHandle(string s);
    [STAThread] static void Main(string[] a) {ServicePointManager.SecurityProtocol=SecurityProtocolType.Tls12;args=a;var role=a[3];if(role=="child"){Test(role);return;}
        var f=new Form {Text="Cage Free Probe "+a[0],Width=390,Height=140};var btn=new Button {Text="Check window",Dock=DockStyle.Fill};f.Controls.Add(btn);btn.Click+=(s,e)=>{f.Text="Cage Click OK "+a[0];File.WriteAllText(Path.Combine(a[1],a[0]+"-clicked.txt"),"yes");};
        f.Shown+=(s,e)=>Task.Run(()=>{using(var child=Process.Start(new ProcessStartInfo(Application.ExecutablePath,"\""+a[0]+"\" \""+a[1]+"\" \""+a[2]+"\" child"){UseShellExecute=false})){Test("parent");child.WaitForExit(24000);}});
        Application.Run(f);
    }
}
