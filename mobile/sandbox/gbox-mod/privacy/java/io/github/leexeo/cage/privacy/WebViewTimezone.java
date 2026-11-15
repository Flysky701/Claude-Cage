package io.github.leexeo.cage.privacy;

import android.app.Application;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.ContextWrapper;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.pm.PackageInfo;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.webkit.WebView;
import java.lang.reflect.Field;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.lang.reflect.Modifier;
import java.util.IdentityHashMap;
import java.util.Map;
import java.util.TimeZone;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * Configures Chromium's real timezone path; first-script coverage is provider-specific.
 * Google 156's isolated renderer receives the native monitor update asynchronously,
 * so installing before engine startup does not guarantee its first script sees the zone.
 * R8 mappings are restricted to the two exact APK versions documented alongside this module.
 * No global flag file, system broadcast, debugging endpoint, page script, or report is changed.
 */
public final class WebViewTimezone {
    public interface Scope { boolean isCurrentGuest(String packageName); }

    private static final String SWITCH = "time-zone-for-testing";
    private static final String PROVIDER = "com.android.webview";
    private static final String VERSION = "110.0.5481.154.1";
    private static final long VERSION_CODE = 548115537L;
    private static final String PHONE_PROVIDER = "com.google.android.webview";
    private static final String PHONE_VERSION = "156.0.8078.47";
    private static final long PHONE_VERSION_CODE = 807804703L;
    private static final int MUMU_110 = 1, PHONE_156 = 2;
    private static final String FACTORY = "com.android.webview.chromium.WebViewChromiumFactoryProvider";
    private static String status = "NOT_PREPARED";
    private static String stage = "none";
    private static String errorClass;
    private static String owner, zone;
    private static boolean attempted, providerTouched, initializedProvider, prepared, stopped;
    private static boolean previousPresent, switchMayHaveChanged, switchRestored;
    private static boolean engineWasNotStarted, nativeCommandLine, suffixWasConfigured;
    private static Object commandLine;
    private static Method hasSwitch, switchValue, appendSwitch, removeSwitch;
    private static String previousValue;
    private static String profileName = "none";
    private static MonitorContext monitorContext;
    private static final AtomicInteger monitorNotifications = new AtomicInteger();
    private static volatile String monitorError;

    private WebViewTimezone() {}

    /**
     * Call synchronously after publishing the guest's InitialApplication and before providers.
     * Earlier calls defer, and an already initialized foreign/unknown provider is not modified.
     * A true result is configuration evidence, not a replacement for first-script verification.
     */
    public static synchronized boolean prepare(Context guest, String packageName,
            String zoneId, Scope scope) {
        if (guest == null || scope == null || !selected(packageName)
                || !scope.isCurrentGuest(packageName)) return false;
        if (stopped) {
            status = "FRESH_PROCESS_REQUIRED";
            return false;
        }
        if (prepared) {
            if (!packageName.equals(owner) || !zone.equals(zoneId)) {
                status = "FRESH_PROCESS_REQUIRED";
                return false;
            }
            try {
                if (monitorContext != null) {
                    stage = "monitorContextRead";
                    boolean retained = monitorContext.isAttached() && monitorContext.active;
                    status = retained ? (monitorNotifications.get() == 0 ? "ARMED_BEFORE_ENGINE"
                        : "MONITOR_NOTIFIED_RUNTIME_UNVERIFIED") : "MONITOR_CONTEXT_CHANGED";
                    return retained;
                }
                stage = "commandLineRead";
                boolean retained = Boolean.TRUE.equals(hasSwitch.invoke(commandLine, SWITCH))
                    && zone.equals(switchValue.invoke(commandLine, SWITCH));
                status = retained ? "PREPARED_BEFORE_ENGINE" : "SWITCH_CHANGED_AFTER_PREPARE";
                return retained;
            } catch (ReflectiveOperationException | RuntimeException | LinkageError e) {
                errorClass = errorType(e);
                status = "COMMAND_LINE_READ_ERROR";
                return false;
            }
        }
        if (attempted) return false;
        if (Build.VERSION.SDK_INT != 31 && Build.VERSION.SDK_INT != 32
                && Build.VERSION.SDK_INT != 36) {
            status = "UNSUPPORTED_ANDROID_VERSION";
            return false;
        }
        if (!"Asia/Tokyo".equals(zoneId)) {
            status = "UNSUPPORTED_ZONE";
            return false;
        }
        if (Looper.myLooper() != Looper.getMainLooper()) {
            status = "DEFER_MAIN_THREAD";
            return false;
        }
        if (!zoneId.equals(TimeZone.getDefault().getID())) {
            status = "DEFER_JAVA_TIMEZONE";
            return false;
        }

        ClassLoader previousLoader = Thread.currentThread().getContextClassLoader();
        try {
            stage = "application";
            Application application = (Application) Class.forName("android.app.ActivityThread")
                .getDeclaredMethod("currentApplication").invoke(null);
            if (application == null || application.getApplicationInfo() == null
                    || !packageName.equals(application.getApplicationInfo().packageName)
                    || !packageName.equals(application.getPackageName())) {
                status = "DEFER_GUEST_APPLICATION";
                return false;
            }
            ClassLoader guestLoader = application.getClassLoader();
            if (guestLoader == null || guest.getClassLoader() != guestLoader) {
                status = "DEFER_GUEST_CLASS_LOADER";
                return false;
            }
            stage = "providerSelection";
            int profile = providerProfile(WebView.getCurrentWebViewPackage());
            if (profile == 0) {
                status = "UNSUPPORTED_WEBVIEW_PROVIDER";
                return false;
            }
            profileName = profile == MUMU_110 ? "mumu-110" : "android16-google-156";

            stage = "providerLock";
            Class<?> androidFactory = Class.forName("android.webkit.WebViewFactory");
            Object providerLock = field(androidFactory, "sProviderLock").get(null);
            if (providerLock == null) throw new IllegalStateException("Missing provider lock");
            synchronized (providerLock) {
                if (field(androidFactory, "sProviderInstance").get(null) != null) {
                    status = "EXISTING_PROVIDER_NOT_COVERED";
                    attempted = true;
                    return false;
                }
                Object suffix = field(androidFactory, "sDataDirectorySuffix").get(null);
                suffixWasConfigured = suffix instanceof String && !((String) suffix).isEmpty();
                if (!suffixWasConfigured) {
                    status = "DEFER_DATA_DIRECTORY_SUFFIX";
                    return false;
                }
                if (!scope.isCurrentGuest(packageName)) return false;

                attempted = true;
                owner = packageName;
                zone = zoneId;
                // WebViewDelegate reads the now-published guest Application. Use its loader
                // for any context-loader lookup during provider construction as well.
                Thread.currentThread().setContextClassLoader(guestLoader);
                Method getProvider = method(androidFactory, "getProvider");
                providerTouched = true;
                stage = "getProvider";
                Object provider = getProvider.invoke(null);
                initializedProvider = true;
                if (provider == null || field(androidFactory, "sProviderInstance").get(null) != provider)
                    throw new IllegalStateException("Provider identity changed");
                PackageInfo loaded = (PackageInfo) method(androidFactory, "getLoadedPackageInfo").invoke(null);
                if (providerProfile(loaded) != profile)
                    throw new IllegalStateException("Provider version changed");

                stage = "engineState";
                ClassLoader providerLoader = provider.getClass().getClassLoader();
                Class<?> factoryClass = Class.forName(FACTORY, false, providerLoader);
                if (!factoryClass.isInstance(provider)) throw new IllegalStateException("Unexpected provider");
                EngineState engine = engineState(provider, factoryClass, providerLoader, profile);
                synchronized (engine.lock) {
                    if (!engine.isIdle()) {
                        status = "ENGINE_ALREADY_STARTING_NOT_COVERED";
                        return false;
                    }
                    engineWasNotStarted = true;
                    if (profile == PHONE_156) {
                        stage = "monitorContext";
                        monitorContext = new MonitorContext(providerLoader, packageName, zoneId, scope);
                        monitorContext.attach();
                        if (!engine.isIdle() || !scope.isCurrentGuest(packageName)) {
                            monitorContext.deactivate();
                            status = "ENGINE_CHANGED_DURING_MONITOR_PREPARE";
                            return false;
                        }
                        prepared = true;
                        status = "ARMED_BEFORE_ENGINE";
                        return true;
                    }
                    stage = "commandLine";
                    bindCommandLine(providerLoader);
                    previousPresent = Boolean.TRUE.equals(hasSwitch.invoke(commandLine, SWITCH));
                    previousValue = (String) switchValue.invoke(commandLine, SWITCH);
                    if (!scope.isCurrentGuest(packageName)) {
                        status = "SCOPE_CHANGED_DURING_PREPARE";
                        return false;
                    }
                    switchMayHaveChanged = true;
                    stage = "append";
                    appendSwitch.invoke(commandLine, SWITCH, zoneId);
                    stage = "verify";
                    prepared = Boolean.TRUE.equals(hasSwitch.invoke(commandLine, SWITCH))
                        && zoneId.equals(switchValue.invoke(commandLine, SWITCH))
                        && engine.isIdle() && scope.isCurrentGuest(packageName);
                    if (!prepared) {
                        restoreSwitch();
                        status = "COMMAND_LINE_VERIFY_FAILED";
                        return false;
                    }
                    status = "PREPARED_BEFORE_ENGINE";
                    return true;
                }
            }
        } catch (ReflectiveOperationException | RuntimeException | LinkageError e) {
            errorClass = errorType(e);
            status = "PREPARE_ERROR";
            if (switchMayHaveChanged) {
                try { restoreSwitch(); }
                catch (ReflectiveOperationException | RuntimeException | LinkageError restoreError) {
                    status = "RESTORE_ERROR_FRESH_PROCESS_REQUIRED";
                    errorClass = errorType(restoreError);
                }
            }
            if (monitorContext != null) {
                try { monitorContext.deactivate(); }
                catch (ReflectiveOperationException | RuntimeException restoreError) {
                    status = "RESTORE_ERROR_FRESH_PROCESS_REQUIRED";
                    errorClass = errorType(restoreError);
                }
            }
            return false;
        } finally {
            Thread.currentThread().setContextClassLoader(previousLoader);
        }
    }

    /**
     * Restores the previous browser command line, then rejects reuse of this process.
     * Removing a startup flag cannot undo ICU/V8 state in already existing renderers;
     * the provider also retains the original guest Context even if no renderer was made.
     */
    public static synchronized void stopAndRestore() {
        if (!providerTouched && !switchMayHaveChanged) return;
        stopped = true;
        prepared = false;
        stage = "restore";
        try {
            if (switchMayHaveChanged) restoreSwitch();
            if (monitorContext != null) monitorContext.deactivate();
        } catch (ReflectiveOperationException | RuntimeException | LinkageError e) {
            status = "RESTORE_ERROR_FRESH_PROCESS_REQUIRED";
            errorClass = errorType(e);
            throw new IllegalStateException("Cannot restore scoped WebView command line; fresh process required", e);
        }
        status = "FRESH_PROCESS_REQUIRED";
        throw new IllegalStateException("Scoped WebView retains guest state; fresh process required before changing guest");
    }

    /** Also call before any VLite cached-application fast path, without clearing this state. */
    public static synchronized void assertProcessReusable(String packageName) {
        if (providerTouched && (stopped || owner == null || !owner.equals(packageName))) {
            stopped = true;
            status = "FRESH_PROCESS_REQUIRED";
            throw new IllegalStateException("Scoped WebView process cannot be rebound to another guest");
        }
    }

    public static synchronized boolean isBlocked() { return stopped; }

    private static void restoreSwitch() throws ReflectiveOperationException {
        removeSwitch.invoke(commandLine, SWITCH);
        if (previousPresent) appendSwitch.invoke(commandLine, SWITCH, previousValue);
        boolean present = Boolean.TRUE.equals(hasSwitch.invoke(commandLine, SWITCH));
        Object value = switchValue.invoke(commandLine, SWITCH);
        switchRestored = present == previousPresent && (!present
            || (previousValue == null ? value == null || "".equals(value) : previousValue.equals(value)));
        if (!switchRestored) throw new IllegalStateException("Command line restore did not match");
        switchMayHaveChanged = false;
    }

    public static synchronized Bundle diagnostics() {
        Bundle out = new Bundle();
        out.putString("status", "ARMED_BEFORE_ENGINE".equals(status) && monitorNotifications.get() > 0
            ? "MONITOR_NOTIFIED_RUNTIME_UNVERIFIED" : status);
        out.putString("stage", stage);
        out.putBoolean("preparedBeforeEngine", prepared);
        out.putBoolean("engineWasNotStarted", engineWasNotStarted);
        out.putBoolean("nativeCommandLine", nativeCommandLine);
        out.putBoolean("suffixWasConfigured", suffixWasConfigured);
        out.putBoolean("providerInitializedByHelper", initializedProvider);
        out.putBoolean("commandLineRestored", switchRestored);
        out.putBoolean("requiresFreshProcessOnGuestChange", providerTouched || stopped);
        out.putBoolean("firstScriptRuntimeVerified", false);
        out.putString("providerProfile", profileName);
        // The Android16 Java callback updates the browser monitor, not each renderer.
        // A notification count or a separate probe's reading must never certify a
        // subsequently created renderer belonging to the target application.
        if ("android16-google-156".equals(profileName)) {
            out.putBoolean("rendererInitialZoneGuaranteed", false);
            out.putBoolean("monitorNotificationAcknowledgedByRenderer", false);
            out.putString("firstScriptCoverage", "ISOLATED_RENDERER_STARTUP_UNCOVERED");
        }
        out.putInt("monitorNotifications", monitorNotifications.get());
        out.putString("strategy", monitorContext == null ? "native-command-line" : "native-monitor");
        out.putBoolean("monitorContextRestored", monitorContext != null && monitorContext.restored);
        if (monitorError != null) out.putString("monitorError", monitorError);
        if (errorClass != null) out.putString("errorClass", errorClass);
        return out;
    }

    private static boolean selected(String packageName) {
        return "com.anthropic.claude".equals(packageName)
            || "io.github.leexeo.cage.gboxprobe".equals(packageName);
    }

    private static int providerProfile(PackageInfo info) {
        if (info == null) return 0;
        if ((Build.VERSION.SDK_INT == 31 || Build.VERSION.SDK_INT == 32)
                && PROVIDER.equals(info.packageName) && VERSION.equals(info.versionName)
                && info.getLongVersionCode() == VERSION_CODE) return MUMU_110;
        if (Build.VERSION.SDK_INT == 36 && PHONE_PROVIDER.equals(info.packageName)
                && PHONE_VERSION.equals(info.versionName)
                && info.getLongVersionCode() == PHONE_VERSION_CODE) return PHONE_156;
        return 0;
    }

    private static EngineState engineState(Object provider, Class<?> factory, ClassLoader loader,
            int profile) throws ReflectiveOperationException {
        if (profile == MUMU_110) {
            // APK 548115537: factory.b is AwInit; M.m guards its integer state M.n.
            Class<?> type = Class.forName("com.android.webview.chromium.M", false, loader);
            Object init = typedField(factory, "b", type, false).get(provider);
            if (!type.isInstance(init)) throw new IllegalStateException("Unexpected init controller");
            return new EngineState(init, typedField(type, "m", Object.class, false).get(init),
                    typedField(type, "n", int.class, false));
        }
        // APK 807804703: shared statics and the startup singleton must reference the same
        // controller and factory delegate. Neither accessor below starts Chromium.
        Class<?> sharedType = Class.forName("com.android.webview.chromium.b", false, loader);
        Class<?> delegateType = Class.forName("com.android.webview.chromium.c", false, loader);
        Class<?> type = Class.forName("WV.yf2", false, loader);
        Class<?> taskType = Class.forName("WV.kg2", false, loader);
        Object shared = typedField(factory, "i", sharedType, false).get(provider);
        Object init = typedField(type, "m", type, true).get(null);
        Object delegate = typedField(factory, "a", delegateType, false).get(provider);
        if (!sharedType.isInstance(shared) || !type.isInstance(init)
                || !delegateType.isInstance(delegate)
                || typedField(sharedType, "b", type, false).get(shared) != init
                || typedField(type, "a", delegateType, false).get(init) != delegate)
            throw new IllegalStateException("Unexpected startup controller identity");
        return new EngineState(init, typedField(type, "d", Object.class, false).get(init),
                typedField(type, "c", AtomicInteger.class, false),
                typedField(type, "g", AtomicInteger.class, false),
                typedField(type, "l", taskType, false),
                typedField(type, "b", CountDownLatch.class, false),
                typedField(type, "j", RuntimeException.class, false),
                typedField(type, "k", Error.class, false));
    }

    private static final class EngineState {
        final Object controller, lock;
        final Field state, requested, task, latch, runtimeError, fatalError;
        EngineState(Object controller, Object lock, Field state, Field... modern) {
            if (lock == null || lock.getClass() != Object.class)
                throw new IllegalStateException("Unexpected engine lock");
            this.controller = controller;
            this.lock = lock;
            this.state = state;
            requested = modern.length == 0 ? null : modern[0];
            task = modern.length == 0 ? null : modern[1];
            latch = modern.length == 0 ? null : modern[2];
            runtimeError = modern.length == 0 ? null : modern[3];
            fatalError = modern.length == 0 ? null : modern[4];
        }
        boolean isIdle() throws IllegalAccessException {
            if (requested == null) return state.getInt(controller) == 0;
            Object current = state.get(controller), trigger = requested.get(controller);
            Object completion = latch.get(controller);
            // 156 has separate atomic request/completion states. Its d lock protects
            // UI-thread selection, not those atomics: inspect both before AND after the
            // write while on the main thread and still holding Android's provider lock.
            return current instanceof AtomicInteger && trigger instanceof AtomicInteger
                && completion instanceof CountDownLatch
                && ((AtomicInteger) current).get() == 0 && ((AtomicInteger) trigger).get() == 0
                && ((CountDownLatch) completion).getCount() == 1 && task.get(controller) == null
                && runtimeError.get(controller) == null && fatalError.get(controller) == null;
        }
    }

    private static void bindCommandLine(ClassLoader loader)
            throws ReflectiveOperationException {
        Class<?> type = Class.forName("ug", false, loader);
        commandLine = method(type, "e").invoke(null);
        nativeCommandLine = Class.forName("tg", false, loader).isInstance(commandLine);
        hasSwitch = instanceMethod(type, "h", boolean.class, String.class);
        switchValue = instanceMethod(type, "f", String.class, String.class);
        appendSwitch = instanceMethod(type, "b", void.class, String.class, String.class);
        removeSwitch = instanceMethod(type, "l", void.class, String.class);
        if (!nativeCommandLine) throw new IllegalStateException("Native command line not ready");
    }

    /**
     * 156 removed time-zone-for-testing. Its actual native monitor receives an explicit
     * zone through aq2.onReceive, so configure that monitor, not JavaScript return values.
     * Only ContextUtils' exact protected-receiver registration path is wrapped.
     */
    private static final class MonitorContext extends ContextWrapper {
        final Field contextField, receiverOwner, monitorReceiver, nativePointer;
        final Class<?> receiverType, monitorType;
        final String packageName, zoneId;
        final Scope scope;
        final Map<BroadcastReceiver, MonitorReceiver> receivers = new IdentityHashMap<>();
        volatile boolean active = true, restored;

        MonitorContext(ClassLoader loader, String packageName, String zoneId, Scope scope)
                throws ReflectiveOperationException {
            this(loader, packageName, zoneId, scope,
                typedField(Class.forName("WV.y10", false, loader), "a", Context.class, true));
        }
        private MonitorContext(ClassLoader loader, String packageName, String zoneId, Scope scope,
                Field contextField) throws ReflectiveOperationException {
            super((Context) contextField.get(null));
            this.contextField = contextField;
            this.packageName = packageName;
            this.zoneId = zoneId;
            this.scope = scope;
            Context base = getBaseContext();
            if (base == null || !packageName.equals(base.getPackageName())
                    || base.getApplicationInfo() == null
                    || !packageName.equals(base.getApplicationInfo().packageName))
                throw new IllegalStateException("Unexpected Chromium context owner");
            receiverType = Class.forName("WV.aq2", false, loader);
            monitorType = Class.forName("org.chromium.device.time_zone_monitor.TimeZoneMonitor",
                false, loader);
            if (receiverType.getSuperclass() != BroadcastReceiver.class)
                throw new IllegalStateException("Unexpected monitor receiver");
            receiverOwner = typedField(receiverType, "a", monitorType, false);
            monitorReceiver = typedField(monitorType, "a", receiverType, false);
            nativePointer = typedField(monitorType, "b", long.class, false);
            instanceMethod(receiverType, "onReceive", void.class, Context.class, Intent.class);
            instanceMethod(monitorType, "stop", void.class);
        }
        void attach() throws IllegalAccessException {
            if (contextField.get(null) != getBaseContext())
                throw new IllegalStateException("Chromium context changed");
            contextField.set(null, this);
            if (!isAttached()) throw new IllegalStateException("Chromium context write failed");
        }
        boolean isAttached() throws IllegalAccessException { return contextField.get(null) == this; }
        synchronized void deactivate() throws IllegalAccessException {
            active = false;
            restoreIfUnused();
        }
        private synchronized void restoreIfUnused() throws IllegalAccessException {
            // Keep unregisterReceiver's identity translation until Chromium unregisters
            // its final monitor. Native ICU/renderer state still requires a fresh process.
            if (!active && receivers.isEmpty() && isAttached()) {
                contextField.set(null, getBaseContext());
                restored = contextField.get(null) == getBaseContext();
                if (!restored) throw new IllegalStateException("Chromium context restore failed");
            }
        }
        @Override public Intent registerReceiver(BroadcastReceiver receiver, IntentFilter filter,
                String permission, Handler scheduler, int flags) {
            if (receiver == null || receiver.getClass() != receiverType)
                return super.registerReceiver(receiver, filter, permission, scheduler, flags);
            if (filter == null || filter.countActions() != 1
                    || !filter.hasAction(Intent.ACTION_TIMEZONE_CHANGED))
                throw new IllegalStateException("Unexpected monitor filter");
            final MonitorReceiver forward;
            try {
                Object monitor = receiverOwner.get(receiver);
                if (!monitorType.isInstance(monitor) || monitorReceiver.get(monitor) != receiver
                        || nativePointer.getLong(monitor) == 0)
                    throw new IllegalStateException("Unexpected native monitor identity");
                synchronized (this) {
                    if (receivers.containsKey(receiver))
                        throw new IllegalStateException("Duplicate monitor registration");
                    forward = new MonitorReceiver(receiver, monitor, nativePointer.getLong(monitor));
                    receivers.put(receiver, forward);
                }
            } catch (IllegalAccessException error) {
                throw new IllegalStateException("Cannot inspect native monitor", error);
            }
            final Intent sticky;
            try {
                sticky = super.registerReceiver(forward, filter, permission, scheduler, flags);
            } catch (RuntimeException | Error error) {
                synchronized (this) { receivers.remove(receiver); }
                throw error;
            }
            // C++ calls getInstance after its TimeZoneMonitor base constructor has set
            // timezone_ and constructed the empty client set. This same-thread callback
            // only updates that base state; it does not use the not-yet-assigned impl_.
            // Runtime first-script timing remains explicitly unverified in diagnostics.
            try {
                forward.deliver(this, new Intent(Intent.ACTION_TIMEZONE_CHANGED)
                    .putExtra(Intent.EXTRA_TIMEZONE, zoneId), true);
            } catch (RuntimeException | LinkageError error) {
                monitorError = errorType(error);
            }
            return sticky;
        }
        @Override public void unregisterReceiver(BroadcastReceiver receiver) {
            final MonitorReceiver forward;
            synchronized (this) { forward = receivers.get(receiver); }
            super.unregisterReceiver(forward == null ? receiver : forward);
            synchronized (this) { if (forward != null) receivers.remove(receiver); }
            try { restoreIfUnused(); }
            catch (IllegalAccessException error) { throw new IllegalStateException(error); }
        }
        private final class MonitorReceiver extends BroadcastReceiver {
            final BroadcastReceiver original;
            final Object monitor;
            final long pointer;
            boolean delivering;
            MonitorReceiver(BroadcastReceiver original, Object monitor, long pointer) {
                this.original = original;
                this.monitor = monitor;
                this.pointer = pointer;
            }
            @Override public void onReceive(Context context, Intent intent) {
                deliver(context, intent, false);
            }
            synchronized void deliver(Context context, Intent intent, boolean initial) {
                if (delivering) {
                    monitorError = "REENTRANT_MONITOR_CALLBACK";
                    return;
                }
                try {
                    if (nativePointer.getLong(monitor) != pointer
                            || monitorReceiver.get(monitor) != original) {
                        monitorError = "MONITOR_STOPPED_OR_CHANGED";
                        return;
                    }
                    boolean scoped = active && scope.isCurrentGuest(packageName) && isAttached();
                    if (initial && !scoped) return;
                    Intent forwarded = intent;
                    // Preserve invalid/unrelated intents and all metadata. Only the
                    // explicit zone in this monitor's valid timezone event is scoped.
                    if (scoped && intent != null && Intent.ACTION_TIMEZONE_CHANGED.equals(intent.getAction())
                            && intent.getStringExtra(Intent.EXTRA_TIMEZONE) != null)
                        forwarded = new Intent(intent).putExtra(Intent.EXTRA_TIMEZONE, zoneId);
                    delivering = true;
                    original.onReceive(context, forwarded);
                    if (scoped && forwarded != intent) monitorNotifications.incrementAndGet();
                } catch (IllegalAccessException error) {
                    monitorError = errorType(error);
                    throw new IllegalStateException("Native monitor identity read failed", error);
                } finally {
                    delivering = false;
                }
            }
        }
    }

    private static Field typedField(Class<?> type, String name, Class<?> valueType, boolean isStatic)
            throws ReflectiveOperationException {
        Field result = field(type, name);
        if (result.getType() != valueType || Modifier.isStatic(result.getModifiers()) != isStatic)
            throw new IllegalStateException("Unexpected field shape");
        return result;
    }

    private static Method instanceMethod(Class<?> type, String name, Class<?> returns,
            Class<?>... parameters) throws ReflectiveOperationException {
        Method result = method(type, name, parameters);
        if (result.getReturnType() != returns || Modifier.isStatic(result.getModifiers()))
            throw new IllegalStateException("Unexpected command line method shape");
        return result;
    }

    private static String errorType(Throwable error) {
        while (error instanceof InvocationTargetException && error.getCause() != null)
            error = error.getCause();
        return error.getClass().getSimpleName();
    }

    private static Field field(Class<?> type, String name) throws ReflectiveOperationException {
        Field result = type.getDeclaredField(name);
        result.setAccessible(true);
        return result;
    }

    private static Method method(Class<?> type, String name, Class<?>... parameters)
            throws ReflectiveOperationException {
        Method result = type.getDeclaredMethod(name, parameters);
        result.setAccessible(true);
        return result;
    }
}
