package io.github.leexeo.cage.space;

import android.content.Context;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.content.pm.SigningInfo;
import android.os.Binder;
import android.os.Build;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.util.LinkedHashSet;

/** UID ownership comes from installed packages in this space, never the personal package manager. */
public final class GuestPackageIdentity {
    private GuestPackageIdentity() {}

    private static boolean supported(String pkg) {
        return "com.google.android.gms".equals(pkg) || "com.google.android.gsf".equals(pkg)
                || "com.android.vending".equals(pkg) || ClaudeBundle.PACKAGE.equals(pkg);
    }

    private static int privateUser() throws ReflectiveOperationException {
        Class<?> core = Class.forName("top.niunaijun.blackbox.BlackBoxCore");
        Context host = (Context) core.getMethod("getContext").invoke(null);
        if (!ClaudeBundle.HOST.equals(host.getPackageName())
                || !(Boolean) core.getMethod("isBlackProcess").invoke(core.getMethod("get").invoke(null)))
            throw new SecurityException("Private identity process required");
        Class<?> thread = Class.forName("top.niunaijun.blackbox.app.BActivityThread");
        if (!supported((String) thread.getMethod("getAppPackageName").invoke(null)))
            throw new SecurityException("Private identity guest required");
        int user = (Integer) thread.getMethod("getUserId").invoke(null);
        if (user != 0) throw new SecurityException("Unsupported private identity user");
        return user;
    }

    public static void prepare(Context guest) {
        try {
            privateUser();
            if (!supported(guest.getPackageName())) throw new SecurityException("Unexpected identity context");
            // Real and virtual UIDs can have the same numeric value. Do not reuse a
            // process-local result obtained before the private package bridge was installed.
            if (Build.VERSION.SDK_INT >= 30) Class.forName("android.app.ApplicationPackageManager")
                    .getMethod("disableGetPackagesForUidCache").invoke(null);
        } catch (ReflectiveOperationException unavailable) {
            throw new SecurityException("Private UID lookup unavailable", unavailable);
        }
    }

    public static Object query(Method method, Object[] args) throws Throwable {
        String name = method.getName();
        boolean reverse = "getPackagesForUid".equals(name);
        boolean source = "getInstallerPackageName".equals(name) || "getInstallSourceInfo".equals(name);
        if (!reverse && !source && !"getPackageUid".equals(name)) return null;
        if (!reverse && (args == null || args.length == 0 || !supported((String) args[0]))) return null;
        try {
            int user = privateUser();
            Class<?> core = Class.forName("top.niunaijun.blackbox.BlackBoxCore");
            Object packages = core.getMethod("getBPackageManager").invoke(null);
            Object service = packages.getClass().getMethod("getService").invoke(packages);
            if (service == null) throw new SecurityException("Private package service unavailable");
            Class<?> api = Class.forName("top.niunaijun.blackbox.core.system.pm.IBPackageManagerService");
            Method info = api.getMethod("getApplicationInfo", String.class, int.class, int.class);
            if (source) {
                boolean modern = "getInstallSourceInfo".equals(name);
                if (args.length != (modern ? 2 : 1)
                        || (modern && (!(args[1] instanceof Integer) || (Integer) args[1] != user)))
                    throw new SecurityException("Unsupported private install source query");
                ApplicationInfo app = (ApplicationInfo) info.invoke(service, args[0], 0, user);
                if (app == null || !args[0].equals(app.packageName))
                    throw new IllegalArgumentException("Package is not installed in this space");
                // All four supported guests were imported by this DEMO. There is
                // no Play install-session implementation and no Play provenance.
                if (!modern) return ClaudeBundle.HOST;
                Context host = (Context) core.getMethod("getContext").invoke(null);
                PackageInfo archive = host.getPackageManager().getPackageArchiveInfo(
                        host.getApplicationInfo().sourceDir, PackageManager.GET_SIGNING_CERTIFICATES);
                if (archive == null || !ClaudeBundle.HOST.equals(archive.packageName) || archive.signingInfo == null)
                    throw new SecurityException("Installing package signing metadata unavailable");
                return Class.forName("android.content.pm.InstallSourceInfo")
                        .getConstructor(String.class, SigningInfo.class, String.class, String.class)
                        .newInstance(ClaudeBundle.HOST, archive.signingInfo, null, ClaudeBundle.HOST);
            }
            if (!reverse) {
                if (args.length != 3 || !(args[1] instanceof Number) || !(args[2] instanceof Integer))
                    throw new SecurityException("Unsupported package UID query");
                long flags = ((Number) args[1]).longValue();
                if ((Integer) args[2] != user || flags != (long) (int) flags) return -1;
                ApplicationInfo app = (ApplicationInfo) info.invoke(service, args[0], (int) flags, user);
                return app == null ? -1 : app.uid;
            }
            if (args == null || args.length != 1 || !(args[0] instanceof Integer))
                throw new SecurityException("Unsupported UID ownership query");
            int uid = (Integer) args[0];
            int hostUid = (Integer) core.getMethod("getHostUid").invoke(null);
            // A local query for Process.myUid() may describe this guest. An incoming
            // unresolved Binder caller must not inherit the receiving guest's identity.
            if (uid == hostUid) {
                if (Binder.getCallingPid() == android.os.Process.myPid()) {
                    String self = (String) Class.forName("top.niunaijun.blackbox.app.BActivityThread")
                            .getMethod("getAppPackageName").invoke(null);
                    ApplicationInfo app = (ApplicationInfo) info.invoke(service, self, 0, user);
                    if (app == null) return new String[0];
                    uid = app.uid;
                } else {
                    // Some framework call sites retain Android's real host UID.
                    // Resolve only the actual incoming Binder PID, using the same
                    // private process registry as the native identity adapter.
                    Integer caller = GuestCallingUid.incoming(hostUid);
                    if (caller == null || caller == hostUid) return new String[0];
                    uid = caller;
                }
            }
            String[] candidates = (String[]) api.getMethod("getPackagesForUid", int.class, int.class)
                    .invoke(service, uid, user);
            LinkedHashSet<String> verified = new LinkedHashSet<>();
            if (candidates != null) for (String pkg : candidates) {
                if (!supported(pkg)) continue;
                ApplicationInfo app = (ApplicationInfo) info.invoke(service, pkg, 0, user);
                // The upstream server falls back to the querying process on a miss.
                // Reject that fallback unless the actual installed UID matches.
                if (app != null && pkg.equals(app.packageName) && app.uid == uid) verified.add(pkg);
            }
            String[] result = verified.toArray(new String[0]);
            GuestIntegrityTrace.uidLookup(new Object[]{uid}, result);
            return result;
        } catch (InvocationTargetException failure) {
            throw failure.getCause();
        }
    }
}
