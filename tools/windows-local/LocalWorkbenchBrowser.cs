using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Globalization;
using System.IO;
using System.IO.Pipes;
using System.Linq;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;

namespace CageLocalTool
{
    internal static partial class CageLocal
    {
        internal static string FindWorkbenchEdge()
        {
            foreach (var folder in new[] { Environment.SpecialFolder.ProgramFilesX86, Environment.SpecialFolder.ProgramFiles })
            {
                string root = Environment.GetFolderPath(folder);
                if (!Path.IsPathRooted(root)) continue;
                string exe = Path.Combine(root, @"Microsoft\Edge\Application\msedge.exe");
                if (File.Exists(exe)) return exe;
            }
            return null;
        }

        private static int RunWorkbenchBrowser(LocalProfileModel profile)
        {
            using (var network = new WorkbenchAppNetwork(profile))
            using (var session = new LocalWorkerSession(profile, "UTC", false, true))
            using (network.Attach(session))
            using (var output = new StreamWriter(Console.OpenStandardOutput(), Utf8NoBom) { AutoFlush = true })
            {
                var opened = session.Call("browser-open", null, 30000);
                var token = (Dictionary<string, object>)opened["token"];
                if (!SameWindowsName((string)token["userSid"], profile.workerSid) ||
                    (string)token["integrityRid"] != "0x2000" || !session.OwnsPid(Convert.ToInt32(opened["pid"])) ||
                    !SameWindowsName((string)opened["desktop"], session.DesktopName))
                    throw new InvalidOperationException("Edge 未通过隔离账户、私有桌面或进程归属检查。");
                output.WriteLine(ToJson(new { type = "ready", workerSid = profile.workerSid, instanceId = profile.instanceId,
                    workerUsername = profile.workerUsername }));
                var input = new StreamReader(Console.OpenStandardInput(), Utf8NoBom);
                string line;
                while ((line = input.ReadLine()) != null)
                {
                    if (line.Length > 32768) throw new InvalidDataException("浏览器输入过长。");
                    var action = FromJsonObject(line);
                    if ((string)action["type"] == "close") break;
                    var result = session.Call("browser-action", action, 15000);
                    output.WriteLine(ToJson(result));
                }
            }
            return 0;
        }

        private sealed class WorkerBrowser : IDisposable
        {
            private AnonymousPipeServerStream toEdge, fromEdge;
            private IntPtr process, job;
            private readonly byte[] received = new byte[16384];
            private int bufferStart, bufferEnd, sequence;
            private string target, session;
            private string displayedTarget, displayedLoader, displayedURL, viewToken;
            private readonly Stack<string> parents = new Stack<string>();
            private int width = 1000, height = 650;
            private const string BrowserHome = "<!doctype html><html lang='zh-CN'><meta charset='utf-8'><title>新标签页</title>" +
                "<style>body{margin:0;background:#f6f6f4;color:#252525;font:16px system-ui}main{max-width:590px;margin:19vh auto;padding:25px}" +
                "h1{font-size:32px}input,button{font:inherit;padding:12px;border:1px solid #aaa;border-radius:6px}input{width:65%}" +
                "button{background:#222;color:white}a{color:#444}</style><main><h1>新标签页</h1>" +
                "<form action='https://www.bing.com/search'><input aria-label='搜索网页' name='q' placeholder='搜索网页' required> <button>搜索</button></form>" +
                "<p><a href='https://claude.ai/'>Claude</a></p></main></html>";

            private static Dictionary<string, object> Fields(params object[] pairs)
            {
                var value = new Dictionary<string, object>();
                for (int i = 0; i < pairs.Length; i += 2) value.Add((string)pairs[i], pairs[i + 1]);
                return value;
            }

            internal Dictionary<string, object> Open(string profileDir, string appData, string localAppData,
                int brokerPort, string timezone, string desktop, bool signIn, bool tailnetSignIn = false)
            {
                if (process != IntPtr.Zero) throw new InvalidOperationException("浏览器已经打开。");
                string executable = FindWorkbenchEdge();
                if (executable == null) throw new FileNotFoundException("Windows 隔离浏览器需要系统安装的 Microsoft Edge。");
                string data = Path.Combine(localAppData, "Cage", signIn ? (tailnetSignIn ? "WorkbenchTailnetSignIn" : "WorkbenchSignIn") : "WorkbenchEdge");
                AssertNoReparsePointOnTreeUpToRoot(data, profileDir);
                Directory.CreateDirectory(data);
                AssertNoReparsePointOnTreeUpToRoot(data, profileDir);
                toEdge = new AnonymousPipeServerStream(PipeDirection.Out, HandleInheritability.Inheritable);
                fromEdge = new AnonymousPipeServerStream(PipeDirection.In, HandleInheritability.Inheritable);
                IntPtr read = toEdge.ClientSafePipeHandle.DangerousGetHandle();
                IntPtr write = fromEdge.ClientSafePipeHandle.DangerousGetHandle();
                // Chromium's Windows pipe switch names the two explicitly inherited handles.
                var args = new[] { "--headless=new", "--remote-debugging-pipe",
                    "--remote-debugging-io-pipes=" + read.ToInt64().ToString(CultureInfo.InvariantCulture) +
                        "," + write.ToInt64().ToString(CultureInfo.InvariantCulture),
                    "--no-first-run", "--no-default-browser-check", "--disable-background-mode", "--disable-sync",
                    "--disable-gpu", "--disable-quic", "--disable-extensions", "--disable-background-networking",
                    "--disable-renderer-backgrounding", "--disable-backgrounding-occluded-windows",
                    "--proxy-server=http://127.0.0.1:" + brokerPort, "--proxy-bypass-list=<-loopback>",
                    "--user-data-dir=" + data, "about:blank" };
                if (signIn) args = new[] { "--inprivate" }.Concat(args).ToArray();
                var env = BuildWorkerEnv(profileDir, appData, localAppData, Path.Combine(localAppData, "Temp"), brokerPort, timezone, null, null);
                IntPtr variables = AllocUnicodeEnvBlock(env), attr = IntPtr.Zero, list = IntPtr.Zero, size = IntPtr.Zero;
                bool initialized = false;
                var pi = new ProcessInformation();
                try
                {
                    InitializeProcThreadAttributeList(IntPtr.Zero, 1, 0, ref size);
                    attr = Marshal.AllocHGlobal(size);
                    CheckWin32(InitializeProcThreadAttributeList(attr, 1, 0, ref size), "Initialize Edge handle list");
                    initialized = true;
                    list = Marshal.AllocHGlobal(2 * IntPtr.Size);
                    Marshal.WriteIntPtr(list, read);
                    Marshal.WriteIntPtr(list, IntPtr.Size, write);
                    CheckWin32(UpdateProcThreadAttribute(attr, 0, (IntPtr)0x20002, list, (IntPtr)(2 * IntPtr.Size),
                        IntPtr.Zero, IntPtr.Zero), "Restrict inherited Edge handles");
                    var startup = new StartupInfoExW();
                    startup.StartupInfo.cb = Marshal.SizeOf(typeof(StartupInfoExW));
                    startup.StartupInfo.lpDesktop = "Winsta0\\" + desktop;
                    startup.lpAttributeList = attr;
                    job = CreateKillOnCloseJob();
                    CheckWin32(CreateProcessEx(executable, new StringBuilder(BuildCommandLine(executable, args)), IntPtr.Zero,
                        IntPtr.Zero, true, ExtendedStartupInfoPresent | CreateUnicodeEnvironment | CreateNoWindow | CreateSuspended,
                        variables, data, ref startup, out pi), "Start isolated Edge");
                    process = pi.hProcess;
                    CheckWin32(AssignProcessToJobObject(job, process), "Attach Edge to tab's job");
                    CheckWin32(ResumeThread(pi.hThread) != uint.MaxValue, "Start isolated Edge thread");
                    toEdge.DisposeLocalCopyOfClientHandle();
                    fromEdge.DisposeLocalCopyOfClientHandle();
                    var token = InspectToken(process);
                    var blank = ((object[])Send("Target.getTargets", null, false)["targetInfos"])
                        .Cast<Dictionary<string, object>>().FirstOrDefault(info => Object.Equals(info["type"], "page") &&
                            Object.Equals(info["url"], "about:blank") && !info.ContainsKey("openerId"));
                    if (blank == null) blank = Send("Target.createTarget", Fields("url", "about:blank"), false);
                    target = (string)blank["targetId"];
                    Send("Target.activateTarget", Fields("targetId", target), false);
                    Attach(target);
                    Send("Browser.setDownloadBehavior", Fields("behavior", "deny"), false);
                    ShowHome();
                    return Fields("pid", pi.dwProcessId, "token", token, "desktop", desktop);
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
                    if (initialized) DeleteProcThreadAttributeList(attr);
                    if (attr != IntPtr.Zero) Marshal.FreeHGlobal(attr);
                    if (list != IntPtr.Zero) Marshal.FreeHGlobal(list);
                    Marshal.FreeHGlobal(variables);
                }
            }

            private void Attach(string id)
            {
                target = id;
                session = (string)Send("Target.attachToTarget", Fields("targetId", target, "flatten", true), false)["sessionId"];
                Send("Network.enable", Fields("maxTotalBufferSize", 65536, "maxResourceBufferSize", 8192, "maxPostDataSize", 0));
                Send("Network.setBlockedURLs", Fields("urls", new[] { "file:*", "filesystem:file:*", "ftp:*", "view-source:*",
                    "edge:*", "chrome:*", "devtools:*", "edge-extension:*", "chrome-extension:*" }));
                Send("Page.setInterceptFileChooserDialog", Fields("enabled", true, "cancel", true));
                Send("Page.bringToFront", null);
                Resize();
            }

            // Login providers can open a child window and close it after consent.
            // Only follow pages opened by this tab or its descendants.
            private Dictionary<string, object> ActivePage()
            {
                var targets = ((object[])Send("Target.getTargets", null, false)["targetInfos"])
                    .Cast<Dictionary<string, object>>().Where(info => (string)info["type"] == "page")
                    .ToDictionary(info => (string)info["targetId"]);
                if (!targets.ContainsKey(target))
                {
                    while (parents.Count != 0)
                    {
                        string parent = parents.Pop();
                        if (targets.ContainsKey(parent)) { Attach(parent); break; }
                    }
                }
                if (!targets.ContainsKey(target)) throw new IOException("隔离网页已关闭。");
                var child = targets.Values.FirstOrDefault(info => info.ContainsKey("openerId") &&
                    (string)info["openerId"] == target && AllowedPageURL((string)info["url"]));
                if (child != null)
                {
                    parents.Push(target);
                    Send("Target.detachFromTarget", Fields("sessionId", session), false);
                    Attach((string)child["targetId"]);
                }
                var current = targets[target];
                if (!AllowedPageURL((string)current["url"]))
                {
                    // Only the network error document and our own new tab are
                    // rendered alongside public web pages. Other internal URL
                    // schemes cannot become a host-file or browser-settings viewer.
                    if ((string)current["url"] == "chrome-error://chromewebdata/")
                        current["url"] = "";
                    else
                    {
                        Send("Page.navigate", Fields("url", "about:blank"));
                        ShowHome();
                        current["title"] = "新标签页";
                        current["url"] = "about:blank";
                    }
                }
                return current;
            }

            private static bool AllowedPageURL(string text)
            {
                Uri dest;
                return text == "about:blank" || Uri.TryCreate(text, UriKind.Absolute, out dest) &&
                    (dest.Scheme == "https" || dest.Scheme == "http") && !dest.IsUnc && !dest.IsLoopback &&
                    !dest.DnsSafeHost.TrimEnd('.').EndsWith(".localhost", StringComparison.OrdinalIgnoreCase) && dest.UserInfo.Length == 0;
            }

            private Dictionary<string, object> Document()
            {
                var tree = (Dictionary<string, object>)Send("Page.getFrameTree", null)["frameTree"];
                return (Dictionary<string, object>)tree["frame"];
            }

            private static bool CanDisplay(Dictionary<string, object> document)
            {
                string url = (string)document["url"];
                return AllowedPageURL(url) || url == "chrome-error://chromewebdata/";
            }

            private bool MatchesView(Dictionary<string, object> request)
            {
                object supplied;
                if (!request.TryGetValue("view", out supplied) || viewToken == null || !Equals(supplied, viewToken) ||
                    target != displayedTarget) return false;
                var document = Document();
                return CanDisplay(document) && Equals(document["loaderId"], displayedLoader) && Equals(document["url"], displayedURL);
            }

            private void Resize()
            {
                Send("Emulation.setDeviceMetricsOverride", Fields("width", width, "height", height, "mobile", false, "deviceScaleFactor", 1));
            }

            private void ShowHome()
            {
                var frame = Document();
                Send("Page.setDocumentContent", Fields("frameId", frame["id"], "html", BrowserHome));
            }

            private Dictionary<string, object> Send(string method, Dictionary<string, object> fields, bool page = true)
            {
                int id = ++sequence;
                var command = Fields("id", id, "method", method, "params", fields ?? Fields());
                if (page) command["sessionId"] = session;
                byte[] data = Utf8NoBom.GetBytes(ToJson(command) + "\0");
                toEdge.Write(data, 0, data.Length);
                var deadline = Stopwatch.StartNew();
                using (var message = new MemoryStream())
                {
                    while (deadline.ElapsedMilliseconds < 10000)
                    {
                        if (bufferStart == bufferEnd)
                        {
                            uint waiting;
                            if (!PeekNamedPipe(fromEdge.SafePipeHandle, IntPtr.Zero, 0, IntPtr.Zero, out waiting, IntPtr.Zero) ||
                                WaitForSingleObject(process, 0) == 0) throw new IOException("隔离 Edge 已退出。");
                            if (waiting == 0) { Thread.Sleep(8); continue; }
                            bufferStart = 0;
                            bufferEnd = fromEdge.Read(received, 0, (int)Math.Min(received.Length, waiting));
                            if (bufferEnd <= 0) throw new EndOfStreamException("Edge 管道已关闭。");
                        }
                        int end = Array.IndexOf(received, (byte)0, bufferStart, bufferEnd - bufferStart);
                        int next = end < 0 ? bufferEnd : end;
                        if (message.Length + next - bufferStart > 4 * 1024 * 1024)
                            throw new InvalidDataException("Edge 响应超过大小限制。");
                        message.Write(received, bufferStart, next - bufferStart);
                        bufferStart = end < 0 ? bufferEnd : end + 1;
                        if (end < 0) continue;
                        var packet = FromJsonObject(Utf8NoBom.GetString(message.GetBuffer(), 0, (int)message.Length));
                        message.SetLength(0);
                        if (!packet.ContainsKey("id") || Convert.ToInt32(packet["id"]) != id) continue;
                        if (packet.ContainsKey("error")) throw new IOException("Edge 未能完成 " + method);
                        return (Dictionary<string, object>)packet["result"];
                    }
                }
                throw new TimeoutException("隔离 Edge 操作超时：" + method);
            }

            private static int Number(Dictionary<string, object> request, string key, int min, int max)
            {
                int value = Convert.ToInt32(request[key], CultureInfo.InvariantCulture);
                if (value < min || value > max) throw new InvalidDataException("无效的浏览器输入坐标或键码。");
                return value;
            }

            private static string Text(Dictionary<string, object> request, string key, int limit)
            {
                string text = request[key] as string;
                if (text == null || text.Length > limit || text.Contains("\0")) throw new InvalidDataException("无效的浏览器输入。");
                return text;
            }

            internal Dictionary<string, object> Action(Dictionary<string, object> request)
            {
                string action = Text(request, "type", 30);
                if ((action == "click" || action == "wheel" || action == "text" || action == "key") && !MatchesView(request))
                    return Fields("type", "notice", "message", "网页正在切换，请在新画面出现后重试。");
                switch (action)
                {
                    case "frame":
                        var info = ActivePage();
                        var before = Document();
                        if (!CanDisplay(before)) return Fields("type", "refreshing");
                        var shot = Send("Page.captureScreenshot", Fields("format", "jpeg", "quality", 74, "captureBeyondViewport", false));
                        var after = Document();
                        if (!CanDisplay(after) || !Equals(before["loaderId"], after["loaderId"]) || !Equals(before["url"], after["url"]))
                            return Fields("type", "refreshing");
                        if (target != displayedTarget || !Equals(after["loaderId"], displayedLoader) || !Equals(after["url"], displayedURL))
                        {
                            displayedTarget = target;
                            displayedLoader = (string)after["loaderId"];
                            displayedURL = (string)after["url"];
                            viewToken = Guid.NewGuid().ToString("N");
                        }
                        return Fields("type", "frame", "image", shot["data"], "view", viewToken,
                            "url", displayedURL == "chrome-error://chromewebdata/" ? info["url"] : displayedURL, "title", info["title"],
                            "width", width, "height", height, "popup", parents.Count != 0);
                    case "close-popup":
                        if (parents.Count != 0) Send("Target.closeTarget", Fields("targetId", target), false);
                        break;
                    case "resize":
                        width = Number(request, "width", 320, 1600);
                        height = Number(request, "height", 180, 1000);
                        Resize();
                        break;
                    case "navigate":
                        string raw = Text(request, "url", 8192);
                        Uri dest;
                        if (!Uri.TryCreate(raw, UriKind.Absolute, out dest) || raw == "about:blank" || !AllowedPageURL(raw) ||
                            raw.Any(Char.IsControl) || raw.Contains("\\"))
                            return Fields("type", "notice", "message", "请输入公网 HTTP 或 HTTPS 网页地址。");
                        var navigate = Send("Page.navigate", Fields("url", dest.AbsoluteUri));
                        if (navigate.ContainsKey("errorText")) return Fields("type", "notice", "message", "网页连接失败：" + Convert.ToString(navigate["errorText"]));
                        break;
                    case "refresh":
                        var location = (Dictionary<string, object>)Send("Target.getTargetInfo", Fields("targetId", target), false)["targetInfo"];
                        if (parents.Count == 0 && (string)location["url"] == "about:blank") ShowHome();
                        else Send("Page.reload", null);
                        break;
                    case "back":
                    case "forward":
                        var history = Send("Page.getNavigationHistory", null);
                        var entries = (object[])history["entries"];
                        int index = Convert.ToInt32(history["currentIndex"]) + (action == "back" ? -1 : 1);
                        if (index >= 0 && index < entries.Length)
                            Send("Page.navigateToHistoryEntry", Fields("entryId", ((Dictionary<string, object>)entries[index])["id"]));
                        break;
                    case "click":
                    case "wheel":
                        int x = Number(request, "x", 0, width - 1), y = Number(request, "y", 0, height - 1);
                        if (action == "click")
                        {
                            Send("Input.dispatchMouseEvent", Fields("type", "mousePressed", "button", "left", "buttons", 1, "x", x, "y", y, "clickCount", 1));
                            Send("Input.dispatchMouseEvent", Fields("type", "mouseReleased", "button", "left", "buttons", 0, "x", x, "y", y, "clickCount", 1));
                        }
                        else Send("Input.dispatchMouseEvent", Fields("type", "mouseWheel", "x", x, "y", y,
                            "deltaX", Number(request, "dx", -2048, 2048), "deltaY", Number(request, "dy", -2048, 2048)));
                        break;
                    case "text":
                        Send("Input.insertText", Fields("text", Text(request, "text", 16384)));
                        break;
                    case "key":
                        string key = Text(request, "key", 32), code = Text(request, "code", 32);
                        int vk = Number(request, "vk", 0, 255), mods = Number(request, "modifiers", 0, 15);
                        var keys = Fields("type", key == "Enter" ? "keyDown" : "rawKeyDown", "key", key, "code", code,
                            "windowsVirtualKeyCode", vk, "modifiers", mods);
                        if (key == "Enter") keys["text"] = "\r";
                        Send("Input.dispatchKeyEvent", keys);
                        keys["type"] = "keyUp";
                        keys.Remove("text");
                        Send("Input.dispatchKeyEvent", keys);
                        break;
                    default:
                        throw new InvalidDataException("未知的浏览器操作。");
                }
                return Fields("type", "ack");
            }

            public void Dispose()
            {
                if (process != IntPtr.Zero)
                {
                    try {
                        // Closing the debugging pipe also tells Edge to quit. Allow the profile
                        // to flush before reclaiming this tab's job tree.
                        if (toEdge != null) {
                            byte[] close = Utf8NoBom.GetBytes("{\"id\":0,\"method\":\"Browser.close\"}\0");
                            toEdge.Write(close, 0, close.Length);
                        }
                        WaitForSingleObject(process, 1800);
                    } catch (IOException) { }
                    CloseHandle(process);
                    process = IntPtr.Zero;
                }
                if (job != IntPtr.Zero)
                {
                    try { WaitForJobDrain(job, 2000); }
                    finally { CloseHandle(job); job = IntPtr.Zero; }
                }
                if (toEdge != null) toEdge.Dispose();
                if (fromEdge != null) fromEdge.Dispose();
                toEdge = fromEdge = null;
                parents.Clear();
                bufferStart = bufferEnd = 0;
                target = session = displayedTarget = viewToken = displayedLoader = displayedURL = null;
            }
        }
    }
}
