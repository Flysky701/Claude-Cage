using System;
using System.Collections.Generic;
using System.IO;
using System.Runtime.InteropServices;
using System.Security.AccessControl;
using Fsp;
using Info = Fsp.Interop.FileInfo;
using VolumeInfo = Fsp.Interop.VolumeInfo;

// The backing directory is a controller-only, handle-confined SFTP mount.
// Only this virtual volume gives the worker a Low mandatory label.
internal sealed class LocalProjectFileSystem : FileSystemBase
{
    private readonly string root, stamp, epoch, gate;
    private readonly byte[] security;
    private readonly bool readOnly;

    private sealed class OpenFile
    {
        internal string Path;
        internal FileStream Stream;
        internal bool Directory;
    }

    private LocalProjectFileSystem(string[] args)
    {
        root = Path.GetFullPath(args[0]);
        stamp = args[3]; epoch = args[4]; gate = args[5]; readOnly = args[7] == "ro";
        var sd = new RawSecurityDescriptor("O:" + args[6] + "G:SYD:P(A;;FA;;;" + args[6] + ")(A;;" +
            (readOnly ? "FRFX" : "0x1301bf") + ";;;" + args[2] + ")S:(ML;;NW;;;LW)");
        security = new byte[sd.BinaryLength]; sd.GetBinaryForm(security, 0);
    }

    public static int Main(string[] args)
    {
        if (args.Length != 8) return 1;
        try
        {
            using (var host = new FileSystemHost(new LocalProjectFileSystem(args)))
            {
                host.SectorSize = 512; host.SectorsPerAllocationUnit = 8;
                host.FileInfoTimeout = 0; host.DirInfoTimeout = 0; host.SecurityTimeout = 0;
                host.CasePreservedNames = true; host.UnicodeOnDisk = true;
                host.PersistentAcls = true; host.FlushAndPurgeOnCleanup = true;
                host.FileSystemName = "CageProject";
                // Windows checks the NTFS mount-point directory itself when an
                // application opens the root to enumerate it. Its parent only
                // grants the worker traversal. Known child paths can still work
                // with an inaccessible mount point, hiding this problem in shells.
                var mountAcl = new RawSecurityDescriptor("O:" + args[6] + "G:SYD:P(A;;FA;;;" + args[6] +
                    ")(A;;FA;;;SY)(A;;FA;;;BA)(A;;FRFX;;;" + args[2] + ")");
                var mountSecurity = new byte[mountAcl.BinaryLength];
                mountAcl.GetBinaryForm(mountSecurity,0);
                int status = host.Mount(args[1], mountSecurity, true, 0);
                if (status < 0) throw new IOException("项目文件系统挂载失败。", status);
                Console.WriteLine("ready"); Console.Out.Flush();
                Console.ReadLine();
                host.Unmount();
            }
            return 0;
        }
        catch (Exception ex) { Console.Error.WriteLine("mount:" + ex.GetType().Name + ":0x" + ex.HResult.ToString("X8")); return 1; }
    }

    // The grant editor takes the same file exclusively for ACL changes and epoch invalidation.
    private IDisposable Grant()
    {
        FileStream lease = new FileStream(gate, FileMode.Open, FileAccess.Read, FileShare.Read);
        try
        {
            if (File.ReadAllText(stamp) != epoch) throw new UnauthorizedAccessException("项目授权已更改。");
            return lease;
        }
        catch { lease.Dispose(); throw; }
    }

    private string Backing(string name)
    {
        string relative = name.TrimStart('\\');
        if (relative.Length == 0) return root;
        foreach (string part in relative.Split('\\'))
            if (part.Length == 0 || part == "." || part == ".." || part.IndexOfAny(Path.GetInvalidFileNameChars()) >= 0)
                throw new UnauthorizedAccessException();
        return Path.Combine(root, relative);
    }

    private void MayWrite(string path)
    {
        if (readOnly || path == root) throw new UnauthorizedAccessException();
        foreach (string part in path.Substring(root.Length + 1).Split('\\'))
            if (part.Equals(".git", StringComparison.OrdinalIgnoreCase)) throw new UnauthorizedAccessException();
    }

    private Info Describe(string path)
    {
        var attr = File.GetAttributes(path);
        if (path == root) attr &= ~FileAttributes.ReparsePoint; // our private WinFsp mount point
        else if ((attr & FileAttributes.ReparsePoint) != 0) throw new UnauthorizedAccessException();
        FileSystemInfo entry = (attr & FileAttributes.Directory) != 0 ? (FileSystemInfo)new DirectoryInfo(path) : new FileInfo(path);
        var info = new Info();
        info.FileAttributes = (uint)attr; info.FileSize = entry is FileInfo ? (ulong)((FileInfo)entry).Length : 0;
        info.AllocationSize = (info.FileSize + 4095) & ~4095UL;
        info.CreationTime = (ulong)entry.CreationTimeUtc.ToFileTimeUtc();
        info.LastAccessTime = (ulong)entry.LastAccessTimeUtc.ToFileTimeUtc();
        info.LastWriteTime = info.ChangeTime = (ulong)entry.LastWriteTimeUtc.ToFileTimeUtc();
        return info;
    }

    public override int ExceptionHandler(Exception exception)
    {
        if (exception is UnauthorizedAccessException) return STATUS_ACCESS_DENIED;
        if (exception is IOException) return NtStatusFromWin32((uint)(exception.HResult & 65535));
        return base.ExceptionHandler(exception);
    }
    public override int GetVolumeInfo(out VolumeInfo info)
    {
        info = new VolumeInfo();
        var drive = new DriveInfo(Path.GetPathRoot(root));
        info.TotalSize = (ulong)drive.TotalSize; info.FreeSize = (ulong)drive.AvailableFreeSpace;
        info.SetVolumeLabel("Cage Project"); return STATUS_SUCCESS;
    }
    public override int GetSecurityByName(string name, out uint attributes, ref byte[] descriptor)
    {
        using (Grant()) { attributes = Describe(Backing(name)).FileAttributes; if (descriptor != null) descriptor = security; }
        return STATUS_SUCCESS;
    }
    public override int GetSecurity(object node, object desc, ref byte[] descriptor)
    {
        using (Grant()) { descriptor = security; } return STATUS_SUCCESS;
    }

    private static FileStream Stream(string path, uint rights, bool create)
    {
        bool write = (rights & 6) != 0, read = (rights & 1) != 0;
        if (!create && !write && !read) return null;
        return new FileStream(path, create ? FileMode.CreateNew : FileMode.Open,
            write || create ? (read ? FileAccess.ReadWrite : FileAccess.Write) : FileAccess.Read,
            FileShare.ReadWrite | FileShare.Delete, 1);
    }
    private int OpenEntry(string name, uint rights, bool create, bool directory, out object node, out object desc, out Info info, out string normal)
    {
        string path = Backing(name);
        node = null; desc = null; normal = null; info = new Info();
        using (Grant())
        {
            if (create) MayWrite(path);
            if (!create) directory = (File.GetAttributes(path) & FileAttributes.Directory) != 0;
            else if (directory) { if (Directory.Exists(path)) return STATUS_OBJECT_NAME_COLLISION; Directory.CreateDirectory(path); }
            if (!directory && (rights & 6) != 0) MayWrite(path);
            var file = new OpenFile { Path = path, Directory = directory };
            if (!directory) file.Stream = Stream(path, rights, create);
            try { info = Describe(path); } catch { if (file.Stream != null) file.Stream.Dispose(); throw; }
            desc = file;
        }
        return STATUS_SUCCESS;
    }
    public override int Open(string name,uint options,uint rights,out object node,out object desc,out Info info,out string normal)
    { return OpenEntry(name,rights,false,false,out node,out desc,out info,out normal); }
    public override int Create(string name,uint options,uint rights,uint attrs,byte[] sd,ulong allocation,out object node,out object desc,out Info info,out string normal)
    { return OpenEntry(name,rights,true,(options & 1)!=0,out node,out desc,out info,out normal); }
    public override void Close(object node,object desc)
    { var file = (OpenFile)desc; if (file != null && file.Stream != null) file.Stream.Dispose(); }
    public override int GetFileInfo(object node,object desc,out Info info)
    { using (Grant()) { info = Describe(((OpenFile)desc).Path); } return STATUS_SUCCESS; }
    public override int Read(object node,object desc,IntPtr buffer,ulong offset,uint length,out uint count)
    {
        count=0; var file=(OpenFile)desc;
        using(Grant()) lock(file) {
            if(file.Stream == null || !file.Stream.CanRead) return STATUS_ACCESS_DENIED;
            file.Stream.Position=checked((long)offset);
            byte[] bytes=new byte[length]; count=(uint)file.Stream.Read(bytes,0,bytes.Length);
            if(count==0 && length!=0) return STATUS_END_OF_FILE;
            Marshal.Copy(bytes,0,buffer,(int)count);
        }
        return STATUS_SUCCESS;
    }
    public override int Write(object node,object desc,IntPtr buffer,ulong offset,uint length,bool append,bool constrained,out uint count,out Info info)
    {
        var f=(OpenFile)desc; count=0; info=new Info();
        using(Grant()) lock(f) {
            MayWrite(f.Path);
            if(f.Stream==null || !f.Stream.CanWrite) return STATUS_ACCESS_DENIED;
            long size=f.Stream.Length, at=append?size:checked((long)offset);
            int n=constrained?(int)Math.Min(length,Math.Max(0,size-at)):checked((int)length);
            if(n>0){byte[] a=new byte[n];Marshal.Copy(buffer,a,0,n);f.Stream.Position=at;f.Stream.Write(a,0,n);f.Stream.Flush();}
            count=(uint)n; info=Describe(f.Path);
        }
        return STATUS_SUCCESS;
    }
    public override int Flush(object node,object desc,out Info info)
    {
        info=new Info(); if(desc==null) return STATUS_SUCCESS;
        using(Grant()) {var f=(OpenFile)desc; lock(f){if(f.Stream!=null) f.Stream.Flush(); info=Describe(f.Path);}}
        return STATUS_SUCCESS;
    }
    public override int SetFileSize(object node,object desc,ulong size,bool allocation,out Info info)
    {
        var f=(OpenFile)desc; info=new Info();
        using(Grant()) lock(f){MayWrite(f.Path);if(f.Stream==null||!f.Stream.CanWrite)return STATUS_ACCESS_DENIED;
            if(!allocation||(ulong)f.Stream.Length>size) f.Stream.SetLength(checked((long)size));info=Describe(f.Path);}
        return STATUS_SUCCESS;
    }
    public override int Overwrite(object node,object desc,uint attrs,bool replace,ulong allocation,out Info info)
    { return SetFileSize(node,desc,0,false,out info); }
    public override int SetBasicInfo(object node,object desc,uint attributes,ulong creation,ulong access,ulong write,ulong change,out Info info)
    {
        var f=(OpenFile)desc;
        using(Grant()){ MayWrite(f.Path);
            if(write!=0) File.SetLastWriteTimeUtc(f.Path, DateTime.FromFileTimeUtc(checked((long)write)));
            if(access!=0) File.SetLastAccessTimeUtc(f.Path, DateTime.FromFileTimeUtc(checked((long)access)));
            info=Describe(f.Path); }
        return STATUS_SUCCESS;
    }
    public override int CanDelete(object node,object desc,string name)
    {
        using(Grant()){ string path=Backing(name);MayWrite(path);
            if(((OpenFile)desc).Directory && Directory.GetFileSystemEntries(path).Length!=0) return STATUS_DIRECTORY_NOT_EMPTY; }
        return STATUS_SUCCESS;
    }
    public override void Cleanup(object node,object desc,string name,uint flags)
    {
        if((flags & CleanupDelete)==0 || name==null)return;
        using(Grant()){string path=Backing(name);MayWrite(path);
            if(((OpenFile)desc).Directory) Directory.Delete(path); else File.Delete(path);}
    }

    [DllImport("kernel32.dll",CharSet=CharSet.Unicode,SetLastError=true)]
    private static extern bool MoveFileEx(string oldPath,string newPath,uint flags);
    public override int Rename(object node,object desc,string name,string next,bool replace)
    {
        using(Grant()){
            string from=Backing(name), to=Backing(next);MayWrite(from);MayWrite(to);
            if(!MoveFileEx(from,to,replace?1u:0u))return NtStatusFromWin32((uint)Marshal.GetLastWin32Error());
            ((OpenFile)desc).Path=to;
        }
        return STATUS_SUCCESS;
    }
    public override bool ReadDirectoryEntry(object node,object desc,string pattern,string marker,ref object context,out string name,out Info info)
    {
        using(Grant()){
            var cursor=context as IEnumerator<string>;
            if(cursor==null){
                var dir=((OpenFile)desc).Path;
                var entries=new List<string>(Directory.GetFileSystemEntries(dir));
                entries.Sort(StringComparer.OrdinalIgnoreCase);
                cursor=entries.FindAll(p=>marker==null||StringComparer.OrdinalIgnoreCase.Compare(Path.GetFileName(p),marker)>0).GetEnumerator();
                context=cursor;
            }
            while(cursor.MoveNext()){
                name=Path.GetFileName(cursor.Current);
                try { info=Describe(cursor.Current); return true; }
                catch(FileNotFoundException){} catch(UnauthorizedAccessException){}
            }
        }
        name=null;info=new Info();return false;
    }
}
