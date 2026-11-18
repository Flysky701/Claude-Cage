using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.IO;
using System.Runtime.InteropServices;
using System.Security.AccessControl;
using System.Security.Principal;
using System.Text;
using System.Threading;
using System.Windows.Forms;
using Microsoft.Win32.SafeHandles;

namespace CageLocalTool
{
    internal static partial class CageLocal
    {
        // Apply ACLs to the same directory object that was validated even if
        // another process concurrently replaces a directory entry or a junction.
        private sealed class PinnedProjectDirectory : IDisposable
        {
            [DllImport("kernel32.dll", EntryPoint="CreateFileW", CharSet=CharSet.Unicode, SetLastError=true)]
            private static extern SafeFileHandle OpenFolder(string path, uint access, uint sharing, IntPtr sa, uint creation, uint flags, IntPtr template);
            [DllImport("kernel32.dll", CharSet=CharSet.Unicode, SetLastError=true)]
            private static extern uint GetFinalPathNameByHandle(SafeFileHandle handle, StringBuilder path, uint size, uint flags);
            [DllImport("advapi32.dll")]
            private static extern uint GetSecurityInfo(SafeFileHandle handle, int kind, uint flags, IntPtr owner, IntPtr group, IntPtr dacl, IntPtr sacl, out IntPtr sd);
            [DllImport("advapi32.dll")]
            private static extern uint SetSecurityInfo(SafeFileHandle handle, int kind, uint flags, IntPtr owner, IntPtr group, IntPtr dacl, IntPtr sacl);
            [DllImport("advapi32.dll")]
            private static extern uint GetSecurityDescriptorLength(IntPtr sd);
            [DllImport("advapi32.dll", SetLastError=true)]
            private static extern bool GetSecurityDescriptorDacl(IntPtr sd, out bool present, out IntPtr dacl, out bool defaulted);

            private SafeFileHandle handle;
            internal static PinnedProjectDirectory Open(string path)
            {
                var handle = OpenFolder(path, 0x00060080 /* READ_CONTROL | WRITE_DAC | READ_ATTRIBUTES */, 3 /* no DELETE */, IntPtr.Zero, 3, 0x02000000, IntPtr.Zero);
                if (handle.IsInvalid) { handle.Dispose(); throw new Win32Exception(Marshal.GetLastWin32Error(), "Could not open project permissions."); }
                try
                {
                    var real = new StringBuilder(32768);
                    uint n = GetFinalPathNameByHandle(handle, real, (uint)real.Capacity, 0);
                    if (n == 0 || n >= real.Capacity || !SameWindowsName(real.ToString(), @"\\?\" + path))
                        throw new InvalidDataException("The selected project resolves to a different directory.");
                    return new PinnedProjectDirectory { handle = handle };
                }
                catch { handle.Dispose(); throw; }
            }
            internal DirectorySecurity ReadDacl()
            {
                IntPtr sd;
                uint error = GetSecurityInfo(handle, 1, 4, IntPtr.Zero, IntPtr.Zero, IntPtr.Zero, IntPtr.Zero, out sd);
                if (error != 0) throw new Win32Exception((int)error);
                try
                {
                    byte[] bytes = new byte[GetSecurityDescriptorLength(sd)];
                    Marshal.Copy(sd, bytes, 0, bytes.Length);
                    var security = new DirectorySecurity();
                    security.SetSecurityDescriptorBinaryForm(bytes, AccessControlSections.Access);
                    return security;
                }
                finally { LocalFree(sd); }
            }
            internal void WriteDacl(DirectorySecurity security)
            {
                var bytes = security.GetSecurityDescriptorBinaryForm();
                var pinned = GCHandle.Alloc(bytes, GCHandleType.Pinned);
                try
                {
                    IntPtr dacl;
                    bool present, defaulted;
                    if (!GetSecurityDescriptorDacl(pinned.AddrOfPinnedObject(), out present, out dacl, out defaulted) || !present || dacl == IntPtr.Zero)
                        throw new InvalidDataException("Could not serialize project permissions.");
                    uint error = SetSecurityInfo(handle, 1, 4, IntPtr.Zero, IntPtr.Zero, dacl, IntPtr.Zero);
                    if (error != 0) throw new Win32Exception((int)error);
                }
                finally { pinned.Free(); }
            }
            public void Dispose() { handle.Dispose(); }
        }
        private static HashSet<string> ProjectCandidates(LocalProfileModel profile, string file)
        {
            var result = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            if (File.Exists(file))
            {
                VerifyControllerOnlyFileAcl(file, profile.controllerSid, profile.workerSid);
                var saved = CreateJsonSerializer().Deserialize<string[]>(File.ReadAllText(file, Utf8NoBom));
                if (saved == null) throw new InvalidDataException("Invalid project record.");
                foreach (string path in saved) result.Add(path);
            }
            return result;
        }

        private static void SaveCandidates(LocalProfileModel profile, string file, HashSet<string> paths)
        {
            string stage = Path.Combine(profile.rootDir, ".projects-" + Guid.NewGuid().ToString("N"));
            try
            {
                using (FileStream fresh = new FileStream(stage, FileMode.CreateNew, FileAccess.Write, FileShare.None)) { }
                SetControllerOnlyFileAcl(stage, profile.controllerSid);
                File.WriteAllText(stage, ToJson(paths), Utf8NoBom);
                if (File.Exists(file)) File.Replace(stage, file, null);
                else File.Move(stage, file);
            }
            finally { if (File.Exists(stage)) File.Delete(stage); }
        }

        private static string ExplicitProjectAccess(string path, string sid)
        {
            bool read = false, modify = false, writeDenied = false;
            DirectorySecurity security = Directory.GetAccessControl(path);
            foreach (FileSystemAccessRule rule in security.GetAccessRules(true, false, typeof(SecurityIdentifier)))
            {
                if (rule.IdentityReference.Value != sid) continue;
                if (rule.AccessControlType == AccessControlType.Deny)
                    writeDenied |= (rule.FileSystemRights & FileSystemRights.Write) != 0;
                else
                {
                    read |= (rule.FileSystemRights & FileSystemRights.ReadAndExecute) == FileSystemRights.ReadAndExecute;
                    modify |= (rule.FileSystemRights & FileSystemRights.Modify) == FileSystemRights.Modify;
                }
            }
            return read && writeDenied ? "ro" : modify ? "rw" : "unconfirmed";
        }

        private static Dictionary<string, object> ChangeProjectGrant(LocalProfileModel profile, string path, string access)
        {
            if (access != "ro" && access != "rw" && access != "revoke") throw new InvalidDataException("Unknown project access.");
            string clean = ValidateProjectTarget(profile, path);
            string file = Path.Combine(profile.rootDir, "workbench-projects.json");
            using (var lease = new FileStream(file + ".lock", FileMode.OpenOrCreate, FileAccess.ReadWrite, FileShare.None))
            {
                var paths = ProjectCandidates(profile, file);
                // First record the candidate. Even a crash between the filesystem
                // ACL change and the reply leaves an enumerable, revocable grant.
                if (access != "revoke" && paths.Add(clean)) SaveCandidates(profile, file, paths);
                ApplyProjectGrant(profile, clean, access);
                if (access == "revoke")
                {
                    if (paths.Remove(clean)) SaveCandidates(profile, file, paths);
                }
                else if (ExplicitProjectAccess(clean, profile.workerSid) != access)
                    throw new IOException("Could not confirm the requested project access.");
            }
            return new Dictionary<string, object> { { "target", clean }, { "access", access }, { "workerSid", profile.workerSid } };
        }

        private static int RunWorkbenchProjects(LocalProfileModel profile)
        {
            string line = Console.ReadLine();
            if (line == null || line.Length > 32768) throw new InvalidDataException("Expected a project request.");
            var req = FromJsonObject(line);
            if (!req.ContainsKey("instanceId") || !req.ContainsKey("workerSid") ||
                !SameWindowsName((string)req["instanceId"], profile.instanceId) || !SameWindowsName((string)req["workerSid"], profile.workerSid))
                throw new UnauthorizedAccessException("The current workbench binding differs from the selected Windows account.");
            string selected = null;
            if (req.ContainsKey("action") && (string)req["action"] == "choose")
            {
                // The controller shows a folder picker only after a user click.
                // Choosing a directory does not change its ACL.
                Exception failure = null;
                Thread picker = new Thread(delegate() {
                    try
                    {
                        using (var dialog = new FolderBrowserDialog { Description = "选择要授权给 Cage 隔离账户的项目文件夹", ShowNewFolderButton = false })
                            if (dialog.ShowDialog() == DialogResult.OK) selected = dialog.SelectedPath;
                    }
                    catch (Exception e) { failure = e; }
                });
                picker.SetApartmentState(ApartmentState.STA);
                picker.Start();
                picker.Join();
                if (failure != null) throw new IOException("The folder picker could not be opened.", failure);
            }
            else if (req.ContainsKey("access")) ChangeProjectGrant(profile, (string)req["path"], (string)req["access"]);
            var projects = new List<Dictionary<string, string>>();
            string file = Path.Combine(profile.rootDir, "workbench-projects.json");
            foreach (string path in ProjectCandidates(profile, file))
            {
                string access = "unconfirmed";
                try
                {
                    ValidateProjectTarget(profile, path);
                    access = ExplicitProjectAccess(path, profile.workerSid);
                }
                catch (IOException) { }
                catch (UnauthorizedAccessException) { }
                projects.Add(new Dictionary<string, string> { { "path", path }, { "access", access } });
            }
            Console.WriteLine(ToJson(new Dictionary<string, object> { { "workerSid", profile.workerSid }, { "instanceId", profile.instanceId },
                { "projects", projects }, { "selected", selected } }));
            return 0;
        }

        private static string SelectedEditorProject(LocalProfileModel profile)
        {
            string raw = Environment.GetEnvironmentVariable("CAGE_LOCAL_EDITOR_PROJECT");
            if (string.IsNullOrWhiteSpace(raw)) return null;
            string path = ValidateProjectTarget(profile, raw);
            if (!ProjectCandidates(profile, Path.Combine(profile.rootDir, "workbench-projects.json")).Contains(path) ||
                ExplicitProjectAccess(path, profile.workerSid) == "unconfirmed")
                throw new UnauthorizedAccessException("Select an authorized project before opening it.");
            return path;
        }
    }
}
