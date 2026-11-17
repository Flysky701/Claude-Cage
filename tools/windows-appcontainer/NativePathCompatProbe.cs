// Independent candidate entry; the shared launcher remains unchanged.
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Runtime.InteropServices;
using System.Text;
using System.Web.Script.Serialization;

internal static class NativePathCompatEntry {
    static int Main(string[] args) { return BoundaryProbe.NativePathCompatMain(args); }
}
internal static partial class BoundaryProbe {
    [DllImport("kernel32",CharSet=CharSet.Unicode,SetLastError=true)] static extern IntPtr LoadLibraryEx(string name,IntPtr file,uint flags);
    [DllImport("kernel32",SetLastError=true)] static extern bool FreeLibrary(IntPtr module);

    static void InitializeNativePathCompat(IntPtr process,int pid,string dll) {
        // Reuse the browser candidate's verified shared-system-image helpers.
        // The target was already verified and assigned its kill-on-close job.
        InvokeSystemExport(process,"ntdll.dll","RtlExitUserThread",IntPtr.Zero);
        byte[] path=Encoding.Unicode.GetBytes(dll+"\0");
        IntPtr memory=VirtualAllocEx(process,IntPtr.Zero,(IntPtr)path.Length,0x3000,4);
        Check(memory!=IntPtr.Zero,"native_path_allocate");
        try {
            IntPtr written;
            Check(WriteProcessMemory(process,memory,path,(IntPtr)path.Length,out written)&&written.ToInt64()==path.Length,"native_path_write");
            InvokeSystemExport(process,"kernel32.dll","LoadLibraryW",memory);
        }finally {VirtualFreeEx(process,memory,IntPtr.Zero,0x8000);}

        IntPtr remote=IntPtr.Zero;
        using(var child=Process.GetProcessById(pid)) {
            foreach(ProcessModule module in child.Modules) {
                if(String.Equals(Path.GetFullPath(module.FileName),dll,StringComparison.OrdinalIgnoreCase))remote=module.BaseAddress;
            }
        }
        if(remote==IntPtr.Zero)throw new InvalidDataException("native_path_library_not_loaded");
        // Map without resolving imports or executing DllMain in the controller;
        // use only the known exported function's relative image offset.
        IntPtr local=LoadLibraryEx(dll,IntPtr.Zero,1);Check(local!=IntPtr.Zero,"native_path_map_export");
        try {
            IntPtr export=GetProcAddress(local,"NativePathCompatStatus");Check(export!=IntPtr.Zero,"native_path_status_export");
            IntPtr entry=new IntPtr(remote.ToInt64()+export.ToInt64()-local.ToInt64());
            var localName=new StringBuilder(32768);var childName=new StringBuilder(32768);
            Check(GetMappedFileName(Process.GetCurrentProcess().Handle,export,localName,32768)>0,"native_path_local_image");
            Check(GetMappedFileName(process,entry,childName,32768)>0,"native_path_child_image");
            if(!String.Equals(localName.ToString(),childName.ToString(),StringComparison.OrdinalIgnoreCase))throw new InvalidDataException("native_path_image_mismatch");
            uint id;IntPtr thread=CreateRemoteThread(process,IntPtr.Zero,IntPtr.Zero,entry,IntPtr.Zero,0,out id);Check(thread!=IntPtr.Zero,"native_path_status_thread");
            try {
                if(WaitForSingleObject(thread,5000)!=0)throw new TimeoutException("native_path_status_timeout");
                uint status;Check(GetExitCodeThread(thread,out status),"native_path_status_result");
                if(status!=1)throw new InvalidDataException("native_path_import_not_installed");
            }finally {CloseHandle(thread);}
        }finally {FreeLibrary(local);}
    }

    internal static int NativePathCompatMain(string[] args) {
        if(args.Length<1||args.Length>2||(args.Length==2&&args[1]!="relative"&&args[1]!="reftable")){Console.Error.WriteLine("NativePathCompatProbe <new fixture> [relative|reftable]");return 2;}
        bool relative=args.Length==2;
        bool reftable=relative&&args[1]=="reftable";
        Session session=null;var report=new Dictionary<string,object>();
        try {
            session=new Session("ac",args[0]);
            string tools=Path.Combine(session.Fixture,"tools"),work=Path.Combine(session.Fixture,"work");
            string dll=Path.Combine(tools,"NativePathCompat.dll"),git=Path.Combine(tools,"git","git.exe");
            string check=Path.Combine(tools,"check","git.exe"),secret=Path.Combine(session.Fixture,"private","secret.txt");
            if(!File.Exists(dll)||!File.Exists(git)||!File.Exists(check))throw new InvalidDataException("native_path_fixture_incomplete");
            File.WriteAllText(secret,"private fixture");
            File.WriteAllText(Path.Combine(work,"sample.txt"),"local development fixture\n",new UTF8Encoding(false));
            string templates=Path.Combine(work,"empty-templates"),hooks=Path.Combine(work,"empty-hooks");
            Directory.CreateDirectory(templates);Directory.CreateDirectory(hooks);
            string[] prefix={"-c","core.hooksPath="+hooks,"-c","credential.helper=","-c","init.defaultBranch=main"};
            bool failedControl=false;
            if(relative) {
                prefix=new[]{"--git-dir=.git","--work-tree=."}.Concat(prefix).ToArray();
                report["followupScope"]="Git-only explicit relative git-dir/work-tree"+(reftable?" and reftable repository format":"")+"; previously passed path semantics not repeated";
            }else {
                var control=Launch(session,git,prefix.Concat(new[]{"init","--template="+templates,"."}).ToArray(),10,"git-unmodified");
                report["unmodifiedControl"]=control;
                string controlError=File.ReadAllText(Path.Combine(session.Fixture,"out","git-unmodified","stderr.txt"));
                failedControl=!control.ContainsKey("error")&&Convert.ToUInt32(control["exitCode"])!=0&&controlError.Contains("unable to get current working directory");
                report["unmodifiedCwdFailureReproduced"]=failedControl;
            }

            var checks=new List<Dictionary<string,object>>();
            Action<IntPtr,int> initialize=(process,pid)=>InitializeNativePathCompat(process,pid,dll);
            if(!relative)checks.Add(Launch(session,check,new[]{session.Sid,secret},10,"path-semantics",initialize));
            var initArgs=new[]{"init","--template="+templates}.Concat(reftable?new[]{"--ref-format=reftable"}:new string[0]).Concat(new[]{"."});
            checks.Add(Launch(session,git,prefix.Concat(initArgs).ToArray(),10,"git-init",initialize));
            checks.Add(Launch(session,git,prefix.Concat(new[]{"add","--","sample.txt"}).ToArray(),10,"git-add",initialize));
            checks.Add(Launch(session,git,prefix.Concat(new[]{"status","--porcelain=v1","--untracked-files=no"}).ToArray(),10,"git-status",initialize));
            string statusText=File.ReadAllText(Path.Combine(session.Fixture,"out","git-status","stdout.txt")).Trim();
            bool all=checks.All(row=>!row.ContainsKey("error")&&!Convert.ToBoolean(row["timedOut"])&&Convert.ToUInt32(row["exitCode"])==0);
            report["checks"]=checks;
            report["statusMatchesStagedFile"]=statusText=="A  sample.txt";
            report["gitIndexCreated"]=File.Exists(Path.Combine(work,".git","index"));
            report["privateFileUnchanged"]=File.ReadAllText(secret)=="private fixture";
            report["compatibilityScope"]="Only Git main-image GetFinalPathNameByHandleW import; access-denied DOS queries for verified cwd only";
            report["passed"]=(relative||failedControl)&&all&&statusText=="A  sample.txt"&&File.Exists(Path.Combine(work,".git","index"))&&File.ReadAllText(secret)=="private fixture";
        }catch(Exception ex){report["passed"]=false;report["error"]=ex.GetType().Name+": "+ex.Message;}
        finally {
            if(session!=null){session.Dispose();report["profileDeleteResult"]=session.DeleteResult;Save(Path.Combine(session.Fixture,"native-path-result.json"),report);}
        }
        Console.WriteLine(new JavaScriptSerializer().Serialize(report));
        return report.ContainsKey("passed")&&Convert.ToBoolean(report["passed"])?0:1;
    }
}
