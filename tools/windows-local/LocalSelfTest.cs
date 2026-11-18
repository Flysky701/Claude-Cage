using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Net;
using System.Net.Sockets;
using System.Security.Principal;
using System.Text;

namespace CageLocalTool
{
    internal static partial class CageLocal
    {
        private static void AssertTrue(bool cond, string message)
        {
            if (!cond)
            {
                throw new InvalidOperationException("SelfTest assertion failed: " + message);
            }
        }

        internal static int RunSelfTests()
        {
            List<string> checks = new List<string>();

            // 1. Deterministic WFP key derivation
            Guid k1 = DeriveWfpKey("11111111-1111-1111-1111-111111111111", "S-1-5-21-1-2-3-1005", "connect-v4");
            Guid k2 = DeriveWfpKey("11111111-1111-1111-1111-111111111111", "S-1-5-21-1-2-3-1005", "connect-v4");
            Guid k3 = DeriveWfpKey("11111111-1111-1111-1111-111111111111", "S-1-5-21-1-2-3-1006", "connect-v4");
            AssertTrue(k1 == k2, "WFP key derivation must be deterministic");
            AssertTrue(k1 != k3, "WFP key derivation must isolate worker SIDs");
            checks.Add("wfp_key_derivation");

            // 2. DPAPI protect/unprotect + tamper rejection
            string inst = Guid.NewGuid().ToString("D");
            string cSid = CurrentUserSid();
            string wSid = "S-1-5-21-100-200-300-1099";
            byte[] secret = Utf8NoBom.GetBytes("Cg!TestSecret_12345");
            byte[] cipher = DpapiProtect(secret, inst, cSid, wSid);
            byte[] roundtrip = DpapiUnprotect(cipher, inst, cSid, wSid);
            AssertTrue(Utf8NoBom.GetString(roundtrip) == "Cg!TestSecret_12345", "DPAPI roundtrip mismatch");
            bool wrongEntropyRejected = false;
            try
            {
                DpapiUnprotect(cipher, inst, cSid, "S-1-5-21-100-200-300-1999");
            }
            catch
            {
                wrongEntropyRejected = true;
            }
            AssertTrue(wrongEntropyRejected, "DPAPI must reject mismatched worker entropy");
            checks.Add("dpapi_roundtrip_and_entropy");

            // 3. Controller-only file ACL helper
            string tmpDir = Path.Combine(Path.GetTempPath(), "CageLocalSelfTest-" + Guid.NewGuid().ToString("N"));
            Directory.CreateDirectory(tmpDir);
            try
            {
                string protectedFile = Path.Combine(tmpDir, "secret.dat");
                File.WriteAllBytes(protectedFile, cipher);
                SetControllerOnlyFileAcl(protectedFile, cSid);
                VerifyControllerOnlyFileAcl(protectedFile, cSid, wSid);
                checks.Add("controller_only_acl");
            }
            finally
            {
                try { Directory.Delete(tmpDir, true); } catch { }
            }

            // 4. Command line quoting & constant-time compare
            AssertTrue(QuoteCmdArg("a\\b\"") == "\"a\\b\\\"\"", "QuoteCmdArg escaping mismatch");
            AssertTrue(ConstantTimeEquals("abc123", "abc123") && !ConstantTimeEquals("abc123", "abc124"), "ConstantTimeEquals mismatch");
            checks.Add("quoting_and_constant_time");

            // 5. Network port byte-order helper + LocalProxyBroker PID gate (accept allowed PID, reject disallowed PID)
            AssertTrue(NetworkPortToHost(0x5000) == 80, "NetworkPortToHost(80)");
            AssertTrue(NetworkPortToHost(0xBB01) == 443, "NetworkPortToHost(443)");

            int selfPid = Process.GetCurrentProcess().Id;
            using (SyntheticOriginServer origin = new SyntheticOriginServer())
            {
                Dictionary<string, IPEndPoint> targets = new Dictionary<string, IPEndPoint>(StringComparer.OrdinalIgnoreCase);
                targets["cage-test.internal:80"] = new IPEndPoint(IPAddress.Loopback, origin.HttpPort);
                targets["cage-test.internal:443"] = new IPEndPoint(IPAddress.Loopback, origin.TunnelPort);

                // First: reject selfPid
                using (LocalProxyBroker denyBroker = new LocalProxyBroker(0, delegate(int pid) { return pid != selfPid; }, targets))
                {
                    bool gotEofOrRejected = false;
                    try
                    {
                        using (TcpClient c = new TcpClient())
                        {
                            c.ReceiveTimeout = 2000;
                            c.Connect(IPAddress.Loopback, denyBroker.Port);
                            byte[] req = Encoding.ASCII.GetBytes("GET http://cage-test.internal/ok HTTP/1.1\r\nHost: cage-test.internal\r\n\r\n");
                            c.GetStream().Write(req, 0, req.Length);
                            byte[] buf = new byte[256];
                            int n = c.GetStream().Read(buf, 0, buf.Length);
                            gotEofOrRejected = (n == 0);
                        }
                    }
                    catch
                    {
                        gotEofOrRejected = true;
                    }
                    AssertTrue(gotEofOrRejected, "Broker must reject disallowed PID");
                    AssertTrue((int)denyBroker.StatsSnapshot()["rejectedCallerCount"] >= 1, "Broker rejectedCallerCount should increment");
                }

                // Second: allow selfPid and test HTTP forward + CONNECT + gate close
                using (LocalProxyBroker allowBroker = new LocalProxyBroker(0, delegate(int pid) { return pid == selfPid; }, targets))
                {
                    using (TcpClient c = new TcpClient())
                    {
                        c.ReceiveTimeout = 3000;
                        c.Connect(IPAddress.Loopback, allowBroker.Port);
                        byte[] req = Encoding.ASCII.GetBytes("GET http://cage-test.internal/ok HTTP/1.1\r\nHost: cage-test.internal\r\n\r\n");
                        c.GetStream().Write(req, 0, req.Length);
                        using (StreamReader sr = new StreamReader(c.GetStream(), Utf8NoBom))
                        {
                            string resp = sr.ReadToEnd();
                            AssertTrue(resp.Contains("CAGE_LOCAL_HTTP_ORIGIN_OK"), "Broker HTTP forward failed");
                        }
                    }

                    using (TcpClient c = new TcpClient())
                    {
                        c.ReceiveTimeout = 3000;
                        c.Connect(IPAddress.Loopback, allowBroker.Port);
                        NetworkStream ns = c.GetStream();
                        byte[] req = Encoding.ASCII.GetBytes("CONNECT cage-test.internal:443 HTTP/1.1\r\nHost: cage-test.internal:443\r\n\r\n");
                        ns.Write(req, 0, req.Length);
                        byte[] buf = new byte[512];
                        int hn = ns.Read(buf, 0, buf.Length);
                        string head = Encoding.ASCII.GetString(buf, 0, hn);
                        AssertTrue(head.StartsWith("HTTP/1.1 200", StringComparison.Ordinal), "Broker CONNECT failed");
                        byte[] ping = Utf8NoBom.GetBytes("SELFTEST");
                        ns.Write(ping, 0, ping.Length);
                        int en = ns.Read(buf, 0, buf.Length);
                        AssertTrue(Utf8NoBom.GetString(buf, 0, en) == "CAGE_TUNNEL_OK:SELFTEST", "Broker CONNECT echo failed");
                    }

                    allowBroker.SetGateOpen(false);
                    using (TcpClient c = new TcpClient())
                    {
                        c.ReceiveTimeout = 3000;
                        c.Connect(IPAddress.Loopback, allowBroker.Port);
                        byte[] req = Encoding.ASCII.GetBytes("GET http://cage-test.internal/ok HTTP/1.1\r\nHost: cage-test.internal\r\n\r\n");
                        c.GetStream().Write(req, 0, req.Length);
                        using (StreamReader sr = new StreamReader(c.GetStream(), Utf8NoBom))
                        {
                            string resp = sr.ReadToEnd();
                            AssertTrue(resp.Contains("503 Proxy Gate Closed"), "Broker closed gate must block traffic");
                        }
                    }
                }
            }
            checks.Add("broker_pid_gate_and_tunnel");

            Dictionary<string, object> summary = new Dictionary<string, object>();
            summary["status"] = "SELFTEST_PASS";
            summary["checks"] = checks.ToArray();
            Console.WriteLine(ToJson(summary));
            return 0;
        }
    }
}
