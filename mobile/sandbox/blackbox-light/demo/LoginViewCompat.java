package io.github.leexeo.cage.space;

import android.app.Activity;
import android.net.Uri;
import android.os.Handler;
import android.os.Looper;
import android.view.View;
import android.webkit.WebView;
import java.lang.reflect.Field;

/** Show the completed Google identifier page without replacing microG's browser client or JS bridge. */
public final class LoginViewCompat implements Runnable {
    private final Activity activity;
    private final Handler main = new Handler(Looper.getMainLooper());
    private int attempts;
    private LoginViewCompat(Activity activity) { this.activity = activity; }
    public static void resume(Activity activity) {
        if (!"org.microg.gms.auth.login.LoginActivity".equals(activity.getClass().getName())) return;
        LoginViewCompat check = new LoginViewCompat(activity);
        check.main.postDelayed(check, 500);
    }
    @Override public void run() {
        if (activity.isFinishing() || activity.isDestroyed()) return;
        try {
            Field field = activity.getClass().getDeclaredField("webView"); field.setAccessible(true);
            WebView web = (WebView) field.get(activity);
            if (web != null && web.getUrl() != null && web.getProgress() == 100) {
                Uri uri = Uri.parse(web.getUrl());
                if ("https".equals(uri.getScheme()) && "accounts.google.com".equals(uri.getHost())
                        && uri.getPath() != null && uri.getPath().endsWith("/identifier")) {
                    web.setVisibility(View.VISIBLE);
                    web.bringToFront();
                    android.util.Log.i("CageDemo", "Loaded Google identifier page shown");
                    return;
                }
            }
        } catch (ReflectiveOperationException | RuntimeException unavailable) { return; }
        if (++attempts < 240) main.postDelayed(this, 500);
    }
}
