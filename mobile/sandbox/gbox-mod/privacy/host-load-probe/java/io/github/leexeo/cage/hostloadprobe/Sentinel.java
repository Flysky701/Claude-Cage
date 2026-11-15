package io.github.leexeo.cage.hostloadprobe;

/** Deliberately unavailable to the helper's boot-parent loader. */
public final class Sentinel {
    private static final int[] counts = new int[5];
    private static int seen;
    private Sentinel() {}

    public static synchronized boolean mark(int id) {
        if (id < 1 || id > 4) return false;
        counts[id]++;
        seen |= 1 << (id - 1);
        return true;
    }
    public static synchronized int seenMask() { return seen; }
    public static synchronized int count(int id) { return id >= 1 && id <= 4 ? counts[id] : -1; }
    public static void loadNested() { System.loadLibrary("cage_sentinel_leaf"); }
}
