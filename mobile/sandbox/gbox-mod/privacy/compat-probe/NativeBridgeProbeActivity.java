package io.github.leexeo.cage.nativebridgeprobe;

import android.app.Activity;
import android.os.Bundle;
import android.os.Build;
import android.util.Log;
import android.widget.TextView;
import java.io.File;
import java.io.FileOutputStream;
import java.nio.charset.StandardCharsets;

/** One disposable process; no network, accounts, property writes, or GBox access. */
public final class NativeBridgeProbeActivity extends Activity {
    private static File report;
    private static native boolean prepareCritical(int sdk, int baseline, String reportPath);
    private static native boolean criticalHealthAndMode(int mode);

    public static synchronized void record(String value) {
        Log.i("CageNativeBridgeProbe", value);
        if (report == null) return;
        try (FileOutputStream stream = new FileOutputStream(report, true)) {
            stream.write((value + "\n").getBytes(StandardCharsets.UTF_8));
            stream.getFD().sync();
        } catch (Exception failure) {
            Log.e("CageNativeBridgeProbe", "report write failed", failure);
        }
    }

    @Override public void onCreate(Bundle state) {
        super.onCreate(state);
        report = new File(getFilesDir(), "latest-native-bridge-report.txt");
        try (FileOutputStream stream = new FileOutputStream(report, false)) {
            stream.write("Cage NativeBridge diagnostic v5 CriticalNative Java caller\n".getBytes(StandardCharsets.UTF_8));
        } catch (Exception failure) { throw new IllegalStateException(failure); }
        TextView status = new TextView(this);
        status.setText("正在验证原生回调兼容性。完成后此测试进程会退出。");
        setContentView(status);
        record("java.start sdk=" + Build.VERSION.SDK_INT + " process64=" + android.os.Process.is64Bit());
        new Thread(() -> {
            try {
                record("java.before.load.arm.library");
                System.loadLibrary("cage_nativebridge_probe");
                record("java.after.load.arm.library");
                int baseline = android.os.Binder.getCallingUid();
                record("PASS critical.Java.baseline.value.not.logged");
                if (!prepareCritical(Build.VERSION.SDK_INT, baseline, report.getAbsolutePath())) {
                    record("STOP critical.prepare.failed");
                    return;
                }
                record("PASS critical.install.returned.to.Java");
                record("critical.Java.replacement.only.before.call");
                int replacement = android.os.Binder.getCallingUid();
                if (replacement != -20261115) {
                    record("FAIL critical.Java.replacement.marker");
                    return;
                }
                record("PASS critical.Java.replacement.marker");
                if (!criticalHealthAndMode(2)) {
                    record("STOP critical.after.replacement.health.failed");
                    return;
                }
                record("critical.Java.direct.original.before.call");
                int delegated = android.os.Binder.getCallingUid();
                if (delegated != baseline) {
                    record("FAIL critical.Java.direct.original.value.differs");
                    return;
                }
                record("PASS critical.Java.direct.original.matches.baseline.value.not.logged");
                if (!criticalHealthAndMode(2)) {
                    record("STOP critical.after.delegation.health.failed");
                    return;
                }
                record("PASS all.critical.Java.caller.stages");
            } catch (Throwable failure) {
                record("java.failure " + failure.getClass().getName() + ": " + failure.getMessage());
            } finally {
                record("java.finished.exiting.disposable.process");
                // Native registration is process local. Exiting restores the original
                // framework method naturally, without writing ART fields to restore it.
                android.os.Process.killProcess(android.os.Process.myPid());
            }
        }, "CageBridgeDiagnostic").start();
    }
}
