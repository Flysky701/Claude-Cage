// Offline integration fixture. All inputs are disposable files from verify_isolation.py.
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Net;
using System.Net.Sockets;
using System.Text;
using System.Web.Script.Serialization;
using Microsoft.Win32;

internal static class IsolationProbe {
    static bool CanRead(string path) {
        try { File.ReadAllText(path); return true; }
        catch (IOException) { return false; }
        catch (UnauthorizedAccessException) { return false; }
    }
    static bool CanWrite(string path, string value) {
        try { File.WriteAllText(path, value); return true; }
        catch (IOException) { return false; }
        catch (UnauthorizedAccessException) { return false; }
    }
    static int Main(string[] args) {
        if (args.Length == 3 && args[0] == "--boxed-child") {
            bool childShared = CanWrite(Path.Combine(args[2], "child.txt"), "boxed-child");
            bool childOutput = CanWrite(Path.Combine(args[1], "child.txt"), "boxed-child");
            return childShared && childOutput ? 0 : 3;
        }
        if (args.Length != 9) return 2;
        string output = args[0], secret = args[1], ordinary = args[2];
        string readOnly = args[3], shared = args[4], keyName = args[5], phase = args[6];
        int port = int.Parse(args[7]);
        var result = new Dictionary<string, object>();
        result["phase"] = phase;
        result["hostEnvironmentHidden"] = Environment.GetEnvironmentVariable("CAGE_TEST_HOST_SECRET") == null;
        result["secretHidden"] = !CanRead(secret);
        result["otherBoxStorageHidden"] = !CanRead(args[8]);
        result["readOnlyReadable"] = CanRead(Path.Combine(readOnly, "read.txt"));
        result["readOnlyWriteDenied"] = !CanWrite(Path.Combine(readOnly, "write.txt"), "unexpected");
        result["sharedReadable"] = CanRead(Path.Combine(shared, "read.txt"));
        result["sharedWriteSucceeded"] = CanWrite(Path.Combine(shared, "write.txt"), "shared-" + phase);
        result["ordinaryBefore"] = File.ReadAllText(ordinary);
        result["ordinaryWriteSucceeded"] = CanWrite(ordinary, "boxed");
        using (var key = Registry.CurrentUser.OpenSubKey(keyName)) {
            result["hostRegistryHidden"] = key == null || (string)key.GetValue("value") != "host";
            result["registryBefore"] = key == null ? null : key.GetValue("value");
        }
        using (var key = Registry.CurrentUser.CreateSubKey(keyName)) {
            key.SetValue("value", "boxed");
            result["registryWriteSucceeded"] = (string)key.GetValue("value") == "boxed";
        }
        bool connected = false;
        using (var tcp = new TcpClient()) {
            try {
                var pending = tcp.BeginConnect(IPAddress.Loopback, port, null, null);
                if (pending.AsyncWaitHandle.WaitOne(1500)) { tcp.EndConnect(pending); connected = true; }
            } catch (SocketException) {}
        }
        result["hostLoopbackBlocked"] = !connected;
        bool resolved = false;
        try { resolved = Dns.GetHostAddresses("offline-fixture.invalid").Length > 0; }
        catch (SocketException) {}
        result["offlineDnsFailed"] = !resolved;
        result["adapterReady"] = Environment.GetEnvironmentVariable("CAGE_LITE_STATUS") == "ready";
        result["offlineMode"] = Environment.GetEnvironmentVariable("CAGE_LITE_NETWORK") == "offline";
        string childFolder = Path.Combine(Path.GetDirectoryName(ordinary), "boxed-bin");
        Directory.CreateDirectory(childFolder);
        string childPath = Path.Combine(childFolder, "BoxedChild.exe");
        File.Copy(Process.GetCurrentProcess().MainModule.FileName, childPath, true);
        var start = new ProcessStartInfo(childPath, "--boxed-child \"" + output + "\" \"" + shared + "\"");
        start.UseShellExecute = false;
        start.CreateNoWindow = true;
        using (var child = Process.Start(start)) {
            bool exited = child.WaitForExit(10000);
            result["boxedChildSharedWriteSucceeded"] = exited && child.ExitCode == 0;
            if (!exited) child.Kill();
        }
        Directory.CreateDirectory(output);
        File.WriteAllText(Path.Combine(output, phase + ".json"), new JavaScriptSerializer().Serialize(result), Encoding.UTF8);
        return 0;
    }
}
