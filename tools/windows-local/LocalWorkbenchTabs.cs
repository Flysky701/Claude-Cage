using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Text.RegularExpressions;
using System.Threading.Tasks;

namespace CageLocalTool
{
    internal static partial class CageLocal
    {
        // Each channel owns its input pipe, capture target and any embedded sign-in
        // browser. Only the authenticated controller can create a channel in the daemon.
        private sealed class WorkerTab : IDisposable
        {
            internal readonly WorkerTerminal Terminal = new WorkerTerminal();
            internal readonly WorkerBrowser Browser = new WorkerBrowser();
            internal readonly WorkerApp App = new WorkerApp();
            internal readonly WorkerServices Services = new WorkerServices();

            public void Dispose()
            {
                using (Terminal)
                using (App)
                using (Browser)
                using (Services) { }
            }
        }

        private sealed class WorkerTabCollection : IDisposable
        {
            // The empty channel is reserved for the older single-app commands.
            private readonly Dictionary<string, WorkerTab> tabs = new Dictionary<string, WorkerTab> { { "", new WorkerTab() } };

            internal WorkerTab Get(string id, string op)
            {
                if (op == "tab-create")
                {
                    if (!ValidTabId(id) || tabs.Count > 32) throw new InvalidDataException("Invalid tab or too many open tabs.");
                    if (tabs.ContainsKey(id)) throw new InvalidOperationException("Tab is already open.");
                    tabs.Add(id, new WorkerTab());
                }
                return tabs[id];
            }

            internal void Close(string id)
            {
                if (!ValidTabId(id)) throw new InvalidDataException("Invalid tab.");
                WorkerTab tab = tabs[id];
                tabs.Remove(id);
                tab.Dispose();
            }

            public void Dispose()
            {
                foreach (var tab in tabs.Values) tab.Dispose();
            }
        }

        private static bool ValidTabId(string id)
        {
            return id != null && Regex.IsMatch(id, @"\A[0-9a-f]{32}\z");
        }

        private sealed class WorkbenchPipeFailure : IOException
        {
            internal WorkbenchPipeFailure(Exception cause) : base("连接隔离工作台时通信中断。", cause) { }
        }

        private sealed class WorkbenchTab
        {
            private readonly LocalWorkerSession session;
            private readonly LocalProfileModel profile;
            internal readonly string Id, App;
            private bool signInOpen, registered;

            internal WorkbenchTab(LocalWorkerSession session, LocalProfileModel profile, string id, string app)
            {
                this.session = session;
                this.profile = profile;
                Id = id;
                App = app;
            }

            private Dictionary<string, object> Call(string op, Dictionary<string, object> payload, int timeout)
            {
                var request = payload == null ? new Dictionary<string, object>() : new Dictionary<string, object>(payload);
                request["channel"] = Id;
                try { return session.Call(op, request, timeout); }
                catch (IOException ex) { throw new WorkbenchPipeFailure(ex); }
                catch (TimeoutException ex) { throw new WorkbenchPipeFailure(ex); }
            }

            private Dictionary<string, object> VerifyProcess(Dictionary<string, object> opened, string integrity)
            {
                var token = (Dictionary<string, object>)opened["token"];
                if (!SameWindowsName((string)token["userSid"], profile.workerSid) || (string)token["integrityRid"] != integrity ||
                    !SameWindowsName((string)opened["desktop"], session.DesktopName) || !session.OwnsPid(Convert.ToInt32(opened["pid"])))
                    throw new InvalidDataException("无法核实此标签页的隔离账户、桌面或进程归属。");
                return token;
            }

            internal Dictionary<string, object> Open(string project, Dictionary<string, object> envelope)
            {
                if (project != null && App != "editor" && App != "terminal" && App != "pty") throw new InvalidDataException("此应用不支持指定项目。");
                string folder = project == null ? null : SelectedWorkbenchVolume(profile, project,
                    envelope.ContainsKey("mount") ? (string)envelope["mount"] : null);
                Call("tab-create", null, 5000);
                registered = true;
                var ready = new Dictionary<string, object> { { "type", "ready" }, { "instanceId", profile.instanceId },
                    { "workerSid", session.HandshakeInfo["userSid"] }, { "workerUsername", profile.workerUsername } };
                switch (App)
                {
                    case "terminal":
                    case "pty":
                        var launch = new Dictionary<string, object> { { "project", folder } };
                        if (App == "pty")
                        {
                            foreach (string key in new[] { "kind", "cliID", "resume", "account" })
                                if (envelope.ContainsKey(key)) launch[key] = envelope[key];
                            if (!launch.ContainsKey("kind")) throw new InvalidDataException("缺少终端类型。");
                            if (envelope.ContainsKey("additional")) {
                                var extra = new List<string>();
                                var more = (System.Collections.IList)envelope["additional"];
                                var mounts = (System.Collections.IList)envelope["additionalMounts"];
                                if (more.Count != mounts.Count) throw new InvalidDataException("附加目录授权无效。");
                                for (int i = 0; i < more.Count; i++)
                                    extra.Add(SelectedWorkbenchVolume(profile, (string)more[i], (string)mounts[i]));
                                if (extra.Count > 0) launch["additional"] = extra;
                            }
                        }
                        var terminal = Call("terminal-open", launch, 20000);
                        ready["integrityLabel"] = VerifyProcess(terminal, "0x1000")["integrityLabel"];
                        if (App == "pty") {
                            ready["account"] = terminal["account"];
                            ready["accountLabel"] = terminal["accountLabel"];
                            ready["reopenedDraft"] = terminal["reopenedDraft"];
                        }
                        break;
                    case "browser":
                        VerifyProcess(Call("browser-open", null, 30000), "0x2000");
                        break;
                    case "editor":
                    case "desktop":
                        string exe = WorkbenchAppPath(profile, App);
                        if (exe == null) throw new FileNotFoundException(App == "editor" ? "请先安装 VS Code。" : "请先为此账户准备 Claude Desktop。");
                        var opened = Call("app-open", new Dictionary<string, object> {
                            { "app", App }, { "exe", exe }, { "project", folder } }, 20000);
                        if (!SameWindowsName((string)opened["userSid"], profile.workerSid) || (string)opened["integrity"] != "Low" ||
                            !SameWindowsName((string)opened["desktop"], session.DesktopName) || !session.OwnsPid(Convert.ToInt32(opened["pid"])))
                            throw new InvalidDataException("无法核实应用窗口归属。");
                        break;
                    case "accounts":
                    case "tailnet":
                        var component = new FileInfo(ServiceExecutable(profile.toolsDir, App));
                        VerifyDeploymentAcl(component.Directory, profile.controllerSid);
                        VerifyDeploymentAcl(component, profile.controllerSid);
                        Call("service-open", new Dictionary<string, object> { { "service", App } }, 15000);
                        break;
                    default:
                        throw new InvalidDataException("未知的工作台应用。");
                }
                return ready;
            }

            internal Dictionary<string, object> ReadTerminal() { return Call("terminal-read", null, 5000); }

            internal object Event(Dictionary<string, object> message)
            {
                string type = (string)message["type"];
                switch (App)
                {
                    case "pty":
                        if (type == "resize") Call("terminal-resize", message, 5000);
                        else if (type == "input") Call("terminal-input", message, 5000);
                        else throw new InvalidDataException("未知的终端操作。");
                        return null;
                    case "terminal":
                        if (type != "input") throw new InvalidDataException("未知的终端操作。");
                        string command = (string)message["text"];
                        ValidateTerminalInput(command);
                        Call("terminal-input", new Dictionary<string, object> { { "text", command } }, 5000);
                        return null;
                    case "browser":
                        return Call("browser-action", message, 15000);
                    case "editor":
                    case "desktop":
                        if (type == "frame") return Call("app-frame", null, 5000);
                        if (type != "click" && type != "key" && type != "text" && type != "wheel")
                            throw new InvalidDataException("未知的应用窗口操作。");
                        Call("app-input", message, 3000);
                        return null;
                    default:
                        if (type == "browser") return SignInBrowser((Dictionary<string, object>)message["event"]);
                        try { return new { type = "state", data = Call("service-action", message, 45000) }; }
                        catch (InvalidOperationException ex) { return new { type = "notice", message = ex.Message }; }
                }
            }

            private object SignInBrowser(Dictionary<string, object> action)
            {
                if ((string)action["type"] == "close")
                {
                    if (signInOpen) Call("browser-close", null, 5000);
                    signInOpen = false;
                    return null;
                }
                if (!signInOpen)
                {
                    VerifyProcess(Call("browser-open", new Dictionary<string, object> { { "signIn", true }, { "service", App } }, 30000), "0x2000");
                    signInOpen = true;
                }
                var frame = Call("browser-action", action, 15000);
                object url;
                Uri parsed;
                if (frame.TryGetValue("url", out url) && Uri.TryCreate(Convert.ToString(url), UriKind.Absolute, out parsed) &&
                    (parsed.Scheme == Uri.UriSchemeHttps || parsed.Scheme == Uri.UriSchemeHttp))
                    frame["url"] = parsed.GetLeftPart(UriPartial.Path);
                return new { type = "browser", data = frame };
            }

            internal void Close()
            {
                if (registered) Call("tab-close", null, 10000);
                registered = false;
            }
        }

        private sealed class WorkbenchTabs
        {
            private readonly Dictionary<string, WorkbenchTab> tabs = new Dictionary<string, WorkbenchTab>();
            private readonly LocalProfileModel profile;
            private readonly LocalWorkerSession session;
            private readonly StreamWriter output;

            internal WorkbenchTabs(LocalProfileModel profile, LocalWorkerSession session, StreamWriter output)
            {
                this.profile = profile;
                this.session = session;
                this.output = output;
            }

            private void Emit(string id, object value)
            {
                if (value != null) output.WriteLine(ToJson(new { id = id, @event = value }));
            }

            private void Close(WorkbenchTab tab)
            {
                tab.Close();
                tabs.Remove(tab.Id);
            }

            private void Request(string line)
            {
                var envelope = FromJsonObject(line);
                string id = (string)envelope["id"];
                if (!ValidTabId(id)) throw new InvalidDataException("Invalid workbench tab id.");
                WorkbenchTab tab;
                tabs.TryGetValue(id, out tab);
                try
                {
                    if (line.Length > 65536) throw new InvalidDataException("标签页请求过长。");
                    switch ((string)envelope["type"])
                    {
                        case "open":
                            string app = (string)envelope["app"];
                            if (tab != null) throw new InvalidDataException("此标签页已打开。");
                            if (app != "terminal" && app != "pty" && tabs.Values.Any(other => other.App == app))
                                throw new InvalidOperationException("此应用已在另一个标签页中打开。");
                            tab = new WorkbenchTab(session, profile, id, app);
                            tabs.Add(id, tab);
                            Emit(id, tab.Open(envelope.ContainsKey("project") ? (string)envelope["project"] : null, envelope));
                            break;
                        case "event":
                            if (tab == null) throw new InvalidDataException("标签页已关闭。");
                            object result = tab.Event((Dictionary<string, object>)envelope["event"]);
                            var data = result as Dictionary<string, object>;
                            if (data != null && Object.Equals(data["type"], "exit")) Close(tab);
                            Emit(id, result);
                            break;
                        case "close":
                            if (tab != null) Close(tab);
                            Emit(id, new { type = "exit" });
                            break;
                        default:
                            throw new InvalidDataException("未知的标签页请求。");
                    }
                }
                catch (Exception ex)
                {
                    // A timed-out or broken daemon pipe cannot carry another RPC safely.
                    if (ex is WorkbenchPipeFailure) throw;
                    if (tab != null) Close(tab);
                    Emit(id, new { type = "error", message = ex.Message });
                }
            }

            internal void Run()
            {
                if (!SameWindowsName((string)session.HandshakeInfo["desktop"], session.DesktopName))
                    throw new InvalidDataException("工作台未连接到隔离桌面。");
                output.WriteLine(ToJson(new { type = "ready", instanceId = profile.instanceId, workerSid = session.HandshakeInfo["userSid"], ptyProtocol = 1 }));
                var input = new StreamReader(Console.OpenStandardInput(), Utf8NoBom);
                Task<string> next = input.ReadLineAsync();
                var poll = Stopwatch.StartNew();
                while (true)
                {
                    var terminals = tabs.Values.Where(tab => tab.App == "terminal" || tab.App == "pty").ToArray();
                    int wait = terminals.Length == 0 ? -1 : Math.Max(0, 65 - (int)Math.Min(65, poll.ElapsedMilliseconds));
                    if (next.Wait(wait))
                    {
                        string line = next.Result;
                        if (line == null) break;
                        Request(line);
                        next = input.ReadLineAsync();
                    }
                    if (poll.ElapsedMilliseconds < 65) continue;
                    poll.Restart();
                    foreach (var tab in terminals)
                    {
                        if (!tabs.ContainsKey(tab.Id)) continue;
                        try
                        {
                            var read = tab.ReadTerminal();
                            string chunk = (string)read["text"];
                            if (chunk.Length != 0) Emit(tab.Id, new { type = "output", text = chunk });
                            if ((bool)read["ended"])
                            {
                                Close(tab);
                                Emit(tab.Id, new { type = "exit", code = read["code"] });
                            }
                        }
                        catch (InvalidOperationException ex)
                        {
                            Close(tab);
                            Emit(tab.Id, new { type = "error", message = ex.Message });
                        }
                    }
                }
            }
        }

        private static int RunWorkbenchTabs(LocalProfileModel profile)
        {
            using (var network = new WorkbenchAppNetwork(profile))
            using (var session = new LocalWorkerSession(profile, "UTC", false, true))
            using (network.Attach(session))
            using (var output = new StreamWriter(Console.OpenStandardOutput(), Utf8NoBom) { AutoFlush = true })
                new WorkbenchTabs(profile, session, output).Run();
            return 0;
        }
    }
}
