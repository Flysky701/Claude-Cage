using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.Drawing.Imaging;
using System.IO;
using System.Runtime.InteropServices;
using System.Security.Principal;
using System.Text;
using Microsoft.Win32;

namespace CageLocalTool
{
    internal static partial class CageLocal
    {
        private static string WorkbenchAppPath(LocalProfileModel profile, string kind)
        {
            bool editor = kind == "editor";
            if (!editor && kind != "desktop") throw new ArgumentException("Unknown application.");
            string name = editor ? "Code.exe" : "Claude.exe";
            var choices = new List<string>();
            string releases = Path.Combine(profile.toolsDir, "claude-desktop-versions");
            if (!editor && Directory.Exists(releases))
            {
                var versions = new SortedList<Version, string>();
                foreach (string dir in Directory.GetDirectories(releases))
                {
                    Version version;
                    if (Version.TryParse(Path.GetFileName(dir), out version)) versions[version] = Path.Combine(dir, name);
                }
                for (int i = versions.Count - 1; i >= 0; i--) choices.Add(versions.Values[i]);
            }
            choices.Add(Path.Combine(profile.toolsDir, editor ? "vscode" : "claude-desktop", name));
            choices.Add(Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles),
                editor ? "Microsoft VS Code" : "Claude", name));
            foreach (RegistryKey hive in new[] { Registry.LocalMachine, Registry.CurrentUser })
                using (RegistryKey key = hive.OpenSubKey(@"SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\" + name))
                    if (key != null && key.GetValue("") is string) choices.Add(((string)key.GetValue("")).Trim('"'));
            foreach (string entry in choices)
            {
                if (!Path.IsPathRooted(entry) || !string.Equals(Path.GetFileName(entry), name, StringComparison.OrdinalIgnoreCase)) continue;
                string path = Path.GetFullPath(entry);
                string root = Path.GetPathRoot(path);
                if (root.Length != 3 || !File.Exists(path)) continue;
                if ((File.GetAttributes(path) & FileAttributes.ReparsePoint) != 0) continue;
                AssertNoReparsePointOnTreeUpToRoot(path, root);
                return path;
            }
            return null;
        }

        private static bool InstalledWorkbenchApp(LocalProfileModel profile, string kind)
        {
            return WorkbenchAppPath(profile, kind) != null;
        }

        private static int RunWorkbenchApp(LocalProfileModel profile, string kind)
        {
            string exe = WorkbenchAppPath(profile, kind);
            if (exe == null) throw new FileNotFoundException(kind == "editor" ? "VS Code is not installed for Cage." : "Claude Desktop is not installed for Cage.");
            string project = kind == "editor" ? SelectedEditorProject(profile) : null;
            using (var network = new WorkbenchAppNetwork(profile))
            using (var session = new LocalWorkerSession(profile, "UTC", false, true))
            using (network.Attach(session))
            using (var output = new StreamWriter(Console.OpenStandardOutput(), Utf8NoBom) { AutoFlush = true })
            {
                var opened = session.Call("app-open", new Dictionary<string, object> { { "app", kind }, { "exe", exe }, { "project", project } }, 20000);
                if (!session.OwnsPid(Convert.ToInt32(opened["pid"])) ||
                    !SameWindowsName((string)opened["userSid"], profile.workerSid) ||
                    !SameWindowsName((string)opened["desktop"], session.DesktopName) || (string)opened["integrity"] != "Low")
                    throw new InvalidOperationException("Application identity verification failed.");
                output.WriteLine(ToJson(new Dictionary<string, object> { { "type", "ready" }, { "instanceId", profile.instanceId },
                    { "workerSid", profile.workerSid }, { "workerUsername", profile.workerUsername } }));
                using (var input = new StreamReader(Console.OpenStandardInput(), Utf8NoBom))
                {
                    string line;
                    while ((line = input.ReadLine()) != null)
                    {
                        var message = FromJsonObject(line);
                        string type = Convert.ToString(message["type"]);
                        if (type == "close") break;
                        if (type == "frame")
                        {
                            var frame = session.Call("app-frame", null, 5000);
                            output.WriteLine(ToJson(frame));
                            if ((string)frame["type"] == "exit") break;
                        }
                        else if (type == "click" || type == "key" || type == "text" || type == "wheel")
                            session.Call("app-input", message, 3000);
                        else throw new InvalidDataException("Unknown application input.");
                    }
                }
            }
            return 0;
        }

        [StructLayout(LayoutKind.Sequential)]
        private struct AppPoint { public int X, Y; }

        [DllImport("user32.dll")] private static extern bool GetClientRect(IntPtr window, out RectStruct rect);
        [DllImport("user32.dll")] private static extern bool PrintWindow(IntPtr window, IntPtr dc, uint flags);
        [DllImport("user32.dll")] private static extern IntPtr ChildWindowFromPointEx(IntPtr parent, AppPoint point, uint flags);
        [DllImport("user32.dll")] private static extern int MapWindowPoints(IntPtr from, IntPtr to, ref AppPoint point, uint count);
        [DllImport("user32.dll", EntryPoint = "PostMessageW", SetLastError = true)]
        private static extern bool PostAppMessage(IntPtr window, uint msg, IntPtr wp, IntPtr lp);
        [DllImport("user32.dll")] private static extern bool IsChild(IntPtr parent, IntPtr window);
        [DllImport("user32.dll")] private static extern bool SetProcessDPIAware();
        [DllImport("advapi32.dll", EntryPoint = "CreateProcessAsUserW", CharSet = CharSet.Unicode, SetLastError = true)]
        private static extern bool CreateWorkbenchApp(IntPtr token, string app, StringBuilder args, IntPtr pa, IntPtr ta,
            bool inherit, uint flags, IntPtr env, string cwd, ref StartupInfoW si, out ProcessInformation pi);

        // Only handles belonging to this app's job on this worker's private
        // desktop can reach PrintWindow or PostMessage. Clients never supply HWNDs.
        private sealed class WorkerApp : IDisposable
        {
            private IntPtr job, process, display, lastClicked;
            private bool sawWindow;
            private readonly Stopwatch startup = new Stopwatch();
            private readonly Dictionary<string, int> keys = new Dictionary<string, int> {
                { "Enter", 13 }, { "Backspace", 8 }, { "Tab", 9 }, { "Escape", 27 }, { "Delete", 46 },
                { "ArrowLeft", 37 }, { "ArrowUp", 38 }, { "ArrowRight", 39 }, { "ArrowDown", 40 },
                { "Home", 36 }, { "End", 35 }, { "PageUp", 33 }, { "PageDown", 34 },
            };

            internal Dictionary<string, object> Open(Dictionary<string, object> req, string profileDir, string appData,
                string localAppData, string temp, int brokerPort, string timezone, string desktop, string sid)
            {
                string kind = (string)req["app"], exe = Path.GetFullPath((string)req["exe"]);
                if (job != IntPtr.Zero || !desktop.StartsWith("CageLocal_", StringComparison.Ordinal) ||
                    (kind != "editor" && kind != "desktop") || !SameWindowsName(Path.GetFileName(exe), kind == "editor" ? "Code.exe" : "Claude.exe"))
                    throw new InvalidDataException("Invalid isolated application.");
                if (!File.Exists(exe)) throw new IOException("The installed application is inaccessible to the isolated account.");
                string work = PrepareTerminalDirectory(profileDir);
                string data = PrepareTerminalDirectory(profileDir, true);
                // Electron creates each app's preferences and caches from its own low token.
                var args = new List<string> { "--user-data-dir=" + Path.Combine(data, kind), "--disable-gpu",
                    "--disable-renderer-backgrounding", "--disable-features=CalculateNativeWinOcclusion",
                    "--proxy-server=http://127.0.0.1:" + brokerPort, "--proxy-bypass-list=<-loopback>" };
                string editorFolder = kind == "editor" ? (string)req["project"] ?? work : null;
                if (editorFolder != null) args.AddRange(new[] { "--new-window", "--disable-extensions", "--skip-welcome",
                    "--skip-release-notes", "--extensions-dir=" + Path.Combine(data, "CodeExtensions"),
                    "--folder-uri", new Uri(Path.GetFullPath(editorFolder)).AbsoluteUri });
                IntPtr source = IntPtr.Zero, low = IntPtr.Zero, env = IntPtr.Zero;
                ProcessInformation pi = new ProcessInformation();
                try
                {
                    SetProcessDPIAware();
                    display = GetThreadDesktop(GetCurrentThreadId());
                    if (!SameWindowsName(GetDesktopName(display), desktop)) throw new InvalidOperationException("Incorrect app desktop.");
                    job = CreateKillOnCloseJob();
                    CheckWin32(OpenProcessToken(Process.GetCurrentProcess().Handle, 0x008b, out source), "Open application source token");
                    CheckWin32(CreateRestrictedToken(source, 1, 0, IntPtr.Zero, 0, IntPtr.Zero, 0, IntPtr.Zero, out low), "Restrict application token");
                    SetTerminalTokenLow(low);
                    if (editorFolder != null)
                    {
                        using (WindowsIdentity.Impersonate(low))
                        {
                            // Report a missing grant before VS Code can fall back to an empty window.
                            using (var entries = Directory.EnumerateFileSystemEntries(editorFolder).GetEnumerator())
                                entries.MoveNext();
                        }
                    }
                    if (kind == "desktop")
                    {
                        // Electron resolves known folders beneath the redirected USERPROFILE.
                        // Create them with the same restricted token that will use them.
                        using (WindowsIdentity.Impersonate(low))
                        {
                            foreach (string name in new[] { "Roaming", "Local" })
                            {
                                string folder = Path.Combine(data, "AppData", name);
                                AssertNoReparsePointOnTreeUpToRoot(folder, profileDir);
                                Directory.CreateDirectory(folder);
                            }
                        }
                    }
                    // VS Code also keeps argv.json under USERPROFILE/.vscode.
                    // Give GUI apps a low-integrity home for their own settings.
                    env = AllocUnicodeEnvBlock(BuildWorkerEnv(data, data, data, data, brokerPort, timezone, null, null));
                    StartupInfoW si = new StartupInfoW { cb = Marshal.SizeOf(typeof(StartupInfoW)), lpDesktop = "Winsta0\\" + desktop,
                        dwFlags = (int)StartfUseShowWindow, wShowWindow = 1 };
                    CheckWin32(CreateWorkbenchApp(low, exe, new StringBuilder(BuildCommandLine(exe, args.ToArray())),
                        IntPtr.Zero, IntPtr.Zero, false, CreateSuspended | CreateUnicodeEnvironment, env, work, ref si, out pi), "Start isolated application");
                    process = pi.hProcess;
                    CheckWin32(AssignProcessToJobObject(job, process), "Attach application to its job");
                    var token = VerifyTerminalToken(process, sid);
                    CheckWin32(ResumeThread(pi.hThread) != uint.MaxValue, "Start application thread");
                    startup.Start();
                    return new Dictionary<string, object> { { "pid", pi.dwProcessId }, { "userSid", token["userSid"] },
                        { "integrity", token["integrityLabel"] }, { "desktop", desktop } };
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
                    if (source != IntPtr.Zero) CloseHandle(source);
                    if (low != IntPtr.Zero) CloseHandle(low);
                    if (env != IntPtr.Zero) Marshal.FreeHGlobal(env);
                }
            }

            private bool Owned(IntPtr window, HashSet<int> pids)
            {
                uint pid;
                // Top-level handles come exclusively from EnumDesktopWindows(display).
                // Descendants come from that top-level window's child hierarchy.
                return GetWindowThreadProcessId(window, out pid) != 0 && pids.Contains((int)pid);
            }

            private static bool HasAppContent(Bitmap bitmap)
            {
                int left = bitmap.Width / 12, top = bitmap.Height * 15 / 100;
                Color first = bitmap.GetPixel(left, top);
                int varied = 0;
                for (int y = top; y < bitmap.Height * 95 / 100; y += Math.Max(1, bitmap.Height / 65))
                    for (int x = left; x < bitmap.Width - left; x += Math.Max(1, bitmap.Width / 65))
                    {
                        Color p = bitmap.GetPixel(x, y);
                        if ((Math.Abs(p.R-first.R) > 8 || Math.Abs(p.G-first.G) > 8 || Math.Abs(p.B-first.B) > 8) && ++varied >= 8)
                            return true;
                    }
                return false;
            }

            private IntPtr Window(HashSet<int> pids)
            {
                IntPtr found = IntPtr.Zero;
                EnumDesktopWindows(display, delegate(IntPtr window, IntPtr arg) {
                    RectStruct rc;
                    if (!Owned(window, pids) || !IsWindowVisible(window) || !GetClientRect(window, out rc) ||
                        rc.Right < 100 || rc.Bottom < 80) return true;
                    found = window;
                    return false;
                }, IntPtr.Zero);
                return found;
            }

            internal Dictionary<string, object> Frame()
            {
                var pids = new HashSet<int>(QueryJobPids(job));
                IntPtr window = Window(pids);
                if (window == IntPtr.Zero)
                {
                    if (!sawWindow && (pids.Count == 0 || startup.Elapsed.TotalSeconds > 40))
                        throw new IOException("The application did not open a window in this isolated profile.");
                    return new Dictionary<string, object> { { "type", pids.Count == 0 ? "exit" : "waiting" } };
                }
                RectStruct size;
                if (!GetClientRect(window, out size) || size.Right > 7680 || size.Bottom > 4320)
                    throw new IOException("Unsupported application window size.");
                int width = Math.Min(2560, size.Right), height = Math.Min(1600, size.Bottom);
                using (var bitmap = new Bitmap(width, height, PixelFormat.Format24bppRgb))
                using (var graphics = Graphics.FromImage(bitmap))
                using (var encoded = new MemoryStream())
                {
                    IntPtr dc = graphics.GetHdc();
                    try { CheckWin32(PrintWindow(window, dc, 3 /* client area and full content */), "Read application window"); }
                    finally { graphics.ReleaseHdc(dc); }
                    if (!sawWindow && !HasAppContent(bitmap))
                    {
                        if (startup.Elapsed.TotalSeconds > 40) throw new IOException("The application opened but has not rendered a readable window.");
                        return new Dictionary<string, object> { { "type", "waiting" } };
                    }
                    bitmap.Save(encoded, ImageFormat.Jpeg);
                    if (encoded.Length > 2 * 1024 * 1024) throw new IOException("Application frame is too large.");
                    sawWindow = true;
                    return new Dictionary<string, object> { { "type", "frame" }, { "width", width }, { "height", height },
                        { "image", Convert.ToBase64String(encoded.GetBuffer(), 0, (int)encoded.Length) } };
                }
            }

            internal Dictionary<string, object> Input(Dictionary<string, object> req)
            {
                var pids = new HashSet<int>(QueryJobPids(job));
                IntPtr top = Window(pids);
                if (top == IntPtr.Zero) throw new IOException("Application window closed.");
                string type = (string)req["type"];
                if (type == "click" || type == "wheel")
                {
                    RectStruct rc;
                    AppPoint point = new AppPoint { X = Convert.ToInt32(req["x"]), Y = Convert.ToInt32(req["y"]) };
                    if (!GetClientRect(top, out rc) || point.X < 0 || point.Y < 0 || point.X >= rc.Right || point.Y >= rc.Bottom)
                        throw new InvalidDataException("Invalid app coordinates.");
                    IntPtr target = top;
                    for (int i = 0; i < 8; i++)
                    {
                        IntPtr next = ChildWindowFromPointEx(target, point, 7);
                        if (next == IntPtr.Zero || next == target || !Owned(next, pids)) break;
                        MapWindowPoints(target, next, ref point, 1);
                        target = next;
                    }
                    if (type == "wheel")
                    {
                        MapWindowPoints(target, IntPtr.Zero, ref point, 1);
                        int delta = Math.Sign(Convert.ToInt32(req["delta"])) * 120;
                        Send(target, 0x020A, delta << 16, Position(point));
                    }
                    else
                    {
                        Send(target, 0x0200, 0, Position(point));
                        Send(target, 0x0201, 1, Position(point));
                        Send(target, 0x0202, 0, Position(point));
                        lastClicked = target;
                    }
                }
                else
                {
                    IntPtr target = lastClicked != IntPtr.Zero && IsChild(top, lastClicked) && Owned(lastClicked, pids) ? lastClicked : top;
                    if (type == "key")
                    {
                        int key;
                        if (!keys.TryGetValue((string)req["key"], out key)) throw new InvalidDataException("Unknown application key.");
                        Send(target, 0x100, key, 1);
                        Send(target, 0x101, key, unchecked((int)0xc0000001));
                    }
                    else if (type == "text")
                    {
                        string text = (string)req["text"];
                        if (text == null || text.Length > 1024 || text.IndexOf('\0') >= 0) throw new InvalidDataException("Invalid application text.");
                        foreach (char c in text) Send(target, 0x102, c, 1);
                    }
                    else throw new InvalidDataException("Unknown application input.");
                }
                return new Dictionary<string, object>();
            }

            private static int Position(AppPoint point) { return (point.X & 65535) | (point.Y << 16); }
            private static void Send(IntPtr window, uint message, int w, int l)
            {
                CheckWin32(PostAppMessage(window, message, (IntPtr)w, (IntPtr)l), "Send input to application");
            }
            public void Dispose()
            {
                if (job != IntPtr.Zero)
                {
                    try { WaitForJobDrain(job, 2000); }
                    finally { CloseHandle(job); job = IntPtr.Zero; }
                }
                if (process != IntPtr.Zero) { CloseHandle(process); process = IntPtr.Zero; }
            }
        }
    }
}
