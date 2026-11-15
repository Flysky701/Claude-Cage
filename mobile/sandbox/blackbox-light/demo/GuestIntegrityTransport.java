package io.github.leexeo.cage.space;

import android.content.ComponentName;
import android.content.Context;
import android.os.Binder;
import android.os.IBinder;
import android.os.Parcel;
import android.os.RemoteException;

/** Keep the real caller PID available to the private process registry. */
public final class GuestIntegrityTransport {
    private static final String SERVICE = "com.google.android.play.core.integrity.protocol.IIntegrityService";

    private GuestIntegrityTransport() {}

    public static IBinder adapt(ComponentName component, IBinder remote) {
        if (component == null || remote == null
                || !"com.android.vending".equals(component.getPackageName())
                || !"com.google.android.finsky.integrityservice.IntegrityService".equals(component.getClassName()))
            return remote;
        try {
            Class<?> core = Class.forName("top.niunaijun.blackbox.BlackBoxCore");
            Context host = (Context) core.getMethod("getContext").invoke(null);
            if (!ClaudeBundle.HOST.equals(host.getPackageName())
                    || !(Boolean) core.getMethod("isBlackProcess").invoke(core.getMethod("get").invoke(null)))
                return remote;
            Class<?> thread = Class.forName("top.niunaijun.blackbox.app.BActivityThread");
            if (!ClaudeBundle.PACKAGE.equals(thread.getMethod("getAppPackageName").invoke(null))
                    || (Integer) thread.getMethod("getUserId").invoke(null) != 0
                    || !SERVICE.equals(remote.getInterfaceDescriptor())) return remote;
            return new Service(remote);
        } catch (ReflectiveOperationException | RemoteException failure) {
            throw new SecurityException("Private service identity unavailable", failure);
        }
    }

    static final class Service extends Binder {
        private final IBinder remote;

        Service(IBinder remote) {
            this.remote = remote;
            attachInterface(null, SERVICE);
        }

        @Override public boolean pingBinder() { return remote.pingBinder(); }
        @Override public boolean isBinderAlive() { return remote.isBinderAlive(); }
        @Override public void linkToDeath(DeathRecipient recipient, int flags) {
            try {
                remote.linkToDeath(recipient, flags);
            } catch (RemoteException dead) {
                // Binder narrows the declared throws clause, but callers use
                // IBinder and must still receive the original RemoteException.
                Service.<RuntimeException>rethrow(dead);
            }
        }
        @SuppressWarnings("unchecked")
        private static <E extends Throwable> void rethrow(Throwable failure) throws E { throw (E) failure; }
        @Override public boolean unlinkToDeath(DeathRecipient recipient, int flags) {
            return remote.unlinkToDeath(recipient, flags);
        }

        @Override protected boolean onTransact(int code, Parcel data, Parcel reply, int flags)
                throws RemoteException {
            if (code != 2 || flags != IBinder.FLAG_ONEWAY)
                return remote.transact(code, data, reply, flags);
            // Android omits the sender PID for one-way Binder transactions. The
            // original SDK invokes this on its PlayCore worker; wait only for
            // the service to accept the request, with the exact original bytes
            // and callback. The token/verdict still arrives on that callback.
            // Never retry, synthesize a response, or trust a package name from
            // the request as proof of ownership.
            Parcel acknowledgement = Parcel.obtain();
            try {
                return remote.transact(code, data, acknowledgement, 0);
            } finally {
                acknowledgement.recycle();
            }
        }
    }
}
