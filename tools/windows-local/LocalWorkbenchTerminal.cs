using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.IO.Pipes;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Security.Cryptography;
using System.Text;
using System.Threading.Tasks;
using Microsoft.Win32.SafeHandles;

namespace CageLocalTool
{
    internal static partial class CageLocal
    {
        private const int TerminalInputLimit = 16 * 1024;

        private static void RefreshTerminalWorker(string destination, string controllerSid)
        {
            // Only the existing, validated deployment's worker executable is updated.
            // File.Replace preserves its protected access rules. Stage on the same volume.
            using (FileStream source = File.OpenRead(Assembly.GetExecutingAssembly().Location))
            using (SHA256 hash = SHA256.Create())
            {
                string expected = Convert.ToBase64String(hash.ComputeHash(source));
                using (FileStream deployed = File.OpenRead(destination))
                {
                    if (Convert.ToBase64String(hash.ComputeHash(deployed)) == expected) return;
                }
                string stage = Path.Combine(Path.GetDirectoryName(destination), Guid.NewGuid().ToString("N") + ".new");
                try
                {
                    source.Position = 0;
                    using (FileStream copy = new FileStream(stage, FileMode.CreateNew, FileAccess.Write, FileShare.None))
                        source.CopyTo(copy);
                    VerifyDeploymentAcl(new FileInfo(stage), controllerSid);
                    File.Replace(stage, destination, null);
                    VerifyDeploymentAcl(new FileInfo(destination), controllerSid);
                }
                finally { if (File.Exists(stage)) File.Delete(stage); }
            }
        }

        private static void ValidateTerminalInput(string text)
        {
            if (text == null || text.IndexOfAny(new[] { '\r', '\n', '\0' }) >= 0 || Utf8NoBom.GetByteCount(text) > TerminalInputLimit)
                throw new InvalidDataException("Expected one PowerShell line of at most 16 KiB.");
        }

        private static int RunWorkbenchTerminal(LocalProfileModel profile)
        {
            using (var network = new WorkbenchAppNetwork(profile))
            {
                using (LocalWorkerSession session = new LocalWorkerSession(profile, "UTC", false, true))
                using (network.Attach(session))
                using (StreamWriter output = new StreamWriter(Console.OpenStandardOutput(), Utf8NoBom) { AutoFlush = true })
                {
                    var opened = session.Call("terminal-open", null, 20000);
                    var token = (Dictionary<string, object>)opened["token"];
                    if (!SameWindowsName((string)token["userSid"], profile.workerSid) ||
                        (string)token["integrityRid"] != "0x1000" ||
                        !SameWindowsName((string)opened["desktop"], session.DesktopName) ||
                        !session.OwnsPid(Convert.ToInt32(opened["pid"])))
                        throw new InvalidOperationException("PowerShell failed its account, desktop or job check.");
                    output.WriteLine(ToJson(new Dictionary<string, object> {
                        { "type", "ready" }, { "workerUsername", profile.workerUsername }, { "workerSid", token["userSid"] },
                        { "instanceId", profile.instanceId }, { "integrityLabel", token["integrityLabel"] }
                    }));
                    // Do not dispose a reader with an outstanding console read on shell exit.
                    // This helper owns its standard input for its entire process lifetime.
                    StreamReader input = new StreamReader(Console.OpenStandardInput(), Utf8NoBom);
                    Task<string> next = input.ReadLineAsync();
                    while (true)
                    {
                        var read = session.Call("terminal-read", null, 5000);
                        string chunk = (string)read["text"];
                        if (chunk.Length != 0)
                            output.WriteLine(ToJson(new Dictionary<string, object> { { "type", "output" }, { "text", chunk } }));
                        if ((bool)read["ended"])
                        {
                            output.WriteLine(ToJson(new Dictionary<string, object> { { "type", "exit" }, { "code", read["code"] } }));
                            return 0;
                        }
                        if (!next.Wait(chunk.Length == 0 ? 70 : 0)) continue;
                        string line = next.Result;
                        if (line == null) break;
                        var message = FromJsonObject(line);
                        string type = Convert.ToString(message["type"]);
                        if (type == "close") break;
                        if (type != "input") throw new InvalidDataException("Unknown terminal input.");
                        string command = (string)message["text"];
                        ValidateTerminalInput(command);
                        session.Call("terminal-input", new Dictionary<string, object> { { "text", command } }, 5000);
                        next = input.ReadLineAsync();
                    }
                    output.WriteLine("{\"type\":\"exit\"}");
                }
            }
            return 0;
        }

        [DllImport("kernel32.dll", SetLastError = true)]
        private static extern bool PeekNamedPipe(SafePipeHandle pipe, IntPtr buffer, uint size, IntPtr read, out uint available, IntPtr left);

        [DllImport("advapi32.dll", SetLastError = true)]
        private static extern bool CreateRestrictedToken(IntPtr existing, uint flags, uint disableCount, IntPtr disable,
            uint privilegeCount, IntPtr privileges, uint restrictCount, IntPtr restrictions, out IntPtr restricted);

        [DllImport("advapi32.dll", EntryPoint = "CreateProcessAsUserW", CharSet = CharSet.Unicode, SetLastError = true)]
        private static extern bool CreateTerminalAsUser(IntPtr token, string image, StringBuilder command,
            IntPtr processAttributes, IntPtr threadAttributes, bool inherit, uint flags, IntPtr environment,
            string directory, ref StartupInfoExW startup, out ProcessInformation process);

        // This class lives exclusively inside the standard-account daemon. The
        // shell's only inherited handles are the two anonymous pipe endpoints.
        private sealed class WorkerTerminal : IDisposable
        {
            private AnonymousPipeServerStream input, output;
            private IntPtr process, job;
            private readonly BlockingCollection<byte[]> commands = new BlockingCollection<byte[]>(16);
            private Task inputPump;
            private readonly Decoder decoder = Utf8NoBom.GetDecoder();
            private readonly byte[] bytes = new byte[8192];
            private readonly char[] chars = new char[8194];

            internal Dictionary<string, object> Open(string profileDir, string appData, string localAppData,
                int brokerPort, string timezone, string desktop, string expectedSid)
            {
                if (process != IntPtr.Zero) throw new InvalidOperationException("A terminal is already open.");
                string work = PrepareTerminalDirectory(profileDir);
                string shell = Path.Combine(Environment.SystemDirectory, @"WindowsPowerShell\v1.0\powershell.exe");
                string driver = "[Console]::OutputEncoding = [Text.UTF8Encoding]::new($false); " +
                    "$OutputEncoding = [Console]::OutputEncoding; " +
                    "[Console]::WriteLine('CageTerminalReady'); " +
                    "while ($null -ne ($__cageLine = [Console]::ReadLine())) { " +
                    "try { . ([ScriptBlock]::Create([Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($__cageLine)))) 2>&1 | Out-Default } " +
                    "catch { [Console]::WriteLine($_.ToString()) } }";
                string[] args = { "-NoLogo", "-NoProfile", "-NonInteractive", "-OutputFormat", "Text", "-Command", driver };
                var environment = BuildWorkerEnv(profileDir, appData, localAppData, work, brokerPort, timezone, null, null);
                environment["CAGE_SSH_CLIENT"] = Assembly.GetExecutingAssembly().Location;
                string toolsDir = Path.Combine(Directory.GetParent(Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location)).FullName, "tools");
                string cli = ServiceExecutable(toolsDir, "accounts");
                if (File.Exists(cli)) {
                    ConfigureClaudeShell(environment, toolsDir);
                    environment["PATH"] = Path.GetDirectoryName(cli) + ";" + environment["PATH"];
                    environment["CLAUDE_CONFIG_DIR"] = WorkerServices.ConfigFolder(localAppData, WorkerServices.SelectedProfile(localAppData));
                }
                IntPtr envBlock = IntPtr.Zero, attrList = IntPtr.Zero, handles = IntPtr.Zero;
                bool initialized = false;
                ProcessInformation pi = new ProcessInformation();
                IntPtr sourceToken = IntPtr.Zero, lowToken = IntPtr.Zero;
                try
                {
                    input = new AnonymousPipeServerStream(PipeDirection.Out, HandleInheritability.Inheritable);
                    output = new AnonymousPipeServerStream(PipeDirection.In, HandleInheritability.Inheritable);
                    IntPtr stdin = input.ClientSafePipeHandle.DangerousGetHandle();
                    IntPtr stdout = output.ClientSafePipeHandle.DangerousGetHandle();
                    job = CreateKillOnCloseJob();
                    IntPtr size = IntPtr.Zero;
                    InitializeProcThreadAttributeList(IntPtr.Zero, 1, 0, ref size);
                    attrList = Marshal.AllocHGlobal(size);
                    CheckWin32(InitializeProcThreadAttributeList(attrList, 1, 0, ref size), "Initialize terminal handle list");
                    initialized = true;
                    handles = Marshal.AllocHGlobal(2 * IntPtr.Size);
                    Marshal.WriteIntPtr(handles, 0, stdin);
                    Marshal.WriteIntPtr(handles, IntPtr.Size, stdout);
                    CheckWin32(UpdateProcThreadAttribute(attrList, 0, (IntPtr)0x20002, handles,
                        (IntPtr)(2 * IntPtr.Size), IntPtr.Zero, IntPtr.Zero), "Set terminal handle list");
                    StartupInfoExW si = new StartupInfoExW();
                    si.StartupInfo.cb = Marshal.SizeOf(typeof(StartupInfoExW));
                    si.StartupInfo.lpDesktop = "Winsta0\\" + desktop;
                    si.StartupInfo.dwFlags = (int)StartfUseStdHandles;
                    si.StartupInfo.hStdInput = stdin;
                    si.StartupInfo.hStdOutput = si.StartupInfo.hStdError = stdout;
                    si.lpAttributeList = attrList;
                    envBlock = AllocUnicodeEnvBlock(environment);
                    CheckWin32(OpenProcessToken(Process.GetCurrentProcess().Handle, 0x008b /* ASSIGN_PRIMARY | DUPLICATE | QUERY | ADJUST_DEFAULT */,
                        out sourceToken), "Open worker primary token");
                    CheckWin32(CreateRestrictedToken(sourceToken, 1 /* DISABLE_MAX_PRIVILEGE */, 0, IntPtr.Zero, 0, IntPtr.Zero,
                        0, IntPtr.Zero, out lowToken), "Restrict terminal token");
                    SetTerminalTokenLow(lowToken);
                    CheckWin32(CreateTerminalAsUser(lowToken, shell, new StringBuilder(BuildCommandLine(shell, args)), IntPtr.Zero, IntPtr.Zero, true,
                        ExtendedStartupInfoPresent | CreateUnicodeEnvironment | CreateNoWindow | CreateSuspended,
                        envBlock, work, ref si, out pi), "Start isolated PowerShell");
                    process = pi.hProcess;
                    CheckWin32(AssignProcessToJobObject(job, process), "Assign terminal job");
                    var token = VerifyTerminalToken(process, expectedSid);
                    input.DisposeLocalCopyOfClientHandle();
                    output.DisposeLocalCopyOfClientHandle();
                    CheckWin32(ResumeThread(pi.hThread) != uint.MaxValue, "Resume isolated PowerShell");
                    WaitUntilReady();
                    inputPump = Task.Run(delegate {
                        foreach (byte[] command in commands.GetConsumingEnumerable())
                            input.Write(command, 0, command.Length);
                    });
                    return new Dictionary<string, object> { { "pid", pi.dwProcessId }, { "token", token }, { "desktop", desktop } };
                }
                catch
                {
                    if (process != IntPtr.Zero) TerminateProcess(process, 1);
                    Dispose();
                    throw;
                }
                finally
                {
                    if (pi.hThread != IntPtr.Zero) CloseHandle(pi.hThread);
                    if (lowToken != IntPtr.Zero) CloseHandle(lowToken);
                    if (sourceToken != IntPtr.Zero) CloseHandle(sourceToken);
                    if (envBlock != IntPtr.Zero) Marshal.FreeHGlobal(envBlock);
                    if (initialized) DeleteProcThreadAttributeList(attrList);
                    if (handles != IntPtr.Zero) Marshal.FreeHGlobal(handles);
                    if (attrList != IntPtr.Zero) Marshal.FreeHGlobal(attrList);
                }
            }

            internal void Input(string text)
            {
                ValidateTerminalInput(text);
                // Base64 keeps the line framing independent of the worker's Windows
                // console input code page. Decoding and execution happen in PowerShell.
                byte[] line = Encoding.ASCII.GetBytes(Convert.ToBase64String(Utf8NoBom.GetBytes(text)) + "\n");
                if (inputPump.IsFaulted) throw new IOException("PowerShell input is closed.", inputPump.Exception);
                if (!commands.TryAdd(line)) throw new InvalidOperationException("PowerShell input queue is full.");
            }

            internal Dictionary<string, object> Read()
            {
                uint available;
                bool exited = WaitForSingleObject(process, 0) == 0;
                if (!PeekNamedPipe(output.SafePipeHandle, IntPtr.Zero, 0, IntPtr.Zero, out available, IntPtr.Zero))
                {
                    int error = Marshal.GetLastWin32Error();
                    if (error != 109 && error != 232) throw new System.ComponentModel.Win32Exception(error);
                    available = 0;
                }
                int read = available == 0 ? 0 : output.Read(bytes, 0, (int)Math.Min((uint)bytes.Length, available));
                bool ended = exited && read == 0;
                int count = decoder.GetChars(bytes, 0, read, chars, 0, ended);
                var result = new Dictionary<string, object> { { "text", new string(chars, 0, count) }, { "ended", ended } };
                if (ended)
                {
                    uint code;
                    CheckWin32(GetExitCodeProcess(process, out code), "Read PowerShell exit code");
                    result["code"] = unchecked((int)code);
                }
                return result;
            }

            private void WaitUntilReady()
            {
                var timer = Stopwatch.StartNew();
                var greeting = new StringBuilder();
                while (timer.ElapsedMilliseconds < 12000)
                {
                    var result = Read();
                    greeting.Append((string)result["text"]);
                    if (greeting.ToString().TrimEnd() == "CageTerminalReady") return;
                    if (greeting.Length > 2048 || (bool)result["ended"])
                        throw new InvalidOperationException("PowerShell failed during startup. " + greeting +
                            (result.ContainsKey("code") ? " Exit code " + result["code"] : ""));
                    System.Threading.Thread.Sleep(30);
                }
                throw new TimeoutException("PowerShell did not finish startup. " + greeting);
            }

            public void Dispose()
            {
                commands.CompleteAdding();
                if (job != IntPtr.Zero)
                {
                    try { WaitForJobDrain(job, 2000); } finally { CloseHandle(job); job = IntPtr.Zero; }
                }
                if (process != IntPtr.Zero) { CloseHandle(process); process = IntPtr.Zero; }
                if (inputPump != null) { try { inputPump.Wait(1500); } catch (AggregateException) { } }
                if (input != null) { input.Dispose(); input = null; }
                if (output != null) { output.Dispose(); output = null; }
            }
        }
    }
}
