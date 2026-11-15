package io.github.leexeo.cage.space;

import android.content.Context;
import android.os.Binder;
import android.os.Build;
import android.os.IInterface;
import java.lang.reflect.Field;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Proxy;
import java.util.Collections;
import java.util.Map;

/** This single-user private space has no personal/work-profile destinations. */
public final class GuestProfiles {
    private static Object privateFetcher;
    private static Object privateService;
    private GuestProfiles() {}

    public static void prepare(Context guest) {
        if (Build.VERSION.SDK_INT < 28) return;
        try {
            Class<?> core = Class.forName("top.niunaijun.blackbox.BlackBoxCore");
            Context host = (Context) core.getMethod("getContext").invoke(null);
            Class<?> thread = Class.forName("top.niunaijun.blackbox.app.BActivityThread");
            if (!ClaudeBundle.HOST.equals(host.getPackageName())
                    || !(Boolean) core.getMethod("isBlackProcess").invoke(core.getMethod("get").invoke(null))
                    || (Integer) thread.getMethod("getUserId").invoke(null) != 0)
                throw new SecurityException("Private profile process required");
            String pkg = (String) thread.getMethod("getAppPackageName").invoke(null);
            if (!guest.getPackageName().equals(pkg)) throw new SecurityException("Private profile context required");
            Class<?> registry = Class.forName("android.app.SystemServiceRegistry");
            Field field = registry.getDeclaredField("SYSTEM_SERVICE_FETCHERS");
            field.setAccessible(true);
            @SuppressWarnings("unchecked") Map<String, Object> fetchers = (Map<String, Object>) field.get(null);
            synchronized (fetchers) {
                if (privateFetcher != null) {
                    if (fetchers.get("crossprofileapps") != privateFetcher)
                        throw new SecurityException("Private profile isolation changed");
                    return;
                }
                Class<?> api = Class.forName("android.content.pm.ICrossProfileApps");
                Binder binder = new Binder();
                privateService = Proxy.newProxyInstance(api.getClassLoader(), new Class<?>[]{api},
                        (self, method, args) -> {
                            switch (method.getName()) {
                                case "asBinder": return binder;
                                case "getTargetUserProfiles": return Collections.emptyList();
                                case "canInteractAcrossProfiles":
                                case "canRequestInteractAcrossProfiles":
                                case "canConfigureInteractAcrossProfiles":
                                case "canUserAttemptToConfigureInteractAcrossProfiles": return false;
                                case "toString": return "Cage private profiles";
                                case "hashCode": return System.identityHashCode(self);
                                case "equals": return args != null && args.length == 1 && self == args[0];
                                default: throw new SecurityException("Cross-profile operations are unavailable in this space");
                            }
                        });
                binder.attachInterface((IInterface) privateService, api.getName());
                Object original = fetchers.get("crossprofileapps");
                if (original == null) throw new SecurityException("Profile service registry unavailable");
                Class<?> fetcher = Class.forName("android.app.SystemServiceRegistry$ServiceFetcher");
                Object replacement = Proxy.newProxyInstance(fetcher.getClassLoader(), new Class<?>[]{fetcher},
                        (self, method, args) -> {
                            if ("getService".equals(method.getName())) {
                                try { return isolate(method.invoke(original, args)); }
                                catch (InvocationTargetException failure) { throw failure.getCause(); }
                            }
                            if ("supportsFetchWithoutContext".equals(method.getName())) return false;
                            if ("toString".equals(method.getName())) return "Cage private profile route";
                            if ("hashCode".equals(method.getName())) return System.identityHashCode(self);
                            if ("equals".equals(method.getName())) return args != null && args.length == 1 && self == args[0];
                            throw new SecurityException("Unsupported profile lookup");
                        });
                fetchers.put("crossprofileapps", replacement);
                privateFetcher = replacement;
            }
            isolate(guest.getSystemService("crossprofileapps"));
        } catch (ReflectiveOperationException failure) {
            throw new SecurityException("Private profiles unavailable", failure);
        }
    }

    private static Object isolate(Object manager) throws ReflectiveOperationException {
        if (manager == null) throw new SecurityException("Private profile manager unavailable");
        Field field = Class.forName("android.content.pm.CrossProfileApps").getDeclaredField("mService");
        field.setAccessible(true);
        field.set(manager, privateService);
        return manager;
    }
}
