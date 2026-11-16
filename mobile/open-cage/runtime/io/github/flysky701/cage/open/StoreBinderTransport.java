package io.github.flysky701.cage.open;

import android.content.ComponentName;
import android.os.Binder;
import android.os.IBinder;
import android.os.Parcel;
import android.os.RemoteException;
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

/** Preserve the kernel caller PID across private Play gRPC one-way calls. */
public final class StoreBinderTransport {
    private static final String DESCRIPTOR = "io.github.flysky701.cage.open.PrivateStoreGrpc";
    private static final int MAX_PENDING = 32, MAX_PARCEL_BYTES = 1024 * 1024;
    private static final ConcurrentHashMap<IBinder, Forwarder> channels = new ConcurrentHashMap<>();

    private StoreBinderTransport() {}

    private static boolean store() {
        return "com.android.vending".equals(top.niunaijun.blackbox.app.BActivityThread.getAppPackageName());
    }

    public static IBinder publish(android.content.pm.ServiceInfo info, IBinder original) throws RemoteException {
        if (!store() || info == null || info.exported || original == null
                || !"com.android.vending".equals(info.packageName)
                || !"com.google.frameworks.client.data.android.server.play.BackgroundProcessEndpointService".equals(info.name)
                || !(original instanceof Binder) || original.getInterfaceDescriptor() != null) return original;
        android.util.Log.i("CageStoreTransport", "Private service: " + info.name);
        return new LocalBridge(original);
    }

    public static IBinder connect(ComponentName name, IBinder remote) {
        if (!store() || name == null || !"com.android.vending".equals(name.getPackageName())) return remote;
        return wrap(remote);
    }

    private static IBinder wrap(IBinder remote) {
        if (remote == null) return null;
        if (Proxy.isProxyClass(remote.getClass()) && Proxy.getInvocationHandler(remote) instanceof Forwarder)
            return remote;
        try {
            if (!DESCRIPTOR.equals(remote.getInterfaceDescriptor())) return remote;
        } catch (RemoteException unavailable) {
            throw new IllegalStateException("Private Store transport unavailable", unavailable);
        }
        Forwarder existing = channels.get(remote);
        if (existing != null) return existing.proxy;
        Forwarder created = new Forwarder(remote);
        existing = channels.putIfAbsent(remote, created);
        if (existing != null) { created.close(); return existing.proxy; }
        try {
            remote.linkToDeath(created, 0);
            created.linked.set(true);
            // A death callback can race the return from linkToDeath().
            if (created.closed.get()) created.unlink();
        } catch (RemoteException | RuntimeException unavailable) {
            created.close();
            throw new IllegalStateException("Private Store transport unavailable", unavailable);
        }
        return created.proxy;
    }

    private static final class Forwarder implements InvocationHandler, IBinder.DeathRecipient {
        final IBinder remote, proxy;
        final AtomicBoolean closed = new AtomicBoolean(), linked = new AtomicBoolean();
        private final Object enqueueLock = new Object();
        private final ThreadPoolExecutor worker = new ThreadPoolExecutor(1, 1, 30, TimeUnit.SECONDS,
                new ArrayBlockingQueue<>(MAX_PENDING), runnable -> {
                    Thread thread = new Thread(runnable, "Cage-store-transport");
                    thread.setDaemon(true);
                    return thread;
                }, new ThreadPoolExecutor.AbortPolicy());

        Forwarder(IBinder remote) {
            this.remote = remote;
            proxy = (IBinder) Proxy.newProxyInstance(StoreBinderTransport.class.getClassLoader(),
                    new Class<?>[]{IBinder.class}, this);
            worker.allowCoreThreadTimeOut(true);
        }

        @Override public Object invoke(Object self, Method method, Object[] args) throws Throwable {
            if (method.getDeclaringClass() == Object.class) {
                if ("equals".equals(method.getName())) return self == args[0];
                if ("hashCode".equals(method.getName())) return System.identityHashCode(self);
                if ("toString".equals(method.getName())) return "PrivateStoreBinderTransport";
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
                    // Kernel delivery retains this registered Store process's actual PID.
                    if (!remote.transact(code, outgoing, reply, flags)) throw unavailable();
                    // The original one-way interface has no business reply.
                    // A synchronous delivery can nevertheless carry a framework exception.
                    if (reply.dataSize() != 0) { reply.setDataPosition(0); reply.readException(); }
                } catch (RemoteException | RuntimeException failed) {
                    // Never retry as oneway or log Parcel contents, accounts, tokens or messages.
                    Log.w("CageStoreBinderTransport", "Private channel closed: " + failed.getClass().getSimpleName());
                    close();
                } catch (Error fatal) {
                    close(); throw fatal;
                } finally {
                    if (reply != null) reply.recycle();
                    if (outgoing != null) outgoing.recycle();
                    recycle();
                }
            }

            private Parcel workerRequest() { return rewrite(code, data, true); }

            void recycle() { if (recycled.compareAndSet(false, true)) data.recycle(); }
        }
    }

    /** gRPC setup contains a version and a callback Binder, without an AIDL header. */
    private static Parcel rewrite(int code, Parcel data, boolean outgoing) {
        Parcel result = Parcel.obtain();
        int saved = data.dataPosition();
        try {
            data.setDataPosition(0);
            if (code == IBinder.FIRST_CALL_TRANSACTION && data.dataSize() >= 8 && data.readInt() == 1) {
                IBinder callback = data.readStrongBinder();
                if (callback != null && data.dataAvail() == 0) {
                    if (outgoing && callback instanceof Binder) callback = new LocalBridge(callback);
                    else if (!outgoing) {
                        IBinder channel = wrap(callback);
                        if (channel != callback) callback = new RemoteRelay(channel);
                    }
                    result.writeInt(1); result.writeStrongBinder(callback);
                    result.setDataPosition(0); return result;
                }
            }
            result.appendFrom(data, 0, data.dataSize()); result.setDataPosition(0); return result;
        } catch (RuntimeException | Error error) { result.recycle(); throw error; }
        finally { data.setDataPosition(saved); }
    }

    /** A real local Binder preserves the object table when passing a callback to gRPC. */
    private static final class RemoteRelay extends Binder {
        private final IBinder remote;
        RemoteRelay(IBinder remote) { this.remote = remote; }
        @Override protected boolean onTransact(int code, Parcel data, Parcel reply, int flags) throws RemoteException {
            return remote.transact(code, data, reply, flags);
        }
    }

    private static final class LocalBridge extends Binder {
        private final IBinder local;
        LocalBridge(IBinder local) { this.local=local; attachInterface(null, DESCRIPTOR); }
        @Override protected boolean onTransact(int code, Parcel data, Parcel reply, int flags) throws RemoteException {
            if(code == INTERFACE_TRANSACTION) return super.onTransact(code,data,reply,flags);
            // Kernel synchronous delivery exposes a PID. The normal guest UID mapping
            // then verifies the registered process and virtual user; unknown callers fail.
            if (!store() || Binder.getCallingPid() <= 0
                    || Binder.getCallingUid() != top.niunaijun.blackbox.app.BActivityThread.getBUid())
                throw new SecurityException("Private Store process required");
            Parcel incoming=rewrite(code,data,false);
            try { return local.transact(code,incoming,null,flags | IBinder.FLAG_ONEWAY); }
            finally { incoming.recycle(); }
        }
    }

    private static RemoteException unavailable() { return new RemoteException("Private Store transport channel unavailable"); }
}
