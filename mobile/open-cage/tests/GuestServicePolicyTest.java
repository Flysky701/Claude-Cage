import io.github.flysky701.cage.open.GuestServicePolicy;

public final class GuestServicePolicyTest {
    public static void main(String[] args) {
        check(true, "com.google.android.gms", null);
        check(true, "com.android.vending", "android.intent.action.BIND");
        check(true, "com.android.vending.mgc", null);
        check(true, null, "com.google.android.gms.auth.api.signin.service.START");
        check(true, null, "com.google.android.finsky.BIND_INTEGRITY_SERVICE");
        check(false, null, null);
        check(false, "com.example.app", "com.google.android.gms.custom");
        check(false, "com.google.android.gms.evil", null);
        check(false, null, "com.google.android.gmsfake.START");
        check(false, null, "android.service.notification.NotificationListenerService");
        System.out.println("10 Google service routing cases passed");
    }
    private static void check(boolean expected, String pkg, String action) {
        if (GuestServicePolicy.privateOnly(pkg, action) != expected)
            throw new AssertionError("Unexpected routing: " + pkg + " / " + action);
    }
}
