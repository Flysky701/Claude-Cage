using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Reflection;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;

namespace CageLocalTool
{
    internal static partial class CageLocal
    {
        private static string ServiceExecutable(string tools, string service)
        {
            return service == "accounts" ? Path.Combine(tools, "claude", "claude.exe") :
                Path.Combine(tools, "tailnet", "cage-tailnet.exe");
        }

        private static void ConfigureClaudeShell(SortedDictionary<string, string> environment, string toolsDir)
        {
            environment["CLAUDE_CODE_USE_POWERSHELL_TOOL"] = "1";
            string bash = Path.Combine(toolsDir, "git-bash", "bash.exe");
            if (File.Exists(bash)) environment["CLAUDE_CODE_GIT_BASH_PATH"] = bash;
        }

        private static int RunWorkbenchService(LocalProfileModel profile, string service)
        {
            var executable = new FileInfo(ServiceExecutable(profile.toolsDir, service));
            VerifyDeploymentAcl(executable.Directory, profile.controllerSid);
            VerifyDeploymentAcl(executable, profile.controllerSid);
            using (var network = new WorkbenchAppNetwork(profile))
            using (var session = new LocalWorkerSession(profile, "UTC", false, true))
            using (network.Attach(session))
            using (var output = new StreamWriter(Console.OpenStandardOutput(), Utf8NoBom) { AutoFlush = true })
            {
                var input = new StreamReader(Console.OpenStandardInput(), Utf8NoBom);
                var open = new Dictionary<string, object> { { "service", service } };
                session.Call("service-open", open, 15000);
                output.WriteLine(ToJson(new { type = "ready", instanceId = profile.instanceId, workerSid = profile.workerSid }));
                bool browser = false;
                string line;
                while ((line = input.ReadLine()) != null)
                {
                    if (line.Length > 32768) throw new InvalidDataException("Service request too large.");
                    var req = FromJsonObject(line);
                    if ((string)req["type"] == "close") break;
                    if ((string)req["type"] == "browser") {
                        var inner = (Dictionary<string, object>)req["event"];
                        if ((string)inner["type"] == "close") {
                            if (browser) session.Call("browser-close", null, 5000);
                            browser = false;
                            continue;
                        }
                        if (!browser) {
                            var opened = session.Call("browser-open", new Dictionary<string, object> {{"signIn", true}}, 30000);
                            var token = (Dictionary<string, object>)opened["token"];
                            if (!SameWindowsName(profile.workerSid, Convert.ToString(token["userSid"])) ||
                                Convert.ToString(token["integrityRid"]) != "0x2000" ||
                                !session.OwnsPid(Convert.ToInt32(opened["pid"])) || !SameWindowsName(Convert.ToString(opened["desktop"]), session.DesktopName))
                                throw new InvalidDataException("Could not verify the sign-in browser.");
                            browser = true;
                        }
                        var frame = session.Call("browser-action", inner, 15000);
                        object address;
                        Uri parsed;
                        if (frame.TryGetValue("url", out address) && Uri.TryCreate(Convert.ToString(address), UriKind.Absolute, out parsed)
                            && (parsed.Scheme == Uri.UriSchemeHttps || parsed.Scheme == Uri.UriSchemeHttp))
                            frame["url"] = parsed.GetLeftPart(UriPartial.Path);
                        output.WriteLine(ToJson(new { type = "browser", data = frame }));
                        continue;
                    }
                    try { output.WriteLine(ToJson(new { type = "state", data = session.Call("service-action", req, 45000) })); }
                    catch (InvalidOperationException ex) { output.WriteLine(ToJson(new { type = "notice", message = ex.Message })); }
                }
            }
            return 0;
        }

        private sealed class WorkerServices : IDisposable
        {
            private string service, exe, profile, local, profiles, chosen, work;
            private SortedDictionary<string, string> environment;
            private Process node, login;
            private string loginURL = "";
            private readonly object outputLock = new object();

            internal void Open(string kind, string user, string appData, string localData, string temp, int port, string timezone)
            {
                if (service != null || (kind != "accounts" && kind != "tailnet")) throw new InvalidDataException("Invalid service.");
                service = kind;
                var deploy = Directory.GetParent(Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location)).FullName;
                exe = ServiceExecutable(Path.Combine(deploy, "tools"), kind);
                if (!File.Exists(exe)) throw new FileNotFoundException("请先为隔离账户准备应用组件。");
                profile = user;
                local = localData;
                // Do not load Claude settings or project hooks from a terminal workspace.
                work = Path.GetDirectoryName(exe);
                environment = BuildWorkerEnv(user, appData, localData, temp, port, timezone, Path.GetDirectoryName(exe), null);
                if (kind == "accounts") {
                    ConfigureClaudeShell(environment, Path.Combine(deploy, "tools"));
                    profiles = Path.Combine(local, "CageClaudeAccounts");
                    AssertNoReparsePointOnTreeUpToRoot(profiles, profile);
                    Directory.CreateDirectory(profiles);
                    chosen = SelectedProfile(local);
                } else {
                    node = Start("", null);
                    node.ErrorDataReceived += delegate { };
                    node.BeginErrorReadLine();
                }
            }

            internal static string SelectedProfile(string localData)
            {
                string root = Path.Combine(localData, "CageClaudeAccounts");
                string selection = Path.Combine(root, "active.txt");
                AssertNoReparsePointOnTreeUpToRoot(selection, localData);
                string id = File.Exists(selection) ? File.ReadAllText(selection).Trim() : "default";
                return ValidID(id) ? id : "default";
            }

            private static bool ValidID(string id)
            {
                return id == "default" || (id != null && Regex.IsMatch(id, @"\A[0-9a-f]{32}\z"));
            }

            internal static string ConfigFolder(string localData, string id)
            {
                if (!ValidID(id)) throw new InvalidDataException("账号档案无效。");
                string dir = Path.Combine(localData, "CageClaudeAccounts", id);
                AssertNoReparsePointOnTreeUpToRoot(dir, localData);
                return dir;
            }

            private Process Start(string args, string config)
            {
                var info = new ProcessStartInfo(exe, args) { UseShellExecute = false, CreateNoWindow = true,
                    WorkingDirectory = work, RedirectStandardInput = true, RedirectStandardOutput = true,
                    RedirectStandardError = true, StandardOutputEncoding = Utf8NoBom, StandardErrorEncoding = Utf8NoBom };
                info.EnvironmentVariables.Clear();
                foreach (var pair in environment) info.EnvironmentVariables[pair.Key] = pair.Value;
                if (config != null) info.EnvironmentVariables["CLAUDE_CONFIG_DIR"] = config;
                return Process.Start(info);
            }

            private static readonly string AccountOptions = "--setting-sources user --settings " + QuoteCmdArg("{\"disableAllHooks\":true}") + " ";

            private static Dictionary<string, object> ClaudeReport(string text)
            {
                // CLI diagnostics can include account data. Expose only verified fields.
                try { return FromJsonObject(text); }
                catch (ArgumentException) { throw new InvalidDataException("Claude Code 返回的状态格式无效。"); }
                catch (InvalidOperationException) { throw new InvalidDataException("Claude Code 返回的状态格式无效。"); }
            }

            private Dictionary<string, object> AccountStatus()
            {
                string dir = ConfigFolder(local, chosen);
                Directory.CreateDirectory(dir);
                using (var child = Start(AccountOptions + "auth status", dir)) {
                    var stdout = child.StandardOutput.ReadToEndAsync();
                    var stderr = child.StandardError.ReadToEndAsync();
                    child.StandardInput.Close();
                    if (!child.WaitForExit(12000)) { child.Kill(); throw new TimeoutException("读取 Claude 登录状态超时。"); }
                    Task.WaitAll(stdout, stderr);
                    if (string.IsNullOrWhiteSpace(stdout.Result) || !stdout.Result.TrimStart().StartsWith("{", StringComparison.Ordinal)) {
                        string diagnostic = stdout.Result + stderr.Result;
                        if (Regex.IsMatch(diagnostic, @"git.bash|bash\.exe", RegexOptions.IgnoreCase))
                            throw new InvalidOperationException("此版本的 Claude Code 需要可在隔离账户内运行的 Git Bash。");
                        if (Regex.IsMatch(diagnostic, @"permission|access.*denied|EACCES|EPERM", RegexOptions.IgnoreCase))
                            throw new InvalidOperationException("Claude Code 无法访问此隔离账户的目录。");
                        throw new InvalidOperationException("Claude Code 未返回登录状态（退出码 " + child.ExitCode + "）。");
                    }
                    var report = ClaudeReport(stdout.Result);
                    object logged, directory;
                    if ((child.ExitCode != 0 && child.ExitCode != 1) ||
                        !report.TryGetValue("loggedIn", out logged) || !(logged is bool) ||
                        (report.TryGetValue("configDirectory", out directory) &&
                            !SameWindowsName(Path.GetFullPath(Convert.ToString(directory)), Path.GetFullPath(dir))))
                        throw new InvalidDataException("无法核实当前 Claude 账号档案。");
                    var state = new Dictionary<string,object>();
                    foreach (string key in new[] { "loggedIn", "email", "orgId", "authMethod", "subscriptionType" })
                        if (report.ContainsKey(key)) state[key] = report[key];
                    return state;
                }
            }

            private void LoginLine(object sender, DataReceivedEventArgs eventArgs)
            {
                if (eventArgs.Data == null) return;
                foreach (Match match in Regex.Matches(eventArgs.Data, @"https://[^\s\x1b<>""']+")) {
                    Uri uri;
                    if (Uri.TryCreate(match.Value, UriKind.Absolute, out uri) && uri.UserInfo == "" && uri.IsDefaultPort &&
                        (uri.Host == "claude.ai" || uri.Host == "platform.claude.com" || uri.Host == "console.anthropic.com") &&
                        uri.AbsolutePath.IndexOf("oauth", StringComparison.OrdinalIgnoreCase) >= 0) {
                        lock (outputLock) loginURL = uri.AbsoluteUri;
                    }
                }
            }

            private static object Field(Dictionary<string, object> record, string key)
            {
                object value;
                return record != null && record.TryGetValue(key, out value) ? value : null;
            }

            private static decimal? UsagePercent(object value)
            {
                if (!(value is decimal || value is int || value is long || value is double)) return null;
                decimal percent = Convert.ToDecimal(value);
                return percent >= 0 && percent <= 100 ? (decimal?)percent : null;
            }

            private Dictionary<string, object> ReadUsage(string dir, Dictionary<string, object> identity)
            {
                if (!Object.Equals(Field(identity, "loggedIn"), true) ||
                    !Object.Equals(Field(identity, "authMethod"), "claude.ai") || Field(identity, "email") == null)
                    throw new InvalidOperationException("请先登录所选的 Claude 账号。");
                string args = AccountOptions + "-p --input-format stream-json --verbose --output-format stream-json " +
                    "--no-session-persistence --strict-mcp-config --tools \"\"";
                Dictionary<string,object> report = null;
                using (var child = Start(args, dir)) {
                    var stdout = child.StandardOutput.ReadToEndAsync();
                    var stderr = child.StandardError.ReadToEndAsync();
                    byte[] request = Utf8NoBom.GetBytes("{\"type\":\"control_request\",\"request_id\":\"quota\",\"request\":{\"subtype\":\"get_usage\",\"skip_behaviors\":true}}\n");
                    child.StandardInput.BaseStream.Write(request, 0, request.Length);
                    child.StandardInput.Close();
                    if (!child.WaitForExit(12000)) { child.Kill(); throw new TimeoutException("额度查询超时。"); }
                    Task.WaitAll(stdout, stderr);
                    if (child.ExitCode != 0 || stdout.Result.Length > 2 * 1024 * 1024)
                        throw new InvalidOperationException("当前 Claude Code 未能读取额度。");
                    foreach (string line in stdout.Result.Split(new[] {'\n'}, StringSplitOptions.RemoveEmptyEntries)) {
                        var packet = ClaudeReport(line);
                        object type = Field(packet, "type");
                        if (Object.Equals(type, "user") || Object.Equals(type, "assistant") ||
                            (Object.Equals(type, "result") && (!Object.Equals(Field(packet, "num_turns"), 0) || !Object.Equals(Field(packet, "is_error"), false))))
                            throw new InvalidDataException("Claude Code 返回了意外的额度查询结果。");
                        var response = Field(packet, "response") as Dictionary<string,object>;
                        if (Object.Equals(type, "control_response") && Object.Equals(Field(response, "request_id"), "quota")) {
                            if (report != null || !Object.Equals(Field(response, "subtype"), "success"))
                                throw new InvalidOperationException("Claude Code 未能完成额度查询。");
                            report = Field(response, "response") as Dictionary<string,object>;
                        }
                    }
                }
                var session = Field(report, "session") as Dictionary<string,object>;
                var models = Field(session, "model_usage") as Dictionary<string,object>;
                if (!(Field(report, "rate_limits_available") is bool) || UsagePercent(Field(session, "total_cost_usd")) != 0 || (models != null && models.Count != 0))
                    throw new InvalidDataException("未取得有效的 Claude 额度报告。");
                var check = AccountStatus();
                foreach (string key in new[] {"loggedIn", "email", "authMethod", "orgId"})
                    if (!Object.Equals(Field(identity, key), Field(check, key))) throw new InvalidOperationException("查询期间账号已更改，请重新查询。");
                var windows = new Dictionary<string, object>();
                if (!Object.Equals(Field(report, "rate_limits_available"), true)) return windows;
                var rate = Field(report, "rate_limits") as Dictionary<string,object>;
                foreach (string key in new[] { "five_hour", "seven_day" }) {
                    var entry = Field(rate, key) as Dictionary<string,object>;
                    decimal? percent = UsagePercent(Field(entry, "utilization"));
                    if (percent == null) {
                        var rows = Field(rate, "limits") as object[];
                        string kind = key == "five_hour" ? "session" : "weekly_all";
                        if (rows != null) foreach (var item in rows) {
                            var row = item as Dictionary<string,object>;
                            if (!Object.Equals(Field(row, "kind"), kind)) continue;
                            var value = UsagePercent(Field(row, "percent"));
                            if (value == null) continue;
                            if (percent.HasValue && percent != value) { percent = null; break; }
                            percent = value;
                        }
                    }
                    if (percent.HasValue) windows[key] = percent.Value;
                }
                return windows;
            }

            private Dictionary<string,object> Accounts(Dictionary<string,object> req, string action)
            {
                string config = ConfigFolder(local, chosen);
                Directory.CreateDirectory(config);
                if (login != null && login.HasExited) { login.WaitForExit(); login.Dispose(); login = null; lock (outputLock) loginURL = ""; }
                if (action == "login") {
                    if (login == null) {
                        login = Start(AccountOptions + "auth login --claudeai", config);
                        login.OutputDataReceived += LoginLine; login.ErrorDataReceived += LoginLine;
                        login.BeginOutputReadLine(); login.BeginErrorReadLine();
                    }
                } else if (action == "code") {
                    string code = Convert.ToString(req["code"]);
                    if (login == null || code.Length > 2048 || code.IndexOfAny(new[] {'\n','\r','\0'}) >= 0) throw new InvalidDataException("无效的登录返回码。");
                    login.StandardInput.WriteLine(code); login.StandardInput.Flush();
                } else if (action == "logout") {
                    if (login != null || !Object.Equals(Field(AccountStatus(), "loggedIn"), true))
                        throw new InvalidOperationException("请先核对当前已登录的账号。");
                    using (var child = Start(AccountOptions + "auth logout", config)) {
                        var stdout = child.StandardOutput.ReadToEndAsync();
                        var stderr = child.StandardError.ReadToEndAsync();
                        child.StandardInput.Close();
                        if (!child.WaitForExit(10000)) { child.Kill(); throw new TimeoutException("退出登录超时。"); }
                        Task.WaitAll(stdout, stderr);
                        if (child.ExitCode != 0) throw new InvalidOperationException("Claude Code 未能退出当前账号。");
                    }
                } else if (action == "add" || action == "select") {
                    if (login != null) throw new InvalidOperationException("请先完成登录或关闭此页。");
                    string id = action == "add" ? Guid.NewGuid().ToString("N") : Convert.ToString(req["profile"]);
                    string dir = ConfigFolder(local, id);
                    if (action == "add") {
                        string label = Convert.ToString(req["label"]).Trim();
                        if (label.Length == 0 || label.Length > 64 || Regex.IsMatch(label, @"\p{C}")) throw new InvalidDataException("请填写 1 至 64 个字符的名称。");
                        Directory.CreateDirectory(dir);
                        File.WriteAllText(Path.Combine(dir, "cage-label.txt"), label, Utf8NoBom);
                    } else if (!Directory.Exists(dir)) throw new InvalidDataException("找不到该账号档案。");
                    string active = Path.Combine(profiles, "active.txt");
                    string stage = Path.Combine(profiles, Guid.NewGuid().ToString("N") + ".tmp");
                    try {
                        File.WriteAllText(stage, id, Utf8NoBom);
                        if (File.Exists(active)) File.Replace(stage, active, null); else File.Move(stage, active);
                    } finally { if (File.Exists(stage)) File.Delete(stage); }
                    chosen = id;
                } else if (action != "status" && action != "poll" && action != "usage") throw new InvalidDataException("未知账号操作。");
                var list = new List<object>();
                foreach (string dir in Directory.GetDirectories(profiles)) {
                    string id = Path.GetFileName(dir);
                    if (!ValidID(id)) continue;
                    string label = Path.Combine(ConfigFolder(local, id), "cage-label.txt");
                    AssertNoReparsePointOnTreeUpToRoot(label, profiles);
                    list.Add(new { id = id, label = File.Exists(label) ? File.ReadAllText(label) : "默认账号" });
                }
                var view = new Dictionary<string,object> { {"profiles", list}, {"selected", chosen}, {"signing_in", login != null} };
                if (action != "poll" || login == null) {
                    var identity = AccountStatus();
                    view["identity"] = identity;
                    if (action == "usage") view["usage"] = ReadUsage(config, identity);
                }
                lock (outputLock) view["auth_url"] = loginURL;
                return view;
            }

            internal Dictionary<string,object> Action(Dictionary<string,object> request)
            {
                string action = Convert.ToString(request["type"]);
                if (service == "accounts") return Accounts(request, action);
                if (service != "tailnet" || node == null || node.HasExited) throw new InvalidOperationException("隔离的 Tailscale 组件已退出。");
                var input = new Dictionary<string,object>{{"action", action}};
                switch (action) {
                    case "status": case "login": case "connect": case "disconnect": case "logout": break;
                    case "add-key": case "remove-key": input["key"] = Convert.ToString(request["key"]); break;
                    default: throw new InvalidDataException("未知 Tailscale 操作。");
                }
                node.StandardInput.WriteLine(ToJson(input)); node.StandardInput.Flush();
                var read = node.StandardOutput.ReadLineAsync();
                if (!read.Wait(15000) || read.Result == null) { Dispose(); throw new IOException("隔离节点未响应。"); }
                var state = FromJsonObject(read.Result);
                state.Remove("proxy_url");
                return state;
            }

            public void Dispose()
            {
                foreach (var child in new[] { node, login }) if (child != null) {
                    try { child.StandardInput.Close(); if (!child.WaitForExit(800)) { child.Kill(); child.WaitForExit(); } } catch (InvalidOperationException) { }
                    child.Dispose();
                }
                node = login = null;
            }
        }
    }
}
