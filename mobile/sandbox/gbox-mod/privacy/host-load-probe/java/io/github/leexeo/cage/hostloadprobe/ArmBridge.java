package io.github.leexeo.cage.hostloadprobe;

public final class ArmBridge {
    private ArmBridge() {}
    public static native int health();
    public static native long[] state();
    public static native long[] details();
    public static native void afterNativeLoad(String filename);
}
