package io.github.leexeo.cage.space;

import android.content.AttributionSource;
import android.os.*;
import java.lang.reflect.*;

/** Preserve virtual app attribution for calls between guest providers. */
public final class GuestProviders {
    public static boolean internal(String pkg) {
        return "com.google.android.gms".equals(pkg) || "com.android.vending".equals(pkg)
                || "com.google.android.gsf".equals(pkg);
    }

    public static Object invoke(IInterface provider, Method method, Object[] original) throws Throwable {
        Object[] args = original == null ? null : original.clone();
        if (args != null && Build.VERSION.SDK_INT >= 31) {
            Class<?> activity = Class.forName("top.niunaijun.blackbox.app.BActivityThread");
            boolean local = provider.asBinder() instanceof Binder;
            int uid = local ? Binder.getCallingUid() : (Integer) activity.getMethod("getBUid").invoke(null);
            String pkg = (String) activity.getMethod("getAppPackageName").invoke(null);
            for (int i = 0; i < args.length; i++) if (args[i] instanceof AttributionSource) {
                AttributionSource originalSource = (AttributionSource) args[i];
                AttributionSource source = new AttributionSource.Builder(originalSource).build();
                Field stateField = AttributionSource.class.getDeclaredField("mAttributionSourceState");
                stateField.setAccessible(true);
                Object state = stateField.get(source);
                state.getClass().getField("uid").setInt(state, uid);
                state.getClass().getField("packageName").set(state, pkg);
                args[i] = source;
            }
        }
        try { return method.invoke(provider, args); }
        catch (InvocationTargetException failure) { throw failure.getCause(); }
    }
}
