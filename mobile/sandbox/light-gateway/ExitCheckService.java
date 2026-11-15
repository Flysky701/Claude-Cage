package io.github.leexeo.cage.localcore;

import android.app.Service;
import android.content.Intent;
import android.os.IBinder;

/** Reserved legacy component. System VPN routing exposes no Binder stream gateway. */
public final class ExitCheckService extends Service {
    @Override public IBinder onBind(Intent intent) { return null; }
}
