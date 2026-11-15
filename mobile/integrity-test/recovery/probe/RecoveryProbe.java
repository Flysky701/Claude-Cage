package io.github.flysky701.recoveryprobe;

import android.app.Instrumentation;
import android.content.Context;
import android.os.Bundle;
import android.os.SystemClock;
import android.util.Base64;
import java.io.File;
import java.nio.file.Files;
import java.security.MessageDigest;

/** Same-certificate, temporary instrumentation; output must be captured privately. */
public final class RecoveryProbe extends Instrumentation {
    private String action;
    @Override public void onCreate(Bundle args) {
        super.onCreate(args); action = args == null ? "run" : args.getString("action", "run"); start();
    }
    @Override public void onStart() {
        Bundle result = new Bundle();
        try {
            Context context = getTargetContext();
            if (!"top.niunaijun.microrec".equals(context.getPackageName())) throw new SecurityException("Recovery only");
            if (!"run".equals(action) && !"open".equals(action)) throw new IllegalArgumentException("Unknown action");
            Class<?> runtime = Class.forName("io.github.leexeo.cage.space.OwnedIntegrityTest");
            runtime.getMethod("launch", Context.class, boolean.class).invoke(null, context, "run".equals(action));
            File apk = new File(context.getDataDir(), "blackbox/data/app/io.github.flysky701.integritytest/base.apk");
            StringBuilder hash = new StringBuilder();
            for (byte b : MessageDigest.getInstance("SHA-256").digest(Files.readAllBytes(apk.toPath())))
                hash.append(Character.forDigit((b >> 4) & 15, 16)).append(Character.forDigit(b & 15, 16));
            result.putString("testApkSha256", hash.toString());
            if ("run".equals(action)) {
                File folder = (File) runtime.getMethod("resultDirectory", Context.class).invoke(null, context);
                long end = SystemClock.elapsedRealtime() + 90000;
                File file;
                do {
                    file = new File(folder, "request.json");
                    if (!file.isFile()) file = new File(folder, "status.json");
                    if (file.isFile()) break;
                    SystemClock.sleep(500);
                } while (SystemClock.elapsedRealtime() < end);
                if (!file.isFile()) throw new IllegalStateException("No request result within 90 seconds");
                if (file.length() > 131072) throw new IllegalStateException("Unexpected result size");
                result.putString("resultFile", file.getName());
                result.putString("privateResultBase64", Base64.encodeToString(Files.readAllBytes(file.toPath()), Base64.NO_WRAP));
            }
            result.putString("result", "OK"); finish(-1, result);
        } catch (Throwable error) {
            while (error instanceof java.lang.reflect.InvocationTargetException && error.getCause() != null) error = error.getCause();
            result.putString("result", "FAIL");
            result.putString("failure", error.getClass().getSimpleName() + ": " + error.getMessage()); finish(0, result);
        }
    }
}
