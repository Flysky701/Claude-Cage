package io.github.leexeo.cage.hostloadprobe.host;

/** This class is packaged only in the independent boot-parent helper DEX. */
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
