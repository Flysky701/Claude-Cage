package io.github.leexeo.cage.privacy;

import android.app.Application;
import android.content.Context;
import android.content.pm.PackageInfo;
import android.os.Build;
import android.os.Bundle;
import android.os.Looper;
import android.webkit.WebView;
import java.lang.reflect.Field;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.util.TimeZone;

/**
 * Configures Chromium's real renderer ICU before its first script can execute.
 * The R8 names below were checked against MuMu's exact 110.0.5481.154.1 provider.
 * No global flag file, broadcast, debugging endpoint, page script, or report is changed.
 */
public final class WebViewTimezone {
    public interface Scope { boolean isCurrentGuest(String packageName); }

    private static final String SWITCH = "time-zone-for-testing";
    private static final String PROVIDER = "com.android.webview";
    private static final String VERSION = "110.0.5481.154.1";
    private static final long VERSION_CODE = 548115537L;
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
        if (Build.VERSION.SDK_INT < 31 || Build.VERSION.SDK_INT > 32) {
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
            if (!matchesProvider(WebView.getCurrentWebViewPackage())) {
                status = "UNSUPPORTED_WEBVIEW_PROVIDER";
                return false;
            }

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
                if (!matchesProvider(loaded)) throw new IllegalStateException("Provider version changed");

                stage = "engineState";
                ClassLoader providerLoader = provider.getClass().getClassLoader();
                Class<?> factoryClass = Class.forName(FACTORY, false, providerLoader);
                if (!factoryClass.isInstance(provider)) throw new IllegalStateException("Unexpected provider");
                // Actual APK: factory.b is WebViewChromiumAwInit (R8 M); M.m guards M.n.
                Object init = field(factoryClass, "b").get(provider);
                Class<?> initClass = Class.forName("com.android.webview.chromium.M", false, providerLoader);
                if (!initClass.isInstance(init)) throw new IllegalStateException("Unexpected init controller");
                Object engineLock = field(initClass, "m").get(init);
                Field state = field(initClass, "n");
                if (engineLock == null || state.getType() != int.class)
                    throw new IllegalStateException("Unexpected engine state");
                synchronized (engineLock) {
                    if (state.getInt(init) != 0) {
                        status = "ENGINE_ALREADY_STARTING_NOT_COVERED";
                        return false;
                    }
                    engineWasNotStarted = true;
                    stage = "commandLine";
                    Class<?> commandClass = Class.forName("ug", false, providerLoader);
                    commandLine = method(commandClass, "e").invoke(null);
                    Class<?> nativeClass = Class.forName("tg", false, providerLoader);
                    nativeCommandLine = nativeClass.isInstance(commandLine);
                    if (!nativeCommandLine) throw new IllegalStateException("Native command line not ready");
                    hasSwitch = method(commandClass, "h", String.class);
                    switchValue = method(commandClass, "f", String.class);
                    appendSwitch = method(commandClass, "b", String.class, String.class);
                    removeSwitch = method(commandClass, "l", String.class);
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
                        && state.getInt(init) == 0 && scope.isCurrentGuest(packageName);
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
        out.putString("status", status);
        out.putString("stage", stage);
        out.putBoolean("preparedBeforeEngine", prepared);
        out.putBoolean("engineWasNotStarted", engineWasNotStarted);
        out.putBoolean("nativeCommandLine", nativeCommandLine);
        out.putBoolean("suffixWasConfigured", suffixWasConfigured);
        out.putBoolean("providerInitializedByHelper", initializedProvider);
        out.putBoolean("commandLineRestored", switchRestored);
        out.putBoolean("requiresFreshProcessOnGuestChange", providerTouched || stopped);
        out.putBoolean("firstScriptRuntimeVerified", false);
        if (errorClass != null) out.putString("errorClass", errorClass);
        return out;
    }

    private static boolean selected(String packageName) {
        return "com.anthropic.claude".equals(packageName)
            || "io.github.leexeo.cage.gboxprobe".equals(packageName);
    }

    private static boolean matchesProvider(PackageInfo info) {
        return info != null && PROVIDER.equals(info.packageName) && VERSION.equals(info.versionName)
            && info.getLongVersionCode() == VERSION_CODE;
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
