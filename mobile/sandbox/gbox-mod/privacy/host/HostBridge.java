package io.github.leexeo.cage.privacy.host;

/** Compiled into an asset DEX with only the bootstrap loader as its parent. */
public final class HostBridge {
    private static boolean opened;
    private HostBridge() {}

    public static synchronized String open(String absoluteLibrary) {
        if (opened) return "STOP host.open.duplicate";
        System.load(absoluteLibrary);
        String result = profile();
        opened = result != null && result.startsWith("PASS ");
        return result;
    }

    private static native String profile();
    public static native String install(Class<?> callbackClass, String nonexistentPrivatePath);
    public static native long[] diagnostics();
}
