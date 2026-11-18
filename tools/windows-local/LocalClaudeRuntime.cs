using System;
using System.Collections;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Security.AccessControl;
using System.Security.Principal;
using System.Text;
using System.Threading;
using Microsoft.Win32.SafeHandles;

namespace CageLocalTool
{
    internal static partial class CageLocal
    {
        // Both the interactive CLI and its account commands use this same Low directory.
        // A legacy credential is imported once. Logout must never resurrect it from the
        // older account directory. No hook, plugin, config, or project is imported.
        private static void PrepareClaudeRuntime(IntPtr low, string profile, string source, string target)
        {
            using (WindowsIdentity.Impersonate(low))
            {
                AssertNoReparsePointOnTreeUpToRoot(target, profile);
                Directory.CreateDirectory(target);
                string lockPath = Path.Combine(target, "cage-runtime.lock");
                AssertNoReparsePointOnTreeUpToRoot(lockPath, profile);
                var timer = Stopwatch.StartNew();
                FileStream lease;
                while (true)
                {
                    try { lease = new FileStream(lockPath, FileMode.OpenOrCreate, FileAccess.Write, FileShare.None); break; }
                    catch (IOException) { if (timer.ElapsedMilliseconds >= 2500) throw; Thread.Sleep(40); }
                }
                using (lease)
                {
                    string marker = Path.Combine(target, "cage-runtime-initialized");
                    AssertNoReparsePointOnTreeUpToRoot(marker, profile);
                    if (File.Exists(marker)) return;
                    string credential = Path.Combine(source, ".credentials.json");
                    string destination = Path.Combine(target, ".credentials.json");
                    AssertNoReparsePointOnTreeUpToRoot(credential, profile);
                    AssertNoReparsePointOnTreeUpToRoot(destination, profile);
                    if (File.Exists(credential) && !File.Exists(destination))
                        ImportExistingClaudeCredential(credential, destination);
                    using (File.Open(marker, FileMode.CreateNew, FileAccess.Write, FileShare.None)) { }
                }
            }
        }

        [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        private static extern uint GetFinalPathNameByHandle(SafeFileHandle handle, StringBuilder path, uint size, uint flags);

        [StructLayout(LayoutKind.Sequential)]
        private struct ClaudeFileInfo
        {
            internal uint Attributes;
            internal System.Runtime.InteropServices.ComTypes.FILETIME Created, Accessed, Written;
            internal uint Volume, SizeHigh, SizeLow, Links, IndexHigh, IndexLow;
        }
        [DllImport("kernel32.dll", SetLastError = true)]
        private static extern bool GetFileInformationByHandle(SafeFileHandle handle, out ClaudeFileInfo info);

        private static void CheckClaudeFileHandle(FileStream stream, string path)
        {
            var real = new StringBuilder(32768);
            uint count = GetFinalPathNameByHandle(stream.SafeFileHandle, real, (uint)real.Capacity, 0);
            ClaudeFileInfo info;
            if (count == 0 || count >= real.Capacity || !SameWindowsName(real.ToString(), @"\\?\" + path) ||
                !GetFileInformationByHandle(stream.SafeFileHandle, out info) || info.Links != 1 ||
                (info.Attributes & (uint)(FileAttributes.ReparsePoint | FileAttributes.Directory)) != 0)
                throw new InvalidDataException("账号凭据文件已重定向。");
        }

        private static string ReadClaudeProfileLabel(string source, string id)
        {
            string path = Path.Combine(source, "cage-label.txt");
            if (File.Exists(path))
            {
                using (var stream = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.Read))
                {
                    CheckClaudeFileHandle(stream, path);
                    if (stream.Length <= 1024)
                    {
                        using (var reader = new StreamReader(stream, Utf8NoBom)) {
                            string label = reader.ReadToEnd().Trim();
                            if (label.Length > 0 && label.Length <= 64 && !label.Any(char.IsControl)) return label;
                        }
                    }
                }
            }
            return id == "default" ? "默认账号" : id;
        }

        private static void ImportExistingClaudeCredential(string credential, string destination)
        {
            string dir = Path.GetDirectoryName(destination);
            using (PinnedProjectDirectory.Open(Path.GetDirectoryName(credential), false))
            using (PinnedProjectDirectory.Open(dir, false))
            using (var origin = new FileStream(credential, FileMode.Open, FileAccess.Read, FileShare.Read))
            {
                CheckClaudeFileHandle(origin, credential);
                if (origin.Length > (1 << 20)) throw new InvalidDataException("账号凭据文件过大。");
                var access = new FileSecurity();
                access.SetAccessRuleProtection(true, false);
                foreach (string id in new[] { CurrentUserSid(), WellKnownAdminsSid, WellKnownSystemSid })
                    access.AddAccessRule(new FileSystemAccessRule(new SecurityIdentifier(id), FileSystemRights.FullControl, AccessControlType.Allow));
                string stage = Path.Combine(dir, Guid.NewGuid().ToString("N") + ".tmp");
                try
                {
                    using (var copy = new FileStream(stage, FileMode.CreateNew, FileSystemRights.FullControl, FileShare.None, 4096, FileOptions.None, access))
                    {
                        CheckClaudeFileHandle(copy, stage);
                        origin.CopyTo(copy);
                        copy.Flush(true);
                    }
                    File.Move(stage, destination);
                }
                finally { if (File.Exists(stage)) File.Delete(stage); }
            }
        }

        // The CLI stores <session-id>.jsonl beneath one project directory.
        // A window closed at onboarding has a real ID but no transcript yet.
        private static bool HasClaudeTranscript(string runtime, string id)
        {
            string projects = Path.Combine(runtime, "projects");
            try
            {
                if ((File.GetAttributes(projects) & FileAttributes.ReparsePoint) != 0)
                    throw new InvalidDataException("Claude 历史目录已重定向。");
            }
            catch (FileNotFoundException) { return false; }
            catch (DirectoryNotFoundException) { return false; }
            int inspected = 0;
            foreach (string project in Directory.EnumerateDirectories(projects))
            {
                if (++inspected > 8192) throw new InvalidDataException("Claude 项目历史目录过多，无法核实记录。");
                if ((File.GetAttributes(project) & FileAttributes.ReparsePoint) != 0) continue;
                string file = Path.Combine(project, id + ".jsonl");
                try
                {
                    var attrs = File.GetAttributes(file);
                    if ((attrs & (FileAttributes.Directory | FileAttributes.ReparsePoint)) != 0)
                        throw new InvalidDataException("Claude 会话记录不是普通文件。");
                    return new FileInfo(file).Length > 0;
                }
                catch (FileNotFoundException) { }
                catch (DirectoryNotFoundException) { }
            }
            return false;
        }

        [DllImport("kernel32.dll", SetLastError = true)]
        private static extern IntPtr GetStdHandle(int kind);
        [DllImport("kernel32.dll", SetLastError = true)]
        private static extern bool DuplicateHandle(IntPtr process, IntPtr source, IntPtr destinationProcess,
            out IntPtr duplicate, uint access, bool inherit, uint options);

        // The supervisor only prepares pipes and a restricted token. All CLI commands,
        // including auth status/login, execute below it and cannot modify its settings.
        private static int RunLowClaudeAccount(string[] args)
        {
            if (!System.Text.RegularExpressions.Regex.IsMatch(Environment.UserName, @"\ACageLocal_[0-9a-f]{8}\z",
                System.Text.RegularExpressions.RegexOptions.IgnoreCase))
                throw new UnauthorizedAccessException("Claude 账号命令只能由专用 Windows 账户运行。");
            string profile = Environment.GetFolderPath(Environment.SpecialFolder.UserProfile);
            string local = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
            string id = Environment.GetEnvironmentVariable("CAGE_CLAUDE_ACCOUNT_ID");
            string source = WorkerServices.ConfigFolder(local, id);
            string runtime = Path.Combine(PrepareTerminalDirectory(profile, true), "ClaudeProfiles", id);
            string root = Directory.GetParent(Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location)).FullName;
            string exe = ServiceExecutable(Path.Combine(root, "tools"), "accounts");
            var env = new SortedDictionary<string, string>(StringComparer.OrdinalIgnoreCase);
            foreach (DictionaryEntry pair in Environment.GetEnvironmentVariables()) env[(string)pair.Key] = (string)pair.Value;
            env.Remove("CAGE_CLAUDE_ACCOUNT_ID");
            env["CLAUDE_CONFIG_DIR"] = runtime;
            env["TMP"] = env["TEMP"] = runtime;
            IntPtr token = IntPtr.Zero, low = IntPtr.Zero, variables = IntPtr.Zero, attr = IntPtr.Zero, list = IntPtr.Zero, job = IntPtr.Zero;
            bool initialized = false;
            var pi = new ProcessInformation();
            var inherited = new IntPtr[3];
            using (var self = Process.GetCurrentProcess())
            try
            {
                CheckWin32(OpenProcessToken(self.Handle, 0x008b, out token), "Open Claude service token");
                CheckWin32(CreateRestrictedToken(token, 1, 0, IntPtr.Zero, 0, IntPtr.Zero, 0, IntPtr.Zero, out low), "Restrict Claude service");
                SetTerminalTokenLow(low);
                PrepareClaudeRuntime(low, profile, source, runtime);
                IntPtr size = IntPtr.Zero;
                InitializeProcThreadAttributeList(IntPtr.Zero, 1, 0, ref size);
                attr = Marshal.AllocHGlobal(size);
                CheckWin32(InitializeProcThreadAttributeList(attr, 1, 0, ref size), "Prepare Claude service handles");
                initialized = true;
                list = Marshal.AllocHGlobal(inherited.Length * IntPtr.Size);
                for (int i = 0; i < inherited.Length; i++)
                {
                    CheckWin32(DuplicateHandle(self.Handle, GetStdHandle(-10-i), self.Handle, out inherited[i], 0, true, 2), "Attach Claude service pipe");
                    Marshal.WriteIntPtr(list, i * IntPtr.Size, inherited[i]);
                }
                CheckWin32(UpdateProcThreadAttribute(attr, 0, (IntPtr)0x20002, list, (IntPtr)(3 * IntPtr.Size), IntPtr.Zero, IntPtr.Zero), "Limit Claude service pipes");
                StartupInfoExW si = new StartupInfoExW();
                si.StartupInfo.cb = Marshal.SizeOf(typeof(StartupInfoExW));
                si.StartupInfo.dwFlags = (int)StartfUseStdHandles;
                si.StartupInfo.hStdInput = inherited[0];
                si.StartupInfo.hStdOutput = inherited[1];
                si.StartupInfo.hStdError = inherited[2];
                si.lpAttributeList = attr;
                variables = AllocUnicodeEnvBlock(env);
                job = CreateKillOnCloseJob();
                CheckWin32(CreateTerminalAsUser(low, exe, new StringBuilder(BuildCommandLine(exe, args.Skip(1).ToArray())),
                    IntPtr.Zero, IntPtr.Zero, true, ExtendedStartupInfoPresent | CreateUnicodeEnvironment | CreateNoWindow | CreateSuspended,
                    variables, Path.GetDirectoryName(exe), ref si, out pi), "Open isolated Claude account CLI");
                CheckWin32(AssignProcessToJobObject(job, pi.hProcess), "Bind Claude account command");
                VerifyTerminalToken(pi.hProcess, CurrentUserSid());
                CheckWin32(ResumeThread(pi.hThread) != uint.MaxValue, "Start Claude account command");
                WaitForSingleObject(pi.hProcess, uint.MaxValue);
                uint code;
                CheckWin32(GetExitCodeProcess(pi.hProcess, out code), "Read Claude account command result");
                return unchecked((int)code);
            }
            finally
            {
                if (pi.hProcess != IntPtr.Zero) { TerminateProcess(pi.hProcess, 1); CloseHandle(pi.hProcess); }
                if (pi.hThread != IntPtr.Zero) CloseHandle(pi.hThread);
                if (job != IntPtr.Zero) CloseHandle(job);
                foreach (IntPtr h in inherited) if (h != IntPtr.Zero) CloseHandle(h);
                if (initialized) DeleteProcThreadAttributeList(attr);
                if (attr != IntPtr.Zero) Marshal.FreeHGlobal(attr);
                if (list != IntPtr.Zero) Marshal.FreeHGlobal(list);
                if (variables != IntPtr.Zero) Marshal.FreeHGlobal(variables);
                if (low != IntPtr.Zero) CloseHandle(low);
                if (token != IntPtr.Zero) CloseHandle(token);
            }
        }
    }
}
