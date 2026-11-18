using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Diagnostics;
using System.IO;
using System.Runtime.InteropServices;
using System.Security.AccessControl;
using System.Security.Principal;
using System.Text;
using Microsoft.Win32;

namespace CageLocalTool
{
    internal static partial class CageLocal
    {
        private const uint NerrSuccess = 0;
        private const uint NerrUserNotFound = 2221;
        private const uint UserPrivUser = 1;
        private const uint UfScript = 0x0001;
        private const uint UfPasswdCantChange = 0x0040;
        private const uint UfDontExpirePasswd = 0x10000;
        private const string SpecialAccountsUserListKey = @"SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\SpecialAccounts\UserList";

        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
        private struct USER_INFO_1
        {
            public string usri1_name;
            public string usri1_password;
            public uint usri1_password_age;
            public uint usri1_priv;
            public string usri1_home_dir;
            public string usri1_comment;
            public uint usri1_flags;
            public string usri1_script_path;
        }

        [StructLayout(LayoutKind.Sequential)]
        private struct LOCALGROUP_MEMBERS_INFO_0
        {
            public IntPtr lgrmi0_sid;
        }

        [DllImport("netapi32.dll", CharSet = CharSet.Unicode)]
        private static extern uint NetUserAdd(string servername, uint level, ref USER_INFO_1 buf, out uint parm_err);

        [DllImport("netapi32.dll", CharSet = CharSet.Unicode)]
        private static extern uint NetUserDel(string servername, string username);

        [DllImport("netapi32.dll", CharSet = CharSet.Unicode)]
        private static extern uint NetUserGetLocalGroups(
            string servername,
            string username,
            uint level,
            uint flags,
            out IntPtr bufptr,
            uint prefmaxlen,
            out uint entriesread,
            out uint totalentries);

        [DllImport("netapi32.dll", CharSet = CharSet.Unicode)]
        private static extern uint NetLocalGroupAddMembers(
            string servername,
            string groupname,
            uint level,
            ref LOCALGROUP_MEMBERS_INFO_0 buf,
            uint totalentries);

        [DllImport("netapi32.dll")]
        private static extern uint NetApiBufferFree(IntPtr buffer);

        [DllImport("userenv.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        private static extern bool DeleteProfile(string lpSidString, string lpProfilePath, string lpComputerName);

        internal static bool IsCurrentProcessAdmin()
        {
            using (WindowsIdentity id = WindowsIdentity.GetCurrent())
            {
                WindowsPrincipal principal = new WindowsPrincipal(id);
                return principal.IsInRole(WindowsBuiltInRole.Administrator);
            }
        }

        internal static string CurrentUserSid()
        {
            using (WindowsIdentity id = WindowsIdentity.GetCurrent())
            {
                return id.User.Value;
            }
        }

        private static string GenerateStrongPassword()
        {
            byte[] random = RandomBytes(24);
            try
            {
                string b64 = Convert.ToBase64String(random).Replace('+', 'A').Replace('/', 'B').TrimEnd('=');
                return "Cg!" + b64 + "9#a";
            }
            finally
            {
                Array.Clear(random, 0, random.Length);
            }
        }

        private static string ResolveLocalGroupShortName(string groupSid)
        {
            string full = new SecurityIdentifier(groupSid).Translate(typeof(NTAccount)).Value;
            int idx = full.IndexOf('\\');
            return idx >= 0 ? full.Substring(idx + 1) : full;
        }

        private static void EnsureWorkerGroupMembership(string workerUsername, string workerSid, bool verifyOnly = false)
        {
            bool inUsers = false;
            IntPtr buf = IntPtr.Zero;
            uint read = 0;
            uint total = 0;
            uint rc = NetUserGetLocalGroups(null, workerUsername, 0, 1, out buf, 0xFFFFFFFFu, out read, out total);
            if (rc != NerrSuccess)
            {
                throw new Win32Exception(unchecked((int)rc), "NetUserGetLocalGroups failed");
            }
            try
            {
                for (int i = 0; i < (int)read; i++)
                {
                    IntPtr strPtr = Marshal.ReadIntPtr(buf, i * IntPtr.Size);
                    string groupName = Marshal.PtrToStringUni(strPtr);
                    if (string.IsNullOrEmpty(groupName))
                    {
                        continue;
                    }
                    string sid = new NTAccount(groupName).Translate(typeof(SecurityIdentifier)).Value;
                    if (string.Equals(sid, WellKnownAdminsSid, StringComparison.OrdinalIgnoreCase))
                    {
                        throw new InvalidOperationException("Worker account must never belong to Administrators.");
                    }
                    if (string.Equals(sid, WellKnownUsersSid, StringComparison.OrdinalIgnoreCase))
                    {
                        inUsers = true;
                    }
                    else if (verifyOnly)
                    {
                        throw new InvalidOperationException("The isolated account must belong only to the local Users group.");
                    }
                }
            }
            finally
            {
                if (buf != IntPtr.Zero)
                {
                    NetApiBufferFree(buf);
                }
            }

            if (!inUsers)
            {
                if (verifyOnly)
                {
                    throw new InvalidOperationException("The isolated account is missing its local Users group.");
                }
                byte[] sidBytes = new byte[new SecurityIdentifier(workerSid).BinaryLength];
                new SecurityIdentifier(workerSid).GetBinaryForm(sidBytes, 0);
                IntPtr sidPtr = Marshal.AllocHGlobal(sidBytes.Length);
                try
                {
                    Marshal.Copy(sidBytes, 0, sidPtr, sidBytes.Length);
                    LOCALGROUP_MEMBERS_INFO_0 member = new LOCALGROUP_MEMBERS_INFO_0 { lgrmi0_sid = sidPtr };
                    string usersGroup = ResolveLocalGroupShortName(WellKnownUsersSid);
                    uint addRc = NetLocalGroupAddMembers(null, usersGroup, 0, ref member, 1);
                    if (addRc != NerrSuccess && addRc != 1378 /* ERROR_MEMBER_IN_ALIAS */)
                    {
                        throw new Win32Exception(unchecked((int)addRc), "NetLocalGroupAddMembers failed");
                    }
                }
                finally
                {
                    Marshal.FreeHGlobal(sidPtr);
                }
            }
        }

        private static void ConfigureDirectoryAcl(string path, string controllerSid, string workerSid, bool workerReadExecute, bool includeAllPackages)
        {
            DirectorySecurity acl = new DirectorySecurity();
            acl.SetAccessRuleProtection(true, false);
            acl.SetOwner(new SecurityIdentifier(controllerSid));
            InheritanceFlags fullInherit = InheritanceFlags.ContainerInherit | InheritanceFlags.ObjectInherit;
            string[] admins = new string[] { controllerSid, WellKnownSystemSid, WellKnownAdminsSid };
            for (int i = 0; i < admins.Length; i++)
            {
                acl.AddAccessRule(new FileSystemAccessRule(
                    new SecurityIdentifier(admins[i]),
                    FileSystemRights.FullControl,
                    fullInherit,
                    PropagationFlags.None,
                    AccessControlType.Allow));
            }
            FileSystemRights workerRights = workerReadExecute
                ? FileSystemRights.ReadAndExecute
                : (FileSystemRights.ListDirectory | FileSystemRights.Traverse | FileSystemRights.ReadAttributes | FileSystemRights.ReadExtendedAttributes | FileSystemRights.ReadPermissions | FileSystemRights.Synchronize);
            InheritanceFlags workerInherit = workerReadExecute ? fullInherit : InheritanceFlags.None;

            acl.AddAccessRule(new FileSystemAccessRule(
                new SecurityIdentifier(workerSid),
                workerRights,
                workerInherit,
                PropagationFlags.None,
                AccessControlType.Allow));

            if (includeAllPackages)
            {
                acl.AddAccessRule(new FileSystemAccessRule(
                    new SecurityIdentifier(WellKnownAllPackagesSid),
                    workerRights,
                    workerInherit,
                    PropagationFlags.None,
                    AccessControlType.Allow));
            }

            Directory.SetAccessControl(path, acl);
        }

        private static void HideFromLogonUi(string username, bool hidden)
        {
            using (RegistryKey key = Registry.LocalMachine.CreateSubKey(SpecialAccountsUserListKey))
            {
                if (key == null)
                {
                    throw new InvalidOperationException("Failed to open SpecialAccounts\\UserList.");
                }
                if (hidden)
                {
                    key.SetValue(username, 0, RegistryValueKind.DWord);
                }
                else
                {
                    key.DeleteValue(username, false);
                }
            }
        }

        internal static int ProvisionCommand(string[] args)
        {
            if (!IsCurrentProcessAdmin())
            {
                throw new UnauthorizedAccessException("provision requires Windows Administrator privileges.");
            }
            string controllerSid = null;
            string profileOut = null;
            int brokerPort = 17981;
            for (int i = 1; i < args.Length; i++)
            {
                if (args[i] == "--controller-sid" && i + 1 < args.Length)
                {
                    controllerSid = args[++i];
                }
                else if (args[i] == "--profile-out" && i + 1 < args.Length)
                {
                    profileOut = Path.GetFullPath(args[++i]);
                }
                else if (args[i] == "--broker-port" && i + 1 < args.Length)
                {
                    brokerPort = int.Parse(args[++i]);
                }
                else
                {
                    throw new InvalidDataException("Unknown provision argument: " + args[i]);
                }
            }
            if (string.IsNullOrEmpty(controllerSid) || !controllerSid.StartsWith("S-1-5-21-", StringComparison.Ordinal))
            {
                throw new InvalidDataException("Valid --controller-sid is required.");
            }
            if (string.IsNullOrEmpty(profileOut) || brokerPort < 1024 || brokerPort > 65535)
            {
                throw new InvalidDataException("Valid --profile-out and --broker-port are required.");
            }

            string instanceId = Guid.NewGuid().ToString("D");
            string shortId = instanceId.Replace("-", "").Substring(0, 8);
            string workerUsername = "CageLocal_" + shortId;
            string password = GenerateStrongPassword();

            string parentDir = ProgramDataParentDir();
            string rootDir = Path.Combine(parentDir, instanceId);
            string binDir = Path.Combine(rootDir, "bin");
            string toolsDir = Path.Combine(rootDir, "tools");
            string sharedDir = Path.Combine(rootDir, "shared");
            string credFile = Path.Combine(rootDir, "worker.dpapi");
            string receiptFile = Path.Combine(rootDir, "wfp-receipt.json");
            string rootProfileFile = Path.Combine(rootDir, "local-profile.json");

            bool userCreated = false;
            bool wfpInstalled = false;
            string workerSid = null;

            try
            {
                USER_INFO_1 info = new USER_INFO_1
                {
                    usri1_name = workerUsername,
                    usri1_password = password,
                    usri1_password_age = 0,
                    usri1_priv = UserPrivUser,
                    usri1_home_dir = null,
                    usri1_comment = "Cage native standard-user isolation account",
                    usri1_flags = UfScript | UfPasswdCantChange | UfDontExpirePasswd,
                    usri1_script_path = null
                };
                uint parmErr;
                uint rc = NetUserAdd(null, 1, ref info, out parmErr);
                if (rc != NerrSuccess)
                {
                    throw new Win32Exception(unchecked((int)rc), string.Format("NetUserAdd failed (rc={0}, parm={1})", rc, parmErr));
                }
                userCreated = true;

                workerSid = new NTAccount(Environment.MachineName, workerUsername).Translate(typeof(SecurityIdentifier)).Value;
                EnsureWorkerGroupMembership(workerUsername, workerSid);
                HideFromLogonUi(workerUsername, true);

                Directory.CreateDirectory(parentDir);
                AssertNoReparsePointOnTreeUpToRoot(parentDir, parentDir);
                ConfigureDirectoryAcl(parentDir, controllerSid, workerSid, false, true);

                Directory.CreateDirectory(rootDir);
                ConfigureDirectoryAcl(rootDir, controllerSid, workerSid, false, true);

                Directory.CreateDirectory(binDir);
                ConfigureDirectoryAcl(binDir, controllerSid, workerSid, true, true);

                Directory.CreateDirectory(toolsDir);
                ConfigureDirectoryAcl(toolsDir, controllerSid, workerSid, true, true);

                Directory.CreateDirectory(sharedDir);
                ConfigureDirectoryAcl(sharedDir, controllerSid, workerSid, false, true);

                string selfExe = typeof(CageLocal).Assembly.Location;
                string targetExe = Path.Combine(binDir, "CageLocal.exe");
                File.Copy(selfExe, targetExe, true);

                Dictionary<string, object> wfpSummary = WfpApply("install", instanceId, workerSid, brokerPort, controllerSid);
                wfpInstalled = true;
                if (!(bool)wfpSummary["allVerified"])
                {
                    throw new InvalidOperationException("WFP filter verification did not pass all rules.");
                }
                wfpSummary["provisionedAtUtc"] = DateTime.UtcNow.ToString("o");
                SaveJsonFile(receiptFile, wfpSummary);
                SetControllerOnlyFileAcl(receiptFile, controllerSid);

                byte[] plainPwd = Utf8NoBom.GetBytes(password);
                try
                {
                    byte[] cipherPwd = DpapiProtect(plainPwd, instanceId, controllerSid, workerSid);
                    File.WriteAllBytes(credFile, cipherPwd);
                    SetControllerOnlyFileAcl(credFile, controllerSid);
                }
                finally
                {
                    Array.Clear(plainPwd, 0, plainPwd.Length);
                }

                LocalProfileModel model = new LocalProfileModel
                {
                    schema = 1,
                    instanceId = instanceId,
                    controllerSid = controllerSid,
                    workerUsername = workerUsername,
                    workerSid = workerSid,
                    rootDir = rootDir,
                    binDir = binDir,
                    toolsDir = toolsDir,
                    sharedDir = sharedDir,
                    credentialFile = credFile,
                    wfpReceiptFile = receiptFile,
                    brokerPort = brokerPort
                };
                SaveJsonFile(rootProfileFile, model);
                SetControllerOnlyFileAcl(rootProfileFile, controllerSid);
                if (!string.Equals(Path.GetFullPath(profileOut), Path.GetFullPath(rootProfileFile), StringComparison.OrdinalIgnoreCase))
                {
                    SaveJsonFile(profileOut, model);
                    SetControllerOnlyFileAcl(profileOut, controllerSid);
                }

                Dictionary<string, object> result = new Dictionary<string, object>();
                result["provisioned"] = true;
                result["profilePath"] = profileOut;
                result["instanceId"] = instanceId;
                result["workerUsername"] = workerUsername;
                result["workerSid"] = workerSid;
                result["isAdmin"] = false;
                result["hiddenFromLogon"] = true;
                result["brokerPort"] = brokerPort;
                result["wfp"] = wfpSummary;
                Console.WriteLine(ToJson(result));
                return 0;
            }
            catch
            {
                if (wfpInstalled && !string.IsNullOrEmpty(workerSid))
                {
                    try { WfpApply("remove", instanceId, workerSid, brokerPort); } catch { }
                }
                if (userCreated)
                {
                    try { HideFromLogonUi(workerUsername, false); } catch { }
                    if (!string.IsNullOrEmpty(workerSid))
                    {
                        try { DeleteProfile(workerSid, null, null); } catch { }
                    }
                    try { NetUserDel(null, workerUsername); } catch { }
                }
                try
                {
                    if (Directory.Exists(rootDir))
                    {
                        Directory.Delete(rootDir, true);
                    }
                }
                catch { }
                throw;
            }
            finally
            {
                password = null;
            }
        }

        private static int TerminateProcessesForSid(string workerSid)
        {
            int killed = 0;
            Process[] procs = Process.GetProcesses();
            for (int i = 0; i < procs.Length; i++)
            {
                Process p = procs[i];
                try
                {
                    IntPtr hProc = OpenProcess(0x1001 /* PROCESS_TERMINATE | PROCESS_QUERY_LIMITED_INFORMATION */, false, p.Id);
                    if (hProc == IntPtr.Zero)
                    {
                        continue;
                    }
                    try
                    {
                        string sid = QueryProcessUserSid(hProc);
                        if (string.Equals(sid, workerSid, StringComparison.OrdinalIgnoreCase))
                        {
                            TerminateProcess(hProc, 1);
                            WaitForSingleObject(hProc, 3000);
                            killed++;
                        }
                    }
                    finally
                    {
                        CloseHandle(hProc);
                    }
                }
                catch
                {
                }
                finally
                {
                    p.Dispose();
                }
            }
            return killed;
        }

        internal static int TeardownCommand(string[] args)
        {
            if (!IsCurrentProcessAdmin())
            {
                throw new UnauthorizedAccessException("teardown requires Windows Administrator privileges.");
            }
            string profilePath = null;
            for (int i = 1; i < args.Length; i++)
            {
                if (args[i] == "--profile" && i + 1 < args.Length)
                {
                    profilePath = Path.GetFullPath(args[++i]);
                }
                else
                {
                    throw new InvalidDataException("Unknown teardown argument: " + args[i]);
                }
            }
            LocalProfileModel profile = LoadProfile(profilePath, false);

            int killed = TerminateProcessesForSid(profile.workerSid);
            Dictionary<string, object> wfp = WfpApply("remove", profile.instanceId, profile.workerSid, profile.brokerPort);
            HideFromLogonUi(profile.workerUsername, false);
            bool profileDeleted = DeleteProfile(profile.workerSid, null, null);
            int deleteProfileErr = profileDeleted ? 0 : Marshal.GetLastWin32Error();
            uint userDelRc = NetUserDel(null, profile.workerUsername);
            if (userDelRc != NerrSuccess && userDelRc != NerrUserNotFound)
            {
                throw new Win32Exception(unchecked((int)userDelRc), "NetUserDel failed");
            }
            if (Directory.Exists(profile.rootDir))
            {
                Directory.Delete(profile.rootDir, true);
            }
            if (File.Exists(profilePath))
            {
                File.Delete(profilePath);
            }

            Dictionary<string, object> result = new Dictionary<string, object>();
            result["tornDown"] = true;
            result["instanceId"] = profile.instanceId;
            result["workerUsername"] = profile.workerUsername;
            result["killedProcesses"] = killed;
            result["wfpRemainingFilters"] = wfp["installedFilters"];
            result["userProfileDeleted"] = profileDeleted;
            result["userProfileDeleteError"] = deleteProfileErr;
            result["accountDeleteResult"] = userDelRc;
            Console.WriteLine(ToJson(result));
            return 0;
        }

        internal static int GrantShareCommand(string[] args)
        {
            string profilePath = null;
            string targetDir = null;
            string access = null;
            for (int i = 1; i < args.Length; i++)
            {
                if (args[i] == "--profile" && i + 1 < args.Length)
                {
                    profilePath = Path.GetFullPath(args[++i]);
                }
                else if (args[i] == "--target" && i + 1 < args.Length)
                {
                    targetDir = Path.GetFullPath(args[++i]);
                }
                else if (args[i] == "--access" && i + 1 < args.Length)
                {
                    access = args[++i];
                }
                else
                {
                    throw new InvalidDataException("Unknown grant-share argument: " + args[i]);
                }
            }
            if (string.IsNullOrEmpty(targetDir) || (access != "ro" && access != "rw" && access != "revoke"))
            {
                throw new InvalidDataException("grant-share requires --profile, --target, and --access <ro|rw|revoke>.");
            }
            LocalProfileModel profile = LoadProfile(profilePath, true);
            var result = ChangeProjectGrant(profile, targetDir, access);
            Console.WriteLine(ToJson(result));
            return 0;
        }

        private static string ValidateProjectTarget(LocalProfileModel profile, string targetDir)
        {
            if (!Directory.Exists(targetDir))
            {
                throw new DirectoryNotFoundException("Share target directory does not exist: " + targetDir);
            }

            string userProfile = Path.GetFullPath(Environment.GetFolderPath(Environment.SpecialFolder.UserProfile)).TrimEnd('\\');
            string windowsDir = Path.GetFullPath(Environment.GetFolderPath(Environment.SpecialFolder.Windows)).TrimEnd('\\');
            string cleanTarget = Path.GetFullPath(targetDir).TrimEnd('\\');
            string pathRoot = Path.GetPathRoot(cleanTarget).TrimEnd('\\');
            if (pathRoot.Length != 2 || pathRoot[1] != ':' || new DriveInfo(pathRoot).DriveType != DriveType.Fixed ||
                string.Equals(cleanTarget, pathRoot, StringComparison.OrdinalIgnoreCase))
                throw new InvalidDataException("Choose a project directory on a local fixed drive.");
            if (typeof(CageLocal).Assembly.Location.StartsWith(cleanTarget + "\\", StringComparison.OrdinalIgnoreCase))
                throw new InvalidDataException("The selected directory contains the local account tool.");
            string workerProfile = null;
            using (RegistryKey key = Registry.LocalMachine.OpenSubKey(@"SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\" + profile.workerSid))
                if (key != null) workerProfile = key.GetValue("ProfileImagePath") as string;
            string[] protectedPaths = { userProfile, workerProfile, windowsDir, ProgramDataParentDir(), Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles),
                Environment.GetFolderPath(Environment.SpecialFolder.ProgramFilesX86) };
            foreach (string protectedPath in protectedPaths)
            {
                if (!string.IsNullOrEmpty(protectedPath) && (SameWindowsName(cleanTarget, protectedPath) ||
                    cleanTarget.StartsWith(protectedPath + "\\", StringComparison.OrdinalIgnoreCase) ||
                    protectedPath.StartsWith(cleanTarget + "\\", StringComparison.OrdinalIgnoreCase)))
                    throw new InvalidDataException("Choose a project outside protected program, account and system directories.");
            }

            for (DirectoryInfo dir = new DirectoryInfo(cleanTarget); dir != null; dir = dir.Parent)
            {
                if ((dir.Attributes & FileAttributes.ReparsePoint) != 0)
                {
                    throw new InvalidDataException("Reparse point found along target path: " + dir.FullName);
                }
            }
            return cleanTarget;
        }

        private static void ApplyProjectGrant(LocalProfileModel profile, string cleanTarget, string access)
        {
            using (var folder = PinnedProjectDirectory.Open(cleanTarget))
            {
                var acl = folder.ReadDacl();
                UpdateProjectDacl(acl, new SecurityIdentifier(profile.workerSid), access);
                folder.WriteDacl(acl);
            }
        }

        private static void UpdateProjectDacl(DirectorySecurity acl, SecurityIdentifier workerSid, string access)
        {
            acl.RemoveAccessRuleAll(new FileSystemAccessRule(workerSid, FileSystemRights.FullControl, AccessControlType.Allow));
            acl.RemoveAccessRuleAll(new FileSystemAccessRule(workerSid, FileSystemRights.FullControl, AccessControlType.Deny));

            if (access == "rw")
            {
                acl.AddAccessRule(new FileSystemAccessRule(
                    workerSid,
                    FileSystemRights.Modify | FileSystemRights.Synchronize,
                    InheritanceFlags.ContainerInherit | InheritanceFlags.ObjectInherit,
                    PropagationFlags.None,
                    AccessControlType.Allow));
            }
            else if (access == "ro")
            {
                acl.AddAccessRule(new FileSystemAccessRule(
                    workerSid,
                    FileSystemRights.ReadAndExecute,
                    InheritanceFlags.ContainerInherit | InheritanceFlags.ObjectInherit,
                    PropagationFlags.None,
                    AccessControlType.Allow));
                acl.AddAccessRule(new FileSystemAccessRule(
                    workerSid,
                    FileSystemRights.Write | FileSystemRights.Delete | FileSystemRights.DeleteSubdirectoriesAndFiles | FileSystemRights.ChangePermissions | FileSystemRights.TakeOwnership,
                    InheritanceFlags.ContainerInherit | InheritanceFlags.ObjectInherit,
                    PropagationFlags.None,
                    AccessControlType.Deny));
            }

        }
    }
}
