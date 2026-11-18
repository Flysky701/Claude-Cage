using System;
using System.Collections.Generic;
using System.IO;
using System.Security.Cryptography;
using System.Text;
using System.Threading;

namespace CageLocalTool
{
    internal static partial class CageLocal
    {
        private static string ProjectVolumeId(string path)
        {
            using (var hash = SHA256.Create())
                return BitConverter.ToString(hash.ComputeHash(Encoding.UTF8.GetBytes(path.ToUpperInvariant()))).Replace("-", "").ToLowerInvariant();
        }

        private static string VolumeStamp(LocalProfileModel profile, string path)
        {
            return Path.Combine(profile.rootDir, "volume-" + ProjectVolumeId(path) + ".grant");
        }

        private static string VolumePath(LocalProfileModel profile, string path)
        {
            return Path.Combine(profile.sharedDir, "project-" + ProjectVolumeId(path));
        }

        private static FileStream AcquireProjectGrantLock(LocalProfileModel profile)
        {
            var timeout = System.Diagnostics.Stopwatch.StartNew();
            while (true)
            {
                try { return new FileStream(Path.Combine(profile.rootDir, "workbench-projects.json.lock"), FileMode.OpenOrCreate, FileAccess.ReadWrite, FileShare.None); }
                catch (IOException ex) { if ((ex.HResult & 0xffff) != 32 || timeout.ElapsedMilliseconds >= 5000) throw; Thread.Sleep(15); }
            }
        }

        // Holding the same lock as live filesystem operations serializes revoke and pending writes.
        private static void InvalidateProjectVolume(LocalProfileModel profile, string path)
        {
            var paths = ProjectCandidates(profile, Path.Combine(profile.rootDir, "workbench-projects.json"));
            paths.Add(path);
            foreach (string candidate in paths)
                if (SameWindowsName(path, candidate) || IsProjectChild(candidate, path) || IsProjectChild(path, candidate))
                    File.Delete(VolumeStamp(profile, candidate));
        }

        private static bool IsProjectChild(string child, string parent)
        {
            return child.StartsWith(parent + Path.DirectorySeparatorChar, StringComparison.OrdinalIgnoreCase);
        }

        private static string SelectedWorkbenchVolume(LocalProfileModel profile, string raw, string mount)
        {
            string host = SelectedWorkbenchProject(profile, raw);
            if (host == null) return null;
            if (!SameWindowsName(VolumePath(profile, host), mount) || !Directory.Exists(mount))
                throw new IOException("项目文件通道尚未就绪，请重新打开项目。");
            return mount;
        }

        private static int PrepareProjectVolume(LocalProfileModel profile)
        {
            var request = FromJsonObject(Console.ReadLine());
            if (!SameWindowsName((string)request["instanceId"], profile.instanceId) || !SameWindowsName((string)request["workerSid"], profile.workerSid))
                throw new InvalidDataException("项目账户已改变。");
            using (AcquireProjectGrantLock(profile))
            {
                string path = ValidateProjectTarget(profile, (string)request["path"]);
                using (var pinned = PinnedProjectDirectory.Open(path))
                {
                SelectedWorkbenchProject(profile,path);
                if (path == null) throw new InvalidDataException("请选择已授权的项目。");
                string stamp = VolumeStamp(profile, path);
                if (!File.Exists(stamp))
                {
                    File.WriteAllText(stamp, Guid.NewGuid().ToString("N"), Utf8NoBom);
                    SetControllerOnlyFileAcl(stamp, profile.controllerSid);
                }
                VerifyControllerOnlyFileAcl(stamp, profile.controllerSid, profile.workerSid);
                string effective = ExplicitProjectAccess(path, profile.workerSid);
                var readOnlyTrees = new List<string>();
                foreach (string other in ProjectCandidates(profile, Path.Combine(profile.rootDir, "workbench-projects.json")))
                {
                    if (!(IsProjectChild(other, path) || IsProjectChild(path, other))) continue;
                    if (Directory.Exists(other) && ExplicitProjectAccess(other, profile.workerSid) == "rw") continue;
                    if (IsProjectChild(path, other)) effective = "ro";
                    else readOnlyTrees.Add(other.Substring(path.Length + 1));
                }
                Console.WriteLine(ToJson(new { path, mount = VolumePath(profile, path), stamp,
                    sharedLock = Path.Combine(profile.rootDir, "workbench-projects.json.lock"), epoch = File.ReadAllText(stamp),
                    access = effective, readOnlyTrees, identity = pinned.VolumeIdentity(), workerSid = profile.workerSid,
                    instanceId = profile.instanceId, controllerSid = profile.controllerSid }));
                return 0;
                }
            }
        }
    }
}
