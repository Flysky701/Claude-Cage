package io.github.leexeo.cage.privacy;

import android.content.Context;
import android.content.pm.ApplicationInfo;
import android.net.ConnectivityManager;
import android.net.LinkProperties;
import android.net.Network;
import android.net.NetworkCapabilities;
import android.net.NetworkInfo;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.HandlerThread;
import android.os.IBinder;
import android.os.Message;
import android.os.Messenger;
import android.os.Parcelable;
import android.os.Parcel;
import android.system.Os;
import android.util.Log;
import java.lang.reflect.Array;
import java.lang.reflect.Field;
import java.lang.reflect.InvocationHandler;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.lang.reflect.Proxy;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TimeZone;
import java.util.concurrent.ConcurrentHashMap;

/** Process-local presentation policy. This class does not route or authorize traffic. */
public final class GuestPrivacy {
    private static final String TAG = "CagePrivacy";
    private static volatile boolean active;
    private static volatile String boundPackage;
    private static volatile String webViewStatus;
    private static boolean osInstalled, nativePropertiesApplied, nativeReadPolicyRequested;
    private static final Set<String> vpnInterfaces = Collections.synchronizedSet(new HashSet<String>());
    private static final Map<IBinder, Messenger> relays = new ConcurrentHashMap<>();
    private static final Map<String, String> originalProperties = new HashMap<>();
    private static TimeZone originalZone;
    private static android.icu.util.TimeZone originalIcuZone;
    private static String originalEnvironmentZone, originalUserZone;
    private static HandlerThread eventThread;
    private static Method clientGet, clientReady, clientPackage;
    private static final WebViewTimezone.Scope WEBVIEW_SCOPE = new WebViewTimezone.Scope() {
        @Override public boolean isCurrentGuest(String pkg) {
            return active && pkg != null && pkg.equals(boundPackage) && pkg.equals(currentPackage());
        }
    };

    private GuestPrivacy() {}

    public static boolean selected(String packageName) {
        return "com.anthropic.claude".equals(packageName)
            || "io.github.leexeo.cage.gboxprobe".equals(packageName);
    }

    /** Called before VLite's cached-application fast path can bypass bind(). */
    public static synchronized void beforeBind(String requestedPackage) {
        NativePrivacy.assertProcessUsable();
        if (active && !java.util.Objects.equals(boundPackage, requestedPackage)) deactivate();
        try { WebViewTimezone.assertProcessReusable(requestedPackage); }
        catch (IllegalStateException failure) {
            throw new GuestProcessReuseBlocked(failure);
        }
    }

    /** Original startup errors keep their behavior; only a persistent reuse block escapes. */
    public static void rethrowIfBlocked(Throwable failure) {
        NativePrivacy.assertProcessUsable();
        if (WebViewTimezone.isBlocked()) throw new GuestProcessReuseBlocked(failure);
    }

    /** Read-only actual guest check used by the synchronous native-load observer. */
    public static boolean isNativeScopeCurrent() {
        String pkg = boundPackage;
        return active && selected(pkg) && pkg.equals(currentPackage());
    }

    public static final class GuestProcessReuseBlocked extends IllegalStateException {
        GuestProcessReuseBlocked(Throwable cause) {
            super("Guest WebView state requires a fresh process before rebinding", cause);
        }
    }

    /** Instrumentation can also receive the host Context before guest startup. */
    public static synchronized void bind(Context guest) {
        Log.i(TAG, "stage.bind.enter");
        String pkg = currentPackage();
        boolean sameGuest = active && pkg != null && pkg.equals(boundPackage);
        Log.i(TAG, "preparation.refresh active=" + active + " sameGuest=" + sameGuest);
        if (!sameGuest) {
            if (active) deactivate();
            Log.i(TAG, "stage.bind.defer.explicitGuestContext");
            return;
        }
        if (!contextIdentity(guest, pkg)) {
            Log.i(TAG, "stage.bind.defer.contextIdentity");
            return;
        }
        apply(guest);
    }

    /** Called only after VLite's actual guest createPackageContext has returned. */
    public static synchronized void bindGuestContext(Context guest) {
        Log.i(TAG, "stage.guestContext.enter");
        String pkg = currentPackage();
        if (!selected(pkg)) {
            if (active) deactivate();
            return;
        }
        if (active && pkg.equals(boundPackage)) {
            bind(guest);
            return;
        }
        if (active) deactivate();
        if (!contextIdentity(guest, pkg)) {
            Log.i(TAG, "stage.guestContext.defer.contextIdentity");
            return;
        }
        if (!runtimePrepared(guest, pkg)) {
            Log.i(TAG, "stage.guestContext.defer.runtime");
            return;
        }
        // DEFER above has not changed any policy or captured a partial binding.
        beforeBind(pkg);
        Log.i(TAG, "stage.guestContext.ready");
        {
            // Snapshot while the policy is still inactive, so control-plane reads are real.
            Log.i(TAG, "stage.bind.before.recordVpn");
            recordVpnInterfaces(guest);
            Log.i(TAG, "stage.bind.after.recordVpn");
            Log.i(TAG, "stage.bind.before.snapshotTime");
            originalZone = TimeZone.getDefault();
            originalEnvironmentZone = System.getenv("TZ");
            originalUserZone = System.getProperty("user.timezone");
            if (Build.VERSION.SDK_INT >= 24) originalIcuZone = android.icu.util.TimeZone.getDefault();
            Log.i(TAG, "stage.bind.after.snapshotTime");
            boundPackage = pkg;
            active = true;
            Log.i(TAG, "stage.bind.before.osProxy");
            installOsProxy();
            Log.i(TAG, "stage.bind.after.osProxy");
            Log.i(TAG, "stage.bind.before.properties");
            nativePropertiesApplied = applyProperties();
            Log.i(TAG, "stage.bind.after.properties");
            Log.i(TAG, "stage.bind.before.nativeReads");
            try {
                nativeReadPolicyRequested = NativePrivacy.bind(guest, pkg, Profile.ZONE,
                    Profile.SIM, Profile.TIMEZONE, Profile.VPN, vpnInterfaces);
            } catch (NativePrivacy.NativeLoadBridgeFailure failure) {
                try { deactivate(); } catch (RuntimeException restore) { failure.addSuppressed(restore); }
                throw failure;
            }
            Log.i(TAG, "stage.bind.after.nativeReads");
            Log.i(TAG, "stage.bind.before.child");
            ChildPolicy.activate(guest, Profile.SIM, Profile.TIMEZONE, Profile.ZONE);
            Log.i(TAG, "stage.bind.after.child");
            Log.i(TAG, "bound sim=" + Profile.SIM + " timezone=" + Profile.TIMEZONE
                + " vpn=" + Profile.VPN + " nativeProperties=" + nativePropertiesApplied
                + " osProxy=" + osInstalled + " nativeReadsRequested=" + nativeReadPolicyRequested);
        }
        Log.i(TAG, "stage.bind.before.apply");
        apply(guest);
        Log.i(TAG, "stage.bind.after.apply");
    }

    private static boolean contextIdentity(Context guest, String pkg) {
        boolean context = false, info = false, source = false, data = false;
        try {
            context = guest != null && pkg != null && pkg.equals(guest.getPackageName());
            ApplicationInfo application = guest == null ? null : guest.getApplicationInfo();
            info = application != null && pkg != null && pkg.equals(application.packageName);
            source = application != null && application.sourceDir != null && !application.sourceDir.isEmpty();
            data = application != null && application.dataDir != null && !application.dataDir.isEmpty();
        } catch (RuntimeException unavailable) {
            Log.i(TAG, "preparation.context.unavailable");
        }
        Log.i(TAG, "preparation.identity context=" + context + " info=" + info
            + " source=" + source + " data=" + data);
        return context && info && source && data;
    }

    private static boolean runtimePrepared(Context guest, String pkg) {
        Class<?> compatibility;
        try {
            compatibility = Class.forName("io.github.leexeo.cage.gbox.NativeCompat");
        } catch (ClassNotFoundException originalBuild) {
            // Original ARM builds have no MuMu adapter. The explicit Context
            // boundary and guest identity are still required in that build.
            Log.i(TAG, "preparation.runtime present=false originalPath=true verified=false frameworkReady=false");
            return true;
        } catch (LinkageError unavailable) {
            Log.i(TAG, "preparation.runtime.unavailable");
            return false;
        }
        try {
            int state = (Integer) compatibility.getMethod("privacyPreparationState").invoke(null);
            boolean original = state == 1, verified = state == 2, paths = false;
            if (verified) {
                paths = Boolean.TRUE.equals(Class.forName("io.github.leexeo.cage.gbox.FrameworkPaths")
                    .getMethod("isGuestContextReady", Context.class, String.class).invoke(null, guest, pkg));
            }
            Log.i(TAG, "preparation.runtime present=true originalPath=" + original
                + " verified=" + verified + " frameworkReady=" + paths);
            return original || verified && paths;
        } catch (ReflectiveOperationException | RuntimeException | LinkageError unavailable) {
            Log.i(TAG, "preparation.runtime.unavailable");
            return false;
        }
    }

    public static void apply(Context guest) {
        Log.i(TAG, "stage.apply.enter");
        if (!inScope() || !contextIdentity(guest, boundPackage)) return;
        if (Profile.TIMEZONE) {
            Log.i(TAG, "stage.apply.before.javaTime");
            TimeZone.setDefault(TimeZone.getTimeZone(Profile.ZONE));
            System.setProperty("user.timezone", Profile.ZONE);
            if (Build.VERSION.SDK_INT >= 24) {
                setIcuZone(android.icu.util.TimeZone.getTimeZone(Profile.ZONE));
            }
            try { Os.setenv("TZ", Profile.ZONE, true); }
            catch (Exception e) { Log.w(TAG, "timezone environment unavailable"); }
            Log.i(TAG, "stage.apply.after.javaTime");
            Log.i(TAG, "stage.apply.before.webview");
            WebViewTimezone.prepare(guest, boundPackage, Profile.ZONE, WEBVIEW_SCOPE);
            Log.i(TAG, "stage.apply.after.webview");
            String nextStatus = WebViewTimezone.diagnostics().getString("status");
            if (nextStatus != null && !nextStatus.equals(webViewStatus)) {
                webViewStatus = nextStatus;
                Log.i(TAG, "webview." + nextStatus);
            }
        }
    }

    private static String currentPackage() {
        try {
            if (clientGet == null) {
                Class<?> clientClass = Class.forName("com.vlite.sdk.client.k");
                clientReady = clientClass.getMethod("hasInit");
                clientPackage = clientClass.getMethod("getVirtualClientPkgName");
                clientGet = clientClass.getMethod("getInst");
            }
            Object client = clientGet.invoke(null);
            if (!Boolean.TRUE.equals(clientReady.invoke(client))) return null;
            return (String) clientPackage.invoke(client);
        } catch (ReflectiveOperationException | RuntimeException e) { return null; }
    }

    private static boolean inScope() {
        if (!active) return false;
        String current = currentPackage();
        if (current != null && current.equals(boundPackage)) return true;
        synchronized (GuestPrivacy.class) { if (active) deactivate(); }
        return false;
    }

    private static void deactivate() {
        active = false;
        try {
            NativePrivacy.deactivate();
            ChildPolicy.deactivate();
            Class<?> nativeApi = Class.forName("com.vlite.sdk.jni.Native");
            Method set = nativeApi.getMethod("addNativeProp", String.class, String.class);
            for (Map.Entry<String, String> value : originalProperties.entrySet())
                set.invoke(null, value.getKey(), value.getValue());
            if (originalZone != null) TimeZone.setDefault(originalZone);
            if (Build.VERSION.SDK_INT >= 24 && originalIcuZone != null)
                setIcuZone(originalIcuZone);
            if (originalUserZone == null) System.clearProperty("user.timezone");
            else System.setProperty("user.timezone", originalUserZone);
            if (originalEnvironmentZone == null) Os.unsetenv("TZ");
            else Os.setenv("TZ", originalEnvironmentZone, true);
            WebViewTimezone.stopAndRestore();
        } catch (Exception | LinkageError e) {
            // A process with un-restorable guest state must not become a different app.
            if (WebViewTimezone.isBlocked()) throw new GuestProcessReuseBlocked(e);
            throw new IllegalStateException("Cannot restore previous guest environment", e);
        } finally {
            boundPackage = null;
            originalProperties.clear();
            nativePropertiesApplied = false;
            nativeReadPolicyRequested = false;
            vpnInterfaces.clear();
            relays.clear();
        }
    }

    private static void setIcuZone(android.icu.util.TimeZone zone) {
        try {
            android.icu.util.TimeZone.class.getDeclaredMethod("setDefault", android.icu.util.TimeZone.class)
                .invoke(null, zone);
        } catch (ReflectiveOperationException e) {
            throw new IllegalStateException("Cannot apply guest ICU timezone", e);
        }
    }

    private static void recordVpnInterfaces(Context context) {
        if (!Profile.VPN) return;
        try {
            ConnectivityManager cm = (ConnectivityManager) context.getSystemService(Context.CONNECTIVITY_SERVICE);
            if (cm == null) return;
            for (Network network : cm.getAllNetworks()) {
                NetworkCapabilities caps = cm.getNetworkCapabilities(network);
                if (caps != null && caps.hasTransport(NetworkCapabilities.TRANSPORT_VPN)) {
                    LinkProperties lp = cm.getLinkProperties(network);
                    if (lp != null && lp.getInterfaceName() != null) vpnInterfaces.add(lp.getInterfaceName());
                }
            }
        } catch (RuntimeException e) { Log.w(TAG, "initial interface observation unavailable"); }
    }

    private static boolean applyProperties() {
        Map<String, String> values = new HashMap<>();
        if (Profile.SIM) {
            values.put("gsm.sim.state", "ABSENT");
            values.put("gsm.sim.operator.alpha", "");
            values.put("gsm.sim.operator.numeric", "");
            values.put("gsm.sim.operator.iso-country", "");
            values.put("gsm.operator.alpha", "");
            values.put("gsm.operator.numeric", "");
            values.put("gsm.operator.iso-country", "");
            values.put("gsm.operator.isroaming", "false");
            values.put("gsm.current.phone-type", "0");
        }
        if (Profile.TIMEZONE) values.put("persist.sys.timezone", Profile.ZONE);
        try {
            Class<?> nativeApi = Class.forName("com.vlite.sdk.jni.Native");
            Method set = nativeApi.getMethod("addNativeProp", String.class, String.class);
            Method get = Class.forName("android.os.SystemProperties").getMethod("get", String.class, String.class);
            for (Map.Entry<String, String> entry : values.entrySet()) {
                originalProperties.put(entry.getKey(), (String) get.invoke(null, entry.getKey(), ""));
                set.invoke(null, entry.getKey(), entry.getValue());
            }
            return true;
        } catch (ReflectiveOperationException | LinkageError e) {
            Log.w(TAG, "native property policy unavailable");
            return false;
        }
    }

    /** Wraps, rather than replaces, VLite's original Binder dispatch. */
    public static Object invoke(OriginalCall original, Object proxy, Method method, Object[] args) throws Throwable {
        if (!inScope()) return original.cageOriginalInvoke(proxy, method, args);
        String owner = method.getDeclaringClass().getName();
        String name = method.getName();
        if (Profile.SIM && phoneInterface(owner) && phoneRead(name)) {
            return privatePhoneValue(method);
        }
        boolean network = Profile.VPN && owner.contains("IConnectivityManager");
        Object[] adjusted = network ? networkArguments(name, args) : args;
        Object result = original.cageOriginalInvoke(proxy, method, adjusted);
        return network ? sanitize(result) : result;
    }

    private static boolean phoneInterface(String owner) {
        return owner.endsWith(".ITelephony") || owner.endsWith(".IPhoneSubInfo")
            || owner.endsWith(".ISub") || owner.endsWith(".ITelephonyRegistry")
            || owner.endsWith(".IHwTelephony");
    }

    private static boolean phoneRead(String name) {
        return name.startsWith("get") || name.startsWith("is") || name.startsWith("has")
            || name.startsWith("listen") || name.startsWith("requestCellInfo")
            || name.startsWith("registerTelephony") || name.startsWith("addOnSubscriptionsChangedListener")
            || name.startsWith("addOnOpportunisticSubscriptionsChangedListener");
    }

    private static Object privatePhoneValue(Method method) {
        Class<?> type = method.getReturnType();
        String name = method.getName();
        if (type == String.class) return "";
        if (type == boolean.class || type == Boolean.class) return false;
        if (type == int.class || type == Integer.class) {
            if (name.contains("SimState") || name.contains("SimCardState")) return 1; // ABSENT
            if (name.contains("SubId") || name.contains("SubscriptionId") || name.contains("SlotIndex")
                || name.contains("SlotId") || name.contains("PhoneId")) return -1;
            return 0;
        }
        if (type == long.class || type == Long.class) return 0L;
        if (type == short.class || type == Short.class) return (short) 0;
        if (type == byte.class || type == Byte.class) return (byte) 0;
        if (type == float.class || type == Float.class) return 0f;
        if (type == double.class || type == Double.class) return 0d;
        if (type == char.class || type == Character.class) return (char) 0;
        if (type.isArray()) return Array.newInstance(type.getComponentType(), 0);
        if (List.class.isAssignableFrom(type)) return new ArrayList<>();
        return null;
    }

    private static synchronized Handler handler() {
        if (eventThread == null) {
            eventThread = new HandlerThread("Cage-privacy-events");
            eventThread.start();
        }
        return new Handler(eventThread.getLooper());
    }

    private static Object[] networkArguments(String name, Object[] args) {
        if (args == null) return null;
        Object[] copy = args.clone();
        for (int i = 0; i < copy.length; i++) {
            if (copy[i] instanceof Messenger) copy[i] = relay((Messenger) copy[i]);
        }
        return copy;
    }

    private static Messenger relay(final Messenger target) {
        Messenger old = relays.get(target.getBinder());
        if (old != null) return old;
        Messenger created = new Messenger(new Handler(handler().getLooper()) {
            @Override public void handleMessage(Message message) {
                Message copy = Message.obtain();
                copy.copyFrom(message);
                Bundle data = message.peekData();
                if (inScope()) {
                    if (data != null) copy.setData(sanitizeBundle(data));
                    copy.obj = sanitize(copy.obj);
                }
                try { target.send(copy); }
                catch (android.os.RemoteException e) { relays.remove(target.getBinder()); }
            }
        });
        Messenger raced = relays.putIfAbsent(target.getBinder(), created);
        return raced == null ? created : raced;
    }

    private static Bundle sanitizeBundle(Bundle source) {
        Bundle out = new Bundle(source);
        out.setClassLoader(NetworkCapabilities.class.getClassLoader());
        for (String key : source.keySet()) {
            Object original = source.get(key), changed = sanitize(original);
            if (changed == original) continue;
            if (changed instanceof Parcelable) out.putParcelable(key, (Parcelable) changed);
            else if (changed instanceof Parcelable[]) out.putParcelableArray(key, (Parcelable[]) changed);
        }
        return out;
    }

    private static Object sanitize(Object value) {
        if (value instanceof NetworkCapabilities) {
            NetworkCapabilities original = (NetworkCapabilities) value;
            NetworkCapabilities copy = new NetworkCapabilities(original);
            if (original.hasTransport(NetworkCapabilities.TRANSPORT_VPN)) {
                invokeRequired(copy, "removeTransportType", new Class<?>[]{int.class}, NetworkCapabilities.TRANSPORT_VPN);
                boolean underlying = copy.hasTransport(NetworkCapabilities.TRANSPORT_WIFI)
                    || copy.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR)
                    || copy.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET);
                if (!underlying) invokeRequired(copy, "addTransportType", new Class<?>[]{int.class}, NetworkCapabilities.TRANSPORT_ETHERNET);
                invokeRequired(copy, "addCapability", new Class<?>[]{int.class}, NetworkCapabilities.NET_CAPABILITY_NOT_VPN);
                invokeOptional(copy, "setUnderlyingNetworks", new Class<?>[]{List.class}, (Object) null);
            }
            return copy;
        }
        if (value instanceof LinkProperties) {
            LinkProperties original = (LinkProperties) value;
            Parcel parcel = Parcel.obtain();
            LinkProperties copy;
            try {
                original.writeToParcel(parcel, 0);
                parcel.setDataPosition(0);
                copy = LinkProperties.CREATOR.createFromParcel(parcel);
            } finally { parcel.recycle(); }
            if (vpnInterface(original.getInterfaceName())) {
                vpnInterfaces.add(original.getInterfaceName());
                NativePrivacy.observeInterface(original.getInterfaceName());
                invokeRequired(copy, "setInterfaceName", new Class<?>[]{String.class}, (Object) null);
            }
            return copy;
        }
        if (value instanceof NetworkInfo) {
            NetworkInfo original = (NetworkInfo) value;
            if (original.getType() != ConnectivityManager.TYPE_VPN) return value;
            try {
                NetworkInfo copy = NetworkInfo.class.getConstructor(int.class, int.class, String.class, String.class)
                    .newInstance(ConnectivityManager.TYPE_ETHERNET, 0, "ETHERNET", "");
                invokeRequired(copy, "setDetailedState", new Class<?>[]{NetworkInfo.DetailedState.class, String.class, String.class},
                    original.getDetailedState(), original.getReason(), original.getExtraInfo());
                invokeRequired(copy, "setIsAvailable", new Class<?>[]{boolean.class}, original.isAvailable());
                return copy;
            } catch (ReflectiveOperationException e) { throw new IllegalStateException("Network view is unavailable", e); }
        }
        if (value instanceof Bundle) return sanitizeBundle((Bundle) value);
        if (value instanceof Object[]) {
            Object[] input = (Object[]) value;
            Object[] out = (Object[]) Array.newInstance(value.getClass().getComponentType(), input.length);
            for (int i = 0; i < input.length; i++) out[i] = sanitize(input[i]);
            return out;
        }
        return value;
    }

    private static boolean vpnInterface(String name) {
        return name != null && (vpnInterfaces.contains(name) || name.matches("(?:tun|tap|ppp|wg|ipsec)[0-9]+"));
    }

    private static synchronized void installOsProxy() {
        if (!Profile.VPN || osInstalled) return;
        try {
            Class<?> libcore = Class.forName("libcore.io.Libcore");
            Field field = libcore.getDeclaredField("os");
            field.setAccessible(true);
            final Object original = field.get(null);
            Class<?> osInterface = Class.forName("libcore.io.Os");
            Object proxy = Proxy.newProxyInstance(GuestPrivacy.class.getClassLoader(), new Class<?>[]{osInterface},
                new InvocationHandler() {
                    @Override public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
                        String name = method.getName();
                        if (Profile.VPN && "if_nametoindex".equals(name) && inScope()
                            && args != null && args.length == 1 && vpnInterface(String.valueOf(args[0]))) return 0;
                        Object result;
                        try { result = method.invoke(original, args); }
                        catch (InvocationTargetException e) { throw e.getCause(); }
                        if (Profile.VPN && "getifaddrs".equals(name) && inScope()) return filterInterfaces(result);
                        return result;
                    }
                });
            field.set(null, proxy);
            osInstalled = true;
        } catch (ReflectiveOperationException | RuntimeException e) { Log.w(TAG, "interface query filter unavailable"); }
    }

    private static Object filterInterfaces(Object result) throws ReflectiveOperationException {
        if (result == null || !result.getClass().isArray()) return result;
        ArrayList<Object> kept = new ArrayList<>();
        for (int i = 0; i < Array.getLength(result); i++) {
            Object item = Array.get(result, i);
            Field name = item.getClass().getField("ifa_name");
            if (!vpnInterface((String) name.get(item))) kept.add(item);
        }
        Object out = Array.newInstance(result.getClass().getComponentType(), kept.size());
        for (int i = 0; i < kept.size(); i++) Array.set(out, i, kept.get(i));
        return out;
    }

    private static Object invokeRequired(Object target, String name, Class<?>[] types, Object... values) {
        try { return target.getClass().getMethod(name, types).invoke(target, values); }
        catch (ReflectiveOperationException e) { throw new IllegalStateException("Private network view unavailable", e); }
    }

    private static void invokeOptional(Object target, String name, Class<?>[] types, Object... values) {
        try { target.getClass().getMethod(name, types).invoke(target, values); }
        catch (ReflectiveOperationException ignored) { }
    }

    public static Bundle diagnostics() {
        Bundle out = new Bundle();
        out.putBoolean("active", active);
        out.putBoolean("sim", active && Profile.SIM);
        out.putBoolean("timezone", active && Profile.TIMEZONE);
        out.putBoolean("vpn", active && Profile.VPN);
        out.putBoolean("nativePropertiesApplied", nativePropertiesApplied);
        out.putBoolean("nativeReadPolicyRequested", nativeReadPolicyRequested);
        out.putString("nativeReadPolicy", NativePrivacy.diagnostics());
        out.putBundle("webViewTimezone", WebViewTimezone.diagnostics());
        out.putBoolean("osProxyInstalled", osInstalled);
        out.putString("zone", active && Profile.TIMEZONE ? Profile.ZONE : "unchanged");
        return out;
    }
}
