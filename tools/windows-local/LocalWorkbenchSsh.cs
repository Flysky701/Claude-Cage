using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Globalization;
using System.IO;
using System.Net;
using System.Net.Sockets;
using System.Reflection;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;

namespace CageLocalTool
{
    internal static partial class CageLocal
    {
        private static bool SshHost(string host)
        {
            return host.Length <= 253 && Regex.IsMatch(host,
                @"\A[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?(?:\.[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?)*\z");
        }

        private static int SshPort(string value)
        {
            int port;
            if (!int.TryParse(value, NumberStyles.None, CultureInfo.InvariantCulture, out port) || port < 1 || port > 65535)
                throw new InvalidDataException("SSH 端口无效。");
            return port;
        }

        private static int WorkerSsh(string[] args)
        {
            if (!Regex.IsMatch(Environment.UserName, @"\ACageLocal_[0-9a-f]{8}\z", RegexOptions.IgnoreCase))
                throw new UnauthorizedAccessException("SSH 工具只能由专用 Windows 账户运行。");
            using (var self = Process.GetCurrentProcess()) VerifyTerminalToken(self.Handle, CurrentUserSid());
            if (args[0] == "ssh-pipe")
            {
                if (args.Length != 3 || !SshHost(args[1])) throw new InvalidDataException("SSH 地址无效。");
                return SshProxyStream(args[1], SshPort(args[2]));
            }
            string profile = Environment.GetFolderPath(Environment.SpecialFolder.UserProfile);
            string dir = Path.Combine(profile, "AppData", "LocalLow", "CageTerminal", "SSH");
            AssertNoReparsePointOnTreeUpToRoot(dir, profile);
            Directory.CreateDirectory(dir);
            string identity = Path.Combine(dir, "id_ed25519");
            string pub = identity + ".pub";
            AssertNoReparsePointOnTreeUpToRoot(identity, profile);
            AssertNoReparsePointOnTreeUpToRoot(pub, profile);
            if (args[0] == "ssh-key" && args.Length == 1)
            {
                if (!File.Exists(identity) && !File.Exists(pub))
                {
                    if (RunSshProgram(dir, "ssh-keygen.exe", new[] { "-q", "-t", "ed25519", "-N", "", "-C", Environment.UserName, "-f", identity }) != 0)
                        throw new IOException("专用 SSH 密钥创建失败。");
                }
                if (!File.Exists(identity))
                    throw new IOException("已有 SSH 密钥文件不完整，请在隔离工作目录的 SSH 文件夹中检查。");
                return RunSshProgram(dir, "ssh-keygen.exe", new[] { "-y", "-P", "", "-f", identity });
            }
            if (args[0] != "ssh-run" || args.Length != 2 || args[1].Length > 14000) throw new InvalidDataException("SSH 命令无效。");
            if (!File.Exists(identity)) throw new FileNotFoundException("请先创建专用 SSH 密钥并将公钥添加到目标主机。");
            var spec = FromJsonObject(Utf8NoBom.GetString(Convert.FromBase64String(args[1])));
            string host = (string)spec["host"], user = (string)spec["user"], command = (string)spec["command"];
            int port = SshPort(Convert.ToString(spec["port"], CultureInfo.InvariantCulture));
            if (!SshHost(host) || !Regex.IsMatch(user, @"\A[A-Za-z0-9_][A-Za-z0-9_.-]{0,63}\z") ||
                string.IsNullOrWhiteSpace(command) || command.Length > 4096 || command.IndexOfAny(new[] { '\r', '\n', '\0' }) >= 0)
                throw new InvalidDataException("请输入有效的主机、用户和单行远程命令。");
            string[] key = Regex.Split(((string)spec["hostKey"]).Trim(), @"\s+");
            if (key.Length < 2 || !Regex.IsMatch(key[0], @"\A(?:ssh-ed25519|ssh-rsa|ecdsa-sha2-nistp(?:256|384|521))\z") ||
                !Regex.IsMatch(key[1], @"\A[A-Za-z0-9+/]{16,3000}={0,2}\z"))
                throw new InvalidDataException("请从可信来源取得该服务器的 SSH 主机公钥。");
            byte[] blob = Convert.FromBase64String(key[1]);
            if (blob.Length <= key[0].Length + 4 || blob[0] != 0 || blob[1] != 0 || blob[2] != 0 || blob[3] != key[0].Length ||
                Encoding.ASCII.GetString(blob, 4, key[0].Length) != key[0]) throw new InvalidDataException("SSH 主机公钥格式错误。");
            string known = Path.Combine(dir, Guid.NewGuid().ToString("N") + ".known_hosts");
            try
            {
                string pin = "cage-peer,[cage-peer]:" + port + " " + key[0] + " " + key[1] + "\n";
                using (var file = new FileStream(known, FileMode.CreateNew, FileAccess.Write, FileShare.None))
                { byte[] bytes = Encoding.ASCII.GetBytes(pin); file.Write(bytes, 0, bytes.Length); }
                string self = Assembly.GetExecutingAssembly().Location.Replace('\\', '/');
                string proxy = "ProxyCommand=\"" + self + "\" ssh-pipe " + host + " " + port;
                return RunSshProgram(dir, "ssh.exe", new[] { "-F", "none", "-n", "-T", "-o", "BatchMode=yes", "-o", "PreferredAuthentications=publickey",
                    "-o", "IdentitiesOnly=yes", "-o", "IdentityAgent=none", "-o", "ClearAllForwardings=yes", "-o", "PermitLocalCommand=no",
                    "-o", "StrictHostKeyChecking=yes", "-o", "UpdateHostKeys=no", "-o", "CheckHostIP=no", "-o", "HostKeyAlias=cage-peer",
                    "-o", "GlobalKnownHostsFile=none", "-o", "UserKnownHostsFile=\"" + known.Replace('\\','/') + "\"", "-o", "ConnectionAttempts=1",
                    "-o", "ConnectTimeout=12", "-o", proxy, "-i", identity, "-p", port.ToString(), "-l", user, "--", host, command });
            }
            finally { if (File.Exists(known)) File.Delete(known); }
        }

        private static int RunSshProgram(string dir, string name, string[] args)
        {
            string exe = Path.Combine(Environment.SystemDirectory, "OpenSSH", name);
            if (!File.Exists(exe)) throw new FileNotFoundException("Windows OpenSSH 客户端尚未安装。");
            var info = new ProcessStartInfo(exe, string.Join(" ", Array.ConvertAll(args, QuoteCmdArg))) {
                UseShellExecute = false, CreateNoWindow = true, WorkingDirectory = dir,
                RedirectStandardInput = true, RedirectStandardOutput = true, RedirectStandardError = true
            };
            using (var child = Process.Start(info))
            {
                child.StandardInput.Close();
                Task output = child.StandardOutput.BaseStream.CopyToAsync(Console.OpenStandardOutput());
                Task errors = child.StandardError.BaseStream.CopyToAsync(Console.OpenStandardError());
                child.WaitForExit(); Task.WaitAll(output, errors);
                return child.ExitCode;
            }
        }

        private static int SshProxyStream(string host, int port)
        {
            Uri proxy;
            if (!Uri.TryCreate(Environment.GetEnvironmentVariable("HTTPS_PROXY"), UriKind.Absolute, out proxy) ||
                proxy.Scheme != "http" || proxy.Host != "127.0.0.1" || proxy.UserInfo != "" || proxy.PathAndQuery != "/")
                throw new IOException("隔离账户代理不可用。");
            using (var client = new TcpClient(AddressFamily.InterNetwork))
            {
                client.Connect(IPAddress.Loopback, proxy.Port);
                using (var socket = client.GetStream())
                {
                    socket.ReadTimeout = 15000;
                    string target = host + ":" + port;
                    byte[] request = Encoding.ASCII.GetBytes("CONNECT " + target + " HTTP/1.1\r\nHost: " + target + "\r\n\r\n");
                    socket.Write(request, 0, request.Length);
                    // Consume exactly the CONNECT header; the server's SSH banner may already follow it.
                    var header = new List<byte>();
                    int suffix = 0;
                    while (header.Count < 8192 && suffix != 0x0d0a0d0a)
                    {
                        int next = socket.ReadByte();
                        if (next < 0) break;
                        header.Add((byte)next);
                        suffix = unchecked((suffix << 8) | next);
                    }
                    if (suffix != 0x0d0a0d0a || !Regex.IsMatch(Encoding.ASCII.GetString(header.ToArray()), @"\AHTTP/1\.[01] 200[ \r]"))
                        throw new IOException("Cage 代理没有接通这台主机，请核对所选节点和目标地址。");
                    socket.ReadTimeout = System.Threading.Timeout.Infinite;
                    Task.Run(async delegate {
                        try { await Console.OpenStandardInput().CopyToAsync(socket); client.Client.Shutdown(SocketShutdown.Send); }
                        catch (IOException) { client.Close(); }
                        catch (SocketException) { client.Close(); }
                        catch (ObjectDisposedException) { }
                    });
                    socket.CopyTo(Console.OpenStandardOutput());
                }
            }
            return 0;
        }
    }
}
