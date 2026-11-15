package io.github.leexeo.cage.gbox;

import android.content.pm.ApplicationInfo;
import android.util.Log;
import java.lang.ref.WeakReference;
import java.lang.reflect.Field;
import java.util.Map;

/** Opt-in, read-only observations; never logs package queries or raw paths. */
public final class CacheTrace {
    private static final String TAG = "CageCacheTrace";
    private static final String GMS = "com.google.android.gms";
    private CacheTrace() {}
    public static void before() { snapshot("before"); }
    public static void after() { snapshot("after"); }
    public static void failed() { snapshot("failed"); }

    private static Field field(Class<?> type, String name) throws Exception {
        for (Class<?> c = type; c != null; c = c.getSuperclass()) {
            try { Field f = c.getDeclaredField(name); f.setAccessible(true); return f; }
            catch (NoSuchFieldException absent) { }
        }
        throw new NoSuchFieldException();
    }
    private static Object get(Object o, String name) throws Exception {
        return field(o.getClass(), name).get(o);
    }
    private static String path(Object o) {
        if (o == null) return "null";
        if (!(o instanceof String)) return "otherType";
        String s = (String) o;
        if (s.contains("/com.cage.android/_root/data/internal_app/")) return "physicalCode";
        if (s.startsWith("/data/app/")) return "virtualCode";
        if (s.startsWith("/system/") || s.startsWith("/apex/")) return "system";
        return "other";
    }
    private static String info(ApplicationInfo a) {
        return " infoId=" + System.identityHashCode(a) + " source=" + path(a.sourceDir)
                + " public=" + path(a.publicSourceDir);
    }
    private static void snapshot(String stage) {
        try {
            Object client = Class.forName("com.vlite.sdk.client.k").getMethod("getInst").invoke(null);
            Object process = client.getClass().getMethod("getVirtualClientProcessName").invoke(client);
            if (!"com.google.android.gms.unstable".equals(process)) return;
            Class<?> at = Class.forName("android.app.ActivityThread");
            Object thread = at.getDeclaredMethod("currentActivityThread").invoke(null);
            synchronized (get(thread, "mResourcesManager")) {
                for (String name : new String[] {"mPackages", "mResourcePackages"}) {
                    Object ref = ((Map<?, ?>) get(thread, name)).get(GMS);
                    Object apk = ref instanceof WeakReference ? ((WeakReference<?>) ref).get() : null;
                    if (apk == null) Log.i(TAG, stage + " " + name + " present=false");
                    else {
                        ApplicationInfo a = (ApplicationInfo) get(apk, "mApplicationInfo");
                        Log.i(TAG, stage + " " + name + " present=true apkId=" + System.identityHashCode(apk)
                                + info(a) + " appDir=" + path(get(apk, "mAppDir"))
                                + " resDir=" + path(get(apk, "mResDir"))
                                + " resources=" + (get(apk, "mResources") != null)
                                + " application=" + (get(apk, "mApplication") != null));
                    }
                }
            }
            Object cache = field(android.content.pm.PackageManager.class, "sApplicationInfoCache").get(null);
            boolean wrapped = cache.getClass().getName().startsWith("com.vlite.");
            if (wrapped) cache = get(cache, "a");
            synchronized (get(cache, "mLock")) {
                Map<?, ?> entries = (Map<?, ?>) get(cache, "mCache");
                int found = 0;
                for (Map.Entry<?, ?> e : entries.entrySet()) {
                    if (!GMS.equals(get(e.getKey(), "packageName"))) continue;
                    if (!(e.getValue() instanceof ApplicationInfo)) continue;
                    ++found;
                    Log.i(TAG, stage + " appInfoCache wrapped=" + wrapped
                            + " flags=" + ((Number) get(e.getKey(), "flags")).longValue()
                            + " user=" + ((Number) get(e.getKey(), "userId")).intValue()
                            + info((ApplicationInfo) e.getValue()));
                }
                Log.i(TAG, stage + " appInfoCache entries=" + found + " wrapped=" + wrapped);
            }
        } catch (Throwable unavailable) {
            Log.i(TAG, stage + " unavailable=" + unavailable.getClass().getSimpleName());
        }
    }
}
