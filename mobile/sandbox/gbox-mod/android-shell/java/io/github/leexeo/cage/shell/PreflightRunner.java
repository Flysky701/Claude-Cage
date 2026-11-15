package io.github.leexeo.cage.shell;

import android.content.Context;
import android.os.Handler;
import android.os.Looper;
import android.os.SystemClock;
import java.io.File;
import java.io.FileInputStream;
import java.nio.charset.StandardCharsets;
import java.util.UUID;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import org.json.JSONObject;

/** One fresh probe session per run. Old files and partial results cannot authorize entry. */
final class PreflightRunner {
    interface Callback { void complete(CheckReport report); }
    private static final ExecutorService WORKER = Executors.newSingleThreadExecutor();
    private static final Handler MAIN = new Handler(Looper.getMainLooper());
    private volatile boolean canceled;
    void cancel() { canceled = true; }
    void run(Context context, String target, Callback callback) {
        final Context app = context.getApplicationContext();
        final String request = UUID.randomUUID().toString();
        final String fingerprint = Checks.fingerprint(app);
        WORKER.execute(() -> {
            CheckReport result = new CheckReport(request, fingerprint, SystemClock.elapsedRealtime(), System.currentTimeMillis());
            try {
                ContainerBridge bridge = new ContainerBridge(app);
                bridge.ensureProbe();
                Checks.Outer outer = Checks.outer(app);
                if (canceled) return;
                bridge.stopProbe();
                final long start = SystemClock.elapsedRealtime();
                MAIN.post(() -> {
                    if (canceled) return;
                    try { bridge.launch(ContainerBridge.PROBE, request); }
                    catch (Exception ignored) { /* Poll ends as unknown; never accept an old report. */ }
                });
                JSONObject guest = null;
                File file = bridge.reportFile();
                while (!canceled && SystemClock.elapsedRealtime() - start < 55000) {
                    try {
                        JSONObject value = read(file);
                        if (CheckPolicy.fresh(request, value.optString("preflightRequest"), start,
                                value.optLong("startedElapsedRealtimeMillis"), value.optBoolean("complete"), SystemClock.elapsedRealtime())
                                && ContainerBridge.PROBE.equals(value.optString("package")) && value.optInt("probeVersion") == 6) {
                            guest = value; break;
                        }
                    } catch (Exception ignored) { }
                    Thread.sleep(250);
                }
                if (canceled) return;
                if (guest == null) throw new IllegalStateException("ProbeUnavailable");
                Checks.evaluate(result, outer, guest, target);
                if (!fingerprint.equals(Checks.fingerprint(app)))
                    result.add("environment_changed", "检查环境已变化", CheckPolicy.State.FAILED, "检查期间网络或系统环境发生变化，请重新检查。");
            } catch (Exception error) {
                result.error = error.getClass().getSimpleName();
                result.add("measurement", "检查未完成", CheckPolicy.State.UNKNOWN,
                    "未取得本轮空间检测结果。请返回重试；这不代表 SIM、VPN 或时区检查通过。");
            }
            if (!canceled) MAIN.post(() -> { if (!canceled) callback.complete(result); });
        });
    }
    private static JSONObject read(File file) throws Exception {
        long length = file.length();
        if (length < 2 || length > 262144) throw new java.io.IOException("Report size");
        byte[] data = new byte[(int) length];
        try (FileInputStream in = new FileInputStream(file)) {
            int at = 0;
            while (at < data.length) { int count = in.read(data, at, data.length - at); if (count < 0) throw new java.io.IOException("Short report"); at += count; }
        }
        return new JSONObject(new String(data, StandardCharsets.UTF_8));
    }
}
