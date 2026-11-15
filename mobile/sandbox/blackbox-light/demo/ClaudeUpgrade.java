package io.github.leexeo.cage.space;

import android.app.ActivityManager;
import android.content.Context;
import android.content.pm.PackageInfo;
import android.os.SystemClock;
import android.system.Os;
import android.system.OsConstants;
import android.system.StructStat;
import android.util.AtomicFile;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileDescriptor;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import org.json.JSONArray;
import org.json.JSONObject;

/** One package, one private user: durable upgrade/rollback, with no personal installer or data deletion. */
final class ClaudeUpgrade {
    private static final String PENDING = "pending-upgrade.json";
    private static final long MAX_BACKUP = 2L * 1024 * 1024 * 1024;
    private static final int MAX_ENTRIES = 50000;
    private static final int MAX_MANIFEST = 16 * 1024 * 1024;
    private static final String[] TREES = {"app", "user", "user-de"};
    private static final Set<String> PHASES = new HashSet<>(Arrays.asList(
            "prepared", "backed-up", "installing", "restoring", "committed", "restored", "aborted"));

    private ClaudeUpgrade() {}

    static boolean pending(Context host) throws IOException {
        File root = ClaudeBundle.root(host, false);
        return ClaudeBundle.child(root, PENDING).exists()
                || ClaudeBundle.child(root, PENDING + ".bak").exists()
                || ClaudeBundle.child(root, PENDING + ".new").exists();
    }

    static void requireIdle(Context host) throws IOException {
        if (pending(host)) throw new IOException("Claude 升级尚未完成，已暂停启动；请从导入入口恢复。");
    }

    /** Package registration is permitted while pending, but bind/ready always remain blocked. */
    static boolean allowRegistration(Context host, File source) throws Exception {
        Journal transaction = readJournal(host);
        ClaudeBundle.State old = transaction.old, next = transaction.next;
        File installed = ClaudeBundle.privateBase(host);
        if (matchesBase(source, installed, old) || matchesBase(source, installed, next)) return true;
        return matchesBase(source, ClaudeBundle.child(old.directoryFile, "base.apk"), old)
                || matchesBase(source, ClaudeBundle.child(next.directoryFile, "base.apk"), next);
    }

    private static boolean matchesBase(File source, File expected, ClaudeBundle.State state) throws Exception {
        if (!source.equals(expected) || !source.isFile()) return false;
        ClaudeBundle.Record base = state.apks.get(0);
        return source.length() == base.size && base.sha256.equals(ClaudeBundle.sha(source, ClaudeBundle.MAX_APK));
    }

    static void requireUpgrade(ClaudeBundle.State old, ClaudeBundle.State next) throws IOException {
        if (old == null || next == null || next.version <= old.version || old.signer == null
                || !old.signer.equals(next.signer) || old.directory.equals(next.directory))
            throw new IOException("升级必须使用更高版本且当前官方签名完全相同的 Claude 完整分包。");
    }

    /** Caller owns install.lock and has already verified every incoming APK and native library. */
    static String install(Context host, ClaudeBundle.State old, ClaudeBundle.State next, int uid) throws Exception {
        requireIdle(host);
        requireUpgrade(old, next);
        ClaudeBundle.validateStored(old, true, ClaudeBundle.privateBase(host));
        ClaudeBundle.validateStored(next, true, null);
        validateCurrent(host, old, uid);
        onlyUserZero(host);
        requirePackageRecord(host);

        Journal transaction = new Journal();
        transaction.id = UUID.randomUUID().toString();
        transaction.directory = ClaudeBundle.child(ClaudeBundle.root(host, false), ".upgrade-" + transaction.id);
        if (!transaction.directory.mkdir()) throw new IOException("无法创建 Claude 升级备份目录。");
        transaction.old = old;
        transaction.next = next;
        transaction.uid = uid;
        transaction.phase = "prepared";
        File oldActive = ClaudeBundle.child(transaction.directory, "old-active.json");
        byte[] activeBytes;
        try (InputStream input = ClaudeBundle.active(ClaudeBundle.root(host, false)).openRead()) {
            activeBytes = read(input, 128 * 1024);
        }
        writeNew(oldActive, activeBytes);
        transaction.activeHash = ClaudeBundle.sha(oldActive, 128 * 1024);
        saveJournal(host, transaction); // Durable launch barrier, before stopping or copying guest data.
        try {
            stop(host);
            validateCurrent(host, old, uid);
            ClaudeBundle.validateStored(old, true, ClaudeBundle.privateBase(host));
            List<Tree> trees = backup(host, transaction);
            transaction.backupHash = ClaudeBundle.sha(ClaudeBundle.child(transaction.directory, "backup.json"), MAX_MANIFEST);
            transaction.phase = "backed-up";
            saveJournal(host, transaction);
            stop(host);
            for (Tree tree : trees) verifyTree(tree, live(host, tree.name));

            transaction.phase = "installing";
            saveJournal(host, transaction); // Recovery must roll back from this point, even after process death.
            installPrivate(next);
            stop(host);
            validateCurrent(host, next, uid);
            ClaudeBundle.validateStored(next, true, ClaudeBundle.privateBase(host));
            // The original guest has not run. Installer-created changes to user data are not accepted silently.
            for (Tree tree : trees) if (!"app".equals(tree.name)) verifyTree(tree, live(host, tree.name));
            ClaudeBundle.publish(ClaudeBundle.active(ClaudeBundle.root(host, false)), next);
            syncDirectory(ClaudeBundle.root(host, false));
            validateActive(host, next);
            transaction.phase = "committed";
            saveJournal(host, transaction);
            closeJournal(host, transaction);
            return "Claude 已升级到 " + next.versionName + "；原版签名、账号和应用数据已保留。";
        } catch (Exception failure) {
            android.util.Log.w("CageDemo", "Claude upgrade stopped: phase=" + transaction.phase
                    + " reason=" + failureCode(failure));
            // Once commit is durable, an app might have started after the barrier was removed.
            // Never restore an older data snapshot after this point.
            if ("committed".equals(transaction.phase))
                throw new IOException("Claude 新版已提交；收尾记录需恢复，升级备份已保留。", failure);
            try {
                rollback(host, transaction);
            } catch (Exception recoveryFailure) {
                failure.addSuppressed(recoveryFailure);
                throw new IOException("Claude 升级未完成且自动恢复受阻；已暂停启动，完整备份与失败现场均保留。", failure);
            }
            throw new IOException("Claude 升级未完成，已恢复原版与原数据；备份和失败现场已保留。", failure);
        }
    }

    /** Fixed reason codes only: never include a user path, filename, account, or exception message. */
    private static String failureCode(Throwable failure) {
        for (int depth = 0; failure != null && depth < 8; depth++, failure = failure.getCause()) {
            String message = failure.getMessage();
            if ("私有安装路径包含链接或路径跳转。".equals(message)) return "linked_path";
            if ("Claude 数据包含链接或特殊文件，已停止自动升级。".equals(message)) return "unsupported_file_kind";
            if ("无法保留 Claude 文件时间。".equals(message)) return "file_timestamp";
            if ("Claude 数据目录集合发生变化。".equals(message)) return "data_paths_changed";
            if ("Claude 数据内容或文件属性校验失败。".equals(message)) return "data_or_metadata_changed";
            if ("Claude 私有安装版本或原应用身份不一致。".equals(message)) return "package_identity";
            if ("空间不足以保存完整备份和恢复副本，未开始升级。".equals(message)) return "backup_space";
            if ("Claude 来宾进程尚未完全退出，未继续改动数据。".equals(message)) return "guest_still_running";
            if ("Claude 私有安装未完成。".equals(message)) return "private_installer";
            if (failure instanceof android.system.ErrnoException)
                return "filesystem_errno_" + ((android.system.ErrnoException) failure).errno;
        }
        return "unclassified";
    }

    /** Resumes only this importer's recorded transaction, under the same exclusive install lock. */
    static String recoverIfNeeded(Context host) throws Exception {
        if (!pending(host)) return null;
        Journal transaction = readJournal(host);
        stop(host);
        if ("committed".equals(transaction.phase)) {
            validateCurrent(host, transaction.next, transaction.uid);
            validateActive(host, transaction.next);
            ClaudeBundle.validateStored(transaction.next, true, ClaudeBundle.privateBase(host));
            saveJournal(host, transaction);
            closeJournal(host, transaction);
            return "Claude " + transaction.next.versionName + " 的升级已完成恢复；现有数据未回退。";
        }
        if ("restored".equals(transaction.phase) || "aborted".equals(transaction.phase)) {
            validateCurrent(host, transaction.old, transaction.uid);
            validateActive(host, transaction.old);
            ClaudeBundle.validateStored(transaction.old, true, ClaudeBundle.privateBase(host));
            saveJournal(host, transaction);
            closeJournal(host, transaction);
        } else {
            rollback(host, transaction);
        }
        return "已恢复 Claude " + transaction.old.versionName + " 与原数据；请重新选择要升级的完整原版分包。";
    }

    private static void rollback(Context host, Journal transaction) throws Exception {
        stop(host);
        onlyUserZero(host);
        ClaudeBundle.validateStored(transaction.old, true, null);
        File activeBackup = ClaudeBundle.child(transaction.directory, "old-active.json");
        if (!transaction.activeHash.equals(ClaudeBundle.sha(activeBackup, 128 * 1024)))
            throw new IOException("旧 Claude 安装记录备份校验失败。");
        if ("prepared".equals(transaction.phase) || "backed-up".equals(transaction.phase)) {
            // No installer was invoked: do not replace live data with a partial or unnecessary snapshot.
            validateCurrent(host, transaction.old, transaction.uid);
            validateActive(host, transaction.old);
            ClaudeBundle.validateStored(transaction.old, true, ClaudeBundle.privateBase(host));
            transaction.phase = "aborted";
            saveJournal(host, transaction);
            closeJournal(host, transaction);
            return;
        }
        List<Tree> trees = readBackup(transaction);
        for (Tree tree : trees) verifyTree(tree, backupRoot(transaction, tree.name));
        transaction.phase = "restoring";
        saveJournal(host, transaction);
        // The private installer deletes its app directory. Move that failed installation aside first.
        preserve(live(host, "app"), transaction, "app-before-rollback");
        installPrivate(transaction.old);
        stop(host);
        validateCurrent(host, transaction.old, transaction.uid);
        for (Tree tree : trees) restoreTree(host, transaction, tree);
        writeAtomic(ClaudeBundle.active(ClaudeBundle.root(host, false)), readFile(activeBackup, 128 * 1024));
        syncDirectory(ClaudeBundle.root(host, false));
        validateCurrent(host, transaction.old, transaction.uid);
        validateActive(host, transaction.old);
        ClaudeBundle.validateStored(transaction.old, true, ClaudeBundle.privateBase(host));
        for (Tree tree : trees) verifyTree(tree, live(host, tree.name));
        transaction.phase = "restored";
        saveJournal(host, transaction);
        closeJournal(host, transaction);
    }

    private static void installPrivate(ClaudeBundle.State state) throws Exception {
        Class<?> option = Class.forName("top.niunaijun.blackbox.entity.pm.InstallOption");
        Object storage = option.getMethod("installByStorage").invoke(null);
        Object result = Class.forName("top.niunaijun.blackbox.core.system.pm.IBPackageManagerService")
                .getMethod("installPackageAsUser", String.class, option, int.class)
                .invoke(service("getBPackageManager"), ClaudeBundle.child(state.directoryFile, "base.apk").getPath(), storage, 0);
        if (result == null || !result.getClass().getField("success").getBoolean(result))
            throw new IOException("Claude 私有安装未完成。");
    }

    private static Object service(String getter) throws Exception {
        Object manager = Class.forName("top.niunaijun.blackbox.BlackBoxCore").getMethod(getter).invoke(null);
        Object service = manager.getClass().getMethod("getService").invoke(manager);
        if (service == null) throw new IOException("空间私有服务暂不可用。");
        return service; // Raw service only; public wrappers may fall back outside the private space.
    }

    private static List<ActivityManager.RunningAppProcessInfo> running() throws Exception {
        Object result = Class.forName("top.niunaijun.blackbox.core.system.am.IBActivityManagerService")
                .getMethod("getRunningAppProcesses", String.class, int.class)
                .invoke(service("getBActivityManager"), ClaudeBundle.PACKAGE, 0);
        if (result == null) throw new IOException("无法确认 Claude 来宾进程状态。");
        Object values = result.getClass().getField("mAppProcessInfoList").get(result);
        if (!(values instanceof List)) throw new IOException("空间进程记录无效。");
        List<ActivityManager.RunningAppProcessInfo> resultList = new ArrayList<>();
        for (Object value : (List<?>) values) {
            if (!(value instanceof ActivityManager.RunningAppProcessInfo)) throw new IOException("空间进程记录无效。");
            ActivityManager.RunningAppProcessInfo process = (ActivityManager.RunningAppProcessInfo) value;
            if (process.pid <= 0 || process.pid == android.os.Process.myPid() || process.processName == null
                    || !(ClaudeBundle.PACKAGE.equals(process.processName) || process.processName.startsWith(ClaudeBundle.PACKAGE + ":")))
                throw new IOException("无法安全确认 Claude 来宾进程。");
            resultList.add(process);
        }
        return resultList;
    }

    private static void stop(Context host) throws Exception {
        if (!pending(host)) throw new IOException("Claude 升级启动保护未生效。");
        Set<Integer> observed = new HashSet<>();
        for (ActivityManager.RunningAppProcessInfo process : running()) observed.add(process.pid);
        Object packages = service("getBPackageManager");
        Class<?> api = Class.forName("top.niunaijun.blackbox.core.system.pm.IBPackageManagerService");
        api.getMethod("stopPackage", String.class, int.class).invoke(packages, ClaudeBundle.PACKAGE, 0);
        long end = SystemClock.elapsedRealtime() + 5000;
        do {
            List<ActivityManager.RunningAppProcessInfo> current = running();
            for (ActivityManager.RunningAppProcessInfo process : current) observed.add(process.pid);
            boolean alive = false;
            for (int pid : observed) if (new File("/proc/" + pid).exists()) alive = true;
            if (current.isEmpty() && !alive) return;
            if (!current.isEmpty()) api.getMethod("stopPackage", String.class, int.class)
                    .invoke(packages, ClaudeBundle.PACKAGE, 0);
            Thread.sleep(100);
        } while (SystemClock.elapsedRealtime() < end);
        throw new IOException("Claude 来宾进程尚未完全退出，未继续改动数据。");
    }

    private static void validateCurrent(Context host, ClaudeBundle.State state, int uid) throws Exception {
        SpacePackages packages = new SpacePackages(host);
        PackageInfo current = packages.installed(ClaudeBundle.PACKAGE);
        if (uid <= 0 || current == null || !packages.privateCopy(current)
                || !ClaudeBundle.PACKAGE.equals(current.packageName) || SpacePackages.version(current) != state.version
                || current.applicationInfo.uid != uid)
            throw new IOException("Claude 私有安装版本或原应用身份不一致。");
    }

    private static void validateActive(Context host, ClaudeBundle.State expected) throws Exception {
        byte[] bytes;
        try (InputStream input = ClaudeBundle.active(ClaudeBundle.root(host, false)).openRead()) { bytes = read(input, 128 * 1024); }
        ClaudeBundle.State actual = ClaudeBundle.decodeState(host, new JSONObject(new String(bytes, StandardCharsets.UTF_8)), true,
                ClaudeBundle.privateBase(host));
        if (actual.version != expected.version || !actual.directory.equals(expected.directory) || !actual.signer.equals(expected.signer))
            throw new IOException("Claude 已发布状态与恢复记录不一致。");
    }

    private static void onlyUserZero(Context host) throws Exception {
        for (String name : new String[]{"user", "user_de"}) {
            File directory = ClaudeBundle.exact(new File(ClaudeBundle.data(host), "blackbox/data/" + name));
            if (!directory.isDirectory()) throw new IOException("无法确认 Claude 私有用户目录。");
            File[] users = directory.listFiles();
            if (users == null) throw new IOException("无法读取空间用户目录。");
            for (File user : users) if (!"0".equals(user.getName())
                    && ClaudeBundle.exact(new File(user, ClaudeBundle.PACKAGE)).exists())
                throw new IOException("Claude 还存在于其他空间用户，当前升级已停止。");
        }
    }

    private static void requirePackageRecord(Context host) throws Exception {
        File app = live(host, "app");
        File record = ClaudeBundle.child(app, "package.conf");
        if (!record.isFile() || record.length() <= 0
                || ClaudeBundle.child(app, "package.conf.new").exists() || ClaudeBundle.child(app, "package.conf.bak").exists())
            throw new IOException("旧 Claude 私有安装记录未稳定，已停止升级。");
    }

    private static File live(Context host, String name) throws IOException {
        String relative;
        if ("app".equals(name)) relative = "app/";
        else if ("user".equals(name)) relative = "user/0/";
        else if ("user-de".equals(name)) relative = "user_de/0/";
        else throw new IOException("未知 Claude 备份范围。");
        return ClaudeBundle.exact(new File(ClaudeBundle.data(host), "blackbox/data/" + relative + ClaudeBundle.PACKAGE));
    }

    private static File backupRoot(Journal transaction, String name) throws IOException {
        if (!Arrays.asList(TREES).contains(name)) throw new IOException("未知 Claude 备份范围。");
        return ClaudeBundle.child(transaction.directory, "backup-" + name);
    }

    private static List<Tree> backup(Context host, Journal transaction) throws Exception {
        List<Tree> trees = new ArrayList<>();
        Budget budget = new Budget();
        for (String name : TREES) trees.add(scan(name, live(host, name), budget));
        // Keep enough space for the backup, replacement base, and a separate restore copy.
        if (transaction.directory.getUsableSpace() < budget.bytes * 2 + ClaudeBundle.MAX_APK + 64L * 1024 * 1024)
            throw new IOException("空间不足以保存完整备份和恢复副本，未开始升级。");
        for (Tree tree : trees) {
            copyTree(tree, live(host, tree.name), backupRoot(transaction, tree.name));
            verifyTree(tree, live(host, tree.name));
            verifyTree(tree, backupRoot(transaction, tree.name));
        }
        JSONArray array = new JSONArray();
        for (Tree tree : trees) array.put(tree.json());
        writeNew(ClaudeBundle.child(transaction.directory, "backup.json"),
                new JSONObject().put("schema", 2).put("trees", array).toString().getBytes(StandardCharsets.UTF_8));
        syncDirectory(transaction.directory);
        return trees;
    }

    private static List<Tree> readBackup(Journal transaction) throws Exception {
        File manifest = ClaudeBundle.child(transaction.directory, "backup.json");
        if (transaction.backupHash == null || !transaction.backupHash.equals(ClaudeBundle.sha(manifest, MAX_MANIFEST)))
            throw new IOException("Claude 完整备份记录不可用，已保留现场并暂停恢复。");
        JSONObject json = new JSONObject(new String(readFile(manifest, MAX_MANIFEST), StandardCharsets.UTF_8));
        JSONArray values = json.getJSONArray("trees");
        if (json.getInt("schema") != 2 || values.length() != TREES.length)
            throw new IOException("Claude 备份缺少完整权限信息，已保留现场并暂停自动恢复。");
        List<Tree> trees = new ArrayList<>();
        Budget budget = new Budget();
        for (int i = 0; i < TREES.length; i++) {
            JSONObject value = values.getJSONObject(i);
            Tree tree = new Tree();
            tree.name = value.getString("name");
            tree.present = value.getBoolean("present");
            if (!TREES[i].equals(tree.name)) throw new IOException("Claude 备份范围不一致。");
            JSONArray entries = value.getJSONArray("entries");
            String previous = null;
            Set<String> directories = new HashSet<>();
            for (int at = 0; at < entries.length(); at++) {
                JSONObject row = entries.getJSONObject(at);
                Entry entry = new Entry();
                entry.path = row.getString("path");
                entry.directory = row.getBoolean("directory");
                entry.mode = row.getInt("mode");
                entry.gid = row.getInt("gid");
                entry.modified = row.getLong("modified");
                entry.size = row.getLong("size");
                entry.hash = row.getString("sha256");
                if (!relative(entry.path) || (previous != null && previous.compareTo(entry.path) >= 0)
                        || !supportedMode(entry.directory, entry.mode) || entry.gid < 0 || entry.modified < 0 || entry.size < 0
                        || (entry.directory ? entry.size != 0 || !entry.hash.isEmpty() : !entry.hash.matches("[0-9a-f]{64}")))
                    throw new IOException("Claude 备份路径或数据摘要无效。");
                if (at == 0 && (!entry.path.isEmpty() || !entry.directory)) throw new IOException("Claude 备份根目录无效。");
                if (at > 0) {
                    int slash = entry.path.lastIndexOf('/');
                    if (!directories.contains(slash < 0 ? "" : entry.path.substring(0, slash)))
                        throw new IOException("Claude 备份缺少父目录。");
                }
                if (entry.directory) directories.add(entry.path);
                budget.add(entry.size);
                tree.entries.add(entry);
                previous = entry.path;
            }
            if (tree.present != !tree.entries.isEmpty()) throw new IOException("Claude 备份存在状态不一致。");
            trees.add(tree);
        }
        return trees;
    }

    private static Tree scan(String name, File root, Budget budget) throws Exception {
        ClaudeBundle.exact(root);
        Tree tree = new Tree();
        tree.name = name;
        tree.present = root.exists();
        if (tree.present) {
            collect(root, root, tree.entries, budget, 0);
            Collections.sort(tree.entries, (a, b) -> a.path.compareTo(b.path));
        }
        return tree;
    }

    private static void collect(File root, File file, List<Entry> entries, Budget budget, int depth) throws Exception {
        if (depth > 64) throw new IOException("Claude 数据目录过深，未开始覆盖。");
        ClaudeBundle.exact(file);
        StructStat stat = Os.lstat(file.getPath());
        boolean directory = OsConstants.S_ISDIR(stat.st_mode);
        if (stat.st_uid != android.os.Process.myUid() || !supportedMode(directory, stat.st_mode & 07777)
                || (!directory && (!OsConstants.S_ISREG(stat.st_mode) || stat.st_nlink != 1))) {
            String kind = directory ? "directory" : OsConstants.S_ISREG(stat.st_mode) ? "regular"
                    : OsConstants.S_ISLNK(stat.st_mode) ? "link" : "special";
            android.util.Log.w("CageDemo", "Claude backup rejected file state: kind=" + kind
                    + " specialMask=" + Integer.toOctalString(stat.st_mode & 07000)
                    + " multiLink=" + (stat.st_nlink > 1)
                    + " ownerMatches=" + (stat.st_uid == android.os.Process.myUid()));
            throw new IOException("Claude 数据包含链接或特殊文件，已停止自动升级。");
        }
        if (file.equals(root) && !directory) throw new IOException("Claude 数据根路径不是目录。");
        Entry entry = new Entry();
        entry.path = file.equals(root) ? "" : file.getPath().substring(root.getPath().length() + 1).replace(File.separatorChar, '/');
        if (!relative(entry.path)) throw new IOException("Claude 数据路径无效。");
        entry.directory = directory;
        entry.mode = stat.st_mode & 07777;
        entry.gid = stat.st_gid;
        entry.modified = file.lastModified();
        entry.size = directory ? 0 : file.length();
        budget.add(entry.size);
        entry.hash = directory ? "" : ClaudeBundle.sha(file, MAX_BACKUP);
        entries.add(entry);
        if (directory) {
            File[] children = file.listFiles();
            if (children == null) throw new IOException("无法完整读取 Claude 数据。");
            Arrays.sort(children, (a, b) -> a.getName().compareTo(b.getName()));
            for (File child : children) collect(root, child, entries, budget, depth + 1);
        }
    }

    private static boolean supportedMode(boolean directory, int mode) {
        // Android may add setgid/sticky to cache directories. Preserve them, never silently strip them.
        return (mode & ~(directory ? 03777 : 0777)) == 0;
    }

    private static boolean relative(String path) {
        if (path == null || path.length() > 4096 || path.indexOf('\\') >= 0 || path.indexOf('\0') >= 0 || path.startsWith("/")) return false;
        if (path.isEmpty()) return true;
        for (String part : path.split("/", -1)) if (part.isEmpty() || ".".equals(part) || "..".equals(part)) return false;
        return true;
    }

    private static File descendant(File root, String path) throws IOException {
        if (!relative(path)) throw new IOException("不安全的 Claude 备份路径。");
        File file = ClaudeBundle.exact(path.isEmpty() ? root : new File(root, path));
        if (!file.equals(root) && !file.getPath().startsWith(root.getPath() + File.separator))
            throw new IOException("Claude 备份路径超出事务范围。");
        return file;
    }

    private static void copyTree(Tree tree, File source, File target) throws Exception {
        ClaudeBundle.exact(target);
        if (target.exists()) throw new IOException("拒绝覆盖已有 Claude 备份。");
        if (!tree.present) return;
        for (Entry entry : tree.entries) {
            File destination = descendant(target, entry.path);
            if (entry.directory) {
                if (!destination.mkdir()) throw new IOException("无法创建 Claude 备份目录。");
            } else {
                File original = descendant(source, entry.path);
                if (!destination.createNewFile()) throw new IOException("拒绝覆盖已有 Claude 备份文件。");
                long copied = 0;
                byte[] buffer = new byte[64 * 1024];
                try (InputStream input = new FileInputStream(original); FileOutputStream output = new FileOutputStream(destination)) {
                    for (int count; (count = input.read(buffer)) != -1;) {
                        copied += count;
                        if (copied > entry.size) throw new IOException("Claude 数据在备份期间改变。");
                        output.write(buffer, 0, count);
                    }
                    if (copied != entry.size) throw new IOException("Claude 数据备份不完整。");
                    output.getFD().sync();
                }
            }
        }
        // Apply directory metadata last, so copying children cannot change its saved timestamp.
        for (int i = tree.entries.size() - 1; i >= 0; i--) {
            Entry entry = tree.entries.get(i);
            File destination = descendant(target, entry.path);
            if (Os.lstat(destination.getPath()).st_gid != entry.gid)
                Os.chown(destination.getPath(), -1, entry.gid);
            Os.chmod(destination.getPath(), entry.mode);
            if (!destination.setLastModified(entry.modified)) throw new IOException("无法保留 Claude 文件时间。");
            if (entry.directory) syncDirectory(destination);
        }
        syncDirectory(target.getParentFile());
    }

    private static void verifyTree(Tree expected, File root) throws Exception {
        Tree actual = scan(expected.name, root, new Budget());
        if (actual.present != expected.present || actual.entries.size() != expected.entries.size())
            throw new IOException("Claude 数据目录集合发生变化。");
        for (int i = 0; i < expected.entries.size(); i++) {
            Entry a = expected.entries.get(i), b = actual.entries.get(i);
            if (!a.path.equals(b.path) || a.directory != b.directory || a.mode != b.mode || a.gid != b.gid
                    || a.size != b.size || !a.hash.equals(b.hash) || (!a.directory && a.modified != b.modified))
                throw new IOException("Claude 数据内容或文件属性校验失败。");
        }
    }

    private static void restoreTree(Context host, Journal transaction, Tree tree) throws Exception {
        File destination = live(host, tree.name);
        try { verifyTree(tree, destination); return; }
        catch (IOException changed) { /* Keep the failed live tree below before placing a verified copy. */ }
        File temporary = ClaudeBundle.child(transaction.directory, "restore-" + tree.name + "-" + UUID.randomUUID());
        copyTree(tree, backupRoot(transaction, tree.name), temporary);
        verifyTree(tree, temporary);
        preserve(destination, transaction, tree.name);
        if (tree.present) {
            if (!temporary.renameTo(destination)) throw new IOException("无法恢复 Claude 数据目录；副本和现场已保留。");
            syncDirectory(destination.getParentFile());
            syncDirectory(transaction.directory);
        }
        verifyTree(tree, destination);
    }

    private static void preserve(File source, Journal transaction, String label) throws Exception {
        ClaudeBundle.exact(source);
        if (!source.exists()) return;
        File target = ClaudeBundle.child(transaction.directory, "preserved-" + label + "-" + UUID.randomUUID());
        if (target.exists() || !source.renameTo(target)) throw new IOException("无法保留 Claude 失败现场，未继续覆盖。");
        syncDirectory(source.getParentFile());
        syncDirectory(transaction.directory);
    }

    private static Journal readJournal(Context host) throws Exception {
        File root = ClaudeBundle.root(host, false);
        File previous = ClaudeBundle.child(root, PENDING + ".bak");
        ClaudeBundle.child(root, PENDING + ".new");
        // Package queries run in another process while the writer owns install.lock.
        // AtomicFile.openRead() may delete a writer's .new file. Read only a committed
        // base (or the legacy .bak), and never repair journal sidecars from a query.
        File committed = previous.exists() ? previous : ClaudeBundle.child(root, PENDING);
        JSONObject json = new JSONObject(new String(readFile(committed, 256 * 1024), StandardCharsets.UTF_8));
        if (json.getInt("schema") != 1 || !ClaudeBundle.HOST.equals(json.getString("host"))
                || !ClaudeBundle.PACKAGE.equals(json.getString("package"))) throw new IOException("未知的 Claude 升级事务，已暂停覆盖。");
        Journal transaction = new Journal();
        transaction.id = json.getString("id");
        transaction.phase = json.getString("phase");
        transaction.uid = json.getInt("uid");
        transaction.activeHash = json.getString("activeHash");
        transaction.backupHash = json.optString("backupHash", null);
        if (!transaction.id.matches("[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}")
                || !PHASES.contains(transaction.phase) || transaction.uid <= 0 || !transaction.activeHash.matches("[0-9a-f]{64}")
                || (transaction.backupHash != null && !transaction.backupHash.matches("[0-9a-f]{64}")))
            throw new IOException("Claude 升级事务记录损坏，已保留现场并暂停覆盖。");
        transaction.directory = ClaudeBundle.child(root, ".upgrade-" + transaction.id);
        if (!transaction.directory.isDirectory()) throw new IOException("Claude 升级备份目录缺失。");
        transaction.old = ClaudeBundle.parseState(host, json.getJSONObject("old"));
        transaction.next = ClaudeBundle.parseState(host, json.getJSONObject("next"));
        requireUpgrade(transaction.old, transaction.next);
        return transaction;
    }

    private static void saveJournal(Context host, Journal transaction) throws Exception {
        JSONObject json = new JSONObject().put("schema", 1).put("host", ClaudeBundle.HOST).put("package", ClaudeBundle.PACKAGE)
                .put("id", transaction.id).put("phase", transaction.phase).put("uid", transaction.uid)
                .put("activeHash", transaction.activeHash).put("old", ClaudeBundle.encodeState(transaction.old))
                .put("next", ClaudeBundle.encodeState(transaction.next));
        if (transaction.backupHash != null) json.put("backupHash", transaction.backupHash);
        writeAtomic(new AtomicFile(ClaudeBundle.child(ClaudeBundle.root(host, false), PENDING)), json.toString().getBytes(StandardCharsets.UTF_8));
        syncDirectory(ClaudeBundle.root(host, false));
    }

    private static void closeJournal(Context host, Journal transaction) throws Exception {
        if (!("committed".equals(transaction.phase) || "restored".equals(transaction.phase) || "aborted".equals(transaction.phase)))
            throw new IOException("Claude 升级尚未达到可结束状态。");
        File root = ClaudeBundle.root(host, false);
        if (ClaudeBundle.child(root, PENDING + ".new").exists() || ClaudeBundle.child(root, PENDING + ".bak").exists())
            throw new IOException("Claude 升级记录尚未稳定。");
        File destination = ClaudeBundle.child(transaction.directory, "closed-" + transaction.phase + "-" + UUID.randomUUID() + ".json");
        if (!ClaudeBundle.child(root, PENDING).renameTo(destination)) throw new IOException("Claude 升级结束记录未完成。");
        syncDirectory(transaction.directory);
        syncDirectory(root);
    }

    private static void writeAtomic(AtomicFile file, byte[] bytes) throws Exception {
        FileOutputStream output = null;
        try {
            output = file.startWrite();
            output.write(bytes);
            file.finishWrite(output);
            File base = ClaudeBundle.exact(file.getBaseFile());
            if (new File(base + ".new").exists() || new File(base + ".bak").exists()
                    || !Arrays.equals(bytes, readFile(base, bytes.length)))
                throw new IOException("Claude 恢复记录未完整提交。");
        } catch (Exception failure) {
            if (output != null) file.failWrite(output);
            throw failure;
        }
    }

    private static void writeNew(File file, byte[] bytes) throws Exception {
        if (!file.createNewFile()) throw new IOException("拒绝覆盖已有 Claude 恢复记录。");
        try (FileOutputStream output = new FileOutputStream(file)) { output.write(bytes); output.getFD().sync(); }
        syncDirectory(file.getParentFile());
    }

    private static byte[] readFile(File file, int limit) throws IOException {
        try (InputStream input = new FileInputStream(file)) { return read(input, limit); }
    }

    private static byte[] read(InputStream input, int limit) throws IOException {
        ByteArrayOutputStream output = new ByteArrayOutputStream();
        byte[] buffer = new byte[8192];
        for (int count; (count = input.read(buffer)) != -1;) {
            if (output.size() + count > limit) throw new IOException("Claude 恢复记录超出限制。");
            output.write(buffer, 0, count);
        }
        return output.toByteArray();
    }

    private static void syncDirectory(File directory) throws Exception {
        FileDescriptor descriptor = Os.open(ClaudeBundle.exact(directory).getPath(), OsConstants.O_RDONLY, 0);
        try {
            if (!OsConstants.S_ISDIR(Os.fstat(descriptor).st_mode)) throw new IOException("恢复记录父路径不是目录。");
            Os.fsync(descriptor);
        } finally { Os.close(descriptor); }
    }

    private static final class Journal {
        String id, phase, activeHash, backupHash;
        File directory;
        int uid;
        ClaudeBundle.State old, next;
    }

    private static final class Budget {
        int entries;
        long bytes;
        void add(long size) throws IOException {
            if (size < 0 || size > MAX_BACKUP || ++entries > MAX_ENTRIES || bytes > MAX_BACKUP - size)
                throw new IOException("Claude 数据超出本次可安全备份范围，未开始覆盖。");
            bytes += size;
        }
    }

    private static final class Tree {
        String name;
        boolean present;
        final List<Entry> entries = new ArrayList<>();
        JSONObject json() throws Exception {
            JSONArray rows = new JSONArray();
            for (Entry entry : entries) rows.put(new JSONObject().put("path", entry.path).put("directory", entry.directory)
                    .put("mode", entry.mode).put("gid", entry.gid).put("modified", entry.modified).put("size", entry.size).put("sha256", entry.hash));
            return new JSONObject().put("name", name).put("present", present).put("entries", rows);
        }
    }

    private static final class Entry {
        String path, hash;
        boolean directory;
        int mode, gid;
        long modified, size;
    }
}
