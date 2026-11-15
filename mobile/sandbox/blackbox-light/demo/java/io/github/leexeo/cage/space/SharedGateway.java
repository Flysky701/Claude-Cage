package io.github.leexeo.cage.space;

import android.content.Context;
import android.net.Network;
import android.net.NetworkCapabilities;
import android.net.Uri;
import android.os.Bundle;
import android.os.IBinder;
import android.provider.Settings;
import android.util.Log;

/** Read the actual system protection state without changing the selected VPN. */
public final class SharedGateway {
    static final String METHOD = "cage_shared_gateway_status";

    public static Bundle status(Context context) {
        try {
            Bundle result = context.getContentResolver().call(
                Uri.parse("content://top.niunaijun.microdem.blackbox.SystemCallProvider"),
                METHOD, null, null);
            return result == null ? new Bundle() : result;
        } catch (RuntimeException e) {
            Log.w("CageInstall", "gateway_state_unavailable=" + e.getClass().getSimpleName());
            return new Bundle();
        }
    }

    public static boolean ready(Context context) {
        return status(context).getBoolean("protectionReady", false);
    }

    // Runs in the host server. Its process also has network masking installed,
    // so use the original system service for this internal protection check.
    static Bundle localStatus(Context context) {
        Bundle result = new Bundle();
        boolean lockdown = false, vpn = false, readable = false, excluded = true;
        try {
            lockdown = Settings.Secure.getInt(context.getContentResolver(), "always_on_vpn_lockdown", 0) == 1;
            String whitelist = Settings.Secure.getString(context.getContentResolver(), "always_on_vpn_lockdown_whitelist");
            excluded = false;
            if (whitelist != null) {
                for (String entry : whitelist.split(",")) {
                    if (entry.trim().equals(context.getPackageName())) excluded = true;
                }
            }
            // Android selects/enforces the user's always-on VPN. Its package ID
            // is not readable by ordinary apps. Require a VPN on THIS app's
            // active network plus lockdown and no exception for this app.
            IBinder binder = (IBinder) Class.forName("android.os.ServiceManager")
                .getMethod("getService", String.class).invoke(null, "connectivity");
            Object service;
            Class<?> hook = Class.forName("top.niunaijun.blackbox.fake.hook.BinderInvocationStub");
            Class<?> api = Class.forName("android.net.IConnectivityManager");
            if (hook.isInstance(binder)) {
                service = hook.getMethod("getBase").invoke(binder);
            } else {
                service = Class.forName("android.net.IConnectivityManager$Stub")
                    .getMethod("asInterface", IBinder.class).invoke(null, binder);
            }
            Network active = (Network) api.getMethod("getActiveNetwork").invoke(service);
            NetworkCapabilities caps = active == null ? null : (NetworkCapabilities)
                api.getMethod("getNetworkCapabilities", Network.class, String.class, String.class)
                    .invoke(service, active, context.getPackageName(), null);
            vpn = caps != null && caps.hasTransport(NetworkCapabilities.TRANSPORT_VPN);
            readable = true;
        } catch (Exception e) {
            Log.w("CageInstall", "gateway_check_error=" + e.getClass().getSimpleName());
        }
        result.putBoolean("protectionReady", lockdown && vpn && readable && !excluded);
        Log.i("CageInstall", "gateway_guard lockdown=" + lockdown + " vpn=" + vpn
            + " readable=" + readable + " excluded=" + excluded);
        return result;
    }
}
