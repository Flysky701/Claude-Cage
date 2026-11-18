using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.IO;
using System.Runtime.InteropServices;
using System.Security.AccessControl;
using System.Security.Principal;

namespace CageLocalTool
{
    internal static partial class CageLocal
    {
        [StructLayout(LayoutKind.Sequential)]
        private struct TerminalMandatoryLabel
        {
            public IntPtr Sid;
            public uint Attributes;
        }

        [StructLayout(LayoutKind.Sequential)]
        private struct TerminalDirectoryAttributes
        {
            public int Length;
            public IntPtr Descriptor;
            public int InheritHandle;
        }

        [DllImport("advapi32.dll", SetLastError = true)]
        private static extern bool SetTokenInformation(IntPtr token, int informationClass,
            ref TerminalMandatoryLabel label, int bufferLength);

        [DllImport("kernel32.dll", EntryPoint = "CreateDirectoryW", CharSet = CharSet.Unicode, SetLastError = true)]
        private static extern bool CreateTerminalDirectory(string path, ref TerminalDirectoryAttributes attributes);

        private static unsafe void SetTerminalTokenLow(IntPtr token)
        {
            var low = new SecurityIdentifier("S-1-16-4096");
            byte[] bytes = new byte[low.BinaryLength];
            low.GetBinaryForm(bytes, 0);
            fixed (byte* sid = bytes)
            {
                    var label = new TerminalMandatoryLabel { Sid = (IntPtr)sid, Attributes = 0x20 /* SE_GROUP_INTEGRITY */ };
                    CheckWin32(SetTokenInformation(token, 25 /* TokenIntegrityLevel */, ref label,
                        Marshal.SizeOf(typeof(TerminalMandatoryLabel)) + bytes.Length), "SetTokenInformation(terminal Low)");
            }
        }

        // The caller retains the suspended process handle and kills the job on any failure.
        private static unsafe Dictionary<string, object> VerifyTerminalToken(IntPtr suspendedProcess, string expectedSid)
        {
            IntPtr token;
            CheckWin32(OpenProcessToken(suspendedProcess, 0x0008 /* QUERY */, out token), "OpenProcessToken(terminal)");
            try
            {
                int size, policy = 0;
                CheckWin32(GetTokenInformation(token, 27 /* TokenMandatoryPolicy */, (IntPtr)(&policy), sizeof(int), out size),
                    "GetTokenInformation(terminal policy)");
                var observed = InspectToken(suspendedProcess);
                if ((policy & 1 /* TOKEN_MANDATORY_POLICY_NO_WRITE_UP */) == 0 ||
                    (string)observed["integrityRid"] != "0x1000" || !SameWindowsName((string)observed["userSid"], expectedSid))
                {
                    throw new UnauthorizedAccessException("The terminal must run as the isolated account at Low integrity with no-write-up.");
                }
                return observed;
            }
            finally
            {
                CloseHandle(token);
            }
        }

        private static string PrepareTerminalDirectory(string profileDir, bool applicationData = false)
        {
            if (string.IsNullOrWhiteSpace(profileDir) || !Path.IsPathRooted(profileDir) ||
                !SameWindowsName(Path.GetFullPath(profileDir),
                    Environment.GetFolderPath(Environment.SpecialFolder.UserProfile)))
            {
                throw new InvalidDataException("Could not locate the isolated user's profile.");
            }
            string low = Path.Combine(profileDir, "AppData", "LocalLow");
            string path = Path.Combine(low, applicationData ? "CageApplications" : "CageTerminal");
            AssertNoReparsePointOnTreeUpToRoot(path, profileDir);
            Directory.CreateDirectory(low);
            string worker = CurrentUserSid();
            // Give the directory its final DACL and integrity label at creation.
            // In particular, never relabel a pre-existing path from a Medium process.
            string sddl = "D:P(A;OICI;FA;;;" + worker + ")(A;OICI;FA;;;SY)(A;OICI;FA;;;BA)S:(ML;OICI;NW;;;LW)";
            IntPtr descriptor;
            uint size;
            CheckWin32(ConvertStringSecurityDescriptorToSecurityDescriptor(sddl, 1, out descriptor, out size),
                "Create terminal directory permissions");
            try
            {
                var attributes = new TerminalDirectoryAttributes
                {
                    Length = Marshal.SizeOf(typeof(TerminalDirectoryAttributes)),
                    Descriptor = descriptor
                };
                if (!CreateTerminalDirectory(path, ref attributes))
                {
                    int error = Marshal.GetLastWin32Error();
                    if (error != 183 /* ERROR_ALREADY_EXISTS */) throw new Win32Exception(error);
                }
            }
            finally
            {
                LocalFree(descriptor);
            }
            AssertNoReparsePointOnTreeUpToRoot(path, profileDir);
            var acl = new DirectoryInfo(path).GetAccessControl();
            if (!acl.AreAccessRulesProtected || !SameWindowsName(acl.GetOwner(typeof(SecurityIdentifier)).Value, worker))
                throw new UnauthorizedAccessException("The terminal directory must belong to the isolated account.");
            foreach (FileSystemAccessRule rule in acl.GetAccessRules(true, true, typeof(SecurityIdentifier)))
            {
                string id = rule.IdentityReference.Value;
                if (rule.AccessControlType == AccessControlType.Allow && !SameWindowsName(id, worker) &&
                    id != WellKnownSystemSid && id != WellKnownAdminsSid)
                    throw new UnauthorizedAccessException("Unexpected permissions on the terminal directory.");
            }
            return path;
        }
    }
}
