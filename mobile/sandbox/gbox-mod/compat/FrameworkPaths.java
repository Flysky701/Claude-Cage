package io.github.leexeo.cage.gbox;

import android.content.Context;
import android.content.pm.ApplicationInfo;
import android.os.Build;
import android.os.Looper;
import android.util.Log;
import java.io.File;
import java.lang.ref.WeakReference;
import java.lang.reflect.Field;
import java.lang.reflect.Method;
import java.util.List;
import java.util.Iterator;
import java.util.Map;
import java.util.Set;

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

    public static String selectPackageAbi(String[] supported, Set<String> apkAbis) {
        if (supported == null || apkAbis == null) return null;
        for (String abi : supported) {
            if (("arm64-v8a".equals(abi) || "armeabi-v7a".equals(abi) || "armeabi".equals(abi))
                    && apkAbis.contains(abi)) {
                return abi;
            }
        }
        for (String abi : supported) {
            if (apkAbis.contains(abi)) return abi;
        }
        return null;
    }

    public static String defaultPackageAbi(String abi) {
        if ("arm64-v8a".equals(abi) || "armeabi-v7a".equals(abi) || "armeabi".equals(abi)) {
            return abi;
        }
        String[] supported = Build.SUPPORTED_ABIS;
        if (supported != null) {
            for (String candidate : supported) {
                if ("arm64-v8a".equals(candidate) || "armeabi-v7a".equals(candidate) || "armeabi".equals(candidate)) {
                    return candidate;
                }
            }
        }
        return abi;
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
            // Publish physical PM results before retiring the stale entry so a
            // concurrent lookup cannot recreate it from the old virtual paths.
            ready = roots;
            stage = "uninitializedPackageCache";
            discardFailedGmsPackageCache(client, roots, copy);
            Log.i(TAG, "bind.ready guestMatches=true rootsDistinct=true copied=true");
        } catch (Exception failure) {
            ready = null;
            Log.e(TAG, "bind.failed stage=" + stage + " exception=" + failure.getClass().getSimpleName());
            throw new IllegalStateException("Guarded Framework path preparation failed");
        }
    }

    /**
     * MuMu's first GMS unstable service bind can ask for a Context before the
     * verified physical-path adapter is ready. Android caches the LoadedApk
     * before loading resources, and that failed cache entry keeps its old path.
     * Only retire that failed, unused code-cache entry in this exact cold path.
     */
    private static void discardFailedGmsPackageCache(Object client, Roots roots,
                                                      ApplicationInfo physical) throws Exception {
        if (!"com.google.android.gms".equals(roots.guest)) return;
        String process = (String) client.getClass().getMethod("getVirtualClientProcessName").invoke(client);
        if (!"com.google.android.gms.unstable".equals(process)) return;
        if (Looper.myLooper() != Looper.getMainLooper()) {
            throw new IllegalStateException("GMS cache repair requires the main thread");
        }
        Object registered = requiredField(client, "q");
        if (!(registered instanceof Map)) throw new IllegalStateException("Unexpected application registry type");
        boolean guestRegistered;
        // This sample registers new Applications on the main thread. Avoid
        // nesting its registry lock inside the framework resource-manager lock.
        synchronized (registered) {
            guestRegistered = ((Map<?, ?>) registered).containsKey(roots.guest);
        }
        Class<?> threadClass = Class.forName("android.app.ActivityThread");
        Object thread = threadClass.getDeclaredMethod("currentActivityThread").invoke(null);
        Object lock = requiredField(thread, "mResourcesManager");
        if (lock == null) throw new IllegalStateException("Framework cache lock unavailable");
        Map<?, ?> packages;
        Object reference, loaded;
        ApplicationInfo cached;
        String appDir, resDir;
        synchronized (lock) {
            Object value = requiredField(thread, "mPackages");
            if (!(value instanceof Map)) throw new IllegalStateException("Unexpected package cache type");
            packages = (Map<?, ?>) value;
            reference = packages.get(roots.guest);
            if (reference == null) return;
            if (!(reference instanceof WeakReference)) throw new IllegalStateException("Unexpected package cache entry");
            loaded = ((WeakReference<?>) reference).get();
            if (loaded == null) return;
            if (!"android.app.LoadedApk".equals(loaded.getClass().getName())) {
                throw new IllegalStateException("Unexpected cached package class");
            }
            cached = (ApplicationInfo) requiredField(loaded, "mApplicationInfo");
            if (cached == null || !roots.guest.equals(cached.packageName)
                    || !roots.guest.equals(requiredField(loaded, "mPackageName"))) {
                throw new IllegalStateException("Cached package identity mismatch");
            }
            appDir = (String) requiredField(loaded, "mAppDir");
            resDir = (String) requiredField(loaded, "mResDir");
        }
        String expectedRes = cached.uid == android.os.Process.myUid() ? physical.sourceDir : physical.publicSourceDir;
        if (equal(appDir, physical.sourceDir) && equal(resDir, expectedRes)) return;
        // Path mapping and application methods run outside the framework lock.
        if (appDir == null || resDir == null || !appDir.startsWith("/data/app/")
                || !resDir.startsWith("/data/app/")
                || !equal(mapped(appDir, roots, CODE, false), physical.sourceDir)
                || !equal(mapped(resDir, roots, CODE, false), expectedRes)) {
            throw new IllegalStateException("Cached paths do not map to the verified guest APK");
        }
        if (guestRegistered || requiredField(client, "o") != null) {
            throw new IllegalStateException("Guest application already initialized");
        }
        Object applications = requiredField(thread, "mAllApplications");
        if (!(applications instanceof List)) throw new IllegalStateException("Unexpected framework application registry");
        for (Object item : (List<?>) applications) {
            if (!(item instanceof android.app.Application)) throw new IllegalStateException("Unexpected application entry");
            if (roots.guest.equals(((android.app.Application) item).getPackageName())) {
                throw new IllegalStateException("Guest application already registered");
            }
        }
        synchronized (lock) {
            if (packages.get(roots.guest) != reference || ((WeakReference<?>) reference).get() != loaded
                    || requiredField(loaded, "mApplicationInfo") != cached
                    || requiredField(loaded, "mApplication") != null
                    || requiredField(loaded, "mResources") != null) {
                throw new IllegalStateException("Refusing to repair a changed or in-use cached package");
            }
        }
        // The same pre-adapter ApplicationInfo can survive in the PM cache,
        // keyed by flags. Removing only LoadedApk recreates it with that stale
        // object. Retire only the observed GMS framework-query entry, preserving
        // all other keys, values and the wrapper's original query behavior.
        retireMatchingGmsApplicationInfo(cached);
        boolean loaderPresent;
        synchronized (lock) {
            if (packages.get(roots.guest) != reference || ((WeakReference<?>) reference).get() != loaded
                    || requiredField(loaded, "mApplicationInfo") != cached
                    || !roots.guest.equals(cached.packageName)
                    || !roots.guest.equals(requiredField(loaded, "mPackageName"))
                    || !equal(requiredField(loaded, "mAppDir"), appDir)
                    || !equal(requiredField(loaded, "mResDir"), resDir)) {
                throw new IllegalStateException("Cached package changed during validation");
            }
            if (requiredField(client, "o") != null || requiredField(loaded, "mApplication") != null
                    || requiredField(loaded, "mResources") != null) {
                throw new IllegalStateException("Refusing to retire an in-use cached package");
            }
            loaderPresent = requiredField(loaded, "mClassLoader") != null;
            packages.remove(roots.guest);
        }
        Log.i(TAG, "cache.failedGmsPackage.retired classLoaderPresent=" + loaderPresent);
    }

    private static void retireMatchingGmsApplicationInfo(ApplicationInfo stale) throws Exception {
        Field cacheField = android.content.pm.PackageManager.class.getDeclaredField("sApplicationInfoCache");
        cacheField.setAccessible(true);
        Object cache = cacheField.get(null);
        if (cache == null) throw new IllegalStateException("Application info cache unavailable");
        if ("com.vlite.sdk.client.virtualservice.a".equals(cache.getClass().getName())) {
            cache = requiredField(cache, "a");
        }
        Class<?> cacheClass = Class.forName("android.app.PropertyInvalidatedCache");
        if (!cacheClass.isInstance(cache)) throw new IllegalStateException("Unexpected application info cache");
        Field lockField = cacheClass.getDeclaredField("mLock");
        Field mapField = cacheClass.getDeclaredField("mCache");
        lockField.setAccessible(true);
        mapField.setAccessible(true);
        Object lock = lockField.get(cache);
        if (lock == null) throw new IllegalStateException("Application info cache lock unavailable");
        int removed = 0;
        synchronized (lock) {
            Object value = mapField.get(cache);
            if (!(value instanceof Map)) throw new IllegalStateException("Unexpected application info entries");
            Iterator<? extends Map.Entry<?, ?>> iterator = ((Map<?, ?>) value).entrySet().iterator();
            while (iterator.hasNext()) {
                Map.Entry<?, ?> entry = iterator.next();
                if (entry.getValue() != stale) continue;
                Object query = entry.getKey();
                if (query == null || !"android.content.pm.PackageManager$ApplicationInfoQuery".equals(query.getClass().getName())) {
                    throw new IllegalStateException("Unexpected application info query");
                }
                if (!"com.google.android.gms".equals(requiredField(query, "packageName"))
                        || ((Number) requiredField(query, "flags")).longValue() != 0x10000400L
                        || ((Number) requiredField(query, "userId")).intValue() != 0) continue;
                iterator.remove();
                ++removed;
            }
        }
        Log.i(TAG, "cache.failedGmsApplicationInfo.retired count=" + removed);
    }

    private static Object requiredField(Object object, String name) throws Exception {
        if (object == null) throw new IllegalStateException("Required framework object unavailable");
        Field field = object.getClass().getDeclaredField(name);
        field.setAccessible(true);
        return field.get(object);
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
