package io.github.leexeo.cage.space;

import android.content.ComponentName;
import android.content.Intent;
import android.os.Binder;
import android.os.Bundle;
import android.os.IBinder;
import android.os.Parcel;
import android.os.RemoteException;

/** Run against Android's real Parcel/Binder implementation; all data is synthetic. */
public final class TransportCheck {
    static int checks;
    static void require(boolean ok, String label) {
        if (!ok) throw new AssertionError(label);
        checks++;
    }

    public static void main(String[] args) throws Exception {
        for (String action : new String[]{IntegrityLabRuntime.CLASSIC, IntegrityLabRuntime.STANDARD}) {
            Intent original = new Intent(action).setPackage(IntegrityLabRuntime.STORE).putExtra("sentinel", "synthetic");
            Intent next = IntegrityLabRuntime.candidate(original, IntegrityLabRuntime.PROBE, 0);
            require(next != original && IntegrityLabRuntime.MGC.equals(next.getPackage()), "route companion");
            require(IntegrityLabRuntime.STORE.equals(original.getPackage()) && original.getComponent() == null,
                "original intent preserved");
            require("synthetic".equals(next.getStringExtra("sentinel")), "extras preserved");
            for (String caller : new String[]{IntegrityLabRuntime.STORE, IntegrityLabRuntime.MGC, "other"})
                require(IntegrityLabRuntime.candidate(original, caller, 0) == original, "excluded caller");
            require(IntegrityLabRuntime.candidate(original, IntegrityLabRuntime.PROBE, 1) == original, "user boundary");
            Intent explicit = new Intent(original).setComponent(new ComponentName("other", IntegrityLabRuntime.CLASSIC_CLASS));
            require(IntegrityLabRuntime.candidate(explicit, IntegrityLabRuntime.PROBE, 0) == explicit, "foreign component");
        }
        Intent other = new Intent("other").setPackage(IntegrityLabRuntime.STORE);
        require(IntegrityLabRuntime.candidate(other, IntegrityLabRuntime.PROBE, 0) == other, "unrelated action");
        transact(GuestIntegrityTransport.CLASSIC, 2, 0);
        transact(GuestIntegrityTransport.STANDARD, 2, 0);
        transact(GuestIntegrityTransport.STANDARD, 3, -19);
        unknownTransaction();
        System.out.println("PASS Android route/transport checks=" + checks);
    }

    static void transact(String descriptor, int code, int error) throws Exception {
        final boolean[] callbackReceived = {false}, requestReceived = {false};
        Binder callback = new Binder() {
            @Override protected boolean onTransact(int receivedCode, Parcel data, Parcel reply, int flags) {
                data.enforceInterface(descriptor + "Callback");
                require(receivedCode == code, "callback code");
                require(data.readInt() == 1, "response presence");
                Bundle response = Bundle.CREATOR.createFromParcel(data);
                require(response.getInt("error") == error, "original error preserved");
                require("synthetic-private-value".equals(response.getString("unknown.field")), "unknown response fields");
                require(!response.containsKey("token"), "no fabricated token");
                callbackReceived[0] = true;
                reply.writeNoException();
                return true;
            }
        };
        Binder target = new Binder() {
            @Override protected boolean onTransact(int receivedCode, Parcel data, Parcel reply, int flags) throws RemoteException {
                require(receivedCode == code && flags == 0, "synchronous request preserves caller PID");
                data.enforceInterface(descriptor);
                require(data.readInt() == 1, "request presence");
                Bundle request = Bundle.CREATOR.createFromParcel(data);
                require("synthetic-nonce".equals(request.getString("nonce")), "request content unchanged");
                require(request.getLong("cloud.prj") == 123L, "project unchanged");
                IBinder observedCallback = data.readStrongBinder();
                require(data.dataAvail() == 0, "no extra request bytes");
                requestReceived[0] = true;
                Bundle response = new Bundle();
                response.putInt("error", error);
                response.putString("unknown.field", "synthetic-private-value");
                Parcel callbackData = Parcel.obtain(), callbackReply = Parcel.obtain();
                try {
                    callbackData.writeInterfaceToken(descriptor + "Callback");
                    callbackData.writeInt(1);
                    response.writeToParcel(callbackData, 0);
                    require(observedCallback.transact(code, callbackData, callbackReply, 0), "callback forwarded");
                    callbackReply.readException();
                } finally { callbackData.recycle(); callbackReply.recycle(); }
                reply.writeNoException();
                return true;
            }
        };
        GuestIntegrityTransport.Service adapter = new GuestIntegrityTransport.Service(target, descriptor);
        Parcel data = Parcel.obtain();
        try {
            Bundle request = new Bundle();
            request.putString("nonce", "synthetic-nonce");
            request.putLong("cloud.prj", 123L);
            data.writeInterfaceToken(descriptor);
            data.writeInt(1);
            request.writeToParcel(data, 0);
            data.writeStrongBinder(callback);
            require(adapter.transact(code, data, null, IBinder.FLAG_ONEWAY), "request forwarded");
            require(requestReceived[0] && callbackReceived[0], "round trip complete");
        } finally { data.recycle(); }
    }

    static void unknownTransaction() throws Exception {
        Binder target = new Binder() {
            @Override protected boolean onTransact(int code, Parcel data, Parcel reply, int flags) {
                require(code == 81 && flags == IBinder.FLAG_ONEWAY, "unknown transaction flags unchanged");
                require(data.readInt() == 42, "unknown payload unchanged");
                return false;
            }
        };
        Parcel data = Parcel.obtain();
        try {
            data.writeInt(42);
            require(!new GuestIntegrityTransport.Service(target, GuestIntegrityTransport.STANDARD)
                .transact(81, data, null, IBinder.FLAG_ONEWAY), "unknown return unchanged");
        } finally { data.recycle(); }
    }
}
