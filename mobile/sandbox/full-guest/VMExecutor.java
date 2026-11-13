package com.max2idea.android.limbo.jni;

/** JNI entry point exported by the upstream Limbo 6.0.1 runtime. Only private files are used. */
public final class VMExecutor {
    static { System.loadLibrary("limbo"); }
    public native String start(String storageDir, String baseDir, String library,
                               String libraryPath, int scaleHint, Object[] args);
    public int get_fd(String uri) { return -1; }
    public int close_fd(int fd) { return -1; }
    public static void onVMResolutionChanged(int width,int height) {}
}
