package io.github.leexeo.cage.space;

import android.content.Context;
import android.util.AtomicFile;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.nio.channels.FileLock;

import top.niunaijun.blackbox.BlackBoxCore;
import top.niunaijun.blackbox.core.system.pm.IBPackageManagerService;

/** Keep the candidate's virtual uninstallation and split-install record in step. */
public final class CandidateClaudeRemoval {
    private CandidateClaudeRemoval() {}

    public static void remove(Context context) throws Exception {
        synchronized (ClaudeBundle.class) {
            File root = ClaudeBundle.root(context, true);
            try (FileOutputStream stream = new FileOutputStream(ClaudeBundle.child(root, "install.lock"), true);
                 FileLock lock = stream.getChannel().tryLock()) {
                if (lock == null || ClaudeUpgrade.pending(context)) {
                    throw new IOException("Claude 安装事务仍在进行。");
                }
                IBPackageManagerService service = BlackBoxCore.getBPackageManager().getService();
                if (service == null) throw new IOException("空间包管理服务未就绪。");
                service.uninstallPackageAsUser(ClaudeBundle.PACKAGE, 0);
                if (service.getPackageInfo(ClaudeBundle.PACKAGE, 0, 0) != null
                        || ClaudeBundle.privateBase(context).exists()) {
                    throw new IOException("Claude 仍在当前空间。");
                }
                ClaudeBundle.active(root).delete();
            }
        }
    }

    // The import path calls this under install.lock, after recovering any pending upgrade.
    static void clearUninstalled(Context context, AtomicFile active) throws IOException {
        if (!ClaudeBundle.privateBase(context).exists()) active.delete();
    }
}
