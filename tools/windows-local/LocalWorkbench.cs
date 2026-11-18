using System;
using System.Collections.Generic;
using System.IO;
using System.Security.AccessControl;
using System.Security.Principal;

namespace CageLocalTool
{
    internal static partial class CageLocal
    {
        private static bool SameWindowsName(string left, string right)
        {
            return string.Equals(left, right, StringComparison.OrdinalIgnoreCase);
        }

        // The deployed daemon and its search paths may be writable only by the
        // controller, SYSTEM or administrators. Existing Phase 1 daemons speak inspect.
        private static void VerifyDeploymentAcl(FileSystemInfo entry, string controllerSid)
        {
            if (!entry.Exists || (entry.Attributes & FileAttributes.ReparsePoint) != 0)
            {
                throw new InvalidDataException("Missing or redirected local runtime component: " + entry.Name);
            }
            DirectoryInfo dir = entry as DirectoryInfo;
            FileSystemSecurity acl = dir != null
                ? (FileSystemSecurity)dir.GetAccessControl()
                : ((FileInfo)entry).GetAccessControl();
            HashSet<string> trusted = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
            {
                controllerSid, WellKnownSystemSid, WellKnownAdminsSid
            };
            if (!trusted.Contains(acl.GetOwner(typeof(SecurityIdentifier)).Value))
            {
                throw new InvalidDataException("Untrusted owner of local runtime component: " + entry.Name);
            }
            FileSystemRights readOnly = FileSystemRights.ReadAndExecute | FileSystemRights.Synchronize;
            foreach (FileSystemAccessRule rule in acl.GetAccessRules(true, true, typeof(SecurityIdentifier)))
            {
                if (rule.AccessControlType == AccessControlType.Allow &&
                    (rule.FileSystemRights & ~readOnly) != 0 && !trusted.Contains(rule.IdentityReference.Value))
                {
                    throw new InvalidDataException("Untrusted write access to local runtime component: " + entry.Name);
                }
            }
        }

        private static LocalProfileModel LoadWorkbenchProfile(string profilePath)
        {
            string controllerSid = CurrentUserSid();
            VerifyControllerOnlyFileAcl(profilePath, controllerSid, null);
            LocalProfileModel profile = LoadProfile(profilePath, false);
            if (!SameWindowsName(controllerSid, profile.controllerSid))
            {
                throw new UnauthorizedAccessException("This isolated account belongs to another Windows user.");
            }
            Guid instance = Guid.Parse(profile.instanceId);
            string parent = ProgramDataParentDir();
            string root = Path.Combine(parent, instance.ToString("D"));
            if (!SameWindowsName(profile.rootDir, root) ||
                !SameWindowsName(profile.binDir, Path.Combine(root, "bin")) ||
                !SameWindowsName(profile.toolsDir, Path.Combine(root, "tools")) ||
                !SameWindowsName(profile.credentialFile, Path.Combine(root, "worker.dpapi")) ||
                !SameWindowsName(profile.workerUsername, "CageLocal_" + instance.ToString("N").Substring(0, 8)))
            {
                throw new InvalidDataException("The local profile does not match the provisioned account layout.");
            }
            VerifyDeploymentAcl(new DirectoryInfo(parent), controllerSid);
            VerifyDeploymentAcl(new DirectoryInfo(root), controllerSid);
            VerifyDeploymentAcl(new DirectoryInfo(profile.toolsDir), controllerSid);
            DirectoryInfo bin = new DirectoryInfo(profile.binDir);
            VerifyDeploymentAcl(bin, controllerSid);
            VerifyDeploymentAcl(new FileInfo(Path.Combine(bin.FullName, "CageLocal.exe")), controllerSid);
            VerifyControllerOnlyFileAcl(profile.credentialFile, controllerSid, profile.workerSid);
            string actualSid = new NTAccount(Environment.MachineName, profile.workerUsername)
                .Translate(typeof(SecurityIdentifier)).Value;
            if (!SameWindowsName(actualSid, profile.workerSid))
            {
                throw new InvalidDataException("The Windows account SID differs from the provisioned profile.");
            }
            EnsureWorkerGroupMembership(profile.workerUsername, profile.workerSid, true);
            return profile;
        }

        private static int WorkbenchCommand(string[] args)
        {
            if (args.Length != 3 || args[1] != "--profile" || string.IsNullOrWhiteSpace(args[2]))
            {
                throw new InvalidDataException(args[0] + " requires --profile <local-profile.json>.");
            }
            LocalProfileModel profile = LoadWorkbenchProfile(Path.GetFullPath(args[2]));
            Dictionary<string, object> rules = WfpApply("status", profile.instanceId, profile.workerSid, profile.brokerPort);
            if (!(bool)rules["allVerified"])
            {
                throw new InvalidOperationException("Live WFP verification failed: " +
                    rules["installedFilters"] + "/" + rules["requiredFilters"] + " rules match.");
            }
            if (args[0] == "workbench-tabs") return RunWorkbenchTabs(profile);
            if (args[0] == "workbench-terminal") return RunWorkbenchTerminal(profile);
            if (args[0] == "workbench-accounts") return RunWorkbenchService(profile, "accounts");
            if (args[0] == "workbench-tailnet") return RunWorkbenchService(profile, "tailnet");
            if (args[0] == "workbench-browser") return RunWorkbenchBrowser(profile);
            if (args[0] == "workbench-desktop") return RunWorkbenchApp(profile, "desktop");
            if (args[0] == "workbench-editor") return RunWorkbenchApp(profile, "editor");
            if (args[0] == "workbench-projects") return RunWorkbenchProjects(profile);
            if (args[0] == "workbench-volume") return PrepareProjectVolume(profile);
            Dictionary<string, object> result = new Dictionary<string, object>
            {
                { "instanceId", profile.instanceId },
                { "workerUsername", profile.workerUsername },
                { "cliInstalled", File.Exists(ServiceExecutable(profile.toolsDir, "accounts")) },
                { "tailnetInstalled", File.Exists(ServiceExecutable(profile.toolsDir, "tailnet")) },
                { "desktopInstalled", InstalledWorkbenchApp(profile, "desktop") },
                { "editorInstalled", InstalledWorkbenchApp(profile, "editor") },
                { "workerSid", profile.workerSid },
                { "browserInstalled", FindWorkbenchEdge() != null },
                { "rulesVerified", true },
                { "installedFilters", rules["installedFilters"] },
                { "requiredFilters", rules["requiredFilters"] }
            };
            if (args[0] == "workbench-probe")
            {
                using (LocalWorkerSession session = new LocalWorkerSession(profile, "UTC", false))
                {
                    Dictionary<string, object> observed = session.Call("inspect", null);
                    Dictionary<string, object> token = (Dictionary<string, object>)observed["token"];
                    if (!SameWindowsName((string)token["userSid"], profile.workerSid) ||
                        !SameWindowsName((string)observed["username"], profile.workerUsername) ||
                        !SameWindowsName((string)observed["desktop"], session.DesktopName) ||
                        (string)token["integrityRid"] != "0x2000")
                    {
                        throw new InvalidDataException("The session identity, integrity or desktop differs from the expected isolation.");
                    }
                    result["observedUsername"] = observed["username"];
                    result["observedSid"] = token["userSid"];
                    result["integrityLabel"] = token["integrityLabel"];
                    result["desktop"] = observed["desktop"];
                    string shell = Path.Combine(Environment.SystemDirectory, @"WindowsPowerShell\v1.0\powershell.exe");
                    Dictionary<string, object> run = session.Call("exec", new Dictionary<string, object>
                    {
                        { "exe", shell },
                        { "args", new[] { "-NoLogo", "-NoProfile", "-NonInteractive", "-Command", "$PSVersionTable.PSVersion.ToString()" } },
                        { "timeoutSeconds", 12 }
                    }, 30000);
                    Dictionary<string, object> shellToken = (Dictionary<string, object>)run["token"];
                    Version version;
                    if ((bool)run["timedOut"] || Convert.ToInt32(run["exitCode"]) != 0 ||
                        !SameWindowsName((string)shellToken["userSid"], profile.workerSid) ||
                        (string)shellToken["integrityRid"] != "0x2000" ||
                        !Version.TryParse(Convert.ToString(run["stdout"]).Trim(), out version))
                    {
                        throw new InvalidOperationException("Windows PowerShell did not return a version under the isolated account.");
                    }
                    result["powershellVersion"] = version.ToString();
                }
            }
            else
            {
                // Exercise the DPAPI binding without starting a logon session.
                byte[] password = DpapiUnprotect(File.ReadAllBytes(profile.credentialFile), profile.instanceId,
                    profile.controllerSid, profile.workerSid);
                Array.Clear(password, 0, password.Length);
            }
            Console.WriteLine(ToJson(result));
            return 0;
        }
    }
}
