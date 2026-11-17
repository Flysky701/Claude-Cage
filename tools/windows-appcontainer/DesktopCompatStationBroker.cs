// A bounded UAC fixture for new objects only. No existing window-station ACLs
// are changed and no application is launched with the broker's elevated token.
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Runtime.InteropServices;
using System.Security.Principal;
using System.Text;
using System.Threading;
using System.Web.Script.Serialization;

internal static partial class BoundaryProbe {
    [DllImport("user32",SetLastError=true)] static extern bool SetProcessWindowStation(IntPtr station);
    [DllImport("user32",CharSet=CharSet.Unicode,SetLastError=true)] static extern IntPtr CreateDesktop(string name,string device,IntPtr mode,uint flags,uint access,IntPtr security);
    [DllImport("user32",CharSet=CharSet.Unicode,SetLastError=true)] static extern IntPtr OpenDesktop(string name,uint flags,bool inherit,uint access);
    [DllImport("user32",SetLastError=true)] static extern bool CloseDesktop(IntPtr desktop);
    [DllImport("kernel32",SetLastError=true)] static extern IntPtr OpenProcess(uint access,bool inherit,int pid);
    [DllImport("kernel32",SetLastError=true)] static extern bool DuplicateHandle(IntPtr source,IntPtr handle,IntPtr target,out IntPtr copy,uint access,bool inherit,uint options);
    [DllImport("kernel32",CharSet=CharSet.Unicode,SetLastError=true)] static extern bool QueryFullProcessImageName(IntPtr process,uint flags,StringBuilder name,ref int length);

    static IntPtr DesktopBrokerAttributes(string user,string package,uint access,out IntPtr sd) {
        uint size;
        string restricted=access==0xE0003?"(D;;0xD013E;;;RC)":"";
        Check(ConvertStringSecurityDescriptorToSecurityDescriptor("D:"+restricted+"(A;;GA;;;"+user+")(A;;GA;;;SY)(A;;0x"+access.ToString("x")+";;;"+package+")S:(ML;;NW;;;LW)",1,out sd,out size),"new_station_descriptor");
        var attr=new DesktopSecurityAttributes{size=Marshal.SizeOf(typeof(DesktopSecurityAttributes)),descriptor=sd};
        IntPtr sa=Marshal.AllocHGlobal(attr.size);Marshal.StructureToPtr(attr,sa,false);return sa;
    }
    static void DesktopBrokerSave(string path,object value) {
        string temp=path+".pending";Save(temp,value);File.Move(temp,path);
    }
    internal static int DesktopStationBroker(string fixture,string package,string user) {
        ValidateFixture(Path.GetFullPath(fixture));
        if(!System.Text.RegularExpressions.Regex.IsMatch(package,"\\AS-1-15-2(?:-[0-9]+){7}\\z") || user!=WindowsIdentity.GetCurrent().User.Value)throw new InvalidDataException("station_broker_identity");
        if(!new WindowsPrincipal(WindowsIdentity.GetCurrent()).IsInRole(WindowsBuiltInRole.Administrator))throw new InvalidDataException("station_broker_requires_elevation");
        string folder=Path.Combine(fixture,"out","station-broker");Directory.CreateDirectory(folder);
        string stationName="Cage.Desktop."+Guid.NewGuid().ToString("N"),desktopName="Cage.Renderer."+Guid.NewGuid().ToString("N");
        var report=new Dictionary<string,object>{{"newObjectsOnly",true},{"existingAclModified",false},{"networkCapabilitiesGranted",0}};
        IntPtr original=GetProcessWindowStation(),station=IntPtr.Zero,desktop=IntPtr.Zero,sd=IntPtr.Zero,sa=IntPtr.Zero,dsd=IntPtr.Zero,dsa=IntPtr.Zero;
        bool changed=false;
        try {
            sa=DesktopBrokerAttributes(user,package,0x2000A,out sd);
            station=CreateWindowStation(stationName,1,0xF037F,sa);Check(station!=IntPtr.Zero,"create_new_named_station");
            Check(SetProcessWindowStation(station),"broker_select_new_station");changed=true;
            dsa=DesktopBrokerAttributes(user,package,0xE0003,out dsd);
            desktop=CreateDesktop(desktopName,null,IntPtr.Zero,0,0xF01FF,dsa);Check(desktop!=IntPtr.Zero,"broker_create_new_desktop");
            Check(SetProcessWindowStation(original),"broker_restore_station");changed=false;
            DesktopBrokerSave(Path.Combine(folder,"ready.json"),new Dictionary<string,object>{{"station",stationName},{"desktop",desktopName},{"created",true}});
            bool duplicated=false;var timer=Stopwatch.StartNew();
            while(timer.Elapsed.TotalSeconds<90 && !File.Exists(Path.Combine(folder,"stop"))) {
                string requestPath=Path.Combine(folder,"duplicate-request.json");
                if(!duplicated && File.Exists(requestPath)) {
                    duplicated=true;var response=new Dictionary<string,object>();IntPtr target=IntPtr.Zero;
                    try {
                        var request=new JavaScriptSerializer().Deserialize<Dictionary<string,object>>(File.ReadAllText(requestPath));
                        int pid=(int)request["pid"];response["nonce"]=(string)request["nonce"];
                        target=OpenProcess(0x1040,false,pid);Check(target!=IntPtr.Zero,"broker_open_target");
                        var identity=Token(target);
                        if(identity[0]!="1" || identity[1]!="0" || identity[2]!=package || identity[3]!="0")throw new InvalidDataException("broker_target_token_mismatch");
                        var image=new StringBuilder(32768);int length=image.Capacity;Check(QueryFullProcessImageName(target,0,image,ref length),"broker_target_image");
                        if(!image.ToString().Equals(Path.Combine(fixture,"tools","DesktopCompatProbe.exe"),StringComparison.OrdinalIgnoreCase))throw new InvalidDataException("broker_target_image_mismatch");
                        IntPtr copy;Check(DuplicateHandle(Process.GetCurrentProcess().Handle,station,target,out copy,0xA,false,0),"broker_duplicate_minimum_station");
                        response["handle"]=copy.ToInt64();response["access"]=0xA;response["tokenVerified"]=true;
                        report["duplicateTargetTokenVerified"]=true;report["duplicatedStationAccess"]=0xA;
                    }catch(Exception ex){response["error"]=ex.GetType().Name+": "+ex.Message;report["duplicateError"]=response["error"];}
                    finally {if(target!=IntPtr.Zero)CloseHandle(target);}
                    DesktopBrokerSave(Path.Combine(folder,"duplicate-response.json"),response);
                }
                Thread.Sleep(100);
            }
            report["stoppedByController"]=File.Exists(Path.Combine(folder,"stop"));
        }catch(Exception ex){report["error"]=ex.GetType().Name+": "+ex.Message;}
        finally {
            if(changed)report["restoredStation"]=SetProcessWindowStation(original);
            if(desktop!=IntPtr.Zero)report["desktopHandleClosed"]=CloseDesktop(desktop);
            if(station!=IntPtr.Zero)report["stationHandleClosed"]=CloseWindowStation(station);
            foreach(var ptr in new[]{sa,dsa})if(ptr!=IntPtr.Zero)Marshal.FreeHGlobal(ptr);
            foreach(var ptr in new[]{sd,dsd})if(ptr!=IntPtr.Zero)LocalFree(ptr);
            IntPtr remaining=OpenWindowStation(stationName,false,2);report["stationRemoved"]=remaining==IntPtr.Zero && Marshal.GetLastWin32Error()==2;if(remaining!=IntPtr.Zero)CloseWindowStation(remaining);
            Save(Path.Combine(folder,"result.json"),report);
        }
        return report.ContainsKey("error")?1:0;
    }
    static Dictionary<string,object> DesktopBrokerOutcome(string action,bool success) {
        return new Dictionary<string,object>{{"operation",action},{"succeeded",success},{"error",success?0:Marshal.GetLastWin32Error()}};
    }
    static int DesktopBrokerStationWorker(string stationName,string desktopName,bool duplicate=false) {
        var rows=new List<Dictionary<string,object>>();IntPtr station=IntPtr.Zero,desktop=IntPtr.Zero,created=IntPtr.Zero,sd=IntPtr.Zero,sa=IntPtr.Zero;
        IntPtr original=GetProcessWindowStation();bool switched=false;
        try {
            if(duplicate) {
                string expected=Path.Combine(AppDomain.CurrentDomain.BaseDirectory,"station-handle.json");
                if(!Path.GetFullPath(stationName).Equals(Path.GetFullPath(expected),StringComparison.OrdinalIgnoreCase))throw new InvalidDataException("startup_data_not_local_readonly_file");
                var data=new JavaScriptSerializer().Deserialize<Dictionary<string,object>>(File.ReadAllText(expected));
                station=(IntPtr)Convert.ToInt64(data["handle"]);
                var name=new StringBuilder(512);uint needed;bool valid=GetUserObjectInformation(station,2,name,1024,out needed);
                rows.Add(DesktopBrokerOutcome("query-duplicated-minimum-station",valid));
                if(!valid || name.ToString()!=(string)data["station"])throw new InvalidDataException("duplicated_station_name_mismatch");
            } else {station=OpenWindowStation(stationName,false,0xA);rows.Add(DesktopBrokerOutcome("open-exact-package-new-station",station!=IntPtr.Zero));}
            if(station!=IntPtr.Zero) {
                switched=SetProcessWindowStation(station);rows.Add(DesktopBrokerOutcome("select-new-station",switched));
                if(switched) {
                    desktop=OpenDesktop(desktopName,0,false,0xE0003);rows.Add(DesktopBrokerOutcome("open-precreated-desktop-chromium-rights",desktop!=IntPtr.Zero));
                    string package=Token(Process.GetCurrentProcess().Handle)[2];sa=DesktopBrokerAttributes(WindowsIdentity.GetCurrent().User.Value,package,0xE0003,out sd);
                    created=CreateDesktop("Cage.Child."+Guid.NewGuid().ToString("N"),null,IntPtr.Zero,0,0xE0003,sa);rows.Add(DesktopBrokerOutcome("create-new-child-desktop-chromium-rights",created!=IntPtr.Zero));
                }
            }
        }catch(Exception ex){rows.Add(new Dictionary<string,object>{{"error",ex.GetType().Name+": "+ex.Message}});}
        finally {
            if(switched)rows.Add(DesktopBrokerOutcome("restore-original-station",SetProcessWindowStation(original)));
            if(created!=IntPtr.Zero)CloseDesktop(created);if(desktop!=IntPtr.Zero)CloseDesktop(desktop);if(station!=IntPtr.Zero)CloseWindowStation(station);
            if(sa!=IntPtr.Zero)Marshal.FreeHGlobal(sa);if(sd!=IntPtr.Zero)LocalFree(sd);
        }
        Console.WriteLine(new JavaScriptSerializer().Serialize(rows));return 0;
    }
    internal static int DesktopBrokerStationTest(string fixture,bool duplicate=false) {
        Session session=null;Process broker=null;var report=new Dictionary<string,object>();string folder=null;
        try {
            session=new Session("ac",fixture);folder=Path.Combine(session.Fixture,"out","station-broker");Directory.CreateDirectory(folder);
            string exe=Path.Combine(session.Fixture,"tools","DesktopCompatProbe.exe");File.Copy(typeof(BoundaryProbe).Assembly.Location,exe);
            // UAC is requested only by this explicitly selected test command.
            var args=new[]{"--station-broker",session.Fixture,session.Sid,WindowsIdentity.GetCurrent().User.Value};
            broker=Process.Start(new ProcessStartInfo(typeof(BoundaryProbe).Assembly.Location,String.Join(" ",args.Select(Quote))){UseShellExecute=true,Verb="runas",WindowStyle=ProcessWindowStyle.Hidden});
            string ready=Path.Combine(folder,"ready.json");var timer=Stopwatch.StartNew();
            while(!File.Exists(ready) && !broker.HasExited && timer.Elapsed.TotalSeconds<30)Thread.Sleep(100);
            if(!File.Exists(ready))throw new InvalidOperationException("station_broker_not_ready");
            var names=new JavaScriptSerializer().Deserialize<Dictionary<string,object>>(File.ReadAllText(ready));
            if(duplicate) {
                string startup=Path.Combine(session.Fixture,"tools","station-handle.json");
                Action<IntPtr,int> initialize=(process,pid)=>{
                    string nonce=Guid.NewGuid().ToString("N");
                    DesktopBrokerSave(Path.Combine(folder,"duplicate-request.json"),new Dictionary<string,object>{{"pid",pid},{"nonce",nonce}});
                    string answer=Path.Combine(folder,"duplicate-response.json");var deadline=Stopwatch.StartNew();
                    while(!File.Exists(answer) && !broker.HasExited && deadline.Elapsed.TotalSeconds<10)Thread.Sleep(50);
                    if(!File.Exists(answer))throw new InvalidOperationException("broker_duplicate_timeout");
                    var response=new JavaScriptSerializer().Deserialize<Dictionary<string,object>>(File.ReadAllText(answer));
                    if(response.ContainsKey("error"))throw new InvalidOperationException((string)response["error"]);
                    if((string)response["nonce"]!=nonce || (int)response["access"]!=0xA || !(bool)response["tokenVerified"])throw new InvalidDataException("broker_duplicate_response");
                    Save(startup,new Dictionary<string,object>{{"handle",response["handle"]},{"station",names["station"]}});
                };
                report["launch"]=Launch(session,exe,new[]{"--broker-station-handle-worker",startup,(string)names["desktop"]},20,"station-chain",initialize);
            } else report["launch"]=Launch(session,exe,new[]{"--broker-station-worker",(string)names["station"],(string)names["desktop"]},20,"station-chain");
            report["duplicateHandleMode"]=duplicate;
        }catch(Exception ex){report["error"]=ex.GetType().Name+": "+ex.Message;}
        finally {
            if(folder!=null)File.WriteAllText(Path.Combine(folder,"stop"),"");
            if(broker!=null){report["brokerExited"]=broker.WaitForExit(10000);broker.Dispose();}
            if(session!=null){session.Dispose();report["profileDeleteResult"]=session.DeleteResult;Save(Path.Combine(session.Fixture,"broker-chain.json"),report);}
        }
        Console.WriteLine(new JavaScriptSerializer().Serialize(report));return report.ContainsKey("error")?1:0;
    }
}
