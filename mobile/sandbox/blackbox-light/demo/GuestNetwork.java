package io.github.leexeo.cage.space;

import android.content.Context;
import android.net.*;
import android.os.*;
import android.util.Log;
import java.lang.reflect.*;
import java.util.concurrent.ConcurrentHashMap;

/** Guest-visible network metadata only. Real Network handles and kernel VPN routing stay intact. */
public final class GuestNetwork {
    private static final String HOST = "top.niunaijun.microdem";
    private static final boolean DIAGNOSTICS = false;
    private static final HandlerThread callbacks = new HandlerThread("Cage-network-events");
    private static final ConcurrentHashMap<IBinder, Messenger> relays = new ConcurrentHashMap<>();
    static { callbacks.start(); }

    public static Object selfPermission(Object base, Method method, Object[] original) throws Throwable {
        if (!"checkPermissionForDevice".equals(method.getName()) || original == null || original.length != 4
                || !(original[1] instanceof Integer) || !(original[2] instanceof Integer)
                || (Integer) original[1] != android.os.Process.myPid()) return null;
        String permission = String.valueOf(original[0]);
        if (!android.Manifest.permission.INTERNET.equals(permission)
                && !android.Manifest.permission.ACCESS_NETWORK_STATE.equals(permission)) return null;
        int guestUid = (Integer) Class.forName("top.niunaijun.blackbox.app.BActivityThread").getMethod("getBUid").invoke(null);
        if ((Integer) original[2] != guestUid) return null;
        Object[] args = original.clone();
        args[2] = Class.forName("top.niunaijun.blackbox.BlackBoxCore").getMethod("getHostUid").invoke(null);
        // Preserve deviceId and return the real system grant/denial; never fabricate a grant.
        try { return method.invoke(base, args); }
        catch (InvocationTargetException failure) { throw failure.getCause(); }
    }

    public static Object invoke(Object base, Method method, Object[] original) throws Throwable {
        Object[] args = original == null ? null : original.clone();
        if (args != null) for (int i = 0; i < args.length; i++) {
            Object arg = args[i];
            // Android verifies the attributed package against the actual Binder caller UID.
            if (arg instanceof String && (arg.equals("com.google.android.gms") || arg.equals("com.android.vending")
                    || arg.equals("com.anthropic.claude") || arg.equals("io.github.leexeo.cage.stablenet"))) args[i] = HOST;
            if (arg instanceof Messenger) args[i] = relay((Messenger) arg);
        }
        try { return sanitize(method.invoke(base, args)); }
        catch (InvocationTargetException failure) { throw failure.getCause(); }
    }

    private static Messenger relay(Messenger target) {
        return relays.computeIfAbsent(target.getBinder(), binder -> {
            Messenger forwarding = new Messenger(new Handler(callbacks.getLooper(), input -> {
                Message message = Message.obtain(input);
                Bundle data = new Bundle(input.getData());
                data.setClassLoader(NetworkCapabilities.class.getClassLoader());
                for (String key : data.keySet()) {
                    Object value = data.get(key), safe = sanitize(value);
                    if (safe != value && safe instanceof Parcelable) data.putParcelable(key, (Parcelable) safe);
                }
                message.setData(data);
                try { target.send(message); } catch (RemoteException gone) { relays.remove(binder); }
                return true;
            }));
            try { binder.linkToDeath(() -> relays.remove(binder), 0); } catch (RemoteException ignored) {}
            return forwarding;
        });
    }

    private static Object sanitize(Object value) {
        if (value instanceof NetworkCapabilities) {
            NetworkCapabilities result = new NetworkCapabilities((NetworkCapabilities) value);
            if (result.hasTransport(NetworkCapabilities.TRANSPORT_VPN)) {
                try {
                    NetworkCapabilities.class.getMethod("removeTransportType", int.class).invoke(result, NetworkCapabilities.TRANSPORT_VPN);
                    if (!result.hasTransport(NetworkCapabilities.TRANSPORT_WIFI)
                            && !result.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR))
                        NetworkCapabilities.class.getMethod("addTransportType", int.class).invoke(result, NetworkCapabilities.TRANSPORT_WIFI);
                    NetworkCapabilities.class.getMethod("addCapability", int.class).invoke(result, NetworkCapabilities.NET_CAPABILITY_NOT_VPN);
                    NetworkCapabilities.class.getMethod("setTransportInfo", Class.forName("android.net.TransportInfo")).invoke(result, new Object[]{null});
                } catch (ReflectiveOperationException unavailable) {
                    throw new IllegalStateException("Guest network metadata unavailable", unavailable);
                }
            }
            return result;
        }
        if (value instanceof NetworkInfo) {
            NetworkInfo info = (NetworkInfo) value;
            if (info.getType() == ConnectivityManager.TYPE_VPN) {
                NetworkInfo result = new NetworkInfo(ConnectivityManager.TYPE_WIFI, 0, "WIFI", "");
                result.setDetailedState(info.getDetailedState(), info.getReason(), null);
                try { NetworkInfo.class.getMethod("setIsAvailable", boolean.class).invoke(result, info.isAvailable()); }
                catch (ReflectiveOperationException failure) { throw new IllegalStateException(failure); }
                return result;
            }
        }
        if (value instanceof NetworkInfo[]) {
            NetworkInfo[] result = ((NetworkInfo[]) value).clone();
            for (int i = 0; i < result.length; i++) result[i] = (NetworkInfo) sanitize(result[i]);
            return result;
        }
        if (value instanceof LinkProperties) {
            Parcel parcel = Parcel.obtain();
            LinkProperties result;
            try {
                ((LinkProperties) value).writeToParcel(parcel, 0);
                parcel.setDataPosition(0);
                result = LinkProperties.CREATOR.createFromParcel(parcel);
            } finally { parcel.recycle(); }
            String iface = result.getInterfaceName();
            if (iface != null && (iface.startsWith("tun") || iface.startsWith("ppp"))) result.setInterfaceName("cage0");
            return result;
        }
        return value;
    }

    public static void bind(Context host, Context guest) {
        String guestPackage = guest.getPackageName();
        if (!"com.google.android.gms".equals(guestPackage) && !"com.android.vending".equals(guestPackage)
                && !"com.anthropic.claude".equals(guestPackage))
            throw new SecurityException("This DEMO only runs its Google and Claude apps");
        if ("com.anthropic.claude".equals(guestPackage)) {
            GuestSplits.verify(host);
        } else {
            try {
                SpacePackages packages = new SpacePackages(host);
                android.content.pm.PackageInfo installed = packages.installed(guestPackage);
                if (!packages.privateCopy(installed)) throw new IllegalStateException("Private guest package missing");
                SpacePackages.inspect(host, new java.io.File(installed.applicationInfo.sourceDir));
            } catch (Exception invalidGuest) { throw new SecurityException("Guest signature unavailable", invalidGuest); }
        }
        boolean ready = false;
        try {
            Bundle state = host.getContentResolver().call(Uri.parse("content://io.github.leexeo.cage.microdemo.status"),
                    "status", null, null);
            ready = state != null && state.getBoolean("protectionReady", false);
        } catch (RuntimeException unavailable) {
            Log.w("CageDemo", "Gateway state unavailable: " + unavailable.getClass().getSimpleName());
        }
        if (!ready) {
            Log.w("CageDemo", "Guest launch blocked: system network protection is not ready");
            android.os.Process.killProcess(android.os.Process.myPid());
            throw new IllegalStateException("Network protection is not ready");
        }
        // This DEMO uses Android's locked VPN, with no Java proxy factory or native socket shim.
        Log.i("CageDemo", "System-network guest: " + guest.getPackageName());
        GuestPackageIdentity.prepare(guest);
        GuestProfiles.prepare(guest);
        GuestIntegrityTrace.identitySnapshot(guest);
        GuestAccounts.bind(host, guest);
        if ("com.android.vending".equals(guest.getPackageName())) {
            ClassLoader loader = guest.getClassLoader();
            try { Class.forName("org.apache.http.ProtocolVersion", false, loader); }
            catch (ClassNotFoundException missingLegacyLibrary) {
                try {
                    String library = "/system/framework/org.apache.http.legacy.jar";
                    if (!new java.io.File(library).isFile()) throw new IllegalStateException("System HTTP library missing");
                    Class.forName("dalvik.system.BaseDexClassLoader").getMethod("addDexPath", String.class)
                            .invoke(loader, library);
                    Class.forName("org.apache.http.ProtocolVersion", false, loader);
                    Log.i("CageDemo", "Play system HTTP library loaded");
                } catch (ReflectiveOperationException unavailable) {
                    throw new IllegalStateException("Play system HTTP library unavailable", unavailable);
                }
            }
        }
        if (DIAGNOSTICS && "com.android.vending".equals(guest.getPackageName())) {
            new Thread(() -> {
                try { Thread.sleep(15000); } catch (InterruptedException stopped) { return; }
                for (StackTraceElement frame : Looper.getMainLooper().getThread().getStackTrace())
                    Log.i("CageDemo", "store_main: " + frame);
            }, "Cage-store-start-check").start();
        }
        if (DIAGNOSTICS && "com.google.android.gms".equals(guest.getPackageName())) {
            LoginCheck.start();
            new Thread(() -> {
                java.net.HttpURLConnection connection = null;
                try {
                    connection = (java.net.HttpURLConnection) new java.net.URL("https://accounts.google.com/").openConnection();
                    connection.setConnectTimeout(8000); connection.setReadTimeout(8000);
                    connection.setUseCaches(false); connection.setInstanceFollowRedirects(false);
                    connection.setRequestMethod("HEAD");
                    Log.i("CageDemo", "guest_https_status=" + connection.getResponseCode());
                } catch (java.io.IOException failure) {
                    Log.i("CageDemo", "guest_https_failure=" + failure.getClass().getSimpleName()
                            + "/" + (failure.getCause() == null ? "none" : failure.getCause().getClass().getSimpleName()));
                } finally { if (connection != null) connection.disconnect(); }
            }, "Cage-login-network-check").start();
        }
        try {
            ConnectivityManager cm = (ConnectivityManager) guest.getSystemService(Context.CONNECTIVITY_SERVICE);
            Network n = cm.getActiveNetwork();
            NetworkCapabilities caps = cm.getNetworkCapabilities(n);
            NetworkInfo info = cm.getActiveNetworkInfo();
            LinkProperties link = cm.getLinkProperties(n);
            Log.i("CageDemo", "guest_network active=" + (n != null) + " vpn="
                    + (caps != null && caps.hasTransport(NetworkCapabilities.TRANSPORT_VPN))
                    + " not_vpn=" + (caps != null && caps.hasCapability(NetworkCapabilities.NET_CAPABILITY_NOT_VPN))
                    + " legacy_type=" + (info == null ? -1 : info.getType())
                    + " dns_count=" + (link == null ? -1 : link.getDnsServers().size())
                    + " internet_permission=" + guest.checkSelfPermission(android.Manifest.permission.INTERNET)
                    + " network_state_permission=" + guest.checkSelfPermission(android.Manifest.permission.ACCESS_NETWORK_STATE));
        } catch (RuntimeException failure) { Log.w("CageDemo", "Network metadata check: " + failure.getClass().getSimpleName()); }
    }
}
