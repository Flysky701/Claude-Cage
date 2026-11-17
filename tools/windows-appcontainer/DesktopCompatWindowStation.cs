// Exact current-package API probe: no changes to the interactive desktop or its ACL.
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Runtime.InteropServices;
using System.Security.Principal;
using System.Text;
using System.Web.Script.Serialization;

internal static partial class BoundaryProbe {
    [StructLayout(LayoutKind.Sequential)] struct DesktopSecurityAttributes {internal int size;internal IntPtr descriptor;internal int inherit;}
    [DllImport("user32",CharSet=CharSet.Unicode,SetLastError=true)] static extern IntPtr CreateWindowStation(string name,uint flags,uint access,IntPtr security);
    [DllImport("user32",CharSet=CharSet.Unicode,SetLastError=true)] static extern IntPtr OpenWindowStation(string name,bool inherit,uint access);
    [DllImport("user32",SetLastError=true)] static extern bool CloseWindowStation(IntPtr station);
    [DllImport("user32")] static extern IntPtr GetProcessWindowStation();
    [DllImport("user32",CharSet=CharSet.Unicode,SetLastError=true)] static extern bool GetUserObjectInformation(IntPtr handle,int kind,StringBuilder value,uint length,out uint needed);
    [DllImport("user32",SetLastError=true)] static extern bool GetUserObjectSecurity(IntPtr handle,ref uint info,byte[] value,uint size,out uint needed);
    static Dictionary<string,object> DesktopStationResult(string operation,IntPtr handle) {
        var row=new Dictionary<string,object>{{"operation",operation},{"succeeded",handle!=IntPtr.Zero},{"error",handle==IntPtr.Zero?Marshal.GetLastWin32Error():0}};
        if(handle!=IntPtr.Zero){var name=new StringBuilder(512);uint needed;if(GetUserObjectInformation(handle,2,name,1024,out needed))row["objectName"]=name.ToString();CloseWindowStation(handle);}return row;
    }
    static int DesktopStationWorker(string existing) {
        var rows=new List<Dictionary<string,object>>();
        uint info=4,needed;var descriptor=new byte[65536];
        bool readable=GetUserObjectSecurity(GetProcessWindowStation(),ref info,descriptor,(uint)descriptor.Length,out needed);
        rows.Add(new Dictionary<string,object>{{"operation","read-current-station-DACL"},{"succeeded",readable},{"error",readable?0:Marshal.GetLastWin32Error()}});
        IntPtr sd=IntPtr.Zero,sa=IntPtr.Zero;
        try {
            if(readable) {
                sd=Marshal.AllocHGlobal((int)needed);Marshal.Copy(descriptor,0,sd,(int)needed);
                var attr=new DesktopSecurityAttributes{size=Marshal.SizeOf(typeof(DesktopSecurityAttributes)),descriptor=sd};
                sa=Marshal.AllocHGlobal(attr.size);Marshal.StructureToPtr(attr,sa,false);
                rows.Add(DesktopStationResult("chromium-unnamed-read-create",CreateWindowStation(null,0,0x80000008,sa)));
                rows.Add(DesktopStationResult("chromium-unnamed-minimum",CreateWindowStation(null,0,0xA,sa)));
            }
            string unique="Cage.Station.Child."+Guid.NewGuid().ToString("N");
            rows.Add(DesktopStationResult("own-named-default-security",CreateWindowStation(unique,0,0xA,IntPtr.Zero)));
            rows.Add(DesktopStationResult("open-host-precreated-exact-package",OpenWindowStation(existing,false,0xA)));
            rows.Add(DesktopStationResult("create-host-precreated-exact-package",CreateWindowStation(existing,0,0xA,IntPtr.Zero)));
        }finally {if(sa!=IntPtr.Zero)Marshal.FreeHGlobal(sa);if(sd!=IntPtr.Zero)Marshal.FreeHGlobal(sd);}
        Console.WriteLine(new JavaScriptSerializer().Serialize(rows));return 0;
    }
    static int DesktopStationTest(string fixture) {
        Session session=null;IntPtr station=IntPtr.Zero,sd=IntPtr.Zero,sa=IntPtr.Zero;
        var report=new Dictionary<string,object>();
        try {
            report["hostToken"]=Token(Process.GetCurrentProcess().Handle);
            session=new Session("ac",fixture);
            string exe=Path.Combine(session.Fixture,"tools","DesktopCompatProbe.exe");File.Copy(typeof(BoundaryProbe).Assembly.Location,exe);
            string name="Cage.Station.Host."+Guid.NewGuid().ToString("N");uint size;
            string user=WindowsIdentity.GetCurrent().User.Value;
            Check(ConvertStringSecurityDescriptorToSecurityDescriptor("D:(A;;GA;;;"+user+")(A;;GA;;;SY)(A;;GA;;;"+session.Sid+")S:(ML;;NW;;;LW)",1,out sd,out size),"station_descriptor");
            var attr=new DesktopSecurityAttributes{size=Marshal.SizeOf(typeof(DesktopSecurityAttributes)),descriptor=sd};sa=Marshal.AllocHGlobal(attr.size);Marshal.StructureToPtr(attr,sa,false);
            // Reject an existing login-session station: it may belong to an
            // unrelated browser and its security descriptor must not change.
            station=CreateWindowStation(null,1,0xA,sa);
            report["hostCreatedNewStation"]=station!=IntPtr.Zero;report["hostCreateOnlyError"]=station==IntPtr.Zero?Marshal.GetLastWin32Error():0;
            if(station!=IntPtr.Zero) {
                var stationName=new StringBuilder(512);uint nameNeeded;Check(GetUserObjectInformation(station,2,stationName,1024,out nameNeeded),"fixture_station_name");name=stationName.ToString();
            }
            report["launch"]=Launch(session,exe,new[]{"--winstation-worker",name},15,"winstation");
        }catch(Exception ex){report["error"]=ex.GetType().Name+": "+ex.Message;}
        finally {
            if(station!=IntPtr.Zero)report["stationClosed"]=CloseWindowStation(station);
            if(sa!=IntPtr.Zero)Marshal.FreeHGlobal(sa);if(sd!=IntPtr.Zero)LocalFree(sd);
            if(session!=null){session.Dispose();report["profileDeleteResult"]=session.DeleteResult;Save(Path.Combine(session.Fixture,"station-result.json"),report);}
        }
        Console.WriteLine(new JavaScriptSerializer().Serialize(report));return report.ContainsKey("error")?1:0;
    }
}
