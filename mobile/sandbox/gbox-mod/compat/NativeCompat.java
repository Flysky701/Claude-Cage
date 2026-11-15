package io.github.leexeo.cage.gbox;

import android.os.Build;
import android.os.Process;
import android.util.Log;

/** Scoped compatibility entry; no account, network or privacy policy changes. */
public final class NativeCompat {
    private static int state;
    private static boolean verified;

    private NativeCompat() {}

    static synchronized boolean isActive() {
        return state == 2 && verified;
    }

    /** 0: not finished, 1: original path, 2: verified compatibility, -1: failed. */
    public static synchronized int privacyPreparationState() {
        if (state == 3) return -1;
        if (state == 1) return 1;
        if (state == 2 && verified) return 2;
        return 0;
    }

    public static synchronized void beforeStart() {
        if (state == 3) throw new IllegalStateException("Native compatibility previously failed");
        if (state != 0) return;
        state = 1;
        int sdk = Build.VERSION.SDK_INT;
        if ((sdk != 31 && sdk != 32) || !Process.is64Bit()) return;
        try {
            System.loadLibrary("cage_compat");
        } catch (UnsatisfiedLinkError unavailable) {
            Log.i("CageNativeCompat", "library.unavailable.originalPath");
            return;
        }
        try {
            int result = nativeInstall(sdk);
            if (result < 0) throw new IllegalStateException("Native compatibility preparation failed");
            if (result == 1) state = 2;
        } catch (RuntimeException failure) {
            state = 3;
            throw failure;
        } catch (Error failure) {
            state = 3;
            throw failure;
        }
    }

    public static synchronized void afterStart() {
        if (state == 2) {
            if (!nativeVerify()) {
                state = 3;
                throw new IllegalStateException("Native compatibility verification failed");
            }
            verified = true;
        }
    }

    private static native int nativeInstall(int sdk);
    private static native boolean nativeVerify();
}
