// Local diagnostic utility; uses the official Microsoft Debugger Platform.
using System;
using System.IO;
using System.Runtime.InteropServices;

internal static class AnalyzeDump {
    [DllImport("kernel32",CharSet=CharSet.Unicode,SetLastError=true)] static extern bool SetDllDirectory(string directory);
    [DllImport("dbgeng")] static extern int DebugCreate(ref Guid iid,out IntPtr client);
    [UnmanagedFunctionPointer(CallingConvention.StdCall)] delegate int OpenDump(IntPtr self,[MarshalAs(UnmanagedType.LPStr)]string path);
    [UnmanagedFunctionPointer(CallingConvention.StdCall)] delegate int OpenLog(IntPtr self,[MarshalAs(UnmanagedType.LPStr)]string path,int append);
    [UnmanagedFunctionPointer(CallingConvention.StdCall)] delegate int Wait(IntPtr self,uint flags,uint timeout);
    [UnmanagedFunctionPointer(CallingConvention.StdCall)] delegate int Execute(IntPtr self,uint output,[MarshalAs(UnmanagedType.LPStr)]string command,uint flags);
    [UnmanagedFunctionPointer(CallingConvention.StdCall)] delegate int CloseLog(IntPtr self);
    static T Method<T>(IntPtr self,int index) {return (T)(object)Marshal.GetDelegateForFunctionPointer(Marshal.ReadIntPtr(Marshal.ReadIntPtr(self),IntPtr.Size*index),typeof(T));}
    static void Check(int code) {Marshal.ThrowExceptionForHR(code);}
    static int Main(string[] args) {
        if(args.Length<3){Console.Error.WriteLine("AnalyzeDump <dbgeng-directory> <dump> <log> [command]");return 2;}
        IntPtr client=IntPtr.Zero,control=IntPtr.Zero;
        try {
            if(!SetDllDirectory(Path.GetFullPath(args[0])))throw new System.ComponentModel.Win32Exception();
            var ci=new Guid("27fe5639-8407-4f47-8364-ee118fb08ac8");Check(DebugCreate(ref ci,out client));
            var co=new Guid("5182e668-105e-416e-ad92-24ef800424ba");Check(Marshal.QueryInterface(client,ref co,out control));
            Check(Method<OpenLog>(control,8)(control,Path.GetFullPath(args[2]),0));
            Check(Method<Execute>(control,66)(control,1,".sympath "+Path.GetFullPath(args[0]),0));
            Check(Method<OpenDump>(client,19)(client,Path.GetFullPath(args[1])));
            Check(Method<Wait>(control,93)(control,0,30000));
            // No remote symbol path by default: application PDBs may be huge.
            string command=args.Length>3?args[3]:".ecxr;.exr -1;du poi(poi(@$peb+0x20)+0x78);~*kb 24;lm";
            foreach(string part in command.Split(';'))if(!String.IsNullOrWhiteSpace(part))Check(Method<Execute>(control,66)(control,1,part.Trim(),0));
            Check(Method<CloseLog>(control,9)(control));return 0;
        }catch(Exception ex){Console.Error.WriteLine(ex.GetType().Name+": "+ex.Message);return 1;}
        finally {if(control!=IntPtr.Zero)Marshal.Release(control);if(client!=IntPtr.Zero)Marshal.Release(client);}
    }
}
