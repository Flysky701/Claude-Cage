package io.github.flysky701.cage.open;

/** Do not silently bind a guest's Google service request to the personal profile. */
public final class GuestServicePolicy {
    private GuestServicePolicy() {}
    public static boolean privateOnly(String explicitPackage, String action) {
        if (explicitPackage != null) return explicitPackage.equals("com.google.android.gms")
                || explicitPackage.equals("com.google.android.gsf")
                || explicitPackage.equals("com.android.vending")
                || explicitPackage.equals("com.android.vending.mgc");
        return action != null && (action.startsWith("com.google.android.gms.")
                || action.startsWith("com.google.android.finsky.")
                || action.startsWith("com.android.vending."));
    }
}
