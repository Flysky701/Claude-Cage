package top.niunaijun.blackbox.network;

import android.os.Handler;
import android.os.Looper;
import android.os.Message;
import android.os.Messenger;
import android.os.RemoteException;
import android.util.Log;
import java.io.*;
import java.nio.charset.StandardCharsets;
import java.util.*;

/** Optional shell-owned comparison, triggered by ADB while the stable guest is foreground. */
final class DefaultCurlControl {
    private static final String TAG = "CageLightControl";
    static void check(Messenger relay, Looper looper) {
        Message request = Message.obtain(null, 4);
        request.replyTo = new Messenger(new Handler(looper, reply -> {
            if (reply.what == 4 && reply.arg1 == 1) new Thread(() -> {
                try { run(); } catch (Exception e) { Log.i(TAG, "control failed " + e); }
            }, "Cage-default-curl-control").start();
            return true;
        }));
        try { relay.send(request); } catch (RemoteException ended) { Log.i(TAG, "relay disconnected"); }
    }
    private static void run() throws Exception {
        List<String> args = new ArrayList<>(Arrays.asList("/system/bin/sh", "-c",
                "echo pid=$$; exec /system/bin/curl \"$@\"", "curl-control", "-q", "--rate", "1/10s"));
        for (int i = 0; i < 5; i++) {
            if (i > 0) args.add("--next");
            Collections.addAll(args, "-fsS", "--max-time", "7", "-H", "Connection: close",
                    "-w", "\nresult-" + i + "=%{exitcode}\n");
            if (i % 2 == 1)
                Collections.addAll(args, "--connect-to", GuestExitCheck.SITE + ":443:" + GuestExitCheck.PIN + ":443");
            args.add("https://" + GuestExitCheck.SITE + "/?cage=" + UUID.randomUUID());
        }
        Process process = new ProcessBuilder(args).redirectErrorStream(true).start();
        try (BufferedReader input = new BufferedReader(new InputStreamReader(process.getInputStream(),
                StandardCharsets.US_ASCII))) {
            for (String line; (line = input.readLine()) != null;)
                if (line.matches("pid=[0-9]+|result-[0-4]=[0-9]+") ||
                        android.util.Patterns.IP_ADDRESS.matcher(line.trim()).matches()) Log.i(TAG, line);
            Log.i(TAG, "complete rc=" + process.waitFor());
        } finally { process.destroy(); }
    }
}
