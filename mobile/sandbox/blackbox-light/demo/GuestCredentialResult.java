package io.github.leexeo.cage.space;

import android.app.Activity;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.credentials.Credential;
import android.credentials.GetCredentialException;
import android.credentials.GetCredentialResponse;
import android.os.Build;
import android.os.Bundle;
import android.os.IBinder;
import android.util.Log;

/** Adapts only the container of an actual private microG credential result on Android 14+. */
public final class GuestCredentialResult {
    private static final String CHOOSER = "org.microg.gms.auth.credentials.identity.IdentityCredentialChooserActivity";
    private static final String RESPONSE = "android.service.credentials.extra.GET_CREDENTIAL_RESPONSE";
    private static final String EXCEPTION = "android.service.credentials.extra.GET_CREDENTIAL_EXCEPTION";
    private GuestCredentialResult() {}

    public static void finish(Object[] args) {
        if (Build.VERSION.SDK_INT < 34 || args == null || args.length != 4
                || !(args[0] instanceof IBinder) || !Integer.valueOf(Activity.RESULT_OK).equals(args[1])
                || !(args[2] instanceof Intent) || !(args[3] instanceof Integer)) return;
        try {
            Class<?> core = Class.forName("top.niunaijun.blackbox.BlackBoxCore");
            Context host = (Context) core.getMethod("getContext").invoke(null);
            if (!ClaudeBundle.HOST.equals(host.getPackageName())
                    || !(Boolean) core.getMethod("isBlackProcess").invoke(core.getMethod("get").invoke(null))) return;
            Class<?> thread = Class.forName("top.niunaijun.blackbox.app.BActivityThread");
            if (!"com.google.android.gms".equals(thread.getMethod("getAppPackageName").invoke(null))
                    || (Integer) thread.getMethod("getUserId").invoke(null) != 0) return;
            Activity activity = (Activity) thread.getMethod("getActivityByToken", IBinder.class).invoke(null, args[0]);
            if (activity == null || activity.isDestroyed() || !CHOOSER.equals(activity.getClass().getName())
                    || !new ComponentName(ClaudeBundle.PACKAGE,
                        "androidx.credentials.playservices.controllers.identityauth.HiddenActivity")
                        .equals(activity.getCallingActivity())
                    || !ClaudeBundle.PACKAGE.equals(activity.getIntent()
                        .getStringExtra("org.microg.gms.identitycredentials.EXTRA_CALLING_PACKAGE"))) return;
            Intent original = (Intent) args[2];
            Bundle extras = original.getExtras();
            if (extras == null) return;
            Object response = extras.get(RESPONSE), error = extras.get(EXCEPTION);
            Intent adapted = new Intent(original);
            if (response instanceof Bundle && error == null) {
                Bundle wrapper = (Bundle) response;
                String type = wrapper.getString("androidx.credentials.provider.extra.EXTRA_CREDENTIAL_TYPE");
                Bundle data = wrapper.getBundle("androidx.credentials.provider.extra.EXTRA_CREDENTIAL_DATA");
                if (wrapper.size() != 2 || type == null || type.isEmpty() || data == null) return;
                // Do not inspect, reconstruct or log any credential data. Keep microG's actual data Bundle.
                adapted.putExtra(RESPONSE, new GetCredentialResponse(new Credential(type, data)));
                args[2] = adapted;
                Log.i("CageDemo", "Private Google result container adapted for Android 14+");
            } else if (error instanceof Bundle && response == null) {
                Bundle wrapper = (Bundle) error;
                String type = wrapper.getString("androidx.credentials.provider.extra.CREATE_CREDENTIAL_EXCEPTION_TYPE");
                String message = wrapper.getString("androidx.credentials.provider.extra.CREATE_CREDENTIAL_EXCEPTION_MESSAGE");
                if (type == null || type.isEmpty()) return;
                adapted.putExtra(EXCEPTION, new GetCredentialException(type, message));
                args[2] = adapted;
                Log.i("CageDemo", "Private Google error container adapted for Android 14+");
            }
        } catch (ReflectiveOperationException | RuntimeException unavailable) {
            // Preserve the original failure/result; never replace it with success.
            Log.w("CageDemo", "Private Google result container unavailable: " + unavailable.getClass().getSimpleName());
        }
    }
}
