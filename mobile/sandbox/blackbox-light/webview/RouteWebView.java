package io.github.leexeo.cage.webviewroute;

import android.Manifest;
import android.content.Context;
import android.content.ContextWrapper;
import android.content.pm.PackageManager;
import android.content.res.Configuration;
import android.os.Binder;
import android.os.Handler;
import android.os.Looper;
import android.os.Process;
import android.util.Log;
import android.webkit.WebView;
import java.lang.reflect.InvocationTargetException;
import java.util.ArrayDeque;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.Executor;

/** HTTPS remains inside Chromium; only its first hop is replaced by the shell's Unix proxy. */
public final class RouteWebView extends WebView {
    private static final String TAG = "CageWebViewRoute";
    private final Handler main = new Handler(Looper.getMainLooper());
    private final ArrayDeque<Runnable> waiting = new ArrayDeque<>();
    private boolean ready;
    private boolean failed;
    private boolean destroyed;
    private String state = "initializing";
    private final Runnable deadline = () -> fail("proxy callback timeout", null);

    public RouteWebView(Context context) {
        super(new WebOnlyContext(context));
        // The wrapper may make the default false; block before the app can submit a request.
        getSettings().setBlockNetworkLoads(true);
        try {
            System.loadLibrary("cage_webview");
            int patched = nativeInstall();
            if (patched <= 0) throw new IllegalStateException("native install=" + patched);
            Log.i(TAG, "native installed " + nativeStatus());
            installProxy();
        } catch (Throwable error) {
            fail("initialization failed", error);
        }
    }

    private void installProxy() throws ReflectiveOperationException {
        ClassLoader loader = RouteWebView.class.getClassLoader();
        Class<?> features = Class.forName("androidx.webkit.WebViewFeature", true, loader);
        Object supported = features.getMethod("isFeatureSupported", String.class).invoke(null, "PROXY_OVERRIDE");
        if (!Boolean.TRUE.equals(supported)) throw new IllegalStateException("PROXY_OVERRIDE unsupported");
        Class<?> builderType = Class.forName("androidx.webkit.ProxyConfig$Builder", true, loader);
        Object builder = builderType.getConstructor().newInstance();
        builderType.getMethod("addProxyRule", String.class).invoke(builder, "http://127.0.0.1:38491");
        // Remove localhost/link-local bypasses too; no addDirect() or direct fallback is installed.
        builderType.getMethod("removeImplicitRules").invoke(builder);
        Object config = builderType.getMethod("build").invoke(builder);
        Class<?> configType = Class.forName("androidx.webkit.ProxyConfig", true, loader);
        Class<?> controllerType = Class.forName("androidx.webkit.ProxyController", true, loader);
        Object controller = controllerType.getMethod("getInstance").invoke(null);
        Executor executor = command -> main.post(command);
        Runnable applied = () -> {
            if (failed || destroyed) return;
            try {
                // Recheck module coverage before releasing queued application requests.
                if (nativeInstall() <= 0) throw new IllegalStateException("native recheck failed");
                getSettings().setBlockNetworkLoads(false);
                if (getSettings().getBlockNetworkLoads()) throw new IllegalStateException("loading remains blocked");
                main.removeCallbacks(deadline);
                state = "ready";
                ready = true;
                Log.i(TAG, "proxy applied; releasing " + waiting.size() + " queued requests; " + nativeStatus());
                while (!waiting.isEmpty() && !destroyed && !failed) waiting.removeFirst().run();
            } catch (Throwable error) {
                fail("could not enable routed loads", error);
            }
        };
        state = "waiting_for_proxy";
        main.postDelayed(deadline, 10000);
        controllerType.getMethod("setProxyOverride", configType, Executor.class, Runnable.class)
                .invoke(controller, config, executor, applied);
    }

    private void submit(Runnable request) {
        if (Looper.myLooper() != Looper.getMainLooper()) {
            throw new IllegalStateException("RouteWebView requires its UI thread");
        }
        if (failed || destroyed) return;
        if (ready) request.run();
        else if (waiting.size() < 8) waiting.addLast(request);
        else fail("initial request queue full", null);
    }

    @Override public void loadUrl(String url) {
        submit(() -> RouteWebView.super.loadUrl(url));
    }

    @Override public void loadUrl(String url, Map<String, String> headers) {
        Map<String, String> saved = headers == null ? null : new HashMap<>(headers);
        submit(() -> RouteWebView.super.loadUrl(url, saved));
    }

    @Override public void postUrl(String url, byte[] postData) {
        byte[] saved = postData == null ? null : postData.clone();
        submit(() -> RouteWebView.super.postUrl(url, saved));
    }

    private void fail(String reason, Throwable error) {
        if (destroyed) return;
        ready = false;
        failed = true;
        state = reason;
        main.removeCallbacks(deadline);
        waiting.clear();
        try { getSettings().setBlockNetworkLoads(true); super.stopLoading(); }
        catch (RuntimeException ignored) { /* The kernel still denies all direct INET sockets. */ }
        Throwable cause = error instanceof InvocationTargetException
                ? ((InvocationTargetException) error).getCause() : error;
        // Never log URL arguments, HTTP data, credentials, cookies, or exception messages.
        Log.e(TAG, reason + (cause == null ? "" : "; " + cause.getClass().getName()));
    }

    public String routeStatus() {
        try { return state + "; " + nativeStatus(); }
        catch (UnsatisfiedLinkError unavailable) { return state + "; native unavailable"; }
    }

    @Override public void destroy() {
        main.removeCallbacksAndMessages(null);
        waiting.clear();
        ready = false;
        destroyed = true;
        super.destroy();
    }

    private static native int nativeInstall();
    private static native String nativeStatus();

    /** Only this view and its derived configuration contexts see this logical permission. */
    private static final class WebOnlyContext extends ContextWrapper {
        WebOnlyContext(Context base) { super(base); }
        private static int answer(String permission, int pid, int uid, int actual) {
            return Manifest.permission.INTERNET.equals(permission)
                    && pid == Process.myPid() && uid == Process.myUid()
                    ? PackageManager.PERMISSION_GRANTED : actual;
        }
        @Override public int checkSelfPermission(String permission) {
            return answer(permission, Process.myPid(), Process.myUid(), super.checkSelfPermission(permission));
        }
        @Override public int checkPermission(String permission, int pid, int uid) {
            return answer(permission, pid, uid, super.checkPermission(permission, pid, uid));
        }
        @Override public int checkCallingOrSelfPermission(String permission) {
            int actual = super.checkCallingOrSelfPermission(permission);
            // BlackBox may virtualize Process.myUid(), whereas Binder exposes the kernel UID.
            return Manifest.permission.INTERNET.equals(permission) && Binder.getCallingPid() == Process.myPid()
                    ? PackageManager.PERMISSION_GRANTED : actual;
        }
        @Override public Context getApplicationContext() { return super.getApplicationContext(); }
        @Override public Context createConfigurationContext(Configuration configuration) {
            return new WebOnlyContext(super.createConfigurationContext(configuration));
        }
    }
}
