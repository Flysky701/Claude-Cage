// Applies a documented input policy only to the newly created, verified child.
// No executable patch, host input-language change, or sandbox-disabling flag.
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Runtime.InteropServices;
using System.Text;
using System.Web.Script.Serialization;

internal static class BrowserInputEntry {
    static int Main(string[] args){return BoundaryProbe.BrowserInputMain(args);}
}
internal static partial class BoundaryProbe {
    [DllImport("kernel32",CharSet=CharSet.Unicode,SetLastError=true)] static extern IntPtr LoadLibrary(string file);
    [DllImport("kernel32",CharSet=CharSet.Ansi,SetLastError=true)] static extern IntPtr GetProcAddress(IntPtr module,string name);
    [DllImport("kernel32",SetLastError=true)] static extern IntPtr VirtualAllocEx(IntPtr process,IntPtr address,IntPtr bytes,uint type,uint protection);
    [DllImport("kernel32",SetLastError=true)] static extern bool VirtualFreeEx(IntPtr process,IntPtr address,IntPtr bytes,uint type);
    [DllImport("kernel32",SetLastError=true)] static extern bool WriteProcessMemory(IntPtr process,IntPtr address,byte[] bytes,IntPtr count,out IntPtr written);
    [DllImport("kernel32",SetLastError=true)] static extern IntPtr CreateRemoteThread(IntPtr process,IntPtr security,IntPtr stack,IntPtr start,IntPtr argument,uint flags,out uint id);
    [DllImport("kernel32",SetLastError=true)] static extern bool GetExitCodeThread(IntPtr thread,out uint code);
    [DllImport("psapi",CharSet=CharSet.Unicode,SetLastError=true)] static extern uint GetMappedFileName(IntPtr process,IntPtr address,StringBuilder file,uint size);
    [DllImport("kernel32",SetLastError=true)] static extern IntPtr VirtualQueryEx(IntPtr process,IntPtr address,IntPtr information,IntPtr bytes);
    [DllImport("dbghelp",EntryPoint="MiniDumpWriteDump",SetLastError=true)] static extern bool CompatDump(IntPtr process,int pid,IntPtr file,uint flags,IntPtr exception,IntPtr streams,IntPtr callbacks);

    static IntPtr VerifiedSystemExport(IntPtr process,string library,string function) {
        IntPtr module=LoadLibrary(Path.Combine(Environment.SystemDirectory,library));Check(module!=IntPtr.Zero,"compat_load_system_library");
        IntPtr entry=GetProcAddress(module,function);Check(entry!=IntPtr.Zero,"compat_system_export");
        // Only use a shared system-image address after confirming that both
        // processes map the same image at the same allocation base.
        var localPath=new StringBuilder(1024);var childPath=new StringBuilder(1024);
        Check(GetMappedFileName(Process.GetCurrentProcess().Handle,entry,localPath,1024)>0,"compat_local_image");
        Check(GetMappedFileName(process,entry,childPath,1024)>0,"compat_child_image");
        IntPtr localInfo=Marshal.AllocHGlobal(48),childInfo=Marshal.AllocHGlobal(48);
        try {
            Check(VirtualQueryEx(Process.GetCurrentProcess().Handle,entry,localInfo,(IntPtr)48)!=IntPtr.Zero,"compat_local_mapping");
            Check(VirtualQueryEx(process,entry,childInfo,(IntPtr)48)!=IntPtr.Zero,"compat_child_mapping");
            if(!String.Equals(localPath.ToString(),childPath.ToString(),StringComparison.OrdinalIgnoreCase) || Marshal.ReadIntPtr(localInfo,8)!=Marshal.ReadIntPtr(childInfo,8))throw new InvalidDataException("compat_system_image_mapping_differs");
        }finally{Marshal.FreeHGlobal(localInfo);Marshal.FreeHGlobal(childInfo);}
        return entry;
    }
    static uint InvokeSystemExport(IntPtr process,string library,string function,IntPtr parameter) {
        uint id;IntPtr thread=CreateRemoteThread(process,IntPtr.Zero,IntPtr.Zero,VerifiedSystemExport(process,library,function),parameter,0,out id);
        Check(thread!=IntPtr.Zero,"compat_initialize_thread");
        try {if(WaitForSingleObject(thread,5000)!=0)throw new TimeoutException("compat_initialize_timeout");uint code;Check(GetExitCodeThread(thread,out code),"compat_initialize_result");return code;}
        finally {CloseHandle(thread);}
    }
    static void InitializeBrowserInput(IntPtr process,int pid) {
        // The main thread stays suspended. This empty initialization thread
        // lets the normal Windows loader finish mapping the executable imports.
        InvokeSystemExport(process,"ntdll.dll","RtlExitUserThread",IntPtr.Zero);
        byte[] path=Encoding.Unicode.GetBytes(Path.Combine(Environment.SystemDirectory,"imm32.dll")+"\0");
        IntPtr memory=VirtualAllocEx(process,IntPtr.Zero,(IntPtr)path.Length,0x3000,4);Check(memory!=IntPtr.Zero,"compat_allocate_path");
        try {
            IntPtr written;Check(WriteProcessMemory(process,memory,path,(IntPtr)path.Length,out written)&&written.ToInt64()==path.Length,"compat_write_library_path");
            InvokeSystemExport(process,"kernel32.dll","LoadLibraryW",memory);
            if(InvokeSystemExport(process,"imm32.dll","ImmDisableIME",new IntPtr(-1))==0)throw new InvalidDataException("compat_ime_policy_failed");
        }finally {VirtualFreeEx(process,memory,IntPtr.Zero,0x8000);}
    }
    internal static int BrowserInputMain(string[] args) {
        if(args.Length<3){Console.Error.WriteLine("BrowserInputProbe <fixture> <exe> <seconds> [args]");return 2;}
        Session session=null;var report=new Dictionary<string,object>();
        try {
            session=new Session("ac",args[0]);
            report=Launch(session,args[1],args.Skip(3).ToArray(),Int32.Parse(args[2]),"browser-input",InitializeBrowserInput,(process,pid)=>{
                using(var file=new FileStream(Path.Combine(session.Fixture,"out","browser-input","timeout.dmp"),FileMode.Create,FileAccess.Write,FileShare.Read))Check(CompatDump(process,pid,file.SafeFileHandle.DangerousGetHandle(),0x1000,IntPtr.Zero,IntPtr.Zero,IntPtr.Zero),"compat_timeout_dump");
            });
            report["inputPolicy"]="ImmDisableIME(-1) only in verified child; native IME needs separate input bridge";
        }catch(Exception ex){report["error"]=ex.GetType().Name+": "+ex.Message;}
        finally {if(session!=null){session.Dispose();report["profileDeleteResult"]=session.DeleteResult;Save(Path.Combine(session.Fixture,"browser-input.json"),report);}}
        Console.WriteLine(new JavaScriptSerializer().Serialize(report));return report.ContainsKey("error")?1:0;
    }
}
