package io.github.flysky701.hihatsprobe;

import android.app.Service;
import android.content.Intent;
import android.os.*;

public class ProbeService extends Service {
    private final Binder binder = new Binder() {
        @Override protected boolean onTransact(int code, Parcel request, Parcel reply, int flags) {
            if (code != 1) return false;
            request.enforceInterface("cage.hihats.probe");
            reply.writeString("HIHATS_SERVICE_OK");
            return true;
        }
    };
    @Override public IBinder onBind(Intent intent) { return binder; }
}
