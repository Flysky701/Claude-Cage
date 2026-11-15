package io.github.leexeo.cage.space;

import android.os.Binder;
import android.os.IInterface;
import java.lang.reflect.Proxy;
import java.util.Collections;

/** No virtual install sessions exist yet. Never expose the personal system installer. */
public final class GuestInstaller {
    private static Object instance;

    public static synchronized Object get() {
        if (instance != null) return instance;
        try {
            Class<?> api = Class.forName("android.content.pm.IPackageInstaller");
            Binder binder = new Binder();
            Object local = Proxy.newProxyInstance(GuestInstaller.class.getClassLoader(), new Class<?>[]{api},
                    (self, method, args) -> {
                        String name = method.getName();
                        if (method.getDeclaringClass() == Object.class) {
                            if ("equals".equals(name)) return self == args[0];
                            if ("hashCode".equals(name)) return System.identityHashCode(self);
                            if ("toString".equals(name)) return "PrivateSpaceInstaller";
                        }
                        if ("asBinder".equals(name)) return binder;
                        if ("getMySessions".equals(name) || "getAllSessions".equals(name)
                                || "getStagedSessions".equals(name))
                            return Class.forName("android.content.pm.ParceledListSlice")
                                    .getConstructor(java.util.List.class).newInstance(Collections.emptyList());
                        if ("getSessionInfo".equals(name) || "registerCallback".equals(name)
                                || "unregisterCallback".equals(name)) return null;
                        throw new UnsupportedOperationException("Private space install sessions are not implemented");
                    });
            binder.attachInterface((IInterface) local, "android.content.pm.IPackageInstaller");
            instance = local;
            return local;
        } catch (ReflectiveOperationException unavailable) {
            throw new IllegalStateException("Private installer unavailable", unavailable);
        }
    }
}
