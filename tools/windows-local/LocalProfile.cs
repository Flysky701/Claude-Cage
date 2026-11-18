using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.IO;
using System.Runtime.InteropServices;
using System.Security.AccessControl;
using System.Security.Cryptography;
using System.Security.Principal;
using System.Text;
using System.Web.Script.Serialization;

namespace CageLocalTool
{
    public sealed class LocalProfileModel
    {
        public int schema { get; set; }
        public string instanceId { get; set; }
        public string controllerSid { get; set; }
        public string workerUsername { get; set; }
        public string workerSid { get; set; }
        public string rootDir { get; set; }
        public string binDir { get; set; }
        public string toolsDir { get; set; }
        public string sharedDir { get; set; }
        public string credentialFile { get; set; }
        public string wfpReceiptFile { get; set; }
        public int brokerPort { get; set; }
    }

    internal static partial class CageLocal
    {
        internal static readonly UTF8Encoding Utf8NoBom = new UTF8Encoding(false);
        internal const string WellKnownSystemSid = "S-1-5-18";
        internal const string WellKnownAdminsSid = "S-1-5-32-544";
        internal const string WellKnownUsersSid = "S-1-5-32-545";
        internal const string WellKnownAllPackagesSid = "S-1-15-2-1";

        [StructLayout(LayoutKind.Sequential)]
        private struct CryptoBlob
        {
            public int cbData;
            public IntPtr pbData;
        }

        [DllImport("crypt32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        private static extern bool CryptProtectData(
            ref CryptoBlob pDataIn,
            string szDataDescr,
            ref CryptoBlob pOptionalEntropy,
            IntPtr pvReserved,
            IntPtr pPromptStruct,
            uint dwFlags,
            out CryptoBlob pDataOut);

        [DllImport("crypt32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        private static extern bool CryptUnprotectData(
            ref CryptoBlob pDataIn,
            IntPtr ppszDataDescr,
            ref CryptoBlob pOptionalEntropy,
            IntPtr pvReserved,
            IntPtr pPromptStruct,
            uint dwFlags,
            out CryptoBlob pDataOut);

        [DllImport("kernel32.dll")]
        private static extern IntPtr LocalFree(IntPtr hMem);

        internal static JavaScriptSerializer CreateJsonSerializer()
        {
            JavaScriptSerializer serializer = new JavaScriptSerializer();
            serializer.MaxJsonLength = int.MaxValue;
            return serializer;
        }

        internal static string ToJson(object value)
        {
            return CreateJsonSerializer().Serialize(value);
        }

        internal static Dictionary<string, object> FromJsonObject(string json)
        {
            Dictionary<string, object> result = CreateJsonSerializer().DeserializeObject(json) as Dictionary<string, object>;
            if (result == null)
            {
                throw new InvalidDataException("Expected JSON object.");
            }
            return result;
        }

        internal static void SaveJsonFile(string path, object value)
        {
            string parent = Path.GetDirectoryName(path);
            if (!string.IsNullOrEmpty(parent))
            {
                Directory.CreateDirectory(parent);
            }
            File.WriteAllText(path, ToJson(value) + Environment.NewLine, Utf8NoBom);
        }

        internal static string ProgramDataParentDir()
        {
            return Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.CommonApplicationData), "CageLocal");
        }

        internal static byte[] BuildDpapiEntropy(string instanceId, string controllerSid, string workerSid)
        {
            string material = string.Format("Cage.LocalNative.v1:{0}:{1}:{2}", instanceId, controllerSid, workerSid);
            using (SHA256 sha = SHA256.Create())
            {
                return sha.ComputeHash(Utf8NoBom.GetBytes(material));
            }
        }

        internal static byte[] DpapiProtect(byte[] plainBytes, string instanceId, string controllerSid, string workerSid)
        {
            return DpapiTransform(plainBytes, instanceId, controllerSid, workerSid, true);
        }

        internal static byte[] DpapiUnprotect(byte[] cipherBytes, string instanceId, string controllerSid, string workerSid)
        {
            return DpapiTransform(cipherBytes, instanceId, controllerSid, workerSid, false);
        }

        private static byte[] DpapiTransform(byte[] inputBytes, string instanceId, string controllerSid, string workerSid, bool protect)
        {
            if (inputBytes == null || inputBytes.Length == 0)
            {
                throw new InvalidDataException("DPAPI payload is empty.");
            }
            byte[] entropyBytes = BuildDpapiEntropy(instanceId, controllerSid, workerSid);
            CryptoBlob inputBlob = new CryptoBlob();
            CryptoBlob entropyBlob = new CryptoBlob();
            CryptoBlob outputBlob = new CryptoBlob();
            inputBlob.cbData = inputBytes.Length;
            inputBlob.pbData = Marshal.AllocHGlobal(inputBytes.Length);
            entropyBlob.cbData = entropyBytes.Length;
            entropyBlob.pbData = Marshal.AllocHGlobal(entropyBytes.Length);
            try
            {
                Marshal.Copy(inputBytes, 0, inputBlob.pbData, inputBytes.Length);
                Marshal.Copy(entropyBytes, 0, entropyBlob.pbData, entropyBytes.Length);
                // CRYPTPROTECT_UI_FORBIDDEN (0x1) | CRYPTPROTECT_LOCAL_MACHINE (0x4);
                // file DACL restricts read access strictly to controllerSid, SYSTEM, and Administrators.
                const uint flags = 0x1 | 0x4;
                bool ok = protect
                    ? CryptProtectData(ref inputBlob, "CageLocal Worker Credential", ref entropyBlob, IntPtr.Zero, IntPtr.Zero, flags, out outputBlob)
                    : CryptUnprotectData(ref inputBlob, IntPtr.Zero, ref entropyBlob, IntPtr.Zero, IntPtr.Zero, flags, out outputBlob);
                if (!ok)
                {
                    throw new Win32Exception(Marshal.GetLastWin32Error(), protect ? "CryptProtectData failed" : "CryptUnprotectData failed");
                }
                byte[] output = new byte[outputBlob.cbData];
                Marshal.Copy(outputBlob.pbData, output, 0, output.Length);
                return output;
            }
            finally
            {
                Array.Clear(entropyBytes, 0, entropyBytes.Length);
                if (inputBlob.pbData != IntPtr.Zero)
                {
                    ZeroUnmanaged(inputBlob.pbData, inputBlob.cbData);
                    Marshal.FreeHGlobal(inputBlob.pbData);
                }
                if (entropyBlob.pbData != IntPtr.Zero)
                {
                    ZeroUnmanaged(entropyBlob.pbData, entropyBlob.cbData);
                    Marshal.FreeHGlobal(entropyBlob.pbData);
                }
                if (outputBlob.pbData != IntPtr.Zero)
                {
                    ZeroUnmanaged(outputBlob.pbData, outputBlob.cbData);
                    LocalFree(outputBlob.pbData);
                }
            }
        }

        internal static void ZeroUnmanaged(IntPtr ptr, int length)
        {
            if (ptr == IntPtr.Zero || length <= 0)
            {
                return;
            }
            byte[] zeros = new byte[Math.Min(length, 4096)];
            int offset = 0;
            while (offset < length)
            {
                int chunk = Math.Min(zeros.Length, length - offset);
                Marshal.Copy(zeros, 0, IntPtr.Add(ptr, offset), chunk);
                offset += chunk;
            }
        }

        internal static void SetControllerOnlyFileAcl(string path, string controllerSid)
        {
            FileSecurity acl = new FileSecurity();
            acl.SetAccessRuleProtection(true, false);
            acl.SetOwner(new SecurityIdentifier(controllerSid));
            string[] owners = new string[] { controllerSid, WellKnownSystemSid, WellKnownAdminsSid };
            for (int i = 0; i < owners.Length; i++)
            {
                acl.AddAccessRule(new FileSystemAccessRule(
                    new SecurityIdentifier(owners[i]),
                    FileSystemRights.FullControl,
                    AccessControlType.Allow));
            }
            File.SetAccessControl(path, acl);
        }

        internal static void VerifyControllerOnlyFileAcl(string path, string controllerSid, string forbiddenSid)
        {
            FileInfo info = new FileInfo(path);
            if (!info.Exists || (info.Attributes & FileAttributes.ReparsePoint) != 0)
            {
                throw new InvalidDataException("Protected file is missing or redirected: " + path);
            }
            FileSecurity acl = info.GetAccessControl();
            if (!acl.AreAccessRulesProtected)
            {
                throw new InvalidDataException("Protected file allows inherited ACLs: " + path);
            }
            HashSet<string> allowed = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            allowed.Add(controllerSid);
            allowed.Add(WellKnownSystemSid);
            allowed.Add(WellKnownAdminsSid);
            AuthorizationRuleCollection rules = acl.GetAccessRules(true, true, typeof(SecurityIdentifier));
            foreach (FileSystemAccessRule rule in rules)
            {
                if (rule.AccessControlType == AccessControlType.Allow)
                {
                    string sid = rule.IdentityReference.Value;
                    if (!string.IsNullOrEmpty(forbiddenSid) && string.Equals(sid, forbiddenSid, StringComparison.OrdinalIgnoreCase))
                    {
                        throw new InvalidDataException("Forbidden SID present on protected file: " + path);
                    }
                    if (!allowed.Contains(sid))
                    {
                        throw new InvalidDataException("Unexpected SID " + sid + " on protected file: " + path);
                    }
                }
            }
        }

        internal static void AssertNoReparsePointOnTreeUpToRoot(string path, string boundaryRoot)
        {
            string full = Path.GetFullPath(path);
            string root = Path.GetFullPath(boundaryRoot).TrimEnd('\\');
            for (DirectoryInfo dir = new DirectoryInfo(full); dir != null; dir = dir.Parent)
            {
                if (dir.Exists && (dir.Attributes & FileAttributes.ReparsePoint) != 0)
                {
                    throw new InvalidDataException("Reparse point detected on path: " + dir.FullName);
                }
                if (string.Equals(dir.FullName.TrimEnd('\\'), root, StringComparison.OrdinalIgnoreCase))
                {
                    break;
                }
            }
        }

        internal static LocalProfileModel LoadProfile(string profilePath, bool verifyProtectedFiles)
        {
            if (string.IsNullOrEmpty(profilePath) || !File.Exists(profilePath))
            {
                throw new FileNotFoundException("Profile file not found.", profilePath);
            }
            FileInfo fi = new FileInfo(profilePath);
            if ((fi.Attributes & FileAttributes.ReparsePoint) != 0 || fi.Length <= 0 || fi.Length > 65536)
            {
                throw new InvalidDataException("Profile file is invalid or redirected.");
            }
            string raw = File.ReadAllText(profilePath, Utf8NoBom);
            LocalProfileModel p = CreateJsonSerializer().Deserialize<LocalProfileModel>(raw);
            ValidateProfileModel(p);
            if (verifyProtectedFiles)
            {
                AssertNoReparsePointOnTreeUpToRoot(p.rootDir, ProgramDataParentDir());
                VerifyControllerOnlyFileAcl(p.credentialFile, p.controllerSid, p.workerSid);
            }
            return p;
        }

        internal static void ValidateProfileModel(LocalProfileModel p)
        {
            if (p == null || p.schema != 1)
            {
                throw new InvalidDataException("Unsupported profile schema.");
            }
            Guid parsedId;
            if (!Guid.TryParse(p.instanceId, out parsedId) || parsedId == Guid.Empty)
            {
                throw new InvalidDataException("Invalid instanceId in profile.");
            }
            if (string.IsNullOrEmpty(p.controllerSid) || !p.controllerSid.StartsWith("S-1-5-21-", StringComparison.Ordinal))
            {
                throw new InvalidDataException("Invalid controllerSid in profile.");
            }
            if (string.IsNullOrEmpty(p.workerSid) || !p.workerSid.StartsWith("S-1-5-21-", StringComparison.Ordinal))
            {
                throw new InvalidDataException("Invalid workerSid in profile.");
            }
            if (string.Equals(p.controllerSid, p.workerSid, StringComparison.OrdinalIgnoreCase))
            {
                throw new InvalidDataException("controllerSid and workerSid must differ.");
            }
            if (string.IsNullOrEmpty(p.workerUsername) || !p.workerUsername.StartsWith("CageLocal_", StringComparison.Ordinal))
            {
                throw new InvalidDataException("Invalid workerUsername in profile.");
            }
            if (p.brokerPort < 1024 || p.brokerPort > 65535)
            {
                throw new InvalidDataException("Invalid brokerPort in profile.");
            }
            string[] requiredPaths = new string[] { p.rootDir, p.binDir, p.toolsDir, p.sharedDir, p.credentialFile, p.wfpReceiptFile };
            for (int i = 0; i < requiredPaths.Length; i++)
            {
                string item = requiredPaths[i];
                if (string.IsNullOrEmpty(item) || !Path.IsPathRooted(item) || item.IndexOfAny(new char[] { '\0', '\r', '\n' }) >= 0)
                {
                    throw new InvalidDataException("Invalid rooted path in profile.");
                }
            }
        }

        internal static string QuoteCmdArg(string value)
        {
            if (value == null)
            {
                return "\"\"";
            }
            StringBuilder sb = new StringBuilder();
            sb.Append('"');
            int backslashes = 0;
            for (int i = 0; i < value.Length; i++)
            {
                char c = value[i];
                if (c == '\\')
                {
                    backslashes++;
                }
                else if (c == '"')
                {
                    sb.Append('\\', backslashes * 2 + 1);
                    sb.Append('"');
                    backslashes = 0;
                }
                else
                {
                    if (backslashes > 0)
                    {
                        sb.Append('\\', backslashes);
                        backslashes = 0;
                    }
                    sb.Append(c);
                }
            }
            if (backslashes > 0)
            {
                sb.Append('\\', backslashes * 2);
            }
            sb.Append('"');
            return sb.ToString();
        }

        internal static string BuildCommandLine(string exe, string[] args)
        {
            List<string> parts = new List<string>();
            parts.Add(QuoteCmdArg(exe));
            if (args != null)
            {
                for (int i = 0; i < args.Length; i++)
                {
                    parts.Add(QuoteCmdArg(args[i]));
                }
            }
            return string.Join(" ", parts.ToArray());
        }

        internal static string BytesToHex(byte[] bytes)
        {
            StringBuilder sb = new StringBuilder(bytes.Length * 2);
            for (int i = 0; i < bytes.Length; i++)
            {
                sb.Append(bytes[i].ToString("x2"));
            }
            return sb.ToString();
        }

        internal static byte[] RandomBytes(int count)
        {
            byte[] buf = new byte[count];
            using (RNGCryptoServiceProvider rng = new RNGCryptoServiceProvider())
            {
                rng.GetBytes(buf);
            }
            return buf;
        }

        internal static bool ConstantTimeEquals(string a, string b)
        {
            if (a == null || b == null || a.Length != b.Length)
            {
                return false;
            }
            int diff = 0;
            for (int i = 0; i < a.Length; i++)
            {
                diff |= (int)(a[i] ^ b[i]);
            }
            return diff == 0;
        }
    }
}
