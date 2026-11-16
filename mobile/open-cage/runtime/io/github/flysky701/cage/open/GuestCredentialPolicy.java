package io.github.flysky701.cage.open;

import android.os.Build;
import android.util.Log;
import java.lang.reflect.Field;
import java.util.Map;
import top.niunaijun.blackbox.BlackBoxCore;

/** Keep framework credential requests from authenticating the host instead of the guest. */
public final class GuestCredentialPolicy {
    private static boolean installed;

    private GuestCredentialPolicy() {}

    public static synchronized void beforeBind(String packageName) {
        if (installed || Build.VERSION.SDK_INT < 34 || packageName == null
                || packageName.equals(BlackBoxCore.getHostPkg())) return;
        try {
            // AndroidX falls back to the app's declared Play Services provider when this
            // framework service is unavailable. Existing private GMS routing handles that
            // provider, preserving the guest package and its real signed APK.
            Class<?> registry = Class.forName("android.app.SystemServiceRegistry");
            Field field = registry.getDeclaredField("SYSTEM_SERVICE_FETCHERS");
            field.setAccessible(true);
            Map<?, ?> fetchers = (Map<?, ?>) field.get(null);
            synchronized (fetchers) {
                fetchers.remove("credential");
            }
            installed = true;
            Log.i("CageCredentialPolicy", "Framework credentials unavailable in guest; private provider fallback enabled");
        } catch (ReflectiveOperationException error) {
            throw new IllegalStateException("Cannot isolate guest credential provider", error);
        }
    }
}
