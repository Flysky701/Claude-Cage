package io.github.leexeo.cage.shell;

public final class CheckPolicyTest {
    private static int count;
    private static void check(boolean value) { ++count; if (!value) throw new AssertionError("case " + count); }
    public static void main(String[] args) {
        check(CheckPolicy.mask(true, true, false) == CheckPolicy.State.PASSED);
        check(CheckPolicy.mask(true, false, false) == CheckPolicy.State.UNKNOWN);
        check(CheckPolicy.mask(false, true, false) == CheckPolicy.State.UNKNOWN);
        check(CheckPolicy.mask(false, false, true) == CheckPolicy.State.FAILED);
        check(CheckPolicy.timezone(true, false) == CheckPolicy.State.FAILED);
        check(CheckPolicy.timezone(false, true) == CheckPolicy.State.UNKNOWN);
        check(CheckPolicy.networkMetadata(true, true, true) == CheckPolicy.State.PASSED);
        check(CheckPolicy.networkMetadata(false, true, true) == CheckPolicy.State.UNKNOWN);
        check(CheckPolicy.networkMetadata(true, false, true) == CheckPolicy.State.UNKNOWN);
        check(CheckPolicy.networkMetadata(true, true, false) == CheckPolicy.State.FAILED);
        check(CheckPolicy.failClosedConfiguration(true, false) == CheckPolicy.State.FAILED);
        check(CheckPolicy.failClosedConfiguration(true, true) == CheckPolicy.State.UNKNOWN);
        check(CheckPolicy.failClosedConfiguration(false, false) == CheckPolicy.State.UNKNOWN);
        check(CheckPolicy.fresh("new", "new", 100, 101, true, 200));
        check(!CheckPolicy.fresh("new", "old", 100, 101, true, 200));
        check(!CheckPolicy.fresh("new", "new", 100, 99, true, 200));
        check(!CheckPolicy.fresh("new", "new", 100, 101, false, 200));
        check(!CheckPolicy.fresh("new", "new", 100, 201, true, 200));
        check(!CheckPolicy.fresh("new", "new", 100, 101, true, 60101));
        check(CheckPolicy.admitted("a", "a", "f", "f", 100, 101));
        check(!CheckPolicy.admitted(null, "a", "f", "f", 100, 101));
        check(!CheckPolicy.admitted("old", "new", "f", "f", 100, 101));
        check(!CheckPolicy.admitted("a", "a", "oldNetwork", "newNetwork", 100, 101));
        check(!CheckPolicy.admitted("a", "a", "f", "f", 100, 99));
        check(!CheckPolicy.admitted("a", "a", "f", "f", 100, 300100));
        check(CheckPolicy.selected("com.anthropic.claude"));
        check(!CheckPolicy.selected("com.google.android.gms"));
        check(!CheckPolicy.selected("another.app"));
        System.out.println(count + " decision and consent cases passed");
    }
}
