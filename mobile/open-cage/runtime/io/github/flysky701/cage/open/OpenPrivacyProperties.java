package io.github.flysky701.cage.open;

/** Process-local SIM/timezone reads for selected guests, never system properties. */
public final class OpenPrivacyProperties {
    private OpenPrivacyProperties() {}
    public static synchronized boolean activate(boolean sim, boolean timezone) {
        String pkg = top.niunaijun.blackbox.app.BActivityThread.getAppPackageName();
        if (android.os.Build.VERSION.SDK_INT != 36 || !android.os.Process.is64Bit()
                || !io.github.leexeo.cage.privacy.GuestPrivacy.selected(pkg)) return false;
        System.loadLibrary("blackbox");
        return nativeSetPolicy((sim ? 1 : 0) | (timezone ? 2 : 0));
    }
    public static synchronized void deactivate() { nativeSetPolicy(0); }
    private static native boolean nativeSetPolicy(int flags);
}
