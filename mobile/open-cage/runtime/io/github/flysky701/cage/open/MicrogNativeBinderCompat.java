package io.github.flysky701.cage.open;

import android.content.Intent;
import android.content.pm.ServiceInfo;
import android.os.Build;
import android.os.IBinder;
import android.os.IInterface;
import android.os.Parcel;
import android.os.RemoteException;
import java.io.FileDescriptor;
import java.lang.reflect.Field;
import java.lang.reflect.Proxy;
import java.util.Map;
import java.util.concurrent.Executor;

/** Preserve microG's service policy using concrete methods callable by Android 16 JNI. */
public final class MicrogNativeBinderCompat {
    private MicrogNativeBinderCompat() {}

    public static void afterBind(ServiceInfo service, Intent intent) {
        if (Build.VERSION.SDK_INT != 36 || service == null || intent == null
                || !"com.google.android.gms".equals(service.packageName)
                || !"com.google.android.gms.droidguard.service.START".equals(intent.getAction())) return;
        MicrogKeystoreCompat.restoreAlgorithms();
        try {
            Field field = Class.forName("android.os.ServiceManager").getDeclaredField("sCache");
            field.setAccessible(true);
            Map<String, IBinder> cache = (Map<String, IBinder>) field.get(null);
            int count = 0;
            synchronized (cache) {
                for (String name : new String[]{"SurfaceFlinger", "thermalservice"}) {
                    IBinder original = cache.get(name);
                    if (original == null || !Proxy.isProxyClass(original.getClass())) continue;
                    String handler = Proxy.getInvocationHandler(original).getClass().getName();
                    if (!handler.startsWith("org.microg.gms.droidguard.core.ServiceCallProxy")) continue;
                    cache.put(name, new NativeCallableBinder(original));
                    count++;
                }
            }
            if (count != 0) android.util.Log.i("CageMicrogBinder", "Adapted native service calls: " + count);
        } catch (ReflectiveOperationException | RuntimeException unavailable) {
            android.util.Log.w("CageMicrogBinder", "Native service adaptation unavailable: "
                    + unavailable.getClass().getSimpleName());
        }
    }

    // Each operation still reaches the original microG wrapper. No dump policy,
    // hardware attestation request, returned data or exception is substituted.
    private static final class NativeCallableBinder implements IBinder {
        private final IBinder original;
        NativeCallableBinder(IBinder original) { this.original = original; }
        @Override public String getInterfaceDescriptor() throws RemoteException { return original.getInterfaceDescriptor(); }
        @Override public boolean pingBinder() { return original.pingBinder(); }
        @Override public boolean isBinderAlive() { return original.isBinderAlive(); }
        @Override public IInterface queryLocalInterface(String descriptor) { return original.queryLocalInterface(descriptor); }
        @Override public void dump(FileDescriptor fd, String[] args) throws RemoteException { original.dump(fd, args); }
        @Override public void dumpAsync(FileDescriptor fd, String[] args) throws RemoteException { original.dumpAsync(fd, args); }
        @Override public boolean transact(int code, Parcel data, Parcel reply, int flags) throws RemoteException {
            return original.transact(code, data, reply, flags);
        }
        @Override public void linkToDeath(DeathRecipient recipient, int flags) throws RemoteException { original.linkToDeath(recipient, flags); }
        @Override public boolean unlinkToDeath(DeathRecipient recipient, int flags) { return original.unlinkToDeath(recipient, flags); }
        @Override public void addFrozenStateChangeCallback(Executor executor, FrozenStateChangeCallback callback) throws RemoteException {
            original.addFrozenStateChangeCallback(executor, callback);
        }
        @Override public boolean removeFrozenStateChangeCallback(FrozenStateChangeCallback callback) {
            return original.removeFrozenStateChangeCallback(callback);
        }
    }
}
