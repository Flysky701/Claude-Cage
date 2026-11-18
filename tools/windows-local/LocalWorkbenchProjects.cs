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
            internal uint[] VolumeIdentity()
            {
                uint[] data = new uint[13]; // BY_HANDLE_FILE_INFORMATION
                if (!GetProjectFileInformation(handle, data)) throw new Win32Exception(Marshal.GetLastWin32Error());
                return new[] { data[7], data[11], data[12] };
            }
            [DllImport("kernel32.dll", EntryPoint = "GetFileInformationByHandle", SetLastError = true)]
            private static extern bool GetProjectFileInformation(SafeFileHandle handle, [Out] uint[] information);
            internal static PinnedProjectDirectory Open(string path, bool modifyAcl = true)
            {
                var handle = OpenFolder(path, modifyAcl ? 0x00060080u : 0x00020080u /* READ_CONTROL, READ_ATTRIBUTES, optional WRITE_DAC */,
                    3 /* no DELETE */, IntPtr.Zero, 3, 0x02000000, IntPtr.Zero);
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
            return ExplicitProjectAccess(Directory.GetAccessControl(path), sid);
        }

        private static string ExplicitProjectAccess(DirectorySecurity security, string sid)
        {
            bool read = false, modify = false, writeDenied = false;
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

        private sealed class PendingProjectGrant : IDisposable
        {
            internal string Path, After;
            internal PinnedProjectDirectory Directory;
            internal readonly List<FileSystemAccessRule> Previous = new List<FileSystemAccessRule>();
            public void Dispose() { if (Directory != null) Directory.Dispose(); }
        }

        // All members must still have the rights observed by the project picker.
        // Pin every target before writing the first ACL and retain its original
        // explicit rules for this SID; unrelated trustees are never rolled back.
        private static void ChangeProjectGrants(LocalProfileModel profile, object[] changes)
        {
            if (changes == null || changes.Length == 0 || changes.Length > 64) throw new InvalidDataException("Invalid project changes.");
            string file = Path.Combine(profile.rootDir, "workbench-projects.json");
            var sid = new SecurityIdentifier(profile.workerSid);
            using (var lease = AcquireProjectGrantLock(profile))
            {
                var original = ProjectCandidates(profile, file);
                var candidates = new HashSet<string>(original, StringComparer.OrdinalIgnoreCase);
                var saved = new HashSet<string>(original, StringComparer.OrdinalIgnoreCase);
                var seen = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
                var pending = new List<PendingProjectGrant>();
                int applied = 0;
                bool staged = false;
                try
                {
                    foreach (object item in changes)
                    {
                        var change = (Dictionary<string, object>)item;
                        string path = ValidateProjectTarget(profile, (string)change["path"]);
                        string before = (string)change["before"], after = (string)change["after"];
                        if (!seen.Add(path) || (after != "rw" && after != "ro" && after != ""))
                            throw new InvalidDataException("Invalid project permission change.");
                        var row = new PendingProjectGrant { Path = path, After = after, Directory = PinnedProjectDirectory.Open(path) };
                        pending.Add(row);
                        var acl = row.Directory.ReadDacl();
                        string current = original.Contains(path) ? ExplicitProjectAccess(acl, profile.workerSid) : "";
                        if (current != before || before == "unconfirmed")
                            throw new IOException("项目授权已变化，请重新打开项目选择器。");
                        foreach (FileSystemAccessRule rule in acl.GetAccessRules(true, false, typeof(SecurityIdentifier)))
                            if (rule.IdentityReference.Value == profile.workerSid) row.Previous.Add(rule);
                        if (after == "") saved.Remove(path);
                        else { candidates.Add(path); saved.Add(path); }
                    }
                    // Even an interrupted controller leaves every potentially
                    // granted directory listed and available for revocation.
                    if (!candidates.SetEquals(original)) { SaveCandidates(profile, file, candidates); staged = true; }
                    foreach (var row in pending)
                    {
                        InvalidateProjectVolume(profile, row.Path);
                        var acl = row.Directory.ReadDacl();
                        UpdateProjectDacl(acl, sid, row.After);
                        row.Directory.WriteDacl(acl);
                        applied++;
                        if (row.After != "" && ExplicitProjectAccess(row.Directory.ReadDacl(), profile.workerSid) != row.After)
                            throw new IOException("项目授权未生效。");
                    }
                    if (!saved.SetEquals(candidates)) SaveCandidates(profile, file, saved);
                }
                catch (Exception originalFailure)
                {
                    Exception rollback = null;
                    for (int i = applied - 1; i >= 0; i--)
                    {
                        try {
                            var row = pending[i];
                            var acl = row.Directory.ReadDacl();
                            UpdateProjectDacl(acl, sid, "");
                            foreach (FileSystemAccessRule prior in row.Previous) acl.AddAccessRule(prior);
                            row.Directory.WriteDacl(acl);
                        } catch (Exception failure) { rollback = failure; }
                    }
                    if (rollback != null) throw new IOException("恢复原权限失败，请检查项目权限：" + rollback.Message, originalFailure);
                    if (staged)
                        SaveCandidates(profile, file, original);
                    throw;
                }
                finally { foreach (var row in pending) row.Dispose(); }
            }
        }

        private static Dictionary<string, object> ChangeProjectGrant(LocalProfileModel profile, string path, string access)
        {
            if (access != "ro" && access != "rw" && access != "revoke") throw new InvalidDataException("Unknown project access.");
            string clean = ValidateProjectTarget(profile, path);
            string file = Path.Combine(profile.rootDir, "workbench-projects.json");
            using (var lease = AcquireProjectGrantLock(profile))
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
            if (line == null || line.Length > 262144) throw new InvalidDataException("Expected a project request.");
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
            else if (req.ContainsKey("changes"))
            {
                ChangeProjectGrants(profile, (object[])req["changes"]);
                Console.WriteLine(ToJson(new { workerSid = profile.workerSid, instanceId = profile.instanceId, applied = true }));
                return 0;
            }
            else if (req.ContainsKey("access")) ChangeProjectGrant(profile, (string)req["path"], (string)req["access"]);
            var projects = new List<Dictionary<string, string>>();
            string file = Path.Combine(profile.rootDir, "workbench-projects.json");
            using (AcquireProjectGrantLock(profile))
            foreach (string path in ProjectCandidates(profile, file))
            {
                string access = "unconfirmed";
                try
                {
                    ValidateProjectTarget(profile, path);
                    access = ExplicitProjectAccess(path, profile.workerSid);
                }
                catch (InvalidDataException) { }
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
            return SelectedWorkbenchProject(profile, Environment.GetEnvironmentVariable("CAGE_LOCAL_EDITOR_PROJECT"));
        }

        private static string SelectedWorkbenchProject(LocalProfileModel profile, string raw)
        {
            if (string.IsNullOrWhiteSpace(raw)) return null;
            string path = ValidateProjectTarget(profile, raw);
            if (!ProjectCandidates(profile, Path.Combine(profile.rootDir, "workbench-projects.json")).Contains(path) ||
                ExplicitProjectAccess(path, profile.workerSid) == "unconfirmed")
                throw new UnauthorizedAccessException("Select an authorized project before opening it.");
            return path;
        }
    }
}
