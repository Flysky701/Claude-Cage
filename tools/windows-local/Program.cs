using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Net;
using System.Net.Sockets;
using System.Text;
using Microsoft.Win32;

namespace CageLocalTool
{
    internal static partial class CageLocal
    {
        private static int CountLiveProcessesForSid(string workerSid)
        {
            int count = 0;
            Process[] procs = Process.GetProcesses();
            for (int i = 0; i < procs.Length; i++)
            {
                Process p = procs[i];
                try
                {
                    IntPtr hProc = OpenProcess(0x1000 /* PROCESS_QUERY_LIMITED_INFORMATION */, false, p.Id);
                    if (hProc == IntPtr.Zero)
                    {
                        continue;
                    }
                    try
                    {
                        string sid = QueryProcessUserSid(hProc);
                        if (string.Equals(sid, workerSid, StringComparison.OrdinalIgnoreCase))
                        {
                            count++;
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
            return count;
        }

        private static Dictionary<string, object> SnapshotHostState()
        {
            Dictionary<string, object> state = new Dictionary<string, object>();
            using (RegistryKey inet = Registry.CurrentUser.OpenSubKey(@"Software\Microsoft\Windows\CurrentVersion\Internet Settings", false))
            {
                state["proxyEnable"] = inet != null ? inet.GetValue("ProxyEnable") : null;
                state["proxyServer"] = inet != null ? inet.GetValue("ProxyServer") : null;
                state["proxyOverride"] = inet != null ? inet.GetValue("ProxyOverride") : null;
            }
            using (RegistryKey probe = Registry.CurrentUser.OpenSubKey(@"Software\CageLocalProbe", false))
            {
                state["probeKeyPresent"] = (probe != null);
            }
            state["timeZoneId"] = TimeZoneInfo.Local.Id;
            return state;
        }

        private static bool HostStateEqual(Dictionary<string, object> a, Dictionary<string, object> b)
        {
            return Equals(a["proxyEnable"], b["proxyEnable"]) &&
                   Equals(a["proxyServer"], b["proxyServer"]) &&
                   Equals(a["proxyOverride"], b["proxyOverride"]) &&
                   Equals(a["probeKeyPresent"], b["probeKeyPresent"]) &&
                   Equals(a["timeZoneId"], b["timeZoneId"]);
        }

        private static bool ProbeBrokerRejectsHostCaller(int brokerPort)
        {
            try
            {
                using (TcpClient c = new TcpClient())
                {
                    c.ReceiveTimeout = 2000;
                    c.SendTimeout = 2000;
                    c.Connect(IPAddress.Loopback, brokerPort);
                    NetworkStream ns = c.GetStream();
                    byte[] req = Encoding.ASCII.GetBytes("GET http://cage-test.internal/ok HTTP/1.1\r\nHost: cage-test.internal\r\n\r\n");
                    ns.Write(req, 0, req.Length);
                    ns.Flush();
                    byte[] buf = new byte[256];
                    int n = ns.Read(buf, 0, buf.Length);
                    return n == 0;
                }
            }
            catch
            {
                return true;
            }
        }

        private static int RunSuiteCommand(string[] args)
        {
            string profilePath = null;
            string specPath = null;
            string outPath = null;
            for (int i = 1; i < args.Length; i++)
            {
                if (args[i] == "--profile" && i + 1 < args.Length)
                {
                    profilePath = Path.GetFullPath(args[++i]);
                }
                else if (args[i] == "--spec" && i + 1 < args.Length)
                {
                    specPath = Path.GetFullPath(args[++i]);
                }
                else if (args[i] == "--out" && i + 1 < args.Length)
                {
                    outPath = Path.GetFullPath(args[++i]);
                }
                else
                {
                    throw new InvalidDataException("Unknown run-suite argument: " + args[i]);
                }
            }
            if (string.IsNullOrEmpty(specPath) || string.IsNullOrEmpty(outPath))
            {
                throw new InvalidDataException("run-suite requires --profile, --spec, and --out.");
            }

            LocalProfileModel profile = LoadProfile(profilePath, true);
            Dictionary<string, object> spec = FromJsonObject(File.ReadAllText(specPath, Utf8NoBom));
            string timezoneIana = spec.ContainsKey("timezone") ? Convert.ToString(spec["timezone"]) : "Asia/Tokyo";
            bool useDefaultDesktop = spec.ContainsKey("useDefaultDesktop") && (bool)spec["useDefaultDesktop"];

            Dictionary<string, object> hostBefore = SnapshotHostState();
            Dictionary<string, object> wfpReceipt = File.Exists(profile.wfpReceiptFile)
                ? FromJsonObject(File.ReadAllText(profile.wfpReceiptFile, Utf8NoBom))
                : new Dictionary<string, object>();

            Dictionary<string, object> report = new Dictionary<string, object>();
            report["schema"] = 1;
            report["dateUtc"] = DateTime.UtcNow.ToString("o");
            report["instanceId"] = profile.instanceId;
            report["workerUsername"] = profile.workerUsername;
            report["workerSid"] = profile.workerSid;
            report["desktopMode"] = useDefaultDesktop ? "Default" : "PrivateCreateDesktop";
            report["wfpProvisionReceipt"] = wfpReceipt;

            TcpListener privateHostListener = new TcpListener(IPAddress.Loopback, 0);
            privateHostListener.Start(4);
            int privateHostPort = ((IPEndPoint)privateHostListener.LocalEndpoint).Port;

            try
            {
                using (SyntheticOriginServer origin = new SyntheticOriginServer())
                {
                    Dictionary<string, IPEndPoint> targets = new Dictionary<string, IPEndPoint>(StringComparer.OrdinalIgnoreCase);
                    targets["cage-test.internal:80"] = new IPEndPoint(IPAddress.Loopback, origin.HttpPort);
                    targets["cage-test.internal:443"] = new IPEndPoint(IPAddress.Loopback, origin.TunnelPort);

                    LocalWorkerSession session = null;
                    LocalProxyBroker broker = null;
                    try
                    {
                        session = new LocalWorkerSession(profile, timezoneIana, useDefaultDesktop);
                        broker = new LocalProxyBroker(profile.brokerPort, delegate(int pid) { return session.OwnsPid(pid); }, targets);

                        report["sessionHandshake"] = session.HandshakeInfo;

                        Dictionary<string, object> inspect = session.Call("inspect", null);
                        report["workerInspect"] = inspect;
                        string workerLocalAppData = Convert.ToString(inspect["localAppData"]);
                        string workerAppData = Convert.ToString(inspect["appData"]);

                        bool nonWorkerRejected = ProbeBrokerRejectsHostCaller(profile.brokerPort);

                        Dictionary<string, object> probeReq = new Dictionary<string, object>();
                        probeReq["hostUserProfile"] = Environment.GetFolderPath(Environment.SpecialFolder.UserProfile);
                        probeReq["hostPrivateFile"] = spec["hostPrivateFile"];
                        probeReq["credentialFile"] = profile.credentialFile;
                        probeReq["sharedRwDir"] = spec["sharedRwDir"];
                        probeReq["sharedRoDir"] = spec["sharedRoDir"];
                        probeReq["hostPrivatePort"] = privateHostPort;

                        Dictionary<string, object> boundaries = session.Call("probe-boundaries", probeReq);
                        boundaries["otherHostLoopbackPending"] = privateHostListener.Pending();
                        boundaries["nonWorkerBrokerRejected"] = nonWorkerRejected;

                        // Kill-switch test: close gate, verify proxy traffic fails immediately, reopen gate
                        broker.SetGateOpen(false);
                        Dictionary<string, object> gatedRes = session.Call("probe-network-http", new Dictionary<string, object> { { "url", "http://cage-test.internal/ok" } });
                        broker.SetGateOpen(true);
                        Dictionary<string, object> reopenedRes = session.Call("probe-network-http", new Dictionary<string, object> { { "url", "http://cage-test.internal/ok" } });

                        int gatedStatus = gatedRes.ContainsKey("statusCode") ? Convert.ToInt32(gatedRes["statusCode"]) : 0;
                        int reopenedStatus = reopenedRes.ContainsKey("statusCode") ? Convert.ToInt32(reopenedRes["statusCode"]) : 0;
                        boundaries["killSwitchClosedStatus"] = gatedStatus;
                        boundaries["killSwitchReopenedStatus"] = reopenedStatus;
                        boundaries["killSwitchPassed"] = (gatedStatus == 503 || gatedStatus == 0) && reopenedStatus == 200;
                        report["boundaries"] = boundaries;

                        // App compatibility suite
                        Dictionary<string, object> apps = new Dictionary<string, object>();
                        Dictionary<string, object> tools = spec["tools"] as Dictionary<string, object>;
                        string sharedRwDir = Convert.ToString(spec["sharedRwDir"]);

                        Func<string, string, Dictionary<string, object>, Dictionary<string, object>> safeAppCall = delegate(string label, string op, Dictionary<string, object> payload)
                        {
                            try
                            {
                                return session.Call(op, payload);
                            }
                            catch (Exception ex)
                            {
                                return new Dictionary<string, object>
                                {
                                    { "error", ex.GetType().Name + ": " + ex.Message }
                                };
                            }
                        };

                        if (tools.ContainsKey("claude") && tools["claude"] != null)
                        {
                            string claudeExe = Convert.ToString(tools["claude"]);
                            apps["ClaudeCodeRing1"] = safeAppCall("ClaudeCodeRing1", "exec", new Dictionary<string, object>
                            {
                                { "exe", claudeExe },
                                { "args", new string[] { "--version" } },
                                { "cwd", sharedRwDir },
                                { "mode", "run-to-exit" },
                                { "timeoutSeconds", 25 }
                            });

                            apps["ClaudeCodeRing2AppContainer"] = safeAppCall("ClaudeCodeRing2AppContainer", "ring2-exec", new Dictionary<string, object>
                            {
                                { "exe", claudeExe },
                                { "args", new string[] { "--version" } },
                                { "timeoutSeconds", 25 }
                            });
                        }

                        if (tools.ContainsKey("node") && tools["node"] != null && spec.ContainsKey("nodeScriptPath"))
                        {
                            string nodeExe = Convert.ToString(tools["node"]);
                            apps["NodeSharedDDrive"] = safeAppCall("NodeSharedDDrive", "exec", new Dictionary<string, object>
                            {
                                { "exe", nodeExe },
                                { "args", new string[] { Convert.ToString(spec["nodeScriptPath"]), sharedRwDir, Convert.ToString(spec["sharedRoDir"]), Convert.ToString(spec["hostPrivateFile"]) } },
                                { "cwd", sharedRwDir },
                                { "mode", "run-to-exit" },
                                { "timeoutSeconds", 25 }
                            });
                        }

                        if (tools.ContainsKey("edge") && tools["edge"] != null)
                        {
                            string edgeExe = Convert.ToString(tools["edge"]);
                            string edgeProfile = Path.Combine(workerLocalAppData, "EdgeProbe_" + Guid.NewGuid().ToString("N").Substring(0, 8));
                            apps["EdgeHeadlessSandboxAndHkcuProxy"] = safeAppCall("EdgeHeadlessSandboxAndHkcuProxy", "exec", new Dictionary<string, object>
                            {
                                { "exe", edgeExe },
                                { "args", new string[] {
                                    "--headless=new",
                                    "--disable-gpu",
                                    "--no-first-run",
                                    "--no-default-browser-check",
                                    "--disable-background-networking",
                                    "--disable-component-update",
                                    "--disable-sync",
                                    "--disable-extensions",
                                    "--disable-quic",
                                    "--disable-features=HttpsFirstBalancedModeAutoEnable,HttpsUpgrades",
                                    "--user-data-dir=" + edgeProfile,
                                    "--dump-dom",
                                    "--timeout=10000",
                                    "http://cage-test.internal/probe.html"
                                } },
                                { "cwd", sharedRwDir },
                                { "mode", "run-to-exit" },
                                { "timeoutSeconds", 30 }
                            });
                        }

                        if (tools.ContainsKey("vscodeExe") && tools["vscodeExe"] != null)
                        {
                            string codeExe = Convert.ToString(tools["vscodeExe"]);
                            if (tools.ContainsKey("vscodeCliJs") && tools["vscodeCliJs"] != null)
                            {
                                string cliJs = Convert.ToString(tools["vscodeCliJs"]);
                                string cliProfile = Path.Combine(workerLocalAppData, "CodeCliProfile");
                                string cliExt = Path.Combine(workerLocalAppData, "CodeCliExt");
                                apps["VSCodeCli"] = safeAppCall("VSCodeCli", "exec", new Dictionary<string, object>
                                {
                                    { "exe", codeExe },
                                    { "args", new string[] { cliJs, "--version", "--user-data-dir=" + cliProfile, "--extensions-dir=" + cliExt } },
                                    { "cwd", sharedRwDir },
                                    { "mode", "run-to-exit" },
                                    { "timeoutSeconds", 25 },
                                    { "extraEnv", new Dictionary<string, object> { { "ELECTRON_RUN_AS_NODE", "1" } } }
                                });
                            }

                            string guiProfile = Path.Combine(workerLocalAppData, "CodeGuiProfile");
                            string guiExt = Path.Combine(workerLocalAppData, "CodeGuiExt");
                            string editorFile = Path.Combine(sharedRwDir, "editor-check.txt");
                            File.WriteAllText(editorFile, "CAGE_LOCAL_VSCODE_EDITOR_FIXTURE", Utf8NoBom);
                            apps["VSCodeGuiSandbox"] = safeAppCall("VSCodeGuiSandbox", "exec", new Dictionary<string, object>
                            {
                                { "exe", codeExe },
                                { "args", new string[] {
                                    "--new-window",
                                    "--skip-welcome",
                                    "--skip-release-notes",
                                    "--disable-extensions",
                                    "--user-data-dir=" + guiProfile,
                                    "--extensions-dir=" + guiExt,
                                    editorFile
                                } },
                                { "cwd", sharedRwDir },
                                { "mode", "observe-gui" },
                                { "timeoutSeconds", 15 }
                            });
                        }

                        if (tools.ContainsKey("claudeDesktopExe") && tools["claudeDesktopExe"] != null)
                        {
                            string desktopExe = Convert.ToString(tools["claudeDesktopExe"]);
                            string desktopProfile = Path.Combine(workerAppData, "Claude");
                            apps["ClaudeDesktopSandbox"] = safeAppCall("ClaudeDesktopSandbox", "exec", new Dictionary<string, object>
                            {
                                { "exe", desktopExe },
                                { "args", new string[] { "--user-data-dir=" + desktopProfile, "--enable-logging=stderr" } },
                                { "cwd", Path.GetDirectoryName(desktopExe) },
                                { "mode", "observe-gui" },
                                { "timeoutSeconds", 15 }
                            });
                        }

                        report["apps"] = apps;
                        report["brokerStats"] = broker.StatsSnapshot();
                    }
                    finally
                    {
                        if (broker != null) broker.Dispose();
                        if (session != null) session.Dispose();
                    }
                }
            }
            finally
            {
                try { privateHostListener.Stop(); } catch { }
            }

            // Allow brief OS handle rundown, then confirm zero lingering worker processes.
            System.Threading.Thread.Sleep(400);
            int lingering = CountLiveProcessesForSid(profile.workerSid);
            Dictionary<string, object> hostAfter = SnapshotHostState();

            report["lingeringWorkerProcesses"] = lingering;
            report["hostStateBefore"] = hostBefore;
            report["hostStateAfter"] = hostAfter;
            report["hostHkcuUnchanged"] = HostStateEqual(hostBefore, hostAfter);

            SaveJsonFile(outPath, report);
            Console.WriteLine(ToJson(new Dictionary<string, object>
            {
                { "suiteCompleted", true },
                { "output", outPath },
                { "lingeringWorkerProcesses", lingering },
                { "hostHkcuUnchanged", report["hostHkcuUnchanged"] }
            }));
            return 0;
        }

        private static int Main(string[] args)
        {
            try
            {
                if (args.Length == 0)
                {
                    Console.Error.WriteLine("Usage: CageLocal.exe <selftest|provision|teardown|grant-share|worker-daemon|run-suite> ...");
                    return 2;
                }
                string cmd = args[0];
                if (cmd == "selftest") return RunSelfTests();
                if (cmd == "provision") return ProvisionCommand(args);
                if (cmd == "teardown") return TeardownCommand(args);
                if (cmd == "grant-share") return GrantShareCommand(args);
                if (cmd == "worker-daemon") return WorkerDaemonCommand(args);
                if (cmd == "run-suite") return RunSuiteCommand(args);

                Console.Error.WriteLine("Unknown subcommand: " + cmd);
                return 2;
            }
            catch (Exception ex)
            {
                Console.Error.WriteLine(ex.GetType().Name + ": " + ex.Message);
                if (ex.InnerException != null)
                {
                    Console.Error.WriteLine("Inner: " + ex.InnerException.GetType().Name + ": " + ex.InnerException.Message);
                }
                return 1;
            }
        }
    }
}
