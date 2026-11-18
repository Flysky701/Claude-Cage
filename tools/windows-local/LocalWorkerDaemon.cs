using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Diagnostics;
using System.IO;
using System.IO.Pipes;
using System.Net;
using System.Net.Sockets;
using System.Runtime.InteropServices;
using System.Security.AccessControl;
using System.Security.Principal;
using System.Text;
using System.Threading;
using Microsoft.Win32;

namespace CageLocalTool
{
    internal static partial class CageLocal
    {
        private const uint LogonWithProfile = 0x00000001;
        private const uint CreateSuspended = 0x00000004;
        private const uint CreateUnicodeEnvironment = 0x00000400;
        private const uint CreateNoWindow = 0x08000000;
        private const uint ExtendedStartupInfoPresent = 0x00080000;
        private const uint StartfUseShowWindow = 0x00000001;
        private const uint StartfUseStdHandles = 0x00000100;
        private const int JobObjectBasicProcessIdList = 3;
        private const int JobObjectExtendedLimitInformation = 9;
        private const uint JobLimitKillOnJobClose = 0x00002000;

        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
        private struct StartupInfoW
        {
            public int cb;
            public string lpReserved;
            public string lpDesktop;
            public string lpTitle;
            public int dwX;
            public int dwY;
            public int dwXSize;
            public int dwYSize;
            public int dwXCountChars;
            public int dwYCountChars;
            public int dwFillAttribute;
            public int dwFlags;
            public short wShowWindow;
            public short cbReserved2;
            public IntPtr lpReserved2;
            public IntPtr hStdInput;
            public IntPtr hStdOutput;
            public IntPtr hStdError;
        }

        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
        private struct StartupInfoExW
        {
            public StartupInfoW StartupInfo;
            public IntPtr lpAttributeList;
        }

        [StructLayout(LayoutKind.Sequential)]
        private struct ProcessInformation
        {
            public IntPtr hProcess;
            public IntPtr hThread;
            public int dwProcessId;
            public int dwThreadId;
        }

        [StructLayout(LayoutKind.Sequential)]
        private struct SecurityCapabilities
        {
            public IntPtr AppContainerSid;
            public IntPtr Capabilities;
            public uint CapabilityCount;
            public uint Reserved;
        }

        [StructLayout(LayoutKind.Sequential)]
        private struct RectStruct
        {
            public int Left;
            public int Top;
            public int Right;
            public int Bottom;
        }

        [StructLayout(LayoutKind.Sequential)]
        private struct UnicodeString
        {
            public ushort Length;
            public ushort MaximumLength;
            public IntPtr Buffer;
        }

        [StructLayout(LayoutKind.Sequential)]
        private struct ObjectAttributes
        {
            public int Length;
            public IntPtr RootDirectory;
            public IntPtr ObjectName;
            public uint Attributes;
            public IntPtr SecurityDescriptor;
            public IntPtr SecurityQualityOfService;
        }

        [StructLayout(LayoutKind.Sequential)]
        private struct IoStatusBlock
        {
            public IntPtr Status;
            public IntPtr Information;
        }

        private enum NtOpenKind
        {
            OpenDirectory,
            OpenFile
        }

        private delegate bool EnumWindowsDelegate(IntPtr hwnd, IntPtr lParam);

        [DllImport("advapi32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        private static extern bool CreateProcessWithLogonW(
            string lpUsername,
            string lpDomain,
            string lpPassword,
            uint dwLogonFlags,
            string lpApplicationName,
            StringBuilder lpCommandLine,
            uint dwCreationFlags,
            IntPtr lpEnvironment,
            string lpCurrentDirectory,
            ref StartupInfoW lpStartupInfo,
            out ProcessInformation lpProcessInfo);

        [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        private static extern bool CreateProcess(
            string lpApplicationName,
            StringBuilder lpCommandLine,
            IntPtr lpProcessAttributes,
            IntPtr lpThreadAttributes,
            bool bInheritHandles,
            uint dwCreationFlags,
            IntPtr lpEnvironment,
            string lpCurrentDirectory,
            ref StartupInfoW lpStartupInfo,
            out ProcessInformation lpProcessInfo);

        [DllImport("kernel32.dll", EntryPoint = "CreateProcessW", CharSet = CharSet.Unicode, SetLastError = true)]
        private static extern bool CreateProcessEx(
            string lpApplicationName,
            StringBuilder lpCommandLine,
            IntPtr lpProcessAttributes,
            IntPtr lpThreadAttributes,
            bool bInheritHandles,
            uint dwCreationFlags,
            IntPtr lpEnvironment,
            string lpCurrentDirectory,
            ref StartupInfoExW lpStartupInfo,
            out ProcessInformation lpProcessInfo);

        [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        private static extern IntPtr CreateJobObject(IntPtr lpJobAttributes, string lpName);

        [DllImport("kernel32.dll", SetLastError = true)]
        private static extern bool SetInformationJobObject(IntPtr hJob, int infoClass, IntPtr info, uint infoLength);

        [DllImport("kernel32.dll", SetLastError = true)]
        private static extern bool AssignProcessToJobObject(IntPtr hJob, IntPtr hProcess);

        [DllImport("kernel32.dll", SetLastError = true)]
        private static extern bool QueryInformationJobObject(IntPtr hJob, int infoClass, IntPtr info, uint infoLength, out uint returnLength);

        [DllImport("kernel32.dll", SetLastError = true)]
        private static extern bool TerminateJobObject(IntPtr hJob, uint uExitCode);

        [DllImport("kernel32.dll", SetLastError = true)]
        internal static extern IntPtr OpenProcess(uint dwDesiredAccess, bool bInheritHandle, int dwProcessId);

        [DllImport("kernel32.dll", SetLastError = true)]
        private static extern bool GetNamedPipeClientProcessId(Microsoft.Win32.SafeHandles.SafePipeHandle pipe, out uint clientPid);

        [DllImport("kernel32.dll", SetLastError = true)]
        internal static extern uint WaitForSingleObject(IntPtr hHandle, uint dwMilliseconds);

        [DllImport("kernel32.dll", SetLastError = true)]
        private static extern bool GetExitCodeProcess(IntPtr hProcess, out uint lpExitCode);

        [DllImport("kernel32.dll", SetLastError = true)]
        private static extern uint ResumeThread(IntPtr hThread);

        [DllImport("kernel32.dll", SetLastError = true)]
        internal static extern bool TerminateProcess(IntPtr hProcess, uint uExitCode);

        [DllImport("kernel32.dll", SetLastError = true)]
        internal static extern bool CloseHandle(IntPtr hObject);

        [DllImport("kernel32.dll", SetLastError = true)]
        private static extern bool SetHandleInformation(IntPtr hObject, uint dwMask, uint dwFlags);

        [DllImport("kernel32.dll")]
        private static extern uint GetCurrentThreadId();

        [DllImport("kernel32.dll", SetLastError = true)]
        private static extern bool InitializeProcThreadAttributeList(IntPtr lpAttributeList, int dwAttributeCount, int dwFlags, ref IntPtr lpSize);

        [DllImport("kernel32.dll", SetLastError = true)]
        private static extern bool UpdateProcThreadAttribute(IntPtr lpAttributeList, uint dwFlags, IntPtr attribute, IntPtr lpValue, IntPtr cbSize, IntPtr lpPreviousValue, IntPtr lpReturnSize);

        [DllImport("kernel32.dll")]
        private static extern void DeleteProcThreadAttributeList(IntPtr lpAttributeList);

        [DllImport("advapi32.dll", SetLastError = true)]
        private static extern bool OpenProcessToken(IntPtr processHandle, uint desiredAccess, out IntPtr tokenHandle);

        [DllImport("advapi32.dll", SetLastError = true)]
        private static extern bool GetTokenInformation(IntPtr tokenHandle, int tokenInfoClass, IntPtr tokenInfo, int tokenInfoLength, out int returnLength);

        [DllImport("advapi32.dll")]
        private static extern IntPtr GetSidSubAuthorityCount(IntPtr pSid);

        [DllImport("advapi32.dll")]
        private static extern IntPtr GetSidSubAuthority(IntPtr pSid, uint nSubAuthority);

        [DllImport("userenv.dll", CharSet = CharSet.Unicode)]
        private static extern int CreateAppContainerProfile(string pszAppContainerName, string pszDisplayName, string pszDescription, IntPtr pCapabilities, uint dwCapabilityCount, out IntPtr ppSidAppContainerSid);

        [DllImport("userenv.dll", CharSet = CharSet.Unicode)]
        private static extern int DeleteAppContainerProfile(string pszAppContainerName);

        [DllImport("userenv.dll", CharSet = CharSet.Unicode)]
        private static extern int GetAppContainerFolderPath(string pszAppContainerSid, out IntPtr ppszPath);

        [DllImport("kernel32.dll")]
        private static extern void CoTaskMemFree(IntPtr pv);

        [DllImport("ole32.dll", EntryPoint = "CoTaskMemFree")]
        private static extern void OleCoTaskMemFree(IntPtr pv);

        [DllImport("advapi32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        private static extern bool ConvertStringSecurityDescriptorToSecurityDescriptor(string StringSecurityDescriptor, uint StringSDRevision, out IntPtr SecurityDescriptor, out uint SecurityDescriptorSize);

        [DllImport("advapi32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        private static extern bool SetFileSecurity(string lpFileName, uint SecurityInformation, IntPtr pSecurityDescriptor);

        [DllImport("advapi32.dll")]
        private static extern IntPtr FreeSid(IntPtr pSid);

        [DllImport("user32.dll")]
        private static extern IntPtr GetProcessWindowStation();

        [DllImport("user32.dll")]
        private static extern IntPtr GetThreadDesktop(uint dwThreadId);

        [DllImport("user32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        private static extern IntPtr CreateDesktop(string lpszDesktop, IntPtr lpszDevice, IntPtr pDevmode, uint dwFlags, uint dwDesiredAccess, IntPtr lpsa);

        [DllImport("user32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        private static extern IntPtr OpenDesktop(string lpszDesktop, uint dwFlags, bool fInherit, uint dwDesiredAccess);

        [DllImport("user32.dll", SetLastError = true)]
        private static extern bool CloseDesktop(IntPtr hDesktop);

        [DllImport("user32.dll", SetLastError = true)]
        private static extern bool GetUserObjectSecurity(IntPtr hObj, ref uint pSIRequested, byte[] pSID, uint nLength, out uint lpnLengthNeeded);

        [DllImport("user32.dll", SetLastError = true)]
        private static extern bool SetUserObjectSecurity(IntPtr hObj, ref uint pSIRequested, byte[] pSID);

        [DllImport("user32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        private static extern bool GetUserObjectInformation(IntPtr hObj, int nIndex, StringBuilder pvInfo, int nLength, out int lpnLengthNeeded);

        [DllImport("user32.dll", SetLastError = true)]
        private static extern bool EnumDesktopWindows(IntPtr hDesktop, EnumWindowsDelegate lpfn, IntPtr lParam);

        [DllImport("user32.dll")]
        private static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);

        [DllImport("user32.dll", CharSet = CharSet.Unicode)]
        private static extern int GetClassName(IntPtr hWnd, StringBuilder lpClassName, int nMaxCount);

        [DllImport("user32.dll", CharSet = CharSet.Unicode)]
        private static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);

        [DllImport("user32.dll")]
        private static extern bool IsWindowVisible(IntPtr hWnd);

        [DllImport("user32.dll")]
        private static extern bool GetWindowRect(IntPtr hWnd, out RectStruct lpRect);

        [DllImport("wininet.dll", SetLastError = true)]
        private static extern bool InternetSetOption(IntPtr hInternet, int dwOption, IntPtr lpBuffer, int dwBufferLength);

        [DllImport("ntdll.dll")]
        private static extern int NtOpenDirectoryObject(out IntPtr DirectoryHandle, uint DesiredAccess, ref ObjectAttributes ObjectAttributes);

        [DllImport("ntdll.dll")]
        private static extern int NtOpenFile(
            out IntPtr FileHandle,
            uint DesiredAccess,
            ref ObjectAttributes ObjectAttributes,
            out IoStatusBlock IoStatusBlock,
            uint ShareAccess,
            uint OpenOptions);

        [DllImport("ntdll.dll")]
        private static extern int NtQuerySecurityObject(IntPtr Handle, uint SecurityInformation, byte[] SecurityDescriptor, uint Length, out uint LengthNeeded);

        [DllImport("ntdll.dll")]
        private static extern int NtSetSecurityObject(IntPtr Handle, uint SecurityInformation, byte[] SecurityDescriptor);

        [DllImport("ntdll.dll")]
        private static extern int RtlNtStatusToDosError(int Status);

        private static void CheckWin32(bool ok, string op)
        {
            if (!ok)
            {
                int err = Marshal.GetLastWin32Error();
                throw new Win32Exception(err, string.Format("{0} failed (win32={1})", op, err));
            }
        }

        internal static string QueryProcessUserSid(IntPtr hProcess)
        {
            return QueryTokenSidAtOffset(hProcess, 1 /* TokenUser */, 0, false, null);
        }

        internal static string QueryProcessLogonSid(IntPtr hProcess)
        {
            string logonSid = QueryTokenSidAtOffset(hProcess, 28 /* TokenLogonSid */, IntPtr.Size, true, null);
            if (!string.IsNullOrEmpty(logonSid))
            {
                return logonSid;
            }
            return QueryTokenSidAtOffset(hProcess, 2 /* TokenGroups */, IntPtr.Size, true, "S-1-5-5-");
        }

        private static string QueryTokenSidAtOffset(IntPtr hProcess, int tokenClass, int sidOffset, bool checkGroupCount, string requiredPrefix)
        {
            IntPtr token;
            if (!OpenProcessToken(hProcess, 0x0008 /* TOKEN_QUERY */, out token))
            {
                return null;
            }
            try
            {
                int needed;
                GetTokenInformation(token, tokenClass, IntPtr.Zero, 0, out needed);
                if (needed <= sidOffset || needed > 4096)
                {
                    return null;
                }
                IntPtr buf = Marshal.AllocHGlobal(needed);
                try
                {
                    int used;
                    if (!GetTokenInformation(token, tokenClass, buf, needed, out used))
                    {
                        return null;
                    }
                    int count = checkGroupCount ? Marshal.ReadInt32(buf, 0) : 1;
                    if (count < 1)
                    {
                        return null;
                    }
                    if (string.IsNullOrEmpty(requiredPrefix))
                    {
                        IntPtr pSid = Marshal.ReadIntPtr(buf, sidOffset);
                        return pSid == IntPtr.Zero ? null : new SecurityIdentifier(pSid).Value;
                    }
                    int entrySize = IntPtr.Size * 2;
                    for (int i = 0; i < count && sidOffset + i * entrySize + IntPtr.Size <= used; i++)
                    {
                        IntPtr pSid = Marshal.ReadIntPtr(buf, sidOffset + i * entrySize);
                        if (pSid == IntPtr.Zero)
                        {
                            continue;
                        }
                        string val = new SecurityIdentifier(pSid).Value;
                        if (val.StartsWith(requiredPrefix, StringComparison.Ordinal))
                        {
                            return val;
                        }
                    }
                    return null;
                }
                finally
                {
                    Marshal.FreeHGlobal(buf);
                }
            }
            finally
            {
                CloseHandle(token);
            }
        }

        private static Dictionary<string, object> InspectToken(IntPtr hProcess)
        {
            IntPtr token;
            CheckWin32(OpenProcessToken(hProcess, 0x0008 /* TOKEN_QUERY */, out token), "OpenProcessToken");
            try
            {
                Dictionary<string, object> info = new Dictionary<string, object>();
                info["userSid"] = QueryProcessUserSid(hProcess);

                IntPtr buf = Marshal.AllocHGlobal(4096);
                try
                {
                    int used;
                    CheckWin32(GetTokenInformation(token, 29 /* TokenIsAppContainer */, buf, 4096, out used), "TokenIsAppContainer");
                    info["isAppContainer"] = (Marshal.ReadInt32(buf) != 0);

                    CheckWin32(GetTokenInformation(token, 30 /* TokenCapabilities */, buf, 4096, out used), "TokenCapabilities");
                    info["capabilityCount"] = Marshal.ReadInt32(buf);

                    CheckWin32(GetTokenInformation(token, 31 /* TokenAppContainerSid */, buf, 4096, out used), "TokenAppContainerSid");
                    IntPtr pkgSid = Marshal.ReadIntPtr(buf);
                    info["appContainerSid"] = pkgSid == IntPtr.Zero ? "" : new SecurityIdentifier(pkgSid).Value;

                    CheckWin32(GetTokenInformation(token, 25 /* TokenIntegrityLevel */, buf, 4096, out used), "TokenIntegrityLevel");
                    IntPtr ilSid = Marshal.ReadIntPtr(buf);
                    IntPtr countPtr = GetSidSubAuthorityCount(ilSid);
                    byte subCount = Marshal.ReadByte(countPtr);
                    uint rid = unchecked((uint)Marshal.ReadInt32(GetSidSubAuthority(ilSid, (uint)(subCount - 1))));
                    info["integrityRid"] = string.Format("0x{0:x}", rid);
                    info["integrityLabel"] = rid >= 0x3000 ? "High+" : (rid >= 0x2000 ? "Medium" : "Low");
                }
                finally
                {
                    Marshal.FreeHGlobal(buf);
                }
                return info;
            }
            finally
            {
                CloseHandle(token);
            }
        }

        private static IntPtr CreateKillOnCloseJob()
        {
            IntPtr job = CreateJobObject(IntPtr.Zero, null);
            CheckWin32(job != IntPtr.Zero, "CreateJobObject");
            IntPtr limits = Marshal.AllocHGlobal(144);
            try
            {
                byte[] zeros = new byte[144];
                Marshal.Copy(zeros, 0, limits, 144);
                Marshal.WriteInt32(limits, 16, unchecked((int)JobLimitKillOnJobClose));
                CheckWin32(SetInformationJobObject(job, JobObjectExtendedLimitInformation, limits, 144), "SetInformationJobObject");
                return job;
            }
            catch
            {
                CloseHandle(job);
                throw;
            }
            finally
            {
                Marshal.FreeHGlobal(limits);
            }
        }

        internal static List<int> QueryJobPids(IntPtr hJob)
        {
            List<int> pids = new List<int>();
            if (hJob == IntPtr.Zero)
            {
                return pids;
            }
            const int maxCount = 512;
            uint len = (uint)(8 + maxCount * IntPtr.Size);
            IntPtr buf = Marshal.AllocHGlobal((int)len);
            try
            {
                uint retLen;
                if (!QueryInformationJobObject(hJob, JobObjectBasicProcessIdList, buf, len, out retLen))
                {
                    return pids;
                }
                int inList = Marshal.ReadInt32(buf, 4);
                for (int i = 0; i < inList && i < maxCount; i++)
                {
                    long pidVal = Marshal.ReadIntPtr(buf, 8 + i * IntPtr.Size).ToInt64();
                    if (pidVal > 0 && pidVal <= int.MaxValue)
                    {
                        pids.Add((int)pidVal);
                    }
                }
                return pids;
            }
            finally
            {
                Marshal.FreeHGlobal(buf);
            }
        }

        private static void WaitForJobDrain(IntPtr hJob, int maxWaitMs)
        {
            if (hJob == IntPtr.Zero)
            {
                return;
            }
            TerminateJobObject(hJob, 1);
            Stopwatch drainSw = Stopwatch.StartNew();
            while (drainSw.ElapsedMilliseconds < maxWaitMs)
            {
                if (QueryJobPids(hJob).Count == 0)
                {
                    break;
                }
                Thread.Sleep(50);
            }
        }

        private static byte[] GetObjectDacl(IntPtr hObj)
        {
            uint si = 4; // DACL_SECURITY_INFORMATION
            uint needed = 0;
            GetUserObjectSecurity(hObj, ref si, null, 0, out needed);
            if (needed == 0)
            {
                throw new Win32Exception(Marshal.GetLastWin32Error(), "GetUserObjectSecurity size query failed");
            }
            byte[] buf = new byte[needed];
            CheckWin32(GetUserObjectSecurity(hObj, ref si, buf, needed, out needed), "GetUserObjectSecurity");
            return buf;
        }

        private static void SetObjectDacl(IntPtr hObj, byte[] sdBytes)
        {
            uint si = 4; // DACL_SECURITY_INFORMATION
            CheckWin32(SetUserObjectSecurity(hObj, ref si, sdBytes), "SetUserObjectSecurity");
        }

        private static byte[] GrantWinStaWorkerAccess(IntPtr hWinSta, string workerSid)
        {
            byte[] originalBytes = GetObjectDacl(hWinSta);
            RawSecurityDescriptor sd = new RawSecurityDescriptor(originalBytes, 0);
            // Grant non-clipboard WinSta0 access to workerSid: 0x2037B omits WINSTA_ACCESSCLIPBOARD (0x4) and WINSTA_CREATEDESKTOP (0x8).
            sd.DiscretionaryAcl.InsertAce(0, new CommonAce(
                AceFlags.None,
                AceQualifier.AccessAllowed,
                0x0002037B,
                new SecurityIdentifier(workerSid),
                false,
                null));
            byte[] updated = new byte[sd.BinaryLength];
            sd.GetBinaryForm(updated, 0);
            SetObjectDacl(hWinSta, updated);
            return originalBytes;
        }

        private static void GrantDesktopWorkerAccess(IntPtr hDesk, string sidStr)
        {
            byte[] originalBytes = GetObjectDacl(hDesk);
            RawSecurityDescriptor sd = new RawSecurityDescriptor(originalBytes, 0);
            if (sd.DiscretionaryAcl != null)
            {
                sd.DiscretionaryAcl.InsertAce(0, new CommonAce(
                    AceFlags.None,
                    AceQualifier.AccessAllowed,
                    0x000F01FF,
                    new SecurityIdentifier(sidStr),
                    false,
                    null));
                byte[] updated = new byte[sd.BinaryLength];
                sd.GetBinaryForm(updated, 0);
                SetObjectDacl(hDesk, updated);
            }
        }

        private static int TryNtObject(string objectPath, IntPtr rootDirectory, uint desiredAccess, NtOpenKind kind, uint shareAccess, uint openOptions, out IntPtr handle)
        {
            IntPtr strPtr = IntPtr.Zero;
            IntPtr usPtr = IntPtr.Zero;
            try
            {
                strPtr = Marshal.StringToHGlobalUni(objectPath);
                UnicodeString us = new UnicodeString();
                us.Length = checked((ushort)(objectPath.Length * 2));
                us.MaximumLength = checked((ushort)((objectPath.Length + 1) * 2));
                us.Buffer = strPtr;
                usPtr = Marshal.AllocHGlobal(Marshal.SizeOf(typeof(UnicodeString)));
                Marshal.StructureToPtr(us, usPtr, false);

                ObjectAttributes oa = new ObjectAttributes();
                oa.Length = Marshal.SizeOf(typeof(ObjectAttributes));
                oa.RootDirectory = rootDirectory;
                oa.ObjectName = usPtr;
                oa.Attributes = 0x00000040; // OBJ_CASE_INSENSITIVE
                oa.SecurityDescriptor = IntPtr.Zero;
                oa.SecurityQualityOfService = IntPtr.Zero;

                if (kind == NtOpenKind.OpenFile)
                {
                    IoStatusBlock iosb;
                    return NtOpenFile(out handle, desiredAccess, ref oa, out iosb, shareAccess, openOptions);
                }
                return NtOpenDirectoryObject(out handle, desiredAccess, ref oa);
            }
            finally
            {
                if (usPtr != IntPtr.Zero) Marshal.FreeHGlobal(usPtr);
                if (strPtr != IntPtr.Zero) Marshal.FreeHGlobal(strPtr);
            }
        }

        private static IntPtr OpenNtDirectoryObject(string objectPath, uint desiredAccess)
        {
            IntPtr hDir;
            int status = TryNtObject(objectPath, IntPtr.Zero, desiredAccess, NtOpenKind.OpenDirectory, 0, 0, out hDir);
            if (status != 0)
            {
                throw new Win32Exception(RtlNtStatusToDosError(status), string.Format("NtOpenDirectoryObject({0}) failed (ntstatus=0x{1:x8})", objectPath, status));
            }
            return hDir;
        }

        private static IntPtr OpenNtFileObject(string objectPath, uint desiredAccess, uint shareAccess, uint openOptions)
        {
            IntPtr hFile;
            int status = TryNtObject(objectPath, IntPtr.Zero, desiredAccess, NtOpenKind.OpenFile, shareAccess, openOptions, out hFile);
            if (status != 0)
            {
                throw new Win32Exception(RtlNtStatusToDosError(status), string.Format("NtOpenFile({0}) failed (ntstatus=0x{1:x8})", objectPath, status));
            }
            return hFile;
        }

        private static byte[] GetNtObjectDacl(IntPtr hObj)
        {
            uint needed = 0;
            int status = NtQuerySecurityObject(hObj, 4 /* DACL_SECURITY_INFORMATION */, null, 0, out needed);
            if (needed == 0)
            {
                throw new Win32Exception(RtlNtStatusToDosError(status), string.Format("NtQuerySecurityObject size query failed (ntstatus=0x{0:x8})", status));
            }
            byte[] buf = new byte[needed];
            status = NtQuerySecurityObject(hObj, 4 /* DACL_SECURITY_INFORMATION */, buf, needed, out needed);
            if (status != 0)
            {
                throw new Win32Exception(RtlNtStatusToDosError(status), string.Format("NtQuerySecurityObject failed (ntstatus=0x{0:x8})", status));
            }
            return buf;
        }

        private static void SetNtObjectDacl(IntPtr hObj, byte[] sdBytes)
        {
            int status = NtSetSecurityObject(hObj, 4 /* DACL_SECURITY_INFORMATION */, sdBytes);
            if (status != 0)
            {
                throw new Win32Exception(RtlNtStatusToDosError(status), string.Format("NtSetSecurityObject failed (ntstatus=0x{0:x8})", status));
            }
        }

        private static byte[] GrantNtObjectWorkerAccess(IntPtr hObj, string sidStr, int directAccessMask)
        {
            byte[] originalBytes = GetNtObjectDacl(hObj);
            RawSecurityDescriptor sd = new RawSecurityDescriptor(originalBytes, 0);
            if (sd.DiscretionaryAcl == null)
            {
                throw new InvalidOperationException("Session object DACL is null.");
            }
            SecurityIdentifier sid = new SecurityIdentifier(sidStr);
            sd.DiscretionaryAcl.InsertAce(0, new CommonAce(
                AceFlags.None,
                AceQualifier.AccessAllowed,
                directAccessMask,
                sid,
                false,
                null));
            sd.DiscretionaryAcl.InsertAce(0, new CommonAce(
                AceFlags.ObjectInherit | AceFlags.ContainerInherit | AceFlags.InheritOnly,
                AceQualifier.AccessAllowed,
                0x10000000,
                sid,
                false,
                null));
            byte[] updated = new byte[sd.BinaryLength];
            sd.GetBinaryForm(updated, 0);
            SetNtObjectDacl(hObj, updated);
            return originalBytes;
        }

        private static void RestoreAndCloseNtObject(IntPtr handle, byte[] originalDacl)
        {
            if (handle == IntPtr.Zero)
            {
                return;
            }
            try
            {
                if (originalDacl != null)
                {
                    SetNtObjectDacl(handle, originalDacl);
                }
            }
            catch
            {
            }
            finally
            {
                try { CloseHandle(handle); } catch { }
            }
        }

        private static void SetLowMandatoryLabelOnDirectory(string path)
        {
            IntPtr sd;
            uint size;
            CheckWin32(ConvertStringSecurityDescriptorToSecurityDescriptor("S:(ML;OICI;NW;;;LW)", 1, out sd, out size), "ConvertStringSecurityDescriptorToSecurityDescriptor(dir)");
            try
            {
                CheckWin32(SetFileSecurity(path, 0x10 /* LABEL_SECURITY_INFORMATION */, sd), "SetFileSecurity(LowLabel)");
            }
            finally
            {
                LocalFree(sd);
            }
        }

        private static IntPtr CreatePrivateDesktopForWorker(string desktopName, string controllerSid, string workerSid)
        {
            IntPtr hDesk = CreateDesktop(desktopName, IntPtr.Zero, IntPtr.Zero, 0, 0x000F01FF /* DESKTOP_ALL_ACCESS */, IntPtr.Zero);
            CheckWin32(hDesk != IntPtr.Zero, "CreateDesktop(" + desktopName + ")");
            try
            {
                byte[] bytes = GetObjectDacl(hDesk);
                RawSecurityDescriptor sd = new RawSecurityDescriptor(bytes, 0);
                string[] fullGrantees = new string[]
                {
                    WellKnownSystemSid,
                    controllerSid,
                    workerSid,
                    "S-1-5-12",
                    WellKnownAllPackagesSid,
                    "S-1-15-2-2"
                };
                for (int i = 0; i < fullGrantees.Length; i++)
                {
                    sd.DiscretionaryAcl.InsertAce(0, new CommonAce(
                        AceFlags.None,
                        AceQualifier.AccessAllowed,
                        0x000F01FF,
                        new SecurityIdentifier(fullGrantees[i]),
                        false,
                        null));
                }
                byte[] updated = new byte[sd.BinaryLength];
                sd.GetBinaryForm(updated, 0);
                SetObjectDacl(hDesk, updated);

                // Allow Low-integrity Ring-2 AppContainer processes to attach to this private desktop.
                RawSecurityDescriptor labelSd = new RawSecurityDescriptor("S:(ML;;NW;;;LW)");
                byte[] labelBytes = new byte[labelSd.BinaryLength];
                labelSd.GetBinaryForm(labelBytes, 0);
                uint labelInfo = 16; // LABEL_SECURITY_INFORMATION
                CheckWin32(SetUserObjectSecurity(hDesk, ref labelInfo, labelBytes), "SetUserObjectSecurity(DesktopLowLabel)");

                return hDesk;
            }
            catch
            {
                CloseDesktop(hDesk);
                throw;
            }
        }

        private static string GetDesktopName(IntPtr hDesk)
        {
            if (hDesk == IntPtr.Zero)
            {
                return "";
            }
            StringBuilder sb = new StringBuilder(256);
            int needed;
            if (!GetUserObjectInformation(hDesk, 2 /* UOI_NAME */, sb, sb.Capacity * 2, out needed))
            {
                return "";
            }
            return sb.ToString();
        }

        private static IntPtr AllocUnicodeEnvBlock(SortedDictionary<string, string> vars)
        {
            StringBuilder sb = new StringBuilder();
            foreach (KeyValuePair<string, string> kv in vars)
            {
                sb.Append(kv.Key).Append('=').Append(kv.Value).Append('\0');
            }
            sb.Append('\0');
            return Marshal.StringToHGlobalUni(sb.ToString());
        }

        private static SortedDictionary<string, string> BuildWorkerEnv(
            string profileDir,
            string appDataDir,
            string localAppDataDir,
            string tempDir,
            int brokerPort,
            string timezoneIana,
            string extraPathPrefix,
            Dictionary<string, string> extraVars)
        {
            string winDir = Environment.GetFolderPath(Environment.SpecialFolder.Windows);
            string sysDir = Environment.SystemDirectory;
            string proxyUrl = string.Format("http://127.0.0.1:{0}", brokerPort);
            string basePath = sysDir + ";" + winDir + ";" + Path.Combine(sysDir, "WindowsPowerShell", "v1.0");
            if (!string.IsNullOrEmpty(extraPathPrefix))
            {
                basePath = extraPathPrefix + ";" + basePath;
            }

            SortedDictionary<string, string> vars = new SortedDictionary<string, string>(StringComparer.OrdinalIgnoreCase);
            vars["SystemRoot"] = winDir;
            vars["WINDIR"] = winDir;
            vars["SystemDrive"] = Path.GetPathRoot(sysDir).TrimEnd('\\');
            vars["COMSPEC"] = Path.Combine(sysDir, "cmd.exe");
            vars["PATHEXT"] = ".COM;.EXE;.BAT;.CMD";
            vars["PATH"] = basePath;
            vars["USERPROFILE"] = profileDir;
            vars["HOME"] = profileDir;
            vars["APPDATA"] = appDataDir;
            vars["LOCALAPPDATA"] = localAppDataDir;
            vars["TEMP"] = tempDir;
            vars["TMP"] = tempDir;
            vars["TZ"] = string.IsNullOrEmpty(timezoneIana) ? "Asia/Tokyo" : timezoneIana;
            vars["HTTP_PROXY"] = proxyUrl;
            vars["HTTPS_PROXY"] = proxyUrl;
            vars["ALL_PROXY"] = proxyUrl;
            vars["NO_PROXY"] = "";
            vars["NODE_USE_ENV_PROXY"] = "1";
            vars["PYTHONUTF8"] = "1";
            vars["PYTHONDONTWRITEBYTECODE"] = "1";
            if (extraVars != null)
            {
                foreach (KeyValuePair<string, string> kv in extraVars)
                {
                    vars[kv.Key] = kv.Value;
                }
            }
            return vars;
        }

        // ==================== WORKER DAEMON SIDE ====================

        internal static int WorkerDaemonCommand(string[] args)
        {
            if (args.Length < 6)
            {
                throw new InvalidDataException("worker-daemon requires <pipeName> <secretHex> <brokerPort> <desktopName> <timezoneIana>");
            }
            string pipeName = args[1];
            string secretHex = args[2];
            int brokerPort = int.Parse(args[3]);
            string expectedDesktop = args[4];
            string timezoneIana = args[5];

            string profileDir = Environment.GetFolderPath(Environment.SpecialFolder.UserProfile);
            string appDataDir = Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData);
            string localAppDataDir = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
            string tempDir = Path.Combine(localAppDataDir, "Temp");
            Directory.CreateDirectory(tempDir);

            // Configure isolated per-user WinINET proxy in this worker's HKCU hive.
            using (RegistryKey internetSettings = Registry.CurrentUser.CreateSubKey(@"Software\Microsoft\Windows\CurrentVersion\Internet Settings"))
            {
                if (internetSettings == null)
                {
                    throw new InvalidOperationException("Unable to open worker HKCU Internet Settings.");
                }
                internetSettings.SetValue("ProxyEnable", 1, RegistryValueKind.DWord);
                internetSettings.SetValue("ProxyServer", string.Format("127.0.0.1:{0}", brokerPort), RegistryValueKind.String);
                internetSettings.SetValue("ProxyOverride", "", RegistryValueKind.String);
            }
            InternetSetOption(IntPtr.Zero, 39 /* INTERNET_OPTION_SETTINGS_CHANGED */, IntPtr.Zero, 0);
            InternetSetOption(IntPtr.Zero, 37 /* INTERNET_OPTION_REFRESH */, IntPtr.Zero, 0);

            Dictionary<string, object> selfToken = InspectToken(Process.GetCurrentProcess().Handle);
            string actualDesktop = GetDesktopName(GetThreadDesktop(GetCurrentThreadId()));

            using (NamedPipeClientStream pipe = new NamedPipeClientStream(".", pipeName, PipeDirection.InOut))
            {
                pipe.Connect(15000);
                using (StreamReader reader = new StreamReader(pipe, Utf8NoBom, false, 65536, true))
                using (StreamWriter writer = new StreamWriter(pipe, Utf8NoBom, 65536, true))
                using (WorkerTabCollection tabs = new WorkerTabCollection())
                {
                    writer.AutoFlush = true;
                    string selfLogonSid = QueryProcessLogonSid(Process.GetCurrentProcess().Handle);
                    Dictionary<string, object> hello = new Dictionary<string, object>();
                    hello["auth"] = secretHex;
                    hello["pid"] = Process.GetCurrentProcess().Id;
                    hello["userSid"] = selfToken["userSid"];
                    hello["logonSid"] = selfLogonSid ?? "";
                    hello["desktop"] = actualDesktop;
                    hello["expectedDesktop"] = expectedDesktop;
                    hello["userProfile"] = profileDir;
                    writer.WriteLine(ToJson(hello));

                    string ackLine = reader.ReadLine();
                    if (string.IsNullOrEmpty(ackLine))
                    {
                        throw new EndOfStreamException("Controller closed pipe during handshake.");
                    }
                    Dictionary<string, object> ack = FromJsonObject(ackLine);
                    if (!ack.ContainsKey("ok") || !(bool)ack["ok"])
                    {
                        throw new InvalidOperationException("Controller rejected worker handshake.");
                    }

                    while (true)
                    {
                        string reqLine = reader.ReadLine();
                        if (reqLine == null)
                        {
                            break;
                        }
                        if (reqLine.Length == 0)
                        {
                            continue;
                        }
                        Dictionary<string, object> req = FromJsonObject(reqLine);
                        string id = req.ContainsKey("id") ? Convert.ToString(req["id"]) : "";
                        string op = req.ContainsKey("op") ? Convert.ToString(req["op"]) : "";
                        Dictionary<string, object> resp = new Dictionary<string, object>();
                        resp["id"] = id;
                        try
                        {
                            string channel = req.ContainsKey("channel") ? (string)req["channel"] : "";
                            WorkerTab tab = tabs.Get(channel, op);
                            if (op == "shutdown")
                            {
                                resp["ok"] = true;
                                writer.WriteLine(ToJson(resp));
                                break;
                            }
                            else if (op == "inspect")
                            {
                                resp["ok"] = true;
                                resp["result"] = WorkerInspect(selfToken, actualDesktop, profileDir, appDataDir, localAppDataDir, brokerPort, timezoneIana);
                            }
                            else if (op == "probe-boundaries")
                            {
                                resp["ok"] = true;
                                resp["result"] = WorkerProbeBoundaries(req, brokerPort);
                            }
                            else if (op == "probe-network-http")
                            {
                                resp["ok"] = true;
                                resp["result"] = WorkerProbeHttpProxy(req, brokerPort);
                            }
                            else if (op == "exec")
                            {
                                resp["ok"] = true;
                                resp["result"] = WorkerExec(req, profileDir, appDataDir, localAppDataDir, tempDir, brokerPort, timezoneIana, actualDesktop);
                            }
                            else if (op == "ring2-exec")
                            {
                                resp["ok"] = true;
                                resp["result"] = WorkerRing2Exec(req, localAppDataDir, brokerPort, timezoneIana, actualDesktop);
                            }
                            else if (op == "app-open")
                            {
                                resp["result"] = tab.App.Open(req, profileDir, appDataDir, localAppDataDir, tempDir, brokerPort, timezoneIana, actualDesktop, (string)selfToken["userSid"]);
                                resp["ok"] = true;
                            }
                            else if (op == "app-frame" || op == "app-input")
                            {
                                resp["result"] = op == "app-frame" ? tab.App.Frame() : tab.App.Input(req);
                                resp["ok"] = true;
                            }
                            else if (op == "service-open")
                            {
                                tab.Services.Open((string)req["service"], profileDir, appDataDir, localAppDataDir, tempDir, brokerPort, timezoneIana);
                                resp["ok"] = true;
                            }
                            else if (op == "service-action")
                            {
                                resp["result"] = tab.Services.Action(req);
                                resp["ok"] = true;
                            }
                            else if (op == "terminal-open")
                            {
                                resp["result"] = tab.Terminal.Open(profileDir, appDataDir, localAppDataDir, brokerPort, timezoneIana, actualDesktop,
                                    (string)selfToken["userSid"], req.ContainsKey("project") ? (string)req["project"] : null,
                                    req.ContainsKey("kind") ? req : null);
                                resp["ok"] = true;
                            }
                            else if (op == "browser-close")
                            {
                                tab.Browser.Dispose();
                                resp["ok"] = true;
                            }
                            else if (op == "browser-open" || op == "browser-action")
                            {
                                resp["result"] = op == "browser-open"
                                    ? tab.Browser.Open(profileDir, appDataDir, localAppDataDir, brokerPort, timezoneIana, actualDesktop,
                                        req.ContainsKey("signIn") && Object.Equals(req["signIn"], true), req.ContainsKey("service") && Object.Equals(req["service"], "tailnet"))
                                    : tab.Browser.Action(req);
                                resp["ok"] = true;
                            }
                            else if (op == "terminal-read")
                            {
                                resp["result"] = tab.Terminal.Read();
                                resp["ok"] = true;
                            }
                            else if (op == "terminal-resize")
                            {
                                tab.Terminal.Resize(Convert.ToInt32(req["cols"]), Convert.ToInt32(req["rows"]));
                                resp["ok"] = true;
                            }
                            else if (op == "terminal-input")
                            {
                                tab.Terminal.Input((string)req["text"]);
                                resp["ok"] = true;
                            }
                            else if (op == "tab-create" || op == "tab-close")
                            {
                                if (op == "tab-close") tabs.Close(channel);
                                resp["ok"] = true;
                            }
                            else
                            {
                                resp["ok"] = false;
                                resp["error"] = "Unknown operation: " + op;
                            }
                        }
                        catch (Exception ex)
                        {
                            resp["ok"] = false;
                            resp["error"] = ex.GetType().Name + ": " + ex.Message;
                        }
                        writer.WriteLine(ToJson(resp));
                    }
                }
            }
            return 0;
        }

        private static Dictionary<string, object> WorkerInspect(
            Dictionary<string, object> selfToken,
            string desktopName,
            string profileDir,
            string appDataDir,
            string localAppDataDir,
            int brokerPort,
            string timezoneIana)
        {
            Dictionary<string, object> r = new Dictionary<string, object>();
            r["token"] = selfToken;
            r["username"] = Environment.UserName;
            r["sessionId"] = Process.GetCurrentProcess().SessionId;
            r["desktop"] = desktopName;
            r["userProfile"] = profileDir;
            r["appData"] = appDataDir;
            r["localAppData"] = localAppDataDir;
            r["tzEnv"] = Environment.GetEnvironmentVariable("TZ");
            r["expectedTz"] = timezoneIana;
            r["brokerPort"] = brokerPort;

            using (RegistryKey key = Registry.CurrentUser.OpenSubKey(@"Software\Microsoft\Windows\CurrentVersion\Internet Settings", false))
            {
                r["hkcuProxyEnable"] = key != null ? key.GetValue("ProxyEnable") : null;
                r["hkcuProxyServer"] = key != null ? key.GetValue("ProxyServer") : null;
            }
            return r;
        }

        private static int ProbeFileReadAccess(string path)
        {
            try
            {
                using (FileStream fs = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.ReadWrite))
                {
                    byte[] b = new byte[16];
                    fs.Read(b, 0, b.Length);
                    return 0;
                }
            }
            catch (UnauthorizedAccessException)
            {
                return 5;
            }
            catch (System.Security.SecurityException)
            {
                return 5;
            }
            catch (IOException ex)
            {
                return ex.HResult & 0xFFFF;
            }
        }

        private static int ProbeDirectoryListAccess(string path)
        {
            try
            {
                Directory.GetFileSystemEntries(path);
                return 0;
            }
            catch (UnauthorizedAccessException)
            {
                return 5;
            }
            catch (IOException ex)
            {
                return ex.HResult & 0xFFFF;
            }
        }

        private static int ProbeTcpConnect(string ipText, int port, int timeoutMs)
        {
            try
            {
                IPAddress addr = IPAddress.Parse(ipText);
                using (Socket sock = new Socket(addr.AddressFamily, SocketType.Stream, ProtocolType.Tcp))
                {
                    IAsyncResult ar = sock.BeginConnect(addr, port, null, null);
                    if (!ar.AsyncWaitHandle.WaitOne(timeoutMs))
                    {
                        return 10060;
                    }
                    sock.EndConnect(ar);
                    return 0;
                }
            }
            catch (SocketException ex)
            {
                return ex.NativeErrorCode;
            }
        }

        private static int ProbeUdpSend(string ipText, int port)
        {
            try
            {
                IPAddress addr = IPAddress.Parse(ipText);
                using (Socket sock = new Socket(addr.AddressFamily, SocketType.Dgram, ProtocolType.Udp))
                {
                    IPAddress bindAddr = addr.AddressFamily == AddressFamily.InterNetworkV6 ? IPAddress.IPv6Any : IPAddress.Any;
                    sock.Bind(new IPEndPoint(bindAddr, 0));
                    sock.Connect(new IPEndPoint(addr, port));
                    sock.Send(new byte[] { 0x12, 0x34, 0x01, 0x00 });
                    return 0;
                }
            }
            catch (SocketException ex)
            {
                return ex.NativeErrorCode;
            }
        }

        private static Dictionary<string, object> WorkerProbeHttpProxy(Dictionary<string, object> req, int brokerPort)
        {
            string url = req.ContainsKey("url") ? Convert.ToString(req["url"]) : "http://cage-test.internal/ok";
            Uri uri = new Uri(url);
            Dictionary<string, object> r = new Dictionary<string, object>();
            try
            {
                using (TcpClient client = new TcpClient())
                {
                    client.ReceiveTimeout = 5000;
                    client.SendTimeout = 5000;
                    client.Connect(IPAddress.Loopback, brokerPort);
                    using (NetworkStream stream = client.GetStream())
                    {
                        string requestText = string.Format(
                            "GET {0} HTTP/1.1\r\nHost: {1}\r\nConnection: close\r\n\r\n",
                            uri.AbsoluteUri,
                            uri.Authority);
                        byte[] outBytes = Encoding.ASCII.GetBytes(requestText);
                        stream.Write(outBytes, 0, outBytes.Length);
                        stream.Flush();
                        using (MemoryStream ms = new MemoryStream())
                        {
                            byte[] buf = new byte[4096];
                            int n;
                            while ((n = stream.Read(buf, 0, buf.Length)) > 0)
                            {
                                ms.Write(buf, 0, n);
                            }
                            string raw = Utf8NoBom.GetString(ms.ToArray());
                            r["connected"] = true;
                            r["rawResponse"] = raw;
                            int spaceIdx = raw.IndexOf(' ');
                            int statusCode = 0;
                            if (spaceIdx > 0 && raw.Length >= spaceIdx + 4)
                            {
                                int.TryParse(raw.Substring(spaceIdx + 1, 3), out statusCode);
                            }
                            r["statusCode"] = statusCode;
                        }
                    }
                }
            }
            catch (SocketException ex)
            {
                r["connected"] = false;
                r["socketError"] = ex.NativeErrorCode;
            }
            catch (Exception ex)
            {
                r["connected"] = false;
                r["error"] = ex.GetType().Name + ": " + ex.Message;
            }
            return r;
        }

        private static Dictionary<string, object> WorkerProbeBoundaries(Dictionary<string, object> req, int brokerPort)
        {
            string hostUserDir = Convert.ToString(req["hostUserProfile"]);
            string hostPrivateFile = Convert.ToString(req["hostPrivateFile"]);
            string credentialFile = Convert.ToString(req["credentialFile"]);
            string sharedRwDir = Convert.ToString(req["sharedRwDir"]);
            string sharedRoDir = Convert.ToString(req["sharedRoDir"]);
            int hostPrivatePort = Convert.ToInt32(req["hostPrivatePort"]);

            Dictionary<string, object> r = new Dictionary<string, object>();
            r["hostUserListCode"] = ProbeDirectoryListAccess(hostUserDir);
            r["hostPrivateFileReadCode"] = ProbeFileReadAccess(hostPrivateFile);
            r["credentialFileReadCode"] = ProbeFileReadAccess(credentialFile);

            string rwReadText = File.ReadAllText(Path.Combine(sharedRwDir, "host-rw.txt"), Utf8NoBom);
            string rwWrittenPath = Path.Combine(sharedRwDir, "worker-write.txt");
            File.WriteAllText(rwWrittenPath, "CAGE_LOCAL_WORKER_WRITE", Utf8NoBom);
            r["sharedRwReadOk"] = (rwReadText == "HOST_RW_FIXTURE");
            r["sharedRwWriteOk"] = (File.ReadAllText(rwWrittenPath, Utf8NoBom) == "CAGE_LOCAL_WORKER_WRITE");

            string roReadText = File.ReadAllText(Path.Combine(sharedRoDir, "host-ro.txt"), Utf8NoBom);
            r["sharedRoReadOk"] = (roReadText == "HOST_RO_FIXTURE");
            int roWriteCode = 0;
            try
            {
                File.WriteAllText(Path.Combine(sharedRoDir, "worker-ro-deny.txt"), "BAD", Utf8NoBom);
            }
            catch (UnauthorizedAccessException)
            {
                roWriteCode = 5;
            }
            catch (IOException ex)
            {
                roWriteCode = ex.HResult & 0xFFFF;
            }
            r["sharedRoWriteCode"] = roWriteCode;

            using (RegistryKey probeKey = Registry.CurrentUser.CreateSubKey(@"Software\CageLocalProbe"))
            {
                probeKey.SetValue("marker", "worker_isolated", RegistryValueKind.String);
            }
            r["workerRegistryWriteOk"] = true;

            r["directTcpV4Code"] = ProbeTcpConnect("1.1.1.1", 443, 1500);
            r["directTcpV6Code"] = ProbeTcpConnect("2606:4700:4700::1111", 443, 1500);
            r["directUdpCode"] = ProbeUdpSend("8.8.8.8", 53);
            r["otherHostLoopbackCode"] = ProbeTcpConnect("127.0.0.1", hostPrivatePort, 1500);

            Dictionary<string, object> httpRes = WorkerProbeHttpProxy(new Dictionary<string, object> { { "url", "http://cage-test.internal/ok" } }, brokerPort);
            r["brokerHttpStatus"] = httpRes.ContainsKey("statusCode") ? httpRes["statusCode"] : 0;
            r["brokerHttpBodyMatch"] = httpRes.ContainsKey("rawResponse") && Convert.ToString(httpRes["rawResponse"]).Contains("CAGE_LOCAL_HTTP_ORIGIN_OK");

            // Test HTTP CONNECT tunnel via broker
            bool connectOk = false;
            string connectEcho = "";
            try
            {
                using (TcpClient c = new TcpClient())
                {
                    c.ReceiveTimeout = 5000;
                    c.SendTimeout = 5000;
                    c.Connect(IPAddress.Loopback, brokerPort);
                    using (NetworkStream s = c.GetStream())
                    {
                        byte[] head = Encoding.ASCII.GetBytes("CONNECT cage-test.internal:443 HTTP/1.1\r\nHost: cage-test.internal:443\r\n\r\n");
                        s.Write(head, 0, head.Length);
                        s.Flush();
                        byte[] respBuf = new byte[1024];
                        int hn = s.Read(respBuf, 0, respBuf.Length);
                        string respHead = hn > 0 ? Encoding.ASCII.GetString(respBuf, 0, hn) : "";
                        if (respHead.StartsWith("HTTP/1.1 200", StringComparison.Ordinal))
                        {
                            byte[] ping = Utf8NoBom.GetBytes("PING_LOCAL_WORKER");
                            s.Write(ping, 0, ping.Length);
                            s.Flush();
                            int en = s.Read(respBuf, 0, respBuf.Length);
                            connectEcho = en > 0 ? Utf8NoBom.GetString(respBuf, 0, en) : "";
                            connectOk = (connectEcho == "CAGE_TUNNEL_OK:PING_LOCAL_WORKER");
                        }
                    }
                }
            }
            catch
            {
                connectOk = false;
            }
            r["brokerConnectTunnelOk"] = connectOk;
            r["brokerConnectEcho"] = connectEcho;
            return r;
        }

        private static List<string> ExtractStringList(Dictionary<string, object> dict, string key)
        {
            List<string> list = new List<string>();
            if (!dict.ContainsKey(key) || dict[key] == null)
            {
                return list;
            }
            object[] arr = dict[key] as object[];
            if (arr != null)
            {
                for (int i = 0; i < arr.Length; i++)
                {
                    list.Add(Convert.ToString(arr[i]));
                }
                return list;
            }
            System.Collections.ArrayList al = dict[key] as System.Collections.ArrayList;
            if (al != null)
            {
                for (int i = 0; i < al.Count; i++)
                {
                    list.Add(Convert.ToString(al[i]));
                }
            }
            return list;
        }

        private static Dictionary<string, string> ExtractStringMap(Dictionary<string, object> dict, string key)
        {
            Dictionary<string, string> map = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
            if (!dict.ContainsKey(key) || dict[key] == null)
            {
                return map;
            }
            Dictionary<string, object> raw = dict[key] as Dictionary<string, object>;
            if (raw != null)
            {
                foreach (KeyValuePair<string, object> kv in raw)
                {
                    map[kv.Key] = Convert.ToString(kv.Value);
                }
            }
            return map;
        }

        private static List<Dictionary<string, object>> SnapshotDesktopWindows(IntPtr hDesk, HashSet<int> jobPids)
        {
            List<Dictionary<string, object>> windows = new List<Dictionary<string, object>>();
            if (hDesk == IntPtr.Zero || jobPids.Count == 0)
            {
                return windows;
            }
            EnumDesktopWindows(hDesk, delegate(IntPtr hwnd, IntPtr lParam)
            {
                uint winPid;
                GetWindowThreadProcessId(hwnd, out winPid);
                if (!jobPids.Contains(unchecked((int)winPid)))
                {
                    return true;
                }
                StringBuilder cls = new StringBuilder(256);
                GetClassName(hwnd, cls, cls.Capacity);
                StringBuilder title = new StringBuilder(512);
                GetWindowText(hwnd, title, title.Capacity);
                RectStruct rc;
                GetWindowRect(hwnd, out rc);
                bool visible = IsWindowVisible(hwnd);

                Dictionary<string, object> w = new Dictionary<string, object>();
                w["hwnd"] = string.Format("0x{0:x}", hwnd.ToInt64());
                w["pid"] = unchecked((int)winPid);
                w["className"] = cls.ToString();
                w["title"] = title.ToString();
                w["visible"] = visible;
                w["width"] = rc.Right - rc.Left;
                w["height"] = rc.Bottom - rc.Top;
                windows.Add(w);
                return true;
            }, IntPtr.Zero);
            return windows;
        }

        private static string ReadSharedTextFile(string path)
        {
            if (!File.Exists(path))
            {
                return "";
            }
            for (int attempt = 0; attempt <= 10; attempt++)
            {
                try
                {
                    using (FileStream fs = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.ReadWrite | FileShare.Delete))
                    using (StreamReader sr = new StreamReader(fs, Utf8NoBom))
                    {
                        return sr.ReadToEnd();
                    }
                }
                catch (FileNotFoundException)
                {
                    return "";
                }
                catch (IOException)
                {
                    if (attempt == 10)
                    {
                        throw;
                    }
                    Thread.Sleep(100);
                }
            }
            return "";
        }

        private static Dictionary<string, object> WorkerExec(
            Dictionary<string, object> req,
            string profileDir,
            string appDataDir,
            string localAppDataDir,
            string tempDir,
            int brokerPort,
            string timezoneIana,
            string desktopName)
        {
            string exe = Path.GetFullPath(Convert.ToString(req["exe"]));
            List<string> args = ExtractStringList(req, "args");
            string cwd = req.ContainsKey("cwd") && req["cwd"] != null ? Path.GetFullPath(Convert.ToString(req["cwd"])) : profileDir;
            string mode = req.ContainsKey("mode") && req["mode"] != null ? Convert.ToString(req["mode"]) : "run-to-exit";
            int timeoutSeconds = req.ContainsKey("timeoutSeconds") ? Convert.ToInt32(req["timeoutSeconds"]) : 25;
            string extraPathPrefix = req.ContainsKey("extraPathPrefix") && req["extraPathPrefix"] != null ? Convert.ToString(req["extraPathPrefix"]) : Path.GetDirectoryName(exe);
            Dictionary<string, string> extraEnv = ExtractStringMap(req, "extraEnv");
            string logDir = Path.Combine(localAppDataDir, "CageExecLogs", Guid.NewGuid().ToString("N"));
            Directory.CreateDirectory(logDir);

            string stdinPath = Path.Combine(logDir, "stdin.txt");
            string stdoutPath = Path.Combine(logDir, "stdout.txt");
            string stderrPath = Path.Combine(logDir, "stderr.txt");
            File.WriteAllText(stdinPath, "", Utf8NoBom);

            IntPtr job = IntPtr.Zero;
            IntPtr envBlock = IntPtr.Zero;
            ProcessInformation pi = new ProcessInformation();
            Dictionary<string, object> r = new Dictionary<string, object>();
            Stopwatch sw = Stopwatch.StartNew();

            try
            {
                SortedDictionary<string, string> vars = BuildWorkerEnv(
                    profileDir,
                    appDataDir,
                    localAppDataDir,
                    tempDir,
                    brokerPort,
                    timezoneIana,
                    extraPathPrefix,
                    extraEnv);
                envBlock = AllocUnicodeEnvBlock(vars);
                job = CreateKillOnCloseJob();

                using (FileStream fsIn = new FileStream(stdinPath, FileMode.Open, FileAccess.Read, FileShare.ReadWrite))
                using (FileStream fsOut = new FileStream(stdoutPath, FileMode.Create, FileAccess.Write, FileShare.ReadWrite))
                using (FileStream fsErr = new FileStream(stderrPath, FileMode.Create, FileAccess.Write, FileShare.ReadWrite))
                {
                    IntPtr hIn = fsIn.SafeFileHandle.DangerousGetHandle();
                    IntPtr hOut = fsOut.SafeFileHandle.DangerousGetHandle();
                    IntPtr hErr = fsErr.SafeFileHandle.DangerousGetHandle();
                    CheckWin32(SetHandleInformation(hIn, 1, 1), "SetHandleInformation stdin");
                    CheckWin32(SetHandleInformation(hOut, 1, 1), "SetHandleInformation stdout");
                    CheckWin32(SetHandleInformation(hErr, 1, 1), "SetHandleInformation stderr");

                    bool isGui = (mode == "observe-gui");
                    StartupInfoW si = new StartupInfoW();
                    si.cb = Marshal.SizeOf(typeof(StartupInfoW));
                    si.lpDesktop = "Winsta0\\" + desktopName;
                    si.dwFlags = (int)(StartfUseStdHandles | (isGui ? StartfUseShowWindow : 0u));
                    si.wShowWindow = (short)(isGui ? 1 : 0);
                    si.hStdInput = hIn;
                    si.hStdOutput = hOut;
                    si.hStdError = hErr;

                    uint flags = CreateUnicodeEnvironment | CreateSuspended | (isGui ? 0u : CreateNoWindow);
                    StringBuilder cmd = new StringBuilder(BuildCommandLine(exe, args.ToArray()));
                    CheckWin32(CreateProcess(exe, cmd, IntPtr.Zero, IntPtr.Zero, true, flags, envBlock, cwd, ref si, out pi), "CreateProcess(" + Path.GetFileName(exe) + ")");
                }

                CheckWin32(AssignProcessToJobObject(job, pi.hProcess), "AssignProcessToJobObject");
                r["token"] = InspectToken(pi.hProcess);
                CheckWin32(ResumeThread(pi.hThread) != uint.MaxValue, "ResumeThread");
                CloseHandle(pi.hThread);
                pi.hThread = IntPtr.Zero;

                if (mode == "observe-gui")
                {
                    IntPtr hDesk = GetThreadDesktop(GetCurrentThreadId());
                    int maxMs = timeoutSeconds * 1000;
                    int firstVisibleWindowMs = -1;
                    int maxProcessCount = 0;
                    List<Dictionary<string, object>> lastWindows = new List<Dictionary<string, object>>();
                    List<Dictionary<string, object>> visibleWindows = new List<Dictionary<string, object>>();
                    bool exitedEarly = false;
                    uint earlyExitCode = 0;

                    while (sw.ElapsedMilliseconds < maxMs)
                    {
                        uint waitRc = WaitForSingleObject(pi.hProcess, 250);
                        List<int> livePids = QueryJobPids(job);
                        if (livePids.Count > maxProcessCount)
                        {
                            maxProcessCount = livePids.Count;
                        }
                        HashSet<int> pidSet = new HashSet<int>(livePids);
                        lastWindows = SnapshotDesktopWindows(hDesk, pidSet);
                        for (int i = 0; i < lastWindows.Count; i++)
                        {
                            Dictionary<string, object> w = lastWindows[i];
                            if ((bool)w["visible"] && (int)w["width"] > 100 && (int)w["height"] > 100)
                            {
                                visibleWindows = lastWindows;
                                if (firstVisibleWindowMs < 0)
                                {
                                    firstVisibleWindowMs = (int)sw.ElapsedMilliseconds;
                                }
                            }
                        }
                        if (waitRc == 0)
                        {
                            GetExitCodeProcess(pi.hProcess, out earlyExitCode);
                            exitedEarly = true;
                            break;
                        }
                        if (firstVisibleWindowMs >= 0 && (sw.ElapsedMilliseconds - firstVisibleWindowMs) >= 3000)
                        {
                            break;
                        }
                    }

                    bool stillAliveAtEnd = WaitForSingleObject(pi.hProcess, 0) != 0;
                    List<int> finalPids = QueryJobPids(job);
                    WaitForJobDrain(job, 2000);
                    CloseHandle(job);
                    job = IntPtr.Zero;
                    WaitForSingleObject(pi.hProcess, 5000);

                    r["exitedEarly"] = exitedEarly;
                    r["stillAliveAtEnd"] = stillAliveAtEnd;
                    r["exitCode"] = exitedEarly ? unchecked((int)earlyExitCode) : 0;
                    r["exitHex"] = exitedEarly ? string.Format("0x{0:x8}", earlyExitCode) : "0x00000000";
                    r["maxJobProcessCount"] = maxProcessCount;
                    r["finalJobProcessCountBeforeStop"] = finalPids.Count;
                    r["firstVisibleWindowMs"] = firstVisibleWindowMs;
                    r["visibleWindowDetected"] = (firstVisibleWindowMs >= 0);
                    r["windows"] = visibleWindows.Count > 0 ? visibleWindows : lastWindows;
                }
                else
                {
                    uint waitRc = WaitForSingleObject(pi.hProcess, (uint)(timeoutSeconds * 1000));
                    bool timedOut = (waitRc == 258 /* WAIT_TIMEOUT */);
                    if (timedOut)
                    {
                        WaitForJobDrain(job, 2000);
                        CloseHandle(job);
                        job = IntPtr.Zero;
                        WaitForSingleObject(pi.hProcess, 5000);
                    }
                    uint exitCode;
                    CheckWin32(GetExitCodeProcess(pi.hProcess, out exitCode), "GetExitCodeProcess");
                    // Terminate and drain any lingering child processes before reading logs.
                    if (job != IntPtr.Zero)
                    {
                        WaitForJobDrain(job, 2000);
                        CloseHandle(job);
                        job = IntPtr.Zero;
                    }
                    r["timedOut"] = timedOut;
                    r["exitCode"] = unchecked((int)exitCode);
                    r["exitHex"] = string.Format("0x{0:x8}", exitCode);
                }

                sw.Stop();
                r["durationMs"] = sw.ElapsedMilliseconds;
                r["stdout"] = ReadSharedTextFile(stdoutPath);
                r["stderr"] = ReadSharedTextFile(stderrPath);
                return r;
            }
            finally
            {
                if (job != IntPtr.Zero)
                {
                    WaitForJobDrain(job, 2000);
                    CloseHandle(job);
                }
                if (pi.hThread != IntPtr.Zero) CloseHandle(pi.hThread);
                if (pi.hProcess != IntPtr.Zero)
                {
                    if (WaitForSingleObject(pi.hProcess, 0) != 0)
                    {
                        TerminateProcess(pi.hProcess, 1);
                    }
                    WaitForSingleObject(pi.hProcess, 3000);
                    CloseHandle(pi.hProcess);
                }
                if (envBlock != IntPtr.Zero) Marshal.FreeHGlobal(envBlock);
                try { Directory.Delete(logDir, true); } catch { }
            }
        }

        private static Dictionary<string, object> WorkerRing2Exec(
            Dictionary<string, object> req,
            string localAppDataDir,
            int brokerPort,
            string timezoneIana,
            string desktopName)
        {
            string exe = Path.GetFullPath(Convert.ToString(req["exe"]));
            if (!File.Exists(exe))
            {
                throw new FileNotFoundException("Ring-2 executable not found.", exe);
            }
            List<string> args = ExtractStringList(req, "args");
            int timeoutSeconds = req.ContainsKey("timeoutSeconds") ? Convert.ToInt32(req["timeoutSeconds"]) : 20;

            string userProfile = Path.GetFullPath(Environment.GetFolderPath(Environment.SpecialFolder.UserProfile)).TrimEnd('\\');
            string acName = "CageLocal.Ring2." + Guid.NewGuid().ToString("N");
            string ring2Parent = Path.Combine(localAppDataDir, "CageRing2");
            string ring2Root = Path.Combine(ring2Parent, Guid.NewGuid().ToString("N"));
            string fullRing2Root = Path.GetFullPath(ring2Root).TrimEnd('\\');
            if (!fullRing2Root.StartsWith(userProfile + "\\", StringComparison.OrdinalIgnoreCase))
            {
                throw new InvalidDataException("Ring-2 root must reside under worker user profile: " + fullRing2Root);
            }
            for (DirectoryInfo preDir = new DirectoryInfo(Path.GetFullPath(ring2Parent).TrimEnd('\\')); preDir != null; preDir = preDir.Parent)
            {
                string preFull = preDir.FullName.TrimEnd('\\');
                bool isRoot = string.Equals(preFull, userProfile, StringComparison.OrdinalIgnoreCase);
                if (!isRoot && !preFull.StartsWith(userProfile + "\\", StringComparison.OrdinalIgnoreCase))
                {
                    break;
                }
                if (preDir.Exists && (preDir.Attributes & FileAttributes.ReparsePoint) != 0)
                {
                    throw new InvalidDataException("Reparse point detected on Ring-2 ancestor path: " + preDir.FullName);
                }
                if (isRoot)
                {
                    break;
                }
            }

            string privDir = Path.Combine(ring2Root, "private");
            string privFile = Path.Combine(privDir, "ring1-secret.txt");
            string logsDir = Path.Combine(ring2Root, "logs");
            string toolsStageDir = Path.Combine(ring2Root, "tools");
            string workDir = Path.Combine(ring2Root, "work");
            string tempDir = Path.Combine(workDir, "Temp");
            Directory.CreateDirectory(privDir);
            Directory.CreateDirectory(logsDir);
            Directory.CreateDirectory(toolsStageDir);
            Directory.CreateDirectory(workDir);

            IntPtr pkgSidPtr = IntPtr.Zero;
            SecurityIdentifier pkgSid = null;
            List<string> traverseModifiedDirs = new List<string>();
            IntPtr hThreadDesk = IntPtr.Zero;
            byte[] originalDeskDacl = null;
            IntPtr attrList = IntPtr.Zero;
            IntPtr secCapPtr = IntPtr.Zero;
            IntPtr handlesPtr = IntPtr.Zero;
            IntPtr envBlock = IntPtr.Zero;
            IntPtr job = IntPtr.Zero;
            ProcessInformation pi = new ProcessInformation();
            bool attrInitialized = false;

            try
            {
                int hr = CreateAppContainerProfile(acName, acName, "CageLocal Ring-2 CLI Container", IntPtr.Zero, 0, out pkgSidPtr);
                Marshal.ThrowExceptionForHR(hr);
                pkgSid = new SecurityIdentifier(pkgSidPtr);

                FileSystemRights traverseRights =
                    FileSystemRights.ListDirectory |
                    FileSystemRights.Traverse |
                    FileSystemRights.ReadAttributes |
                    FileSystemRights.ReadExtendedAttributes |
                    FileSystemRights.ReadPermissions |
                    FileSystemRights.Synchronize;

                for (DirectoryInfo dir = new DirectoryInfo(fullRing2Root); dir != null; dir = dir.Parent)
                {
                    string dirFull = dir.FullName.TrimEnd('\\');
                    bool isProfileRoot = string.Equals(dirFull, userProfile, StringComparison.OrdinalIgnoreCase);
                    if (!isProfileRoot && !dirFull.StartsWith(userProfile + "\\", StringComparison.OrdinalIgnoreCase))
                    {
                        break;
                    }
                    if (!dir.Exists || (dir.Attributes & FileAttributes.ReparsePoint) != 0)
                    {
                        throw new InvalidDataException("Ring-2 ancestor missing or is a reparse point: " + dir.FullName);
                    }
                    DirectorySecurity dirAcl = dir.GetAccessControl(AccessControlSections.Access);
                    dirAcl.AddAccessRule(new FileSystemAccessRule(
                        pkgSid,
                        traverseRights,
                        InheritanceFlags.None,
                        PropagationFlags.None,
                        AccessControlType.Allow));
                    dir.SetAccessControl(dirAcl);
                    traverseModifiedDirs.Add(dirFull);
                    if (isProfileRoot)
                    {
                        break;
                    }
                }

                string workerSidStr = WindowsIdentity.GetCurrent().User.Value;
                InheritanceFlags inheritBoth = InheritanceFlags.ContainerInherit | InheritanceFlags.ObjectInherit;

                DirectorySecurity toolsAcl = new DirectorySecurity();
                toolsAcl.SetAccessRuleProtection(true, false);
                toolsAcl.AddAccessRule(new FileSystemAccessRule(new SecurityIdentifier(workerSidStr), FileSystemRights.FullControl, inheritBoth, PropagationFlags.None, AccessControlType.Allow));
                toolsAcl.AddAccessRule(new FileSystemAccessRule(new SecurityIdentifier(WellKnownSystemSid), FileSystemRights.FullControl, inheritBoth, PropagationFlags.None, AccessControlType.Allow));
                toolsAcl.AddAccessRule(new FileSystemAccessRule(pkgSid, FileSystemRights.ReadAndExecute, inheritBoth, PropagationFlags.None, AccessControlType.Allow));
                Directory.SetAccessControl(toolsStageDir, toolsAcl);

                string stagedExe = Path.Combine(toolsStageDir, Path.GetFileName(exe));
                File.Copy(exe, stagedExe, true);
                File.SetAttributes(stagedExe, FileAttributes.Normal);

                DirectorySecurity workAcl = new DirectorySecurity();
                workAcl.SetAccessRuleProtection(true, false);
                workAcl.AddAccessRule(new FileSystemAccessRule(new SecurityIdentifier(workerSidStr), FileSystemRights.FullControl, inheritBoth, PropagationFlags.None, AccessControlType.Allow));
                workAcl.AddAccessRule(new FileSystemAccessRule(new SecurityIdentifier(WellKnownSystemSid), FileSystemRights.FullControl, inheritBoth, PropagationFlags.None, AccessControlType.Allow));
                workAcl.AddAccessRule(new FileSystemAccessRule(pkgSid, FileSystemRights.Modify | FileSystemRights.Synchronize | FileSystemRights.ChangePermissions, inheritBoth, PropagationFlags.None, AccessControlType.Allow));
                Directory.SetAccessControl(workDir, workAcl);
                SetLowMandatoryLabelOnDirectory(workDir);
                Directory.CreateDirectory(tempDir);

                DirectorySecurity privAcl = new DirectorySecurity();
                privAcl.SetAccessRuleProtection(true, false);
                privAcl.AddAccessRule(new FileSystemAccessRule(new SecurityIdentifier(workerSidStr), FileSystemRights.FullControl, inheritBoth, PropagationFlags.None, AccessControlType.Allow));
                privAcl.AddAccessRule(new FileSystemAccessRule(new SecurityIdentifier(WellKnownSystemSid), FileSystemRights.FullControl, inheritBoth, PropagationFlags.None, AccessControlType.Allow));
                Directory.SetAccessControl(privDir, privAcl);
                File.WriteAllText(privFile, "RING1_ONLY_SECRET", Utf8NoBom);

                hThreadDesk = GetThreadDesktop(GetCurrentThreadId());
                if (hThreadDesk != IntPtr.Zero)
                {
                    originalDeskDacl = GetObjectDacl(hThreadDesk);
                    RawSecurityDescriptor deskSd = new RawSecurityDescriptor(originalDeskDacl, 0);
                    if (deskSd.DiscretionaryAcl != null)
                    {
                        deskSd.DiscretionaryAcl.InsertAce(0, new CommonAce(
                            AceFlags.None,
                            AceQualifier.AccessAllowed,
                            0x000F01FF,
                            pkgSid,
                            false,
                            null));
                        byte[] updatedDeskDacl = new byte[deskSd.BinaryLength];
                        deskSd.GetBinaryForm(updatedDeskDacl, 0);
                        SetObjectDacl(hThreadDesk, updatedDeskDacl);
                    }
                }

                string stdinPath = Path.Combine(logsDir, "stdin.txt");
                string stdoutPath = Path.Combine(logsDir, "stdout.txt");
                string stderrPath = Path.Combine(logsDir, "stderr.txt");
                File.WriteAllText(stdinPath, "", Utf8NoBom);

                SortedDictionary<string, string> vars = BuildWorkerEnv(workDir, workDir, workDir, tempDir, brokerPort, timezoneIana, toolsStageDir, null);
                envBlock = AllocUnicodeEnvBlock(vars);
                job = CreateKillOnCloseJob();

                Dictionary<string, object> result = new Dictionary<string, object>();
                using (FileStream fsIn = new FileStream(stdinPath, FileMode.Open, FileAccess.Read, FileShare.ReadWrite))
                using (FileStream fsOut = new FileStream(stdoutPath, FileMode.Create, FileAccess.Write, FileShare.ReadWrite))
                using (FileStream fsErr = new FileStream(stderrPath, FileMode.Create, FileAccess.Write, FileShare.ReadWrite))
                {
                    IntPtr[] streams = new IntPtr[]
                    {
                        fsIn.SafeFileHandle.DangerousGetHandle(),
                        fsOut.SafeFileHandle.DangerousGetHandle(),
                        fsErr.SafeFileHandle.DangerousGetHandle()
                    };
                    for (int i = 0; i < streams.Length; i++)
                    {
                        CheckWin32(SetHandleInformation(streams[i], 1, 1), "SetHandleInformation ring2 stdio");
                    }

                    IntPtr attrSize = IntPtr.Zero;
                    InitializeProcThreadAttributeList(IntPtr.Zero, 2, 0, ref attrSize);
                    attrList = Marshal.AllocHGlobal(attrSize);
                    CheckWin32(InitializeProcThreadAttributeList(attrList, 2, 0, ref attrSize), "InitializeProcThreadAttributeList");
                    attrInitialized = true;

                    SecurityCapabilities secCap = new SecurityCapabilities { AppContainerSid = pkgSidPtr, Capabilities = IntPtr.Zero, CapabilityCount = 0, Reserved = 0 };
                    secCapPtr = Marshal.AllocHGlobal(Marshal.SizeOf(secCap));
                    Marshal.StructureToPtr(secCap, secCapPtr, false);
                    CheckWin32(UpdateProcThreadAttribute(attrList, 0, (IntPtr)0x20009 /* PROC_THREAD_ATTRIBUTE_SECURITY_CAPABILITIES */, secCapPtr, (IntPtr)Marshal.SizeOf(secCap), IntPtr.Zero, IntPtr.Zero), "UpdateProcThreadAttribute(SecurityCapabilities)");

                    handlesPtr = Marshal.AllocHGlobal(IntPtr.Size * 3);
                    for (int i = 0; i < 3; i++)
                    {
                        Marshal.WriteIntPtr(handlesPtr, i * IntPtr.Size, streams[i]);
                    }
                    CheckWin32(UpdateProcThreadAttribute(attrList, 0, (IntPtr)0x20002 /* PROC_THREAD_ATTRIBUTE_HANDLE_LIST */, handlesPtr, (IntPtr)(IntPtr.Size * 3), IntPtr.Zero, IntPtr.Zero), "UpdateProcThreadAttribute(HandleList)");

                    StartupInfoExW siEx = new StartupInfoExW();
                    siEx.StartupInfo.cb = Marshal.SizeOf(typeof(StartupInfoExW));
                    siEx.StartupInfo.lpDesktop = null;
                    siEx.StartupInfo.dwFlags = (int)StartfUseStdHandles;
                    siEx.StartupInfo.hStdInput = streams[0];
                    siEx.StartupInfo.hStdOutput = streams[1];
                    siEx.StartupInfo.hStdError = streams[2];
                    siEx.lpAttributeList = attrList;

                    uint flags = ExtendedStartupInfoPresent | CreateUnicodeEnvironment | CreateNoWindow | CreateSuspended;
                    StringBuilder cmd = new StringBuilder(BuildCommandLine(stagedExe, args.ToArray()));
                    CheckWin32(CreateProcessEx(stagedExe, cmd, IntPtr.Zero, IntPtr.Zero, true, flags, envBlock, workDir, ref siEx, out pi), "CreateProcessEx(Ring2)");
                }

                CheckWin32(AssignProcessToJobObject(job, pi.hProcess), "AssignProcessToJobObject(Ring2)");

                Dictionary<string, object> childToken = InspectToken(pi.hProcess);
                if (!(bool)childToken["isAppContainer"] || (int)childToken["capabilityCount"] != 0 || !string.Equals(Convert.ToString(childToken["appContainerSid"]), pkgSid.Value, StringComparison.OrdinalIgnoreCase))
                {
                    throw new InvalidOperationException("Ring-2 child token verification failed.");
                }
                result["token"] = childToken;
                result["ring2PrivateFixturePath"] = privFile;

                CheckWin32(ResumeThread(pi.hThread) != uint.MaxValue, "ResumeThread(Ring2)");
                CloseHandle(pi.hThread);
                pi.hThread = IntPtr.Zero;

                uint waitRc = WaitForSingleObject(pi.hProcess, (uint)(timeoutSeconds * 1000));
                bool timedOut = (waitRc == 258);
                if (timedOut)
                {
                    WaitForJobDrain(job, 2000);
                    CloseHandle(job);
                    job = IntPtr.Zero;
                    WaitForSingleObject(pi.hProcess, 5000);
                }
                uint exitCode;
                CheckWin32(GetExitCodeProcess(pi.hProcess, out exitCode), "GetExitCodeProcess(Ring2)");
                if (job != IntPtr.Zero)
                {
                    WaitForJobDrain(job, 2000);
                    CloseHandle(job);
                    job = IntPtr.Zero;
                }
                result["timedOut"] = timedOut;
                result["exitCode"] = unchecked((int)exitCode);
                result["stdout"] = ReadSharedTextFile(stdoutPath);
                result["stderr"] = ReadSharedTextFile(stderrPath);
                return result;
            }
            finally
            {
                if (job != IntPtr.Zero)
                {
                    WaitForJobDrain(job, 2000);
                    CloseHandle(job);
                }
                if (pi.hThread != IntPtr.Zero) CloseHandle(pi.hThread);
                if (pi.hProcess != IntPtr.Zero)
                {
                    if (WaitForSingleObject(pi.hProcess, 0) != 0)
                    {
                        TerminateProcess(pi.hProcess, 1);
                    }
                    WaitForSingleObject(pi.hProcess, 3000);
                    CloseHandle(pi.hProcess);
                }
                if (hThreadDesk != IntPtr.Zero && originalDeskDacl != null)
                {
                    try { SetObjectDacl(hThreadDesk, originalDeskDacl); } catch { }
                }
                if (attrInitialized) DeleteProcThreadAttributeList(attrList);
                if (attrList != IntPtr.Zero) Marshal.FreeHGlobal(attrList);
                if (secCapPtr != IntPtr.Zero) Marshal.FreeHGlobal(secCapPtr);
                if (handlesPtr != IntPtr.Zero) Marshal.FreeHGlobal(handlesPtr);
                if (envBlock != IntPtr.Zero) Marshal.FreeHGlobal(envBlock);
                if (pkgSid != null)
                {
                    for (int i = traverseModifiedDirs.Count - 1; i >= 0; i--)
                    {
                        try
                        {
                            string d = traverseModifiedDirs[i];
                            if (Directory.Exists(d))
                            {
                                DirectoryInfo di = new DirectoryInfo(d);
                                if ((di.Attributes & FileAttributes.ReparsePoint) == 0)
                                {
                                    DirectorySecurity acl = di.GetAccessControl(AccessControlSections.Access);
                                    acl.PurgeAccessRules(pkgSid);
                                    di.SetAccessControl(acl);
                                }
                            }
                        }
                        catch
                        {
                        }
                    }
                }
                if (pkgSidPtr != IntPtr.Zero)
                {
                    FreeSid(pkgSidPtr);
                    try { DeleteAppContainerProfile(acName); } catch { }
                }
                try { Directory.Delete(ring2Root, true); } catch { }
            }
        }

        // ==================== CONTROLLER SESSION HOST ====================

        internal sealed class LocalWorkerSession : IDisposable
        {
            private readonly LocalProfileModel profile;
            private readonly IntPtr hWinSta;
            private readonly byte[] originalWinStaDacl;
            private readonly IntPtr hBaseNamedObjects;
            private readonly byte[] originalBaseNamedDacl;
            private readonly IntPtr hAppContainerNamedObjects;
            private readonly byte[] originalAppContainerNamedDacl;
            private readonly IntPtr hPipeAppContainerNamedObjects;
            private readonly byte[] originalPipeAppContainerNamedDacl;
            private readonly IntPtr hDesktop;
            private readonly IntPtr hJob;
            private readonly NamedPipeServerStream pipeServer;
            private StreamReader pipeReader;
            private StreamWriter pipeWriter;
            private Mutex desktopAccessLock;
            private bool ownsDesktopAccessLock;
            private readonly string secretHex;
            private int nextId;
            private bool disposed;

            internal string DesktopName { get; private set; }
            internal IntPtr JobHandle { get { return hJob; } }
            internal Dictionary<string, object> HandshakeInfo { get; private set; }

            internal LocalWorkerSession(LocalProfileModel profile, string timezoneIana, bool useDefaultDesktop, bool refreshTerminalWorker = false)
            {
                this.profile = profile;
                byte[] cipherPwd = File.ReadAllBytes(profile.credentialFile);
                byte[] plainPwdBytes = DpapiUnprotect(cipherPwd, profile.instanceId, profile.controllerSid, profile.workerSid);
                string password = Utf8NoBom.GetString(plainPwdBytes);
                Array.Clear(plainPwdBytes, 0, plainPwdBytes.Length);

                IntPtr envBlock = IntPtr.Zero;
                ProcessInformation pi = new ProcessInformation();
                try
                {
                    // These DACLs are shared by all profiles on this Windows desktop.
                    // Serialize both the workbench probe and the compatibility suite.
                    desktopAccessLock = new Mutex(false, @"Local\CageLocal.DesktopAccess");
                    try { ownsDesktopAccessLock = desktopAccessLock.WaitOne(0); }
                    catch (AbandonedMutexException) { ownsDesktopAccessLock = true; }
                    if (!ownsDesktopAccessLock)
                    {
                        throw new InvalidOperationException("Another Cage local session is already using this desktop.");
                    }
                    hWinSta = GetProcessWindowStation();
                    originalWinStaDacl = GrantWinStaWorkerAccess(hWinSta, profile.workerSid);
                    int sessionId = Process.GetCurrentProcess().SessionId;
                    string sessionRoot = string.Format(@"\Sessions\{0}", sessionId);
                    hBaseNamedObjects = OpenNtDirectoryObject(sessionRoot + @"\BaseNamedObjects", 0x00060000);
                    originalBaseNamedDacl = GrantNtObjectWorkerAccess(hBaseNamedObjects, profile.workerSid, 0x0003000F);
                    hAppContainerNamedObjects = OpenNtDirectoryObject(sessionRoot + @"\AppContainerNamedObjects", 0x00060000);
                    originalAppContainerNamedDacl = GrantNtObjectWorkerAccess(hAppContainerNamedObjects, profile.workerSid, 0x0003000F);
                    hPipeAppContainerNamedObjects = OpenNtFileObject(@"\Device\NamedPipe" + sessionRoot + @"\AppContainerNamedObjects", 0x00060000, 7, 1);
                    originalPipeAppContainerNamedDacl = GrantNtObjectWorkerAccess(hPipeAppContainerNamedObjects, profile.workerSid, 0x00130006);

                    if (useDefaultDesktop)
                    {
                        DesktopName = "Default";
                        hDesktop = IntPtr.Zero;
                    }
                    else
                    {
                        DesktopName = "CageLocal_" + profile.instanceId.Replace("-", "").Substring(0, 8) + "_" + Guid.NewGuid().ToString("N").Substring(0, 6);
                        hDesktop = CreatePrivateDesktopForWorker(DesktopName, profile.controllerSid, profile.workerSid);
                    }

                    string pipeName = "Cage.Local." + Guid.NewGuid().ToString("N");
                    secretHex = BytesToHex(RandomBytes(32));

                    PipeSecurity pipeSec = new PipeSecurity();
                    pipeSec.SetAccessRuleProtection(true, false);
                    pipeSec.SetOwner(new SecurityIdentifier(profile.controllerSid));
                    pipeSec.AddAccessRule(new PipeAccessRule(new SecurityIdentifier(WellKnownSidType.NetworkSid, null), PipeAccessRights.FullControl, AccessControlType.Deny));
                    string[] allowed = new string[] { profile.controllerSid, profile.workerSid, WellKnownSystemSid };
                    for (int i = 0; i < allowed.Length; i++)
                    {
                        pipeSec.AddAccessRule(new PipeAccessRule(new SecurityIdentifier(allowed[i]), PipeAccessRights.FullControl, AccessControlType.Allow));
                    }
                    pipeServer = new NamedPipeServerStream(pipeName, PipeDirection.InOut, 1, PipeTransmissionMode.Byte, PipeOptions.Asynchronous, 65536, 65536, pipeSec);

                    hJob = CreateKillOnCloseJob();

                    string workerExe = Path.Combine(profile.binDir, "CageLocal.exe");
                    if (!File.Exists(workerExe))
                    {
                        throw new FileNotFoundException("Worker binary missing in provisioned binDir.", workerExe);
                    }
                    if (refreshTerminalWorker) RefreshTerminalWorker(workerExe, profile.controllerSid);

                    string winDir = Environment.GetFolderPath(Environment.SpecialFolder.Windows);
                    string sysDir = Environment.SystemDirectory;
                    SortedDictionary<string, string> launchVars = new SortedDictionary<string, string>(StringComparer.OrdinalIgnoreCase);
                    launchVars["SystemRoot"] = winDir;
                    launchVars["WINDIR"] = winDir;
                    launchVars["SystemDrive"] = Path.GetPathRoot(sysDir).TrimEnd('\\');
                    launchVars["COMSPEC"] = Path.Combine(sysDir, "cmd.exe");
                    launchVars["PATHEXT"] = ".COM;.EXE;.BAT;.CMD";
                    launchVars["PATH"] = sysDir + ";" + winDir + ";" + Path.Combine(sysDir, "WindowsPowerShell", "v1.0");
                    launchVars["TZ"] = string.IsNullOrEmpty(timezoneIana) ? "Asia/Tokyo" : timezoneIana;
                    envBlock = AllocUnicodeEnvBlock(launchVars);

                    StartupInfoW si = new StartupInfoW();
                    si.cb = Marshal.SizeOf(typeof(StartupInfoW));
                    si.lpDesktop = "Winsta0\\" + DesktopName;
                    si.dwFlags = (int)StartfUseShowWindow;
                    si.wShowWindow = 0;

                    StringBuilder cmd = new StringBuilder(BuildCommandLine(
                        workerExe,
                        new string[]
                        {
                            "worker-daemon",
                            pipeName,
                            secretHex,
                            profile.brokerPort.ToString(),
                            DesktopName,
                            string.IsNullOrEmpty(timezoneIana) ? "Asia/Tokyo" : timezoneIana
                        }));

                    CheckWin32(CreateProcessWithLogonW(
                        profile.workerUsername,
                        ".",
                        password,
                        LogonWithProfile,
                        workerExe,
                        cmd,
                        CreateSuspended | CreateNoWindow | CreateUnicodeEnvironment,
                        envBlock,
                        profile.toolsDir,
                        ref si,
                        out pi), "CreateProcessWithLogonW");

                    CheckWin32(AssignProcessToJobObject(hJob, pi.hProcess), "AssignProcessToJobObject(daemon)");
                    CheckWin32(ResumeThread(pi.hThread) != uint.MaxValue, "ResumeThread(daemon)");
                    CloseHandle(pi.hThread);
                    pi.hThread = IntPtr.Zero;

                    IAsyncResult waitPipe = pipeServer.BeginWaitForConnection(null, null);
                    if (!waitPipe.AsyncWaitHandle.WaitOne(15000))
                    {
                        throw new TimeoutException("Timed out waiting for CageLocal worker-daemon pipe connection.");
                    }
                    pipeServer.EndWaitForConnection(waitPipe);
                    uint clientPid;
                    CheckWin32(GetNamedPipeClientProcessId(pipeServer.SafePipeHandle, out clientPid), "GetNamedPipeClientProcessId");
                    if (clientPid != (uint)pi.dwProcessId)
                    {
                        throw new UnauthorizedAccessException("The connected pipe client is not the launched worker.");
                    }
                    pipeReader = new StreamReader(pipeServer, Utf8NoBom, false, 65536, true);
                    pipeWriter = new StreamWriter(pipeServer, Utf8NoBom, 65536, true);
                    pipeWriter.AutoFlush = true;

                    string helloLine = ReadReplyWithTimeout();
                    if (string.IsNullOrEmpty(helloLine))
                    {
                        throw new EndOfStreamException("Worker daemon closed pipe before auth.");
                    }
                    Dictionary<string, object> hello = FromJsonObject(helloLine);
                    string gotSecret = hello.ContainsKey("auth") ? Convert.ToString(hello["auth"]) : "";
                    if (!ConstantTimeEquals(gotSecret, secretHex))
                    {
                        throw new UnauthorizedAccessException("Worker daemon failed pipe authentication.");
                    }
                    // This private response comes from the process handle held above,
                    // identified by the kernel's pipe-client PID and the one-time nonce.
                    string workerLogonSid = hello.ContainsKey("logonSid") ? Convert.ToString(hello["logonSid"]) : "";
                    if (!hello.ContainsKey("userSid") || !string.Equals(profile.workerSid, Convert.ToString(hello["userSid"]), StringComparison.OrdinalIgnoreCase) ||
                        !System.Text.RegularExpressions.Regex.IsMatch(workerLogonSid, @"\AS-1-5-5-[0-9]+-[0-9]+\z"))
                    {
                        throw new InvalidOperationException("Worker daemon failed to report valid logon SID.");
                    }
                    GrantWinStaWorkerAccess(hWinSta, workerLogonSid);
                    if (hDesktop != IntPtr.Zero)
                    {
                        GrantDesktopWorkerAccess(hDesktop, workerLogonSid);
                    }
                    GrantNtObjectWorkerAccess(hBaseNamedObjects, workerLogonSid, 0x0003000F);
                    GrantNtObjectWorkerAccess(hAppContainerNamedObjects, workerLogonSid, 0x0003000F);
                    GrantNtObjectWorkerAccess(hPipeAppContainerNamedObjects, workerLogonSid, 0x00130006);
                    hello.Remove("auth");
                    HandshakeInfo = hello;
                    pipeWriter.WriteLine("{\"ok\":true}");
                }
                catch
                {
                    if (pi.hProcess != IntPtr.Zero) TerminateProcess(pi.hProcess, 1);
                    Dispose();
                    throw;
                }
                finally
                {
                    password = null;
                    if (envBlock != IntPtr.Zero) Marshal.FreeHGlobal(envBlock);
                    if (pi.hThread != IntPtr.Zero) CloseHandle(pi.hThread);
                    if (pi.hProcess != IntPtr.Zero) CloseHandle(pi.hProcess);
                }
            }

            internal bool OwnsPid(int pid)
            {
                List<int> pids = QueryJobPids(hJob);
                return pids.Contains(pid);
            }

            private string ReadReplyWithTimeout(int milliseconds = 5000)
            {
                var reply = pipeReader.ReadLineAsync();
                if (!reply.Wait(milliseconds))
                {
                    throw new TimeoutException("Timed out waiting for the isolated worker.");
                }
                return reply.Result;
            }

            internal Dictionary<string, object> Call(string op, Dictionary<string, object> payload, int replyTimeoutMs = 0)
            {
                Dictionary<string, object> req = payload != null
                    ? new Dictionary<string, object>(payload)
                    : new Dictionary<string, object>();
                string id = Interlocked.Increment(ref nextId).ToString();
                req["id"] = id;
                req["op"] = op;
                pipeWriter.WriteLine(ToJson(req));

                if (replyTimeoutMs == 0 && (op == "inspect" || op == "shutdown")) replyTimeoutMs = 5000;
                string line = replyTimeoutMs > 0 ? ReadReplyWithTimeout(replyTimeoutMs) : pipeReader.ReadLine();
                if (string.IsNullOrEmpty(line))
                {
                    throw new EndOfStreamException("Worker daemon pipe closed during op: " + op);
                }
                Dictionary<string, object> resp = FromJsonObject(line);
                if (!resp.ContainsKey("id") || !Object.Equals(resp["id"], id))
                    throw new IOException("Isolated worker replied to a different request.");
                if (!resp.ContainsKey("ok") || !(bool)resp["ok"])
                {
                    string err = resp.ContainsKey("error") ? Convert.ToString(resp["error"]) : "Worker RPC failed";
                    throw new InvalidOperationException(string.Format("Worker op '{0}' failed: {1}", op, err));
                }
                return resp.ContainsKey("result") ? (resp["result"] as Dictionary<string, object>) : new Dictionary<string, object>();
            }

            public void Dispose()
            {
                if (disposed)
                {
                    return;
                }
                disposed = true;
                if (pipeWriter != null)
                {
                    if (HandshakeInfo != null) { try { Call("shutdown", null); } catch { } }
                    try { pipeWriter.Dispose(); } catch { }
                }
                if (pipeReader != null) { try { pipeReader.Dispose(); } catch { } }
                if (pipeServer != null) { try { pipeServer.Dispose(); } catch { } }
                if (hJob != IntPtr.Zero) { try { WaitForJobDrain(hJob, 2000); } catch { } finally { CloseHandle(hJob); } }
                if (hDesktop != IntPtr.Zero) { try { CloseDesktop(hDesktop); } catch { } }
                RestoreAndCloseNtObject(hPipeAppContainerNamedObjects, originalPipeAppContainerNamedDacl);
                RestoreAndCloseNtObject(hAppContainerNamedObjects, originalAppContainerNamedDacl);
                RestoreAndCloseNtObject(hBaseNamedObjects, originalBaseNamedDacl);
                if (hWinSta != IntPtr.Zero && originalWinStaDacl != null)
                {
                    try { SetObjectDacl(hWinSta, originalWinStaDacl); } catch { }
                }
                if (ownsDesktopAccessLock) desktopAccessLock.ReleaseMutex();
                if (desktopAccessLock != null) desktopAccessLock.Dispose();
            }
        }
    }
}
