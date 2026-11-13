package io.github.leexeo.cage.localcore;

import android.app.Service;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.os.*;
import android.util.Log;
import java.io.IOException;
import java.util.concurrent.atomic.AtomicBoolean;

/** One fixed HTTPS check on the already running core. Binding never starts the core. */
public final class ExitCheckService extends Service {
    private final AtomicBoolean pending = new AtomicBoolean();
    private final Messenger endpoint = new Messenger(new Handler(Looper.getMainLooper(), request -> {
        if (request.what < 1 || request.what > 4 || request.replyTo == null) return true;
        int uid = request.sendingUid;
        try {
            if (getPackageManager().getApplicationInfo(CoreService.spacePackage(this), 0).uid != uid ||
                    getPackageManager().checkSignatures(android.os.Process.myUid(), uid)
                            != PackageManager.SIGNATURE_MATCH) {
                Log.w("CageBoundExit", "Rejected caller identity");
                return true;
            }
        } catch (PackageManager.NameNotFoundException absent) {
            Log.w("CageBoundExit", "Test shell not visible to helper");
            return true;
        }
        Messenger recipient = request.replyTo;
        if (request.what == 4) {
            // One-shot comparison enabled explicitly in the helper's private test directory.
            boolean enabled = getFileStreamPath("default-curl-control").delete();
            try { recipient.send(Message.obtain(null, 4, enabled ? 1 : 0, 0)); }
            catch (RemoteException ended) { /* Guest exited. */ }
            return true;
        }
        if (request.what == 2 || request.what == 3) {
            String destination = request.what == 2 ? "ipv4.icanhazip.com" : request.getData().getString("destination");
            FixedSiteStream.open(recipient, request.what, destination);
            return true;
        }
        if (!pending.compareAndSet(false, true)) {
            reply(recipient, null);
            return true;
        }
        new Thread(() -> {
            String ip = null;
            try {
                CoreService core = CoreService.readyCore;
                if (core != null) ip = core.verifyExit();
            } catch (IOException unavailable) {
                Log.i("CageBoundExit", "HTTPS unavailable");
            } finally {
                pending.set(false);
                Log.i("CageBoundExit", "callerUid=" + uid + " HTTPS=" + (ip != null));
                reply(recipient, ip);
            }
        }, "Cage-bound-exit").start();
        return true;
    }));

    private static void reply(Messenger recipient, String ip) {
        Message response = Message.obtain(null, 1);
        response.getData().putString("ipv4", ip);
        try { recipient.send(response); } catch (RemoteException gone) { /* Caller finished. */ }
    }
    @Override public IBinder onBind(Intent intent) { return endpoint.getBinder(); }
}
