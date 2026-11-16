package io.github.leexeo.cage.space;

import android.content.ComponentName;
import android.os.Binder;
import android.os.IBinder;
import android.os.Parcel;
import android.os.RemoteException;
import android.os.StrictMode;
import android.util.Log;
import java.lang.reflect.InvocationHandler;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.lang.reflect.Proxy;
import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ThreadPoolExecutor;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicBoolean;

/** Private microG authenticator channel: asynchronous callers, authenticated synchronous delivery. */
public final class AccountTransport {
    private static final String DESCRIPTOR = "android.accounts.IAccountAuthenticator";
    private static final String SERVICE = "org.microg.gms.auth.loginservice.GoogleLoginService";
    private static final int MAX_PENDING = 32, MAX_PARCEL_BYTES = 1024 * 1024;
    private static final ConcurrentHashMap<IBinder, Forwarder> channels = new ConcurrentHashMap<>();

    private AccountTransport() {}

    public static IBinder wrap(ComponentName name, IBinder remote) {
        if (name == null || remote == null || !"com.google.android.gms".equals(name.getPackageName())
                || !SERVICE.equals(name.getClassName())) return remote;
        return wrap(remote, DESCRIPTOR);
    }

    /** Preserve the registered guest caller, without changing any integrity request or verdict. */
    public static IBinder wrapIntegrity(ComponentName name, IBinder remote) {
        if (name == null || remote == null || !"com.android.vending".equals(name.getPackageName())) return remote;
        if ("com.google.android.finsky.integrityservice.IntegrityService".equals(name.getClassName()))
            return wrap(remote, "com.google.android.play.core.integrity.protocol.IIntegrityService");
        if ("com.google.android.finsky.expressintegrityservice.ExpressIntegrityService".equals(name.getClassName()))
            return wrap(remote, "com.google.android.play.core.integrity.protocol.IExpressIntegrityService");
        return remote;
    }

    private static IBinder wrap(IBinder remote, String descriptor) {
        if (Proxy.isProxyClass(remote.getClass()) && Proxy.getInvocationHandler(remote) instanceof Forwarder)
            return remote;
        try {
            if (!descriptor.equals(remote.getInterfaceDescriptor())) return remote;
        } catch (RemoteException unavailable) {
            throw new IllegalStateException("Private authenticator unavailable", unavailable);
        }
        Forwarder existing = channels.get(remote);
        if (existing != null) return existing.proxy;
        Forwarder created = new Forwarder(remote, descriptor);
        existing = channels.putIfAbsent(remote, created);
        if (existing != null) { created.close(); return existing.proxy; }
        try {
            remote.linkToDeath(created, 0);
            created.linked.set(true);
            // A death callback can race the return from linkToDeath().
            if (created.closed.get()) created.unlink();
        } catch (RemoteException | RuntimeException unavailable) {
            created.close();
            throw new IllegalStateException("Private authenticator unavailable", unavailable);
        }
        return created.proxy;
    }

    private static final class Forwarder implements InvocationHandler, IBinder.DeathRecipient {
        final IBinder remote, proxy;
        final String descriptor;
        final AtomicBoolean closed = new AtomicBoolean(), linked = new AtomicBoolean();
        private final Object enqueueLock = new Object();
        private final ThreadPoolExecutor worker = new ThreadPoolExecutor(1, 1, 30, TimeUnit.SECONDS,
                new ArrayBlockingQueue<>(MAX_PENDING), runnable -> {
                    Thread thread = new Thread(runnable, "Cage-account-transport");
                    thread.setDaemon(true);
                    return thread;
                }, new ThreadPoolExecutor.AbortPolicy());

        Forwarder(IBinder remote, String descriptor) {
            this.remote = remote;
            this.descriptor = descriptor;
            proxy = (IBinder) Proxy.newProxyInstance(AccountTransport.class.getClassLoader(),
                    new Class<?>[]{IBinder.class}, this);
            worker.allowCoreThreadTimeOut(true);
        }

        @Override public Object invoke(Object self, Method method, Object[] args) throws Throwable {
            if (method.getDeclaringClass() == Object.class) {
                if ("equals".equals(method.getName())) return self == args[0];
                if ("hashCode".equals(method.getName())) return System.identityHashCode(self);
                if ("toString".equals(method.getName())) return "PrivateAccountTransport";
            }
            if ("queryLocalInterface".equals(method.getName())) return null;
            if ("transact".equals(method.getName()) && args != null && args.length == 4
                    && (((Integer) args[3]) & IBinder.FLAG_ONEWAY) != 0)
                return enqueue((Integer) args[0], (Parcel) args[1], (Integer) args[3]);
            try { return method.invoke(remote, args); }
            catch (InvocationTargetException failed) { throw failed.getCause(); }
        }

        private boolean enqueue(int code, Parcel original, int flags) throws RemoteException {
            synchronized (enqueueLock) {
                if (closed.get() || !remote.isBinderAlive()) {
                    close(); throw unavailable();
                }
                if (original == null || original.dataSize() > MAX_PARCEL_BYTES) {
                    close(); throw unavailable();
                }
                Parcel copy = Parcel.obtain();
                Call call = null;
                boolean accepted = false;
                try {
                    // appendFrom copies the Binder object table and retains its references.
                    // marshall()/unmarshall() would discard those live callback/capability refs.
                    copy.appendFrom(original, 0, original.dataSize());
                    copy.setDataPosition(0);
                    call = new Call(code, flags & ~IBinder.FLAG_ONEWAY, copy);
                    worker.execute(call);
                    accepted = true;
                    // The original AIDL caller can recycle its Parcel immediately after return.
                    return true;
                } catch (RuntimeException rejected) {
                    close();
                    throw unavailable();
                } catch (Error fatal) {
                    close(); throw fatal;
                } finally {
                    if (!accepted) { if (call == null) copy.recycle(); else call.recycle(); }
                }
            }
        }

        @Override public void binderDied() { close(); }

        void close() {
            if (!closed.compareAndSet(false, true)) return;
            channels.remove(remote, this);
            // shutdownNow returns only work that never started; never recycle in-flight native I/O.
            for (Runnable pending : worker.shutdownNow()) ((Call) pending).recycle();
            unlink();
        }

        void unlink() {
            if (!linked.compareAndSet(true, false)) return;
            try { remote.unlinkToDeath(this, 0); }
            catch (RuntimeException alreadyGone) { /* Death notification may already have removed it. */ }
        }

        private final class Call implements Runnable {
            final int code, flags;
            final Parcel data;
            private final AtomicBoolean recycled = new AtomicBoolean();

            Call(int code, int flags, Parcel data) { this.code = code; this.flags = flags; this.data = data; }

            @Override public void run() {
                Parcel outgoing = null, reply = null;
                try {
                    if (closed.get()) return;
                    outgoing = workerRequest();
                    reply = Parcel.obtain();
                    // Synchronous kernel delivery preserves this actual process PID so the
                    // receiving service can resolve the registered private caller's UID.
                    if (!remote.transact(code, outgoing, reply, flags)) throw unavailable();
                    // This is a void oneway AIDL interface: success has no business reply.
                    // A synchronous delivery can nevertheless carry a framework exception.
                    if (reply.dataSize() != 0) { reply.setDataPosition(0); reply.readException(); }
                } catch (RemoteException | RuntimeException failed) {
                    // Never retry as oneway or log Parcel contents, accounts, tokens or messages.
                    Log.w("CageAccountTransport", "Private channel closed: " + failed.getClass().getSimpleName());
                    close();
                } catch (Error fatal) {
                    close(); throw fatal;
                } finally {
                    if (reply != null) reply.recycle();
                    if (outgoing != null) outgoing.recycle();
                    recycle();
                }
            }

            private Parcel workerRequest() {
                StrictMode.ThreadPolicy workerPolicy = StrictMode.getThreadPolicy();
                long workSource = Binder.clearCallingWorkSource();
                final int payload;
                try {
                    data.setDataPosition(0);
                    // Ask the platform to consume its own version-dependent Binder header.
                    // enforceInterface also imports StrictMode and WorkSource into this thread.
                    data.enforceInterface(descriptor);
                    payload = data.dataPosition();
                } finally {
                    try { StrictMode.setThreadPolicy(workerPolicy); }
                    finally { Binder.restoreCallingWorkSource(workSource); }
                }
                Parcel outgoing = Parcel.obtain();
                try {
                    // Normal oneway delivery clears the sender's StrictMode policy. Reusing
                    // its header after converting to synchronous delivery would instead import
                    // the original main-thread policy. Generate a header on this worker, after
                    // restoring its policy, without relaxing any thread or process-wide policy.
                    outgoing.writeInterfaceToken(descriptor);
                    outgoing.appendFrom(data, payload, data.dataSize() - payload);
                    outgoing.setDataPosition(0);
                    return outgoing;
                } catch (RuntimeException | Error failed) {
                    outgoing.recycle();
                    throw failed;
                }
            }

            void recycle() { if (recycled.compareAndSet(false, true)) data.recycle(); }
        }
    }

    private static RemoteException unavailable() { return new RemoteException("Private authenticator channel unavailable"); }
}
