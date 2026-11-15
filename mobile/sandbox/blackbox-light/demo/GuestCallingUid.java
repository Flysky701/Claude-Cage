package io.github.leexeo.cage.space;

import android.app.ActivityManager;
import android.content.pm.ApplicationInfo;
import android.os.Binder;
import java.lang.reflect.Method;
import java.util.List;

/** Resolve an incoming guest Binder caller by its real PID in this space's process registry. */
public final class GuestCallingUid {
    private static final ThreadLocal<Boolean> resolving = new ThreadLocal<>();
    private static final String[] PACKAGES = {"com.google.android.gms", "com.android.vending",
            "com.google.android.gsf", "com.anthropic.claude"};

    public static Integer incoming(int realUid) {
        if (Boolean.TRUE.equals(resolving.get())) return realUid;
        int pid = Binder.getCallingPid();
        try {
            Class<?> core = Class.forName("top.niunaijun.blackbox.BlackBoxCore");
            if (realUid != (Integer) core.getMethod("getHostUid").invoke(null)) {
                GuestIntegrityTrace.callerUid(realUid, pid, realUid, "outside_host");
                return null;
            }
            if (pid == android.os.Process.myPid()) {
                GuestIntegrityTrace.callerUid(realUid, pid, realUid, "local");
                return null;
            }
            Class<?> activity = Class.forName("top.niunaijun.blackbox.app.BActivityThread");
            String recipient = (String) activity.getMethod("getAppPackageName").invoke(null);
            boolean guest = false;
            for (String pkg : PACKAGES) if (pkg.equals(recipient)) guest = true;
            if (!guest) return null;
            // An unresolved incoming caller retains its real identity. Never use the
            // recipient's cached UID or the UID supplied by an AttributionSource.
            if (pid <= 0) {
                GuestIntegrityTrace.callerUid(realUid, pid, realUid, "pid_unavailable");
                return realUid;
            }
            resolving.set(true);
            int user = (Integer) activity.getMethod("getUserId").invoke(null);
            Object manager = core.getMethod("getBActivityManager").invoke(null);
            Method processes = manager.getClass().getMethod("getRunningAppProcesses", String.class, int.class);
            Object packages = core.getMethod("getBPackageManager").invoke(null);
            Object packageService = packages.getClass().getMethod("getService").invoke(packages);
            if (packageService == null) return realUid;
            Method info = Class.forName("top.niunaijun.blackbox.core.system.pm.IBPackageManagerService")
                    .getMethod("getApplicationInfo", String.class, int.class, int.class);
            for (String pkg : PACKAGES) {
                Object result = processes.invoke(manager, pkg, user);
                if (result == null) continue;
                List<?> entries = (List<?>) result.getClass().getField("mAppProcessInfoList").get(result);
                for (Object entry : entries) {
                    ActivityManager.RunningAppProcessInfo process = (ActivityManager.RunningAppProcessInfo) entry;
                    if (process.pid != pid) continue;
                    ApplicationInfo app = (ApplicationInfo) info.invoke(packageService, pkg, 0, user);
                    int mapped = app == null || app.uid < 10000 ? realUid : app.uid;
                    GuestIntegrityTrace.callerUid(realUid, pid, mapped, "process_match");
                    return mapped;
                }
            }
            GuestIntegrityTrace.callerUid(realUid, pid, realUid, "process_missing");
            return realUid;
        } catch (ReflectiveOperationException | RuntimeException unavailable) {
            GuestIntegrityTrace.callerUid(realUid, pid, realUid, "lookup_unavailable_" + unavailable.getClass().getSimpleName());
            return realUid;
        } finally { resolving.remove(); }
    }
}
