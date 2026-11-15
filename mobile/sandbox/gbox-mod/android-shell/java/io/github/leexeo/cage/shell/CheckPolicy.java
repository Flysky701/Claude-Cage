package io.github.leexeo.cage.shell;

/** Pure decision rules: no missing evidence becomes a pass; test consent is not evidence. */
public final class CheckPolicy {
    public enum State { PASSED, FAILED, UNKNOWN }
    public static final long LIFETIME_MS = 5 * 60 * 1000;
    public static final String ZONE = "Asia/Tokyo";

    private CheckPolicy() {}
    public static State mask(boolean complete, boolean outerPositive, boolean guestSignal) {
        if (guestSignal) return State.FAILED;
        if (!complete || !outerPositive) return State.UNKNOWN;
        return State.PASSED;
    }
    public static State timezone(boolean complete, boolean matches) {
        return !complete ? State.UNKNOWN : matches ? State.PASSED : State.FAILED;
    }
    public static State networkMetadata(boolean complete, boolean positiveControl, boolean emptyView) {
        if (!complete || !positiveControl) return State.UNKNOWN;
        return emptyView ? State.PASSED : State.FAILED;
    }
    public static State failClosedConfiguration(boolean readable, boolean configured) {
        // Even enabled settings do not establish actual routing enforcement.
        return readable && !configured ? State.FAILED : State.UNKNOWN;
    }
    public static boolean fresh(String expectedRequest, String reportRequest, long startedElapsed,
            long reportStartElapsed, boolean complete, long elapsedNow) {
        return expectedRequest != null && expectedRequest.equals(reportRequest) && complete
            && startedElapsed > 0 && reportStartElapsed >= startedElapsed
            && reportStartElapsed <= elapsedNow && elapsedNow - startedElapsed < 60000;
    }
    public static boolean admitted(String approvedRequest, String latestRequest, String approvedFingerprint,
            String currentFingerprint, long approvedAt, long now) {
        return approvedRequest != null && approvedRequest.equals(latestRequest)
            && approvedFingerprint != null && approvedFingerprint.equals(currentFingerprint)
            && approvedAt > 0 && now >= approvedAt && now - approvedAt < LIFETIME_MS;
    }
    public static boolean selected(String packageName) {
        return "com.anthropic.claude".equals(packageName)
            || "io.github.leexeo.cage.gboxprobe".equals(packageName);
    }
}
