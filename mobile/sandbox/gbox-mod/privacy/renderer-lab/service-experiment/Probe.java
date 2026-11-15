package io.github.leexeo.cage.timezonelab;

import android.app.Activity;
import android.content.Context;
import android.content.pm.PackageInfo;
import android.os.Bundle;
import android.os.Handler;
import android.os.SystemClock;
import android.webkit.JavascriptInterface;
import android.webkit.RenderProcessGoneDetail;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.TextView;
import io.github.leexeo.cage.privacy.WebViewTimezone;
import java.io.FileOutputStream;
import java.lang.reflect.Constructor;
import java.lang.reflect.Method;
import java.nio.charset.StandardCharsets;
import java.util.TimeZone;
import org.json.JSONArray;
import org.json.JSONObject;
import org.json.JSONTokener;

/** No INTERNET permission. All pages, workers and reports belong to this disposable app. */
public final class Probe extends Activity {
    private static final String ZONE = "Asia/Tokyo";
    private static final String READ = "JSON.stringify({zone:Intl.DateTimeFormat().resolvedOptions().timeZone,"
        + "offset:-new Date().getTimezoneOffset(),epoch:Date.now(),url:location.href,history:history.length})";
    private final Handler handler = new Handler();
    private final JSONObject report = new JSONObject();
    private final JSONArray stages = new JSONArray();
    private WebView web;
    private TextView text;
    private String mode;
    private int generation, completed;
    private boolean finished, expectGone;
    private long deadline;

    private void put(JSONObject object, String key, Object value) {
        try { object.put(key, value); } catch (Exception e) { throw new IllegalStateException(e); }
    }
    private void record(String name, Object value) { put(report, name, value); }

    @Override public void onCreate(Bundle saved) {
        super.onCreate(saved);
        text = new TextView(this);
        setContentView(text);
        mode = getIntent().getStringExtra("mode");
        if (mode == null) mode = "baseline";
        record("schema", 1);
        record("mode", mode);
        record("runId", getIntent().getStringExtra("runId"));
        record("pid", android.os.Process.myPid());
        record("originalZone", TimeZone.getDefault().getID());
        record("stages", stages);
        record("networkPermission", false);
        try {
            PackageInfo provider = WebView.getCurrentWebViewPackage();
            record("provider", provider.packageName);
            record("providerVersion", provider.versionName);
            if (android.os.Build.VERSION.SDK_INT != 36
                    || !"com.google.android.webview".equals(provider.packageName)
                    || !"156.0.8078.47".equals(provider.versionName)
                    || provider.getLongVersionCode() != 807804703L)
                throw new IllegalStateException("Unsupported exact provider");
            if (!"baseline".equals(mode)) installMonitor();
            createView();
        } catch (Throwable error) { fail(error); }
        handler.postDelayed(() -> { if (!finished) fail(new IllegalStateException("Overall deadline")); }, 20000);
    }

    private void installMonitor() throws Exception {
        // The same bundled helper already used by the source container, scoped only to this app.
        Class<?> bypass = Class.forName("org.lsposed.hiddenapibypass.HiddenApiBypass");
        boolean exempted = (Boolean) bypass.getMethod("setHiddenApiExemptions", String[].class)
            .invoke(null, (Object) new String[]{"Landroid/webkit/WebViewFactory;"});
        if (!exempted) throw new IllegalStateException("Factory access unavailable");
        WebView.setDataDirectorySuffix("timezone-lab");
        TimeZone.setDefault(TimeZone.getTimeZone(ZONE));
        // Chromium's native monitor supplies the renderer update; Java default alone is insufficient.
        Class<?> factory = Class.forName("android.webkit.WebViewFactory");
        Method getProvider = factory.getDeclaredMethod("getProvider");
        getProvider.setAccessible(true);
        Object provider = getProvider.invoke(null);
        if(mode.equals("renderer-unmonitored")) {
            java.lang.reflect.Field contextField=Class.forName("WV.y10",false,provider.getClass().getClassLoader()).getDeclaredField("a");
            contextField.setAccessible(true);
            contextField.set(null,new RendererRedirect((Context)contextField.get(null)));
            record("monitorInstalled",false);
            return;
        }
        Class<?> monitor = Class.forName("io.github.leexeo.cage.privacy.WebViewTimezone$MonitorContext");
        Constructor<?> constructor = monitor.getDeclaredConstructor(ClassLoader.class, String.class,
            String.class, WebViewTimezone.Scope.class);
        constructor.setAccessible(true);
        Object wrapper = constructor.newInstance(provider.getClass().getClassLoader(), getPackageName(),
            ZONE, (WebViewTimezone.Scope) pkg -> getPackageName().equals(pkg) && !finished);
        Method attach = monitor.getDeclaredMethod("attach");
        attach.setAccessible(true);
        attach.invoke(wrapper);
        if(mode.startsWith("renderer"))RendererRedirect.install(wrapper);
        record("monitorInstalled", true);
    }

    private void createView() {
        final int token = ++generation;
        web = new WebView(this);
        web.getSettings().setJavaScriptEnabled(!"gate-disabled".equals(mode));
        web.addJavascriptInterface(new Bridge(token), "OwnedReport");
        web.setWebViewClient(new WebViewClient() {
            @Override public boolean onRenderProcessGone(WebView view, RenderProcessGoneDetail detail) {
                record("rendererGone", true);
                record("rendererDidCrash", detail.didCrash());
                view.destroy();
                if (view == web) web = null;
                if (expectGone && !finished) {
                    expectGone = false;
                    handler.post(Probe.this::createView);
                } else if (!finished) fail(new IllegalStateException("Unexpected renderer loss"));
                return true;
            }
        });
        JSONObject entry = new JSONObject();
        put(entry, "generation", token);
        put(entry, "gateReadings", new JSONArray());
        stages.put(entry);
        if (mode.startsWith("renderer")) {
            if(mode.equals("renderer-unmonitored"))web.evaluateJavascript(READ,value -> record("unconditionedInitialEval",value));
            loadOwnedPage(token);
        }
        else if ("baseline".equals(mode) || "monitor".equals(mode)) loadOwnedPage(token);
        else {
            deadline = SystemClock.elapsedRealtime() + 5000;
            poll(token, entry);
        }
    }

    private void poll(int token, JSONObject entry) {
        if (finished || generation != token || web == null) return;
        if (SystemClock.elapsedRealtime() >= deadline) {
            fail(new IllegalStateException("Timezone confirmation deadline"));
            return;
        }
        web.evaluateJavascript(READ, value -> {
            if (finished || generation != token || web == null) return;
            try {
                Object decoded = new JSONTokener(value).nextValue();
                if (!(decoded instanceof String)) throw new IllegalStateException("Missing blank document result");
                JSONObject read = new JSONObject((String) decoded);
                entry.getJSONArray("gateReadings").put(read);
                if (!"about:blank".equals(read.getString("url")))
                    throw new IllegalStateException("Gate has navigated unexpectedly");
                boolean expected = ZONE.equals(read.getString("zone")) && read.getInt("offset") == 540;
                if (expected && !"gate-mismatch".equals(mode)) {
                    put(entry, "gateConfirmed", true);
                    loadOwnedPage(token);
                } else handler.postDelayed(() -> poll(token, entry), 10);
            } catch (Throwable error) { fail(error); }
        });
    }

    private void loadOwnedPage(int token) {
        // The very first target script reads the engine's native Date/Intl values unchanged.
        String html = "<!doctype html><script>window.first=" + READ + ";"
            + "window.values={first:JSON.parse(first)};function done(){if(values.frame&&values.worker)"
            + "{values.later=JSON.parse(" + READ + ");OwnedReport.deliver(JSON.stringify(values));}}"
            + "onmessage=function(e){values.frame=e.data;done();};"
            + "var source=\"postMessage({zone:Intl.DateTimeFormat().resolvedOptions().timeZone,"
            + "offset:-new Date().getTimezoneOffset(),epoch:Date.now()})\";"
            + "var workerUrl=URL.createObjectURL(new Blob([source],{type:'text/javascript'}));"
            + "var worker=new Worker(workerUrl);worker.onmessage=function(e){values.worker=e.data;"
            + "worker.terminate();URL.revokeObjectURL(workerUrl);done();};</script>"
            + "<iframe srcdoc=\"<script>parent.postMessage({zone:Intl.DateTimeFormat().resolvedOptions().timeZone,"
            + "offset:-new Date().getTimezoneOffset(),epoch:Date.now()},'*')<" + "/script>\"></iframe>";
        web.loadDataWithBaseURL("https://timezone-lab.invalid/", html, "text/html", "UTF-8", null);
    }

    private final class Bridge {
        final int token;
        Bridge(int token) { this.token = token; }
        @JavascriptInterface public void deliver(String value) {
            handler.post(() -> {
                if (finished || generation != token || web == null) return;
                try {
                    JSONObject entry = stages.getJSONObject(token - 1);
                    JSONArray pages = entry.optJSONArray("pages");
                    if (pages == null) { pages = new JSONArray(); put(entry, "pages", pages); }
                    pages.put(new JSONObject(value));
                    ++completed;
                    if (("gate-recreate".equals(mode) || "renderer-recreate".equals(mode)) && completed == 1) {
                        expectGone = true;
                        if (web.getWebViewRenderProcess() == null || !web.getWebViewRenderProcess().terminate())
                            throw new IllegalStateException("Cannot terminate owned renderer");
                    } else if ("gate-reload".equals(mode) && completed == 1) web.reload();
                    else if ("gate-newview".equals(mode) && completed == 1) {
                        web.destroy();
                        web = null;
                        handler.post(Probe.this::createView);
                    } else save();
                } catch (Throwable error) { fail(error); }
            });
        }
    }

    private void fail(Throwable error) {
        while (error instanceof java.lang.reflect.InvocationTargetException && error.getCause() != null)
            error = error.getCause();
        record("error", error.getClass().getSimpleName());
        // Only our fixed failures are recorded; no arbitrary provider messages or addresses.
        if (error.getClass() == IllegalStateException.class) record("failureStage", error.getMessage());
        save();
    }
    private void save() {
        if (finished) return;
        finished = true;
        record("complete", true);
        record("completedPages", completed);
        record("redirected",RendererRedirect.redirected.get());
        record("epochAtSave", System.currentTimeMillis());
        try (FileOutputStream out = openFileOutput("result.json", Context.MODE_PRIVATE)) {
            out.write(report.toString(2).getBytes(StandardCharsets.UTF_8));
            text.setText(report.toString(2));
        } catch (Exception error) { text.setText(error.getClass().getSimpleName()); }
    }
    @Override protected void onDestroy() {
        finished = true;
        handler.removeCallbacksAndMessages(null);
        if (web != null) web.destroy();
        super.onDestroy();
    }
}
