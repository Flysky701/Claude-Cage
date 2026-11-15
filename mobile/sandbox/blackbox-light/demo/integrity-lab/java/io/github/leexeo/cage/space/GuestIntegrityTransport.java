package io.github.leexeo.cage.space;

import android.content.ComponentName;
import android.os.Binder;
import android.os.Bundle;
import android.os.IBinder;
import android.os.Parcel;
import android.os.RemoteException;
import android.os.SystemClock;
import android.util.Log;

/** The observed MGC AIDL uses synchronous replies for both request families. */
public final class GuestIntegrityTransport {
    static final String CLASSIC = "com.google.android.play.core.integrity.protocol.IIntegrityService";
    static final String STANDARD = "com.google.android.play.core.integrity.protocol.IExpressIntegrityService";

    public static IBinder adapt(ComponentName component, IBinder remote) {
        if (component == null || remote == null || !(IntegrityLabRuntime.MGC.equals(component.getPackageName())
                || IntegrityLabRuntime.STORE.equals(component.getPackageName()))) return remote;
        String descriptor = IntegrityLabRuntime.CLASSIC_CLASS.equals(component.getClassName()) ? CLASSIC
            : IntegrityLabRuntime.STANDARD_CLASS.equals(component.getClassName()) ? STANDARD : null;
        if (descriptor == null) return remote;
        try {
            if (!IntegrityLabRuntime.LAB.equals(IntegrityLabRuntime.host().getPackageName())) return remote;
            Class<?> thread = Class.forName("top.niunaijun.blackbox.app.BActivityThread");
            String caller = (String) thread.getMethod("getAppPackageName").invoke(null);
            if (!(IntegrityLabRuntime.PROBE.equals(caller) || "com.anthropic.claude".equals(caller))
                    || ((Integer) thread.getMethod("getUserId").invoke(null)) != 0) return remote;
            if (!descriptor.equals(remote.getInterfaceDescriptor())) throw new SecurityException("Unexpected Integrity interface");
            return new Service(remote, descriptor);
        } catch (Exception e) {
            throw new SecurityException("Private Integrity transport unavailable", e);
        }
    }

    static class Forwarder extends Binder {
        final IBinder remote;
        Forwarder(IBinder remote, String descriptor) {
            this.remote = remote;
            attachInterface(null, descriptor);
        }
        @Override public boolean pingBinder() { return remote.pingBinder(); }
        @Override public boolean isBinderAlive() { return remote.isBinderAlive(); }
        @Override public void linkToDeath(DeathRecipient recipient, int flags) {
            try { remote.linkToDeath(recipient, flags); }
            catch (RemoteException e) { GuestIntegrityTransport.<RuntimeException>rethrow(e); }
        }
        @Override public boolean unlinkToDeath(DeathRecipient recipient, int flags) {
            return remote.unlinkToDeath(recipient, flags);
        }
    }

    @SuppressWarnings("unchecked")
    private static <E extends Throwable> void rethrow(Throwable error) throws E { throw (E) error; }

    static final class Service extends Forwarder {
        final String descriptor;
        Service(IBinder remote, String descriptor) { super(remote, descriptor); this.descriptor = descriptor; }

        @Override protected boolean onTransact(int code, Parcel data, Parcel reply, int flags) throws RemoteException {
            boolean standard = STANDARD.equals(descriptor);
            boolean request = code == 2 || (standard && code == 3);
            if (!request) return remote.transact(code, data, reply, flags);
            String phase = standard ? (code == 2 ? "standard_prepare" : "standard_request") : "classic_request";
            Parcel observed = withCallback(data, phase);
            Parcel synchronous = (flags & IBinder.FLAG_ONEWAY) != 0 ? Parcel.obtain() : null;
            try {
                boolean result = remote.transact(code, observed == null ? data : observed,
                    synchronous == null ? reply : synchronous,
                    synchronous == null ? flags : flags & ~IBinder.FLAG_ONEWAY);
                if (result && synchronous != null && synchronous.dataSize() > 0) synchronous.readException();
                return result;
            } finally {
                if (observed != null) observed.recycle();
                if (synchronous != null) synchronous.recycle();
            }
        }

        private Parcel withCallback(Parcel source, String phase) {
            Parcel inspect = Parcel.obtain();
            Parcel replacement = null;
            try {
                inspect.appendFrom(source, 0, source.dataSize());
                inspect.setDataPosition(0);
                inspect.enforceInterface(descriptor);
                if (inspect.readInt() != 1) return null;
                Bundle.CREATOR.createFromParcel(inspect);
                int offset = inspect.dataPosition();
                IBinder callback = inspect.readStrongBinder();
                if (callback == null || inspect.dataAvail() != 0) return null;
                replacement = Parcel.obtain();
                replacement.appendFrom(source, 0, offset);
                replacement.setDataPosition(offset);
                replacement.writeStrongBinder(new Callback(callback, descriptor + "Callback", phase));
                replacement.setDataPosition(0);
                Log.i("CageIntegrity", "request phase=" + phase);
                return replacement;
            } catch (RuntimeException e) {
                if (replacement != null) replacement.recycle();
                Log.i("CageIntegrity", "request_shape=unknown phase=" + phase);
                return null;
            } finally { inspect.recycle(); }
        }
    }

    static final class Callback extends Forwarder {
        final String descriptor, phase;
        final long started = SystemClock.elapsedRealtime();
        Callback(IBinder remote, String descriptor, String phase) {
            super(remote, descriptor); this.descriptor = descriptor; this.phase = phase;
        }
        @Override protected boolean onTransact(int code, Parcel data, Parcel reply, int flags) throws RemoteException {
            if (code == 2 || code == 3) inspect(data);
            return remote.transact(code, data, reply, flags);
        }
        private void inspect(Parcel source) {
            Parcel copy = Parcel.obtain();
            try {
                copy.appendFrom(source, 0, source.dataSize());
                copy.setDataPosition(0);
                copy.enforceInterface(descriptor);
                if (copy.readInt() != 1) return;
                Bundle response = Bundle.CREATOR.createFromParcel(copy);
                // Never serialize the Bundle, token, nonce, account or warm-up session ID.
                boolean token = response.getString("token") != null && !response.getString("token").isEmpty();
                Log.i("CageIntegrity", "callback phase=" + phase + " error=" + response.getInt("error", 0)
                    + " tokenPresent=" + token + " warmupPresent=" + response.containsKey("warm.up.sid")
                    + " elapsedMs=" + (SystemClock.elapsedRealtime() - started));
            } catch (RuntimeException e) {
                Log.i("CageIntegrity", "callback_shape=unknown phase=" + phase);
            } finally { copy.recycle(); }
        }
    }
}
