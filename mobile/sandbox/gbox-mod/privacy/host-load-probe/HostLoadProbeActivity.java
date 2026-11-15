package io.github.leexeo.cage.hostloadprobe;

import android.app.Activity;
import android.os.Build;
import android.os.Bundle;
import android.util.Log;
import android.webkit.WebResourceError;
import android.webkit.WebResourceRequest;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.TextView;
import dalvik.system.DexClassLoader;
import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.nio.charset.StandardCharsets;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicReference;
import org.json.JSONArray;
import org.json.JSONObject;

/** Disposable local process. No network, account, GBox or existing probe access. */
public final class HostLoadProbeActivity extends Activity {
    private static final String TAG = "CageHostLoadProbe";
    private static File report;
    private static File summary;
    private static String stage = "start";
    private static final JSONObject result = new JSONObject();

    private static synchronized void record(String value) {
        Log.i(TAG, value);
        if (report == null) return;
        try (FileOutputStream stream = new FileOutputStream(report, true)) {
            stream.write((value + "\n").getBytes(StandardCharsets.UTF_8));
            stream.getFD().sync();
        } catch (Exception failure) {
            Log.e(TAG, "report.write.failed." + failure.getClass().getSimpleName());
        }
    }

    private static void at(String value) {
        stage = value;
        record("before." + value);
        persist();
    }

    private static void require(boolean condition, String label) {
        record((condition ? "PASS " : "FAIL ") + label);
        if (!condition) throw new IllegalStateException(label);
    }

    private File extract(String asset, File directory) throws Exception {
        File output = new File(directory, asset);
        try (InputStream input = getAssets().open(asset);
             FileOutputStream stream = new FileOutputStream(output, false)) {
            byte[] buffer = new byte[8192];
            int size;
            while ((size = input.read(buffer)) != -1) stream.write(buffer, 0, size);
            stream.getFD().sync();
        }
        return output;
    }

    private static Object call(Method method, Object... arguments) throws Throwable {
        try { return method.invoke(null, arguments); }
        catch (InvocationTargetException failure) { throw failure.getCause(); }
    }

    private static synchronized void persist() {
        if (summary == null) return;
        try {
            result.put("lastStage", stage);
            try (FileOutputStream stream = new FileOutputStream(summary, false)) {
                stream.write(result.toString(2).getBytes(StandardCharsets.UTF_8));
                stream.getFD().sync();
            }
        } catch (Exception failure) { record("summary.write.failed." + failure.getClass().getSimpleName()); }
    }

    private static void counters(String name, long[] values) throws Exception {
        Object recorded = values == null ? JSONObject.NULL : new JSONArray(values);
        result.put(name, recorded);
        record("COUNTERS " + name + "=" + recorded);
        persist();
    }

    private static long[] hostState(String name, Method diagnostics) throws Throwable {
        long[] state = (long[]) call(diagnostics);
        counters(name, state);
        require(state != null && state.length == 8, "host.state.shape");
        return state;
    }

    private static long[] armState(String name) throws Exception {
        long[] state = ArmBridge.state();
        counters(name, state);
        counters(name + "Details", ArmBridge.details());
        require(state != null && state.length == 3, "arm.state.shape");
        return state;
    }

    private long[][] localWebView(Method diagnostics) throws Throwable {
        CountDownLatch pageDone = new CountDownLatch(1);
        AtomicBoolean providerCreated = new AtomicBoolean();
        AtomicBoolean finished = new AtomicBoolean();
        AtomicReference<Throwable> failure = new AtomicReference<>();
        AtomicReference<WebView> holder = new AtomicReference<>();
        at("webview.provider.creation");
        runOnUiThread(() -> {
            try {
                WebView view = new WebView(this);
                holder.set(view);
                providerCreated.set(true);
                record("PASS webview.provider.created");
                view.getSettings().setBlockNetworkLoads(true);
                view.setWebViewClient(new WebViewClient() {
                    @Override public void onPageFinished(WebView webView, String ignoredUrl) {
                        finished.set(true);
                        record("PASS webview.local.html.onPageFinished");
                        pageDone.countDown();
                    }
                    @Override public void onReceivedError(WebView webView, WebResourceRequest request, WebResourceError error) {
                        if (request.isForMainFrame()) {
                            failure.set(new IllegalStateException("Local HTML load failed"));
                            record("FAIL webview.local.html.error.code=" + error.getErrorCode());
                            pageDone.countDown();
                        }
                    }
                });
                setContentView(view);
                record("before.webview.local.html.loadData");
                view.loadData("<!doctype html><html><head><meta charset='utf-8'></head><body></body></html>",
                    "text/html", "UTF-8");
            } catch (Throwable error) {
                failure.set(error);
                pageDone.countDown();
            }
        });
        boolean returned = pageDone.await(25, TimeUnit.SECONDS);
        CountDownLatch destroyed = new CountDownLatch(1);
        runOnUiThread(() -> {
            try { if (holder.get() != null) holder.get().destroy(); }
            catch (Throwable error) { failure.compareAndSet(null, error); }
            finally { destroyed.countDown(); }
        });
        boolean released = destroyed.await(5, TimeUnit.SECONDS);
        long[] host = hostState("hostAfterWebView", diagnostics);
        long[] arm = armState("armAfterWebView");
        if (failure.get() != null) throw failure.get();
        require(returned && providerCreated.get() && finished.get() && released, "webview.local.page.completed.and.released");
        result.put("webViewLocalPageCompleted", true);
        result.put("webViewTimezoneModified", false);
        return new long[][] {host, arm};
    }

    private void execute() {
        boolean passed = false;
        try {
            require((Build.VERSION.SDK_INT == 31 || Build.VERSION.SDK_INT == 32)
                && android.os.Process.is64Bit(), "runtime.api31_32.process64");
            at("arm.bridge.load");
            System.loadLibrary("cage_host_load_arm");
            require(ArmBridge.health() == 0x43414745, "arm.bridge.health.before");
            require(Sentinel.class.getClassLoader() == getClassLoader(), "sentinel.application.loader");
            at("baseline.arm.library.load");
            System.loadLibrary("cage_sentinel_baseline");
            armState("armBaseline");
            require(Sentinel.count(1) == 1, "baseline.jniOnLoad.findClass.once");

            File directory = new File(getCodeCacheDir(), "host-load-proof-v1");
            require(directory.isDirectory() || directory.mkdirs(), "private.helper.directory");
            File dex = extract("host-bridge.dex", directory);
            File nativeLibrary = extract("libcage_host_load_bridge.so", directory);
            ClassLoader boot = Object.class.getClassLoader();
            DexClassLoader loader = new DexClassLoader(dex.getAbsolutePath(), directory.getAbsolutePath(), null, boot);
            require(loader.getParent() == boot, "host.loader.boot.parent");
            boolean cannotSeeApp = false;
            try { Class.forName(Sentinel.class.getName(), false, loader); }
            catch (ClassNotFoundException expected) { cannotSeeApp = true; }
            require(cannotSeeApp, "host.loader.cannot.resolve.app.sentinel");
            Class<?> helper = Class.forName("io.github.leexeo.cage.hostloadprobe.host.HostBridge", true, loader);
            require(helper.getClassLoader() == loader, "host.helper.defined.by.independent.loader");
            Method open = helper.getMethod("open", String.class);
            Method install = helper.getMethod("install", Class.class, String.class);
            Method diagnostics = helper.getMethod("diagnostics");
            at("host.x86.library.open");
            String opened = (String) call(open, nativeLibrary.getAbsolutePath());
            record("host.open=" + opened);
            require(opened != null && opened.startsWith("PASS"), "host.x86.library.open");
            File missing = new File(getFilesDir(), ".absent-host-load-" + Long.toHexString(System.nanoTime()) + ".so");
            require(!missing.exists(), "missing.library.absent");
            hostState("hostBeforeInstallation", diagnostics);
            armState("armBeforeInstallation");
            at("host.wrapper.install");
            String installed = (String) call(install, ArmBridge.class, missing.getAbsolutePath());
            record("host.install=" + installed);
            long[] hostBefore = hostState("hostBefore", diagnostics);
            long[] armBefore = armState("armBefore");
            require(installed != null && installed.startsWith("PASS"), "host.wrapper.install.error.pair");
            require(hostBefore[0] == 1 && hostBefore[7] == 1, "host.wrapper.original.metadata.intact");
            require(ArmBridge.health() == 0x43414745, "arm.bridge.health.after.install");

            at("wrapped.arm.library.load");
            System.loadLibrary("cage_sentinel_after");
            hostState("hostAfterWrapped", diagnostics);
            armState("armAfterWrapped");
            require(Sentinel.count(2) == 1, "wrapped.jniOnLoad.findClass.once");
            require(ArmBridge.health() == 0x43414745, "arm.bridge.health.after.wrapped");
            at("nested.arm.library.load");
            System.loadLibrary("cage_sentinel_nested");
            long[] hostSuccess = hostState("hostAfterSuccess", diagnostics);
            long[] armSuccess = armState("armAfterSuccess");
            require(Sentinel.seenMask() == 15, "all.four.distinct.jniOnLoad.sentinels.seen");
            for (int id = 1; id <= 4; ++id) require(Sentinel.count(id) == 1, "sentinel.once." + id);
            require(ArmBridge.health() == 0x43414745, "arm.bridge.health.after.nested");
            require(hostSuccess[2] - hostBefore[2] == 3, "host.three.new.arm.loads.successful");
            require(hostSuccess[4] - hostBefore[4] == 3, "host.three.success.notifications");
            require(hostBefore[5] == 0 && hostSuccess[5] == 0, "host.no.pending.exception");
            require(hostSuccess[6] >= 2, "host.nested.nativeLoad.depth.observed");
            require(hostSuccess[7] == 1, "host.original.metadata.retained");
            require(armBefore[0] == 0 && armBefore[1] == 0 && armBefore[2] == 0
                && armSuccess[0] == 3 && armSuccess[1] == 3 && armSuccess[2] == 0,
                "host.to.arm.three.callbacks.returned");

            at("java.missing.library.control");
            boolean originalError = false;
            try { System.load(missing.getAbsolutePath()); }
            catch (UnsatisfiedLinkError expected) { originalError = true; }
            long[] hostEnd = hostState("hostFinal", diagnostics);
            long[] armEnd = armState("armFinal");
            require(originalError, "java.missing.library.original.error.type");
            require(hostEnd[1] - hostSuccess[1] == 1 && hostEnd[3] - hostSuccess[3] == 1 && hostEnd[2] == hostSuccess[2]
                && hostEnd[4] == hostSuccess[4] && armEnd[0] == armSuccess[0], "missing.library.no.success.notification");
            require(ArmBridge.health() == 0x43414745, "arm.bridge.final.health");
            result.put("sentinelMask", Sentinel.seenMask());
            long[][] webViewStates = localWebView(diagnostics);
            long[] hostWebView = webViewStates[0];
            long[] armWebView = webViewStates[1];
            require(ArmBridge.health() == 0x43414745 && hostWebView[5] == 0 && hostWebView[7] == 1
                && armWebView[2] == 0, "webview.afterward.jni.healthy.metadata.intact");
            passed = true;
            record("PASS all.host.loader.stages");
        } catch (Throwable failure) {
            record("FAIL stage=" + stage + " exception=" + failure.getClass().getSimpleName());
            try { result.put("exceptionType", failure.getClass().getSimpleName()); }
            catch (Exception ignored) {}
        } finally {
            try {
                result.put("schemaVersion", 2);
                result.put("passed", passed);
                result.put("lastStage", stage);
                result.put("networkOrAccounts", false);
                result.put("gboxIntegrationTested", false);
                persist();
            } catch (Exception failure) { record("summary.write.failed." + failure.getClass().getSimpleName()); }
            record("FINISHED passed=" + passed + " exiting.disposable.process");
            // The Runtime registration affects only this disposable process.
            android.os.Process.killProcess(android.os.Process.myPid());
        }
    }

    @Override public void onCreate(Bundle state) {
        super.onCreate(state);
        report = new File(getFilesDir(), "latest-host-load-report.txt");
        summary = new File(getFilesDir(), "latest-host-load-report.json");
        try (FileOutputStream stream = new FileOutputStream(report, false)) {
            stream.write("Cage Host Loader Probe 02\n".getBytes(StandardCharsets.UTF_8));
        } catch (Exception failure) { throw new IllegalStateException("Cannot create local diagnostic report"); }
        TextView text = new TextView(this);
        text.setText("正在验证类加载器和原生回调。完成后测试进程会退出。");
        setContentView(text);
        new Thread(this::execute, "CageHostLoaderProbe").start();
    }
}
