package io.github.leexeo.cage.space;

import android.content.Context;
import android.content.ComponentName;
import android.content.Intent;
import android.content.pm.ApplicationInfo;
import android.os.Build;
import android.util.Log;
import java.lang.reflect.Field;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.lang.reflect.Proxy;
import java.util.Map;

/** Keeps the guest's existing AndroidX fallback away from the personal credential provider. */
public final class GuestCredentials {
    private static Object privateFetcher;
    private GuestCredentials() {}

    public static Object invokeSystemBind(Object base, Method method, Object[] args) throws Throwable {
        try { guardSystemBind(args); }
        catch (SecurityException unavailable) {
            // bindService returns zero when no permitted service exists. Throwing here leaves
            // some clients waiting forever for an onServiceConnected that cannot arrive.
            if (method.getReturnType() != int.class) throw unavailable;
            return 0;
        }
        try { return method.invoke(base, args); }
        catch (InvocationTargetException failure) { throw failure.getCause(); }
    }

    /** Last check at every real bind call, including the upstream exception fallback. */
    public static void guardSystemBind(Object[] args) {
        Intent intent = null;
        if (args != null) for (Object arg : args) if (arg instanceof Intent) {
            if (intent != null) throw new SecurityException("Ambiguous service request");
            intent = (Intent) arg;
        }
        if (intent == null) return;
        ComponentName component = intent.getComponent();
        if (component != null && ClaudeBundle.HOST.equals(component.getPackageName())
                && component.getClassName().matches("top\\.niunaijun\\.blackbox\\.proxy\\.ProxyService\\$P[0-9]{1,2}")) return;
        String target = component == null ? intent.getPackage() : component.getPackageName();
        String action = intent.getAction();
        if (!"com.google.android.gms".equals(target) && !"com.android.vending".equals(target)
                && (action == null || (!action.startsWith("com.google.android.gms.")
                    && !action.startsWith("com.android.vending.")
                    && !action.startsWith("com.google.android.play.core.integrityservice.")
                    && !action.startsWith("com.google.android.play.core.expressintegrityservice.")))) return;
        try {
            Context host = (Context) Class.forName("top.niunaijun.blackbox.BlackBoxCore")
                    .getMethod("getContext").invoke(null);
            if (!ClaudeBundle.HOST.equals(host.getPackageName())) return;
        } catch (ReflectiveOperationException unavailable) {
            throw new SecurityException("Private service identity unavailable", unavailable);
        }
        String safeAction = action != null && action.matches("[a-zA-Z0-9_.$]{1,180}") ? action : "unspecified";
        Log.w("CageDemo", "Blocked personal Google service fallback: " + safeAction);
        throw new SecurityException("Google services must resolve inside this space");
    }

    public static synchronized void beforeContext(ApplicationInfo info) {
        if (Build.VERSION.SDK_INT < 34 || info == null || !ClaudeBundle.PACKAGE.equals(info.packageName)) return;
        try {
            Class<?> core = Class.forName("top.niunaijun.blackbox.BlackBoxCore");
            Context host = (Context) core.getMethod("getContext").invoke(null);
            if (!ClaudeBundle.HOST.equals(host.getPackageName())) return;
            Object instance = core.getMethod("get").invoke(null);
            if (!(Boolean) core.getMethod("isBlackProcess").invoke(instance)) return;
            Class<?> thread = Class.forName("top.niunaijun.blackbox.app.BActivityThread");
            if (!ClaudeBundle.PACKAGE.equals(thread.getMethod("getAppPackageName").invoke(null))
                    || (Integer) thread.getMethod("getUserId").invoke(null) != 0)
                throw new SecurityException("Unexpected credential guest identity");
            Class<?> registry = Class.forName("android.app.SystemServiceRegistry");
            Field field = registry.getDeclaredField("SYSTEM_SERVICE_FETCHERS");
            field.setAccessible(true);
            @SuppressWarnings("unchecked")
            Map<String, Object> fetchers = (Map<String, Object>) field.get(null);
            synchronized (fetchers) {
                if (privateFetcher != null) {
                    if (fetchers.get("credential") != privateFetcher)
                        throw new SecurityException("Guest credential isolation changed");
                    return;
                }
                Class<?> fetcher = Class.forName("android.app.SystemServiceRegistry$ServiceFetcher");
                if (!fetcher.isInterface()) throw new SecurityException("Unsupported credential registry");
                Object replacement = Proxy.newProxyInstance(fetcher.getClassLoader(), new Class<?>[]{fetcher},
                        (proxy, method, args) -> {
                            switch (method.getName()) {
                                case "getService": return null;
                                case "supportsFetchWithoutContext": return false;
                                case "toString": return "Cage private credential route";
                                case "hashCode": return System.identityHashCode(proxy);
                                case "equals": return args != null && args.length == 1 && proxy == args[0];
                                default: throw new SecurityException("Unsupported credential lookup");
                            }
                        });
                // This map belongs to this one guest process. No system service or APK is modified.
                fetchers.put("credential", replacement);
                privateFetcher = replacement;
            }
            Log.i("CageDemo", "Claude credentials: private Play Services fallback enabled");
        } catch (ReflectiveOperationException | RuntimeException failure) {
            throw new SecurityException("Personal credential provider is unavailable in this guest", failure);
        }
    }
}
