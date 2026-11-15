package io.github.leexeo.cage.gbox;

import android.content.Context;
import android.content.pm.ApplicationInfo;
import android.util.Log;
import java.io.File;
import java.lang.reflect.Field;
import java.lang.reflect.Method;

/** Scoped Framework path consumption. This does not intercept arbitrary file syscalls. */
public final class FrameworkPaths {
    private static final String TAG = "CageFrameworkPaths";
    private static final int CODE = 0, CE = 1, DE = 2;
    private static volatile boolean ioReturnedZero;
    private static volatile Roots ready;
    private static int pmReports;

    private FrameworkPaths() {}

    public static void ioboxReturned(int result) {
        if (!NativeCompat.isActive()) return;
        ioReturnedZero = result == 0;
        Log.i(TAG, "iobox.returnObserved zero=" + ioReturnedZero);
    }

    public static synchronized void bind(Context host, Object bindData) {
        if (!NativeCompat.isActive()) return;
        ready = null;
        String stage = "iobox";
        try {
            if (!ioReturnedZero) throw new IllegalStateException("I/O initialization was not confirmed");
            stage = "bindRecord";
            Field field = bindData.getClass().getField("c");
            ApplicationInfo original = (ApplicationInfo) field.get(bindData);
            String guest = (String) bindData.getClass().getField("a").get(bindData);
            Object client = Class.forName("com.vlite.sdk.client.k").getMethod("getInst").invoke(null);
            String current = (String) client.getClass().getMethod("getVirtualClientPkgName").invoke(client);
            if (original == null || guest == null || !guest.equals(current)
                    || !guest.equals(original.packageName)) throw new IllegalStateException("Guest binding identity mismatch");
            stage = "roots";
            Roots roots = establish(host, original, guest);
            stage = "applicationInfo";
            ApplicationInfo copy = convert(original, roots, "bind");
            field.set(bindData, copy);
            ready = roots;
            Log.i(TAG, "bind.ready guestMatches=true rootsDistinct=true copied=true");
        } catch (Exception failure) {
            ready = null;
            Log.e(TAG, "bind.failed stage=" + stage + " exception=" + failure.getClass().getSimpleName());
            throw new IllegalStateException("Guarded Framework path preparation failed");
        }
    }

    public static Object fromPackageManager(Object value) {
        Roots roots = ready;
        if (roots == null || !NativeCompat.isActive() || !(value instanceof ApplicationInfo)) return value;
        ApplicationInfo original = (ApplicationInfo) value;
        if (!roots.guest.equals(original.packageName)) return value;
        try {
            // The original PM result/cache object and every identity field remain untouched.
            return convert(original, roots, "pm");
        } catch (Exception failure) {
            Log.e(TAG, "pm.failed exception=" + failure.getClass().getSimpleName());
            throw new IllegalStateException("Guarded Framework path conversion failed");
        }
    }

    public static void contextCreated(Context context) {
        Roots roots = ready;
        if (roots == null || !NativeCompat.isActive() || context == null) return;
        try {
            ApplicationInfo info = context.getApplicationInfo();
            String credential = (String) optional(info, "credentialProtectedDataDir");
            Log.i(TAG, "context.created packageMatches=" + roots.guest.equals(info.packageName)
                    + " sourceInsideCode=" + inside(info.sourceDir, roots.code)
                    + " dataInsideCe=" + inside(info.dataDir, roots.ce)
                    + " credentialInsideCe=" + inside(credential, roots.ce)
                    + " deviceInsideDe=" + inside(info.deviceProtectedDataDir, roots.de));
        } catch (Exception unavailable) {
            Log.i(TAG, "context.observationUnavailable exception=" + unavailable.getClass().getSimpleName());
        }
    }

    /** Read-only readiness check for the exact Context returned by the guest bind. */
    public static boolean isGuestContextReady(Context context, String guest) {
        Roots roots = ready;
        if (!NativeCompat.isActive() || !ioReturnedZero || roots == null || context == null
                || guest == null || !guest.equals(roots.guest)) return false;
        try {
            ApplicationInfo info = context.getApplicationInfo();
            if (info == null || !guest.equals(context.getPackageName()) || !guest.equals(info.packageName)) return false;
            String credential = (String) optional(info, "credentialProtectedDataDir");
            return inside(info.sourceDir, roots.code) && inside(info.dataDir, roots.ce)
                && (credential == null || inside(credential, roots.ce))
                && (info.deviceProtectedDataDir == null || inside(info.deviceProtectedDataDir, roots.de));
        } catch (Exception unavailable) {
            Log.i(TAG, "context.readinessUnavailable exception=" + unavailable.getClass().getSimpleName());
            return false;
        }
    }

    private static Roots establish(Context host, ApplicationInfo info, String guest) throws Exception {
        String expected = new File(host.getApplicationInfo().dataDir, "_root").getCanonicalPath();
        Class<?> environment = Class.forName("com.vlite.sdk.context.j");
        String actual = ((File) environment.getMethod("x").invoke(null)).getCanonicalPath();
        if (!expected.equals(actual)) throw new IllegalStateException("Unexpected virtual root");
        File internal = (File) Class.forName("com.vlite.sdk.context.l").getMethod("b").invoke(null);
        String internalRoot = internal.getCanonicalPath();
        if (!internalRoot.equals(expected + "/data/internal_app")) throw new IllegalStateException("Unexpected package root");
        String ce = ((File) environment.getMethod("t", String.class).invoke(null, guest)).getCanonicalPath();
        String de = ((File) environment.getMethod("q", String.class).invoke(null, guest)).getCanonicalPath();
        String ceUser = dataRootUser(ce, expected + "/data/user/", guest);
        String deUser = dataRootUser(de, expected + "/data/user_de/", guest);
        if (!ceUser.equals(deUser) || ce.equals(de) || !new File(ce).isDirectory() || !new File(de).isDirectory()) {
            throw new IllegalStateException("Guest data roots unavailable or aliased");
        }
        Method query = Class.forName("com.vlite.sdk.jni.Native").getMethod("a", String.class);
        String source = info.sourceDir;
        // Bind metadata is already physical in the verified sample; do not redirect it twice.
        if (!inside(source, internalRoot)) source = (String) query.invoke(null, source);
        if (source == null || !inside(source, internalRoot)) throw new IllegalStateException("Guest code root unavailable");
        File code = new File(source).getCanonicalFile().getParentFile();
        if (code == null || !internalRoot.equals(code.getParent()) || !code.getName().startsWith(guest + "-")
                || !code.isDirectory()) throw new IllegalStateException("Guest package directory mismatch");
        return new Roots(guest, code.getCanonicalPath(), ce, de, query);
    }

    private static String dataRootUser(String path, String prefix, String guest) {
        if (!path.startsWith(prefix) || !path.endsWith("/" + guest)) throw new IllegalStateException("Unexpected guest data directory");
        String user = path.substring(prefix.length(), path.length() - guest.length() - 1);
        if (user.isEmpty()) throw new IllegalStateException("Missing virtual user directory");
        for (int index = 0; index < user.length(); ++index) {
            if (user.charAt(index) < '0' || user.charAt(index) > '9') throw new IllegalStateException("Invalid virtual user directory");
        }
        return user;
    }

    private static boolean inside(String path, String root) throws Exception {
        if (path == null || !new File(path).isAbsolute()) return false;
        String canonical = new File(path).getCanonicalPath();
        return canonical.equals(root) || canonical.startsWith(root + "/");
    }

    private static String mapped(String value, Roots roots, int kind, boolean directory) throws Exception {
        if (value == null) return null;
        String allowed = kind == CE ? roots.ce : kind == DE ? roots.de : roots.code;
        if (inside(value, allowed)) return value;
        String result = (String) roots.query.invoke(null, value);
        if ((result == null || value.equals(result)) && directory && !value.endsWith("/")) {
            String slash = value + "/";
            String alternative = (String) roots.query.invoke(null, slash);
            if (alternative != null && !slash.equals(alternative)) {
                result = alternative.endsWith("/") ? alternative.substring(0, alternative.length() - 1) : alternative;
            }
        }
        if (result == null || value.equals(result)) return value;
        if (!inside(result, allowed)) throw new IllegalStateException("Mapped path outside guest field root");
        return result;
    }

    private static int stringField(ApplicationInfo before, ApplicationInfo after, Roots roots,
                                   String name, int kind, boolean directory) throws Exception {
        Field field;
        try { field = ApplicationInfo.class.getDeclaredField(name); }
        catch (NoSuchFieldException absent) { return 0; }
        field.setAccessible(true);
        String old = (String) field.get(before);
        String value = mapped(old, roots, kind, directory);
        field.set(after, value);
        return equal(old, value) ? 0 : 1;
    }

    private static int arrayField(ApplicationInfo before, ApplicationInfo after, Roots roots,
                                  String name) throws Exception {
        Field field;
        try { field = ApplicationInfo.class.getDeclaredField(name); }
        catch (NoSuchFieldException absent) { return 0; }
        field.setAccessible(true);
        String[] original = (String[]) field.get(before);
        if (original == null) return 0;
        String[] copy = original.clone();
        int changed = 0;
        for (int index = 0; index < copy.length; ++index) {
            copy[index] = mapped(original[index], roots, CODE, false);
            if (!equal(copy[index], original[index])) ++changed;
        }
        field.set(after, copy);
        return changed;
    }

    private static boolean equal(Object first, Object second) {
        return first == second || first != null && first.equals(second);
    }

    private static Object optional(ApplicationInfo info, String field) throws Exception {
        try { Field member = ApplicationInfo.class.getDeclaredField(field); member.setAccessible(true); return member.get(info); }
        catch (NoSuchFieldException absent) { return null; }
    }

    private static ApplicationInfo convert(ApplicationInfo before, Roots roots, String origin) throws Exception {
        ApplicationInfo after = new ApplicationInfo(before);
        int code = 0, data = 0;
        for (String name : new String[] {"sourceDir", "publicSourceDir", "scanSourceDir", "scanPublicSourceDir"}) {
            code += stringField(before, after, roots, name, CODE, false);
        }
        for (String name : new String[] {"nativeLibraryDir", "secondaryNativeLibraryDir", "nativeLibraryRootDir"}) {
            code += stringField(before, after, roots, name, CODE, true);
        }
        for (String name : new String[] {"splitSourceDirs", "splitPublicSourceDirs", "sharedLibraryFiles", "resourceDirs", "overlayPaths"}) {
            code += arrayField(before, after, roots, name);
        }
        for (String name : new String[] {"dataDir", "credentialProtectedDataDir", "credentialEncryptedDataDir"}) {
            data += stringField(before, after, roots, name, CE, true);
        }
        for (String name : new String[] {"deviceProtectedDataDir", "deviceEncryptedDataDir"}) {
            data += stringField(before, after, roots, name, DE, true);
        }
        String credential = (String) optional(after, "credentialProtectedDataDir");
        if (!inside(after.sourceDir, roots.code) || !inside(after.dataDir, roots.ce)
                || credential != null && !inside(credential, roots.ce)
                || after.deviceProtectedDataDir != null && !inside(after.deviceProtectedDataDir, roots.de)) {
            throw new IllegalStateException("Required Framework path remains outside guest root");
        }
        boolean identity = before.uid == after.uid && before.flags == after.flags
                && before.targetSdkVersion == after.targetSdkVersion && before.enabled == after.enabled
                && equal(before.packageName, after.packageName) && equal(before.processName, after.processName)
                && equal(before.permission, after.permission)
                && equal(optional(before, "primaryCpuAbi"), optional(after, "primaryCpuAbi"))
                && equal(optional(before, "secondaryCpuAbi"), optional(after, "secondaryCpuAbi"));
        if (!identity) throw new IllegalStateException("Application identity changed");
        if (!"pm".equals(origin) || pmReports++ < 4) {
            Log.i(TAG, origin + ".copy codeFieldsChanged=" + code + " dataFieldsChanged=" + data
                    + " identityPreserved=true sourceInsideCode=" + inside(after.sourceDir, roots.code)
                    + " dataInsideCe=" + inside(after.dataDir, roots.ce)
                    + " credentialInsideCe=" + inside(credential, roots.ce)
                    + " deviceInsideDe=" + inside(after.deviceProtectedDataDir, roots.de));
        }
        return after;
    }

    private static final class Roots {
        final String guest, code, ce, de;
        final Method query;
        Roots(String guest, String code, String ce, String de, Method query) {
            this.guest = guest; this.code = code; this.ce = ce; this.de = de; this.query = query;
        }
    }
}
