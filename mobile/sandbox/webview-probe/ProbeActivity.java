package io.github.leexeo.cage.webviewprobe;

import android.Manifest;
import android.app.Activity;
import android.app.Application;
import android.content.Context;
import android.content.ContextWrapper;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.content.res.Configuration;
import android.net.http.SslError;
import android.os.Binder;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.os.Process;
import android.system.ErrnoException;
import android.system.Os;
import android.system.OsConstants;
import android.util.AtomicFile;
import android.webkit.SslErrorHandler;
import android.webkit.WebResourceError;
import android.webkit.WebResourceRequest;
import android.webkit.WebResourceResponse;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;
import java.io.File;
import java.io.FileDescriptor;
import java.io.FileOutputStream;
import java.nio.charset.StandardCharsets;
import java.util.UUID;

/** First-layer experiment only: no proxy, native hooks, accounts, or TLS exceptions. */
public class ProbeActivity extends Activity {
    public static final class Plain extends ProbeActivity {}
    public static final class Wrapped extends ProbeActivity {}
    private static final String TARGET = "https://example.com/";
    private static final String PROCESS_RUN = UUID.randomUUID().toString();
    private static int processRunCount;
    private final Handler main = new Handler(Looper.getMainLooper());
    private final JSONObject report = new JSONObject();
    private Trace trace;
    private WebView web;
    private TextView status;
    private String mode;
    private File resultFile;
    private boolean finished;
    private final Runnable deadline = () -> complete("observation_timeout");

    private static void put(JSONObject object, String key, Object value) {
        try { object.put(key, value == null ? JSONObject.NULL : value); }
        catch (JSONException impossible) { throw new IllegalStateException(impossible); }
    }

    @Override public void onCreate(Bundle saved) {
        super.onCreate(saved);
        mode = this instanceof Wrapped ? "wrapped" : "plain";
        trace = new Trace();
        resultFile = new File(getFilesDir(), "probe-" + mode + ".json");
        put(report, "schema_version", 1);
        put(report, "mode", mode);
        put(report, "run_id", UUID.randomUUID().toString());
        put(report, "process_instance", PROCESS_RUN);
        put(report, "run_in_process", ++processRunCount);
        put(report, "started_at_ms", System.currentTimeMillis());
        put(report, "pid", Process.myPid());
        put(report, "uid", Process.myUid());
        put(report, "process_name", Application.getProcessName());
        put(report, "sdk_int", android.os.Build.VERSION.SDK_INT);
        put(report, "target_url", TARGET);
        put(report, "scope", "WebView loading gate only; Chromium proxy transport is absent");
        put(report, "completed", false);
        LinearLayout page = new LinearLayout(this);
        page.setOrientation(LinearLayout.VERTICAL);
        status = new TextView(this);
        status.setTextIsSelectable(true);
        status.setPadding(16, 16, 16, 16);
        ScrollView details = new ScrollView(this);
        details.addView(status);
        page.addView(details, new LinearLayout.LayoutParams(-1, 0, 1));
        setContentView(page);
        main.post(() -> runProbe(page));
    }

    private void runProbe(LinearLayout page) {
        trace.phase = "before_webview";
        put(report, "permission_before", realPermission());
        put(report, "kernel_before_webview", kernelSockets());
        persist();
        try {
            // Separate processes and data directories prevent cross-mode provider/cache reuse.
            WebView.setDataDirectorySuffix("probe-" + mode);
            Context context = "wrapped".equals(mode) ? new WebOnlyContext(this, trace) : this;
            trace.phase = "webview_constructor";
            web = new WebView(context);
            put(report, "webview_context_class", web.getContext().getClass().getName());
            trace.phase = "webview_settings";
            WebSettings settings = web.getSettings();
            put(report, "settings_class", settings.getClass().getName());
            put(report, "block_network_loads_initial", settings.getBlockNetworkLoads());
            JSONObject change = new JSONObject();
            try {
                settings.setBlockNetworkLoads(false);
                put(change, "succeeded", true);
            } catch (RuntimeException denied) {
                put(change, "succeeded", false);
                put(change, "exception_class", denied.getClass().getName());
                put(change, "exception_message", clipped(denied.getMessage(), 200));
            }
            put(change, "block_network_loads_after", settings.getBlockNetworkLoads());
            put(report, "set_block_network_loads_false", change);
            PackageInfo provider = WebView.getCurrentWebViewPackage();
            JSONObject identity = new JSONObject();
            if (provider != null) {
                put(identity, "package", provider.packageName);
                put(identity, "version_name", provider.versionName);
                put(identity, "version_code", provider.getLongVersionCode());
            }
            put(report, "webview_provider", identity);
            put(report, "permission_after_settings", realPermission());
            put(report, "kernel_after_settings", kernelSockets());
            settings.setAllowFileAccess(false);
            settings.setAllowContentAccess(false);
            settings.setCacheMode(WebSettings.LOAD_NO_CACHE);
            settings.setJavaScriptEnabled(false);
            web.setWebViewClient(client());
            page.addView(web, new LinearLayout.LayoutParams(-1,
                    (int) (180 * getResources().getDisplayMetrics().density)));
            trace.phase = "page_load";
            persist();
            if (getIntent().getBooleanExtra("load_page", true)) {
                main.postDelayed(deadline, 15000);
                web.loadUrl(TARGET);
            } else {
                complete("page_load_disabled");
            }
        } catch (RuntimeException failure) {
            JSONObject error = new JSONObject();
            put(error, "class", failure.getClass().getName());
            put(error, "message", clipped(failure.getMessage(), 240));
            put(report, "probe_exception", error);
            complete("probe_exception");
        }
    }

    private WebViewClient client() {
        return new WebViewClient() {
            @Override public boolean shouldOverrideUrlLoading(WebView view, WebResourceRequest request) {
                // The exported launcher cannot supply a URL; navigation stays on the fixed fixture.
                boolean blocked = !TARGET.equals(request.getUrl().toString());
                if (blocked) {
                    put(report, "other_navigation_blocked", true);
                    persist();
                }
                return blocked;
            }
            @Override public void onPageFinished(WebView view, String url) {
                put(report, "on_page_finished", true);
                put(report, "finished_url_is_fixed_target", TARGET.equals(url));
                // onPageFinished may describe Chromium's error document; it is not success proof.
                complete("page_finished");
            }
            @Override public void onReceivedError(WebView view, WebResourceRequest request, WebResourceError error) {
                if (!request.isForMainFrame()) return;
                JSONObject value = new JSONObject();
                put(value, "code", error.getErrorCode());
                put(value, "description", clipped(String.valueOf(error.getDescription()), 200));
                put(value, "url_is_fixed_target", TARGET.equals(request.getUrl().toString()));
                put(report, "main_frame_error", value);
                complete("main_frame_error");
            }
            @Override public void onReceivedHttpError(WebView view, WebResourceRequest request, WebResourceResponse response) {
                if (!request.isForMainFrame()) return;
                put(report, "main_frame_http_status", response.getStatusCode());
                persist();
            }
            @Override public void onReceivedSslError(WebView view, SslErrorHandler handler, SslError error) {
                handler.cancel();
                put(report, "ssl_error_cancelled", error.getPrimaryError());
                complete("ssl_error_cancelled");
            }
        };
    }

    private JSONObject realPermission() {
        JSONObject value = new JSONObject();
        put(value, "activity_check_self_permission", checkSelfPermission(Manifest.permission.INTERNET));
        put(value, "package_manager_check_permission", getPackageManager().checkPermission(
                Manifest.permission.INTERNET, getPackageName()));
        try {
            PackageInfo info = getPackageManager().getPackageInfo(getPackageName(), PackageManager.GET_PERMISSIONS);
            boolean requested = false;
            if (info.requestedPermissions != null) {
                for (String permission : info.requestedPermissions)
                    if (Manifest.permission.INTERNET.equals(permission)) requested = true;
            }
            put(value, "manifest_requests_internet", requested);
        } catch (PackageManager.NameNotFoundException failure) {
            put(value, "package_lookup_failed", true);
        }
        return value;
    }

    private static JSONArray kernelSockets() {
        JSONArray checks = new JSONArray();
        for (int family : new int[]{OsConstants.AF_INET, OsConstants.AF_INET6}) {
            for (int type : new int[]{OsConstants.SOCK_STREAM, OsConstants.SOCK_DGRAM}) {
                JSONObject item = new JSONObject();
                put(item, "family", family == OsConstants.AF_INET ? "IPv4" : "IPv6");
                put(item, "type", type == OsConstants.SOCK_STREAM ? "TCP" : "UDP");
                FileDescriptor descriptor = null;
                try {
                    // Never connect or send; close immediately if the permission boundary is absent.
                    descriptor = Os.socket(family, type, 0);
                    put(item, "result", "unexpectedly_created");
                } catch (ErrnoException denied) {
                    put(item, "errno", denied.errno);
                    put(item, "result", denied.errno == OsConstants.EACCES || denied.errno == OsConstants.EPERM
                            ? "permission_denied" : "other_errno");
                    put(item, "errno_message", Os.strerror(denied.errno));
                } finally {
                    if (descriptor != null) {
                        try { Os.close(descriptor); }
                        catch (ErrnoException failure) { put(item, "close_errno", failure.errno); }
                    }
                }
                checks.put(item);
            }
        }
        return checks;
    }

    private void complete(String reason) {
        if (!finished) {
            finished = true;
            main.removeCallbacks(deadline);
            trace.phase = "after_load";
            put(report, "kernel_after_load", kernelSockets());
            put(report, "permission_after_load", realPermission());
            put(report, "completion_reason", reason);
            put(report, "completed_at_ms", System.currentTimeMillis());
            put(report, "completed", true);
        }
        persist();
    }

    private void persist() {
        put(report, "permission_events", trace.snapshot());
        put(report, "permission_events_dropped", trace.dropped());
        put(report, "saved_at_ms", System.currentTimeMillis());
        AtomicFile file = new AtomicFile(resultFile);
        FileOutputStream out = null;
        try {
            String json = report.toString(2);
            out = file.startWrite();
            out.write(json.getBytes(StandardCharsets.UTF_8));
            file.finishWrite(out);
            status.setText("模式：" + mode + "\n结果：files/" + resultFile.getName()
                    + "\n仅诊断加载开关；未接入 Chromium 代理。\n\n" + json);
        } catch (Exception failure) {
            if (out != null) file.failWrite(out);
            status.setText("结果保存失败：" + failure.getClass().getSimpleName());
        }
    }

    @Override protected void onDestroy() {
        main.removeCallbacksAndMessages(null);
        if (trace != null && resultFile != null) complete("activity_destroyed");
        if (web != null) {
            web.stopLoading();
            web.destroy();
            web = null;
        }
        super.onDestroy();
    }

    private void observed(String method, String permission, int pid, int uid, int result) {
        if (trace != null) trace.permission("activity", method, permission, pid, uid, result, result);
    }
    @Override public int checkSelfPermission(String permission) {
        int result = super.checkSelfPermission(permission);
        observed("checkSelfPermission", permission, Process.myPid(), Process.myUid(), result);
        return result;
    }
    @Override public int checkPermission(String permission, int pid, int uid) {
        int result = super.checkPermission(permission, pid, uid);
        observed("checkPermission", permission, pid, uid, result);
        return result;
    }
    @Override public int checkCallingOrSelfPermission(String permission) {
        int result = super.checkCallingOrSelfPermission(permission);
        observed("checkCallingOrSelfPermission", permission, Binder.getCallingPid(), Binder.getCallingUid(), result);
        return result;
    }
    @Override public int checkCallingPermission(String permission) {
        int result = super.checkCallingPermission(permission);
        observed("checkCallingPermission", permission, Binder.getCallingPid(), Binder.getCallingUid(), result);
        return result;
    }

    private static String clipped(String value, int max) {
        return value == null || value.length() <= max ? value : value.substring(0, max);
    }

    /** Only this WebView's context graph sees the logical override; the app context stays real. */
    private static final class WebOnlyContext extends ContextWrapper {
        private final Trace trace;
        WebOnlyContext(Context base, Trace trace) { super(base); this.trace = trace; }

        private int answer(String method, String permission, int pid, int uid, int actual) {
            int result = Manifest.permission.INTERNET.equals(permission)
                    && pid == Process.myPid() && uid == Process.myUid()
                    ? PackageManager.PERMISSION_GRANTED : actual;
            trace.permission("webview_wrapper", method, permission, pid, uid, actual, result);
            return result;
        }
        @Override public int checkSelfPermission(String permission) {
            return answer("checkSelfPermission", permission, Process.myPid(), Process.myUid(),
                    super.checkSelfPermission(permission));
        }
        @Override public int checkPermission(String permission, int pid, int uid) {
            return answer("checkPermission", permission, pid, uid, super.checkPermission(permission, pid, uid));
        }
        @Override public int checkCallingOrSelfPermission(String permission) {
            return answer("checkCallingOrSelfPermission", permission, Binder.getCallingPid(), Binder.getCallingUid(),
                    super.checkCallingOrSelfPermission(permission));
        }
        @Override public int checkCallingPermission(String permission) {
            // Keep calling-only semantics: no override for this method.
            int actual = super.checkCallingPermission(permission);
            trace.permission("webview_wrapper", "checkCallingPermission", permission,
                    Binder.getCallingPid(), Binder.getCallingUid(), actual, actual);
            return actual;
        }
        @Override public Context getApplicationContext() {
            trace.note("getApplicationContext", "original application context returned");
            return super.getApplicationContext();
        }
        @Override public Context createConfigurationContext(Configuration configuration) {
            trace.note("createConfigurationContext", "derived WebView context remains wrapped");
            return new WebOnlyContext(super.createConfigurationContext(configuration), trace);
        }
    }

    private static final class Trace {
        private final JSONArray events = new JSONArray();
        private int overflow;
        volatile String phase = "initialization";
        synchronized void permission(String context, String method, String permission, int pid, int uid,
                int actual, int returned) {
            JSONObject item = new JSONObject();
            put(item, "context", context);
            put(item, "method", method);
            put(item, "permission", permission);
            put(item, "pid", pid);
            put(item, "uid", uid);
            put(item, "actual_result", actual);
            put(item, "returned_result", returned);
            put(item, "overridden", actual != returned);
            JSONArray callers = new JSONArray();
            for (StackTraceElement frame : Thread.currentThread().getStackTrace()) {
                String name = frame.getClassName();
                if (name.startsWith("java.lang.Thread") || name.startsWith(ProbeActivity.class.getName())) continue;
                callers.put(clipped(name + "." + frame.getMethodName(), 180));
                if (callers.length() == 4) break;
            }
            put(item, "callers", callers);
            add(item);
        }
        synchronized void note(String method, String value) {
            JSONObject item = new JSONObject();
            put(item, "context", "webview_wrapper");
            put(item, "method", method);
            put(item, "note", value);
            add(item);
        }
        private void add(JSONObject item) {
            if (events.length() >= 64) { overflow++; return; }
            put(item, "phase", phase);
            put(item, "time_ms", System.currentTimeMillis());
            events.put(item);
        }
        synchronized JSONArray snapshot() {
            try { return new JSONArray(events.toString()); }
            catch (JSONException impossible) { throw new IllegalStateException(impossible); }
        }
        synchronized int dropped() { return overflow; }
    }
}
