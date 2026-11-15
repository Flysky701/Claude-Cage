package io.github.leexeo.cage.gbox;

import android.net.Uri;
import android.os.IInterface;
import java.lang.reflect.InvocationHandler;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.lang.reflect.Proxy;
import com.vlite.sdk.client.k;

/** Relocates two companion-to-host provider endpoints in the coexistence build.
 * The original provider, Binder caller, permission checks and returned data remain
 * in use. This does not replace package signatures or grant caller permissions.
 */
public final class HostRelocation {
    private static final String OLD_HOST = "com.gbox.android";
    private static final String NEW_HOST = "com.cage.android";

    private HostRelocation() {}

    private static boolean companionCaller() {
        try {
            k client = k.getInst();
            if (!client.hasInit()) return false;
            String pkg = client.getVirtualClientPkgName();
            return "com.google.android.gms".equals(pkg)
                    || "com.gbox.android.helper".equals(pkg);
        } catch (RuntimeException error) {
            return false;
        }
    }

    public static String authority(String authority) {
        if (!companionCaller()) return authority;
        if ((OLD_HOST + ".check_env").equals(authority)) return NEW_HOST + ".check_env";
        if ((OLD_HOST + ".host_api").equals(authority)) return NEW_HOST + ".host_api";
        return authority;
    }

    public static IInterface provider(String authority, IInterface original) {
        if (original == null || !companionCaller()
                || (!(NEW_HOST + ".check_env").equals(authority)
                    && !(NEW_HOST + ".host_api").equals(authority))) return original;
        try {
            Class<?> providerInterface = Class.forName("android.content.IContentProvider");
            return (IInterface) Proxy.newProxyInstance(
                    original.getClass().getClassLoader(),
                    new Class<?>[] {providerInterface}, new Forwarder(original, authority));
        } catch (ClassNotFoundException error) {
            throw new IllegalStateException("Provider interface unavailable", error);
        }
    }

    private static final class Forwarder implements InvocationHandler {
        private final IInterface original;
        private final String target;
        private final String source;

        Forwarder(IInterface original, String target) {
            this.original = original;
            this.target = target;
            this.source = OLD_HOST + target.substring(NEW_HOST.length());
        }

        @Override public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
            Object[] forwarded = args == null ? null : args.clone();
            if (forwarded != null && companionCaller()) {
                for (int index = 0; index < forwarded.length; index++) {
                    Object value = forwarded[index];
                    if (source.equals(value)) forwarded[index] = target;
                    else if (value instanceof Uri) {
                        Uri uri = (Uri) value;
                        if ("content".equals(uri.getScheme()) && source.equals(uri.getAuthority())) {
                            forwarded[index] = uri.buildUpon().authority(target).build();
                        }
                    }
                }
            }
            try {
                return method.invoke(original, forwarded);
            } catch (InvocationTargetException error) {
                throw error.getCause();
            }
        }
    }
}
