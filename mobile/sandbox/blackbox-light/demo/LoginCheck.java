package io.github.leexeo.cage.space;

import android.app.Activity;
import android.os.*;
import android.util.Log;
import android.view.*;
import android.webkit.WebView;
import java.lang.reflect.*;
import java.util.Map;

/** Temporary DEMO-only check. Reads no input values, cookies, page body or URL parameters. */
public final class LoginCheck implements Runnable {
    private final Handler main = new Handler(Looper.getMainLooper());
    private int attempts;
    private boolean settingsLogged;
    public static void start() { LoginCheck check = new LoginCheck(); check.main.postDelayed(check, 1000); }
    private WebView find(View view) {
        if (view instanceof WebView) return (WebView) view;
        if (view instanceof ViewGroup) {
            ViewGroup group = (ViewGroup) view;
            for (int i = 0; i < group.getChildCount(); i++) {
                WebView found = find(group.getChildAt(i));
                if (found != null) return found;
            }
        }
        return null;
    }
    @Override public void run() {
        try {
            Class<?> thread = Class.forName("android.app.ActivityThread");
            Object current = thread.getMethod("currentActivityThread").invoke(null);
            Field activities = thread.getDeclaredField("mActivities"); activities.setAccessible(true);
            for (Object record : ((Map<?, ?>) activities.get(current)).values()) {
                Field field = record.getClass().getDeclaredField("activity"); field.setAccessible(true);
                Activity activity = (Activity) field.get(record);
                if (activity == null || !activity.getClass().getName().equals("org.microg.gms.auth.login.LoginActivity")) continue;
                WebView web = find(activity.getWindow().getDecorView());
                if (web == null) for (Field candidate : activity.getClass().getDeclaredFields()) {
                    if (!WebView.class.isAssignableFrom(candidate.getType())) continue;
                    candidate.setAccessible(true); web = (WebView) candidate.get(activity);
                    if (web != null) break;
                }
                if (web == null) continue;
                if (!settingsLogged) {
                    Log.i("CageDemo", "login_webview blocked=" + web.getSettings().getBlockNetworkLoads()
                            + " js=" + web.getSettings().getJavaScriptEnabled() + " visibility=" + web.getVisibility());
                    settingsLogged = true;
                }
                if (web.getUrl() == null || web.getUrl().startsWith("about:")) continue;
                final WebView checked = web;
                main.postDelayed(() -> checked.evaluateJavascript("JSON.stringify({protocol:location.protocol,host:location.hostname,forms:document.forms.length,inputs:document.querySelectorAll('input').length,error:(document.querySelector('.error-code')||{}).textContent||''})",
                        result -> Log.i("CageDemo", "login_page_shape=" + result)), 5000);
                return;
            }
        } catch (ReflectiveOperationException | RuntimeException unavailable) {
            Log.w("CageDemo", "login_shape_unavailable=" + unavailable.getClass().getSimpleName()); return;
        }
        if (++attempts < 120) main.postDelayed(this, 1000);
    }
}
