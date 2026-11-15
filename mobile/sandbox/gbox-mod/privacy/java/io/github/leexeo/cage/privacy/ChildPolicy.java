package io.github.leexeo.cage.privacy;

import android.content.Context;
import android.os.Build;
import android.os.Process;
import android.system.Os;
import android.util.Log;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.lang.reflect.Method;
import java.security.MessageDigest;
import java.util.LinkedHashMap;
import java.util.Map;

/** Reversible environment for children of one selected, guarded guest process. */
final class ChildPolicy {
    // mumu/child-property-probe01-result.json: PASS. GBox integration still
    // needs its own runtime check; this does not expand the ABI/profile guard.
    private static final boolean CHILD_PROBE_VALIDATED = true;
    private static final String TAG = "CageChildPolicy";
    private static final String ASSET = "cage-child/x86_64/libcage_child_properties.so";
    private static final String[] KEYS = {"LD_PRELOAD", "CAGE_CHILD_SCOPE", "CAGE_CHILD_POLICY",
        "CAGE_CHILD_SIM", "CAGE_CHILD_TIMEZONE", "CAGE_CHILD_ZONE", "CAGE_CHILD_DIAGNOSTIC"};
    private static final Map<String, String> saved = new LinkedHashMap<>();
    private static boolean active;

    private ChildPolicy() {}

    static synchronized void activate(Context guest, boolean sim, boolean timezone, String zone) {
        deactivate();
        if (!CHILD_PROBE_VALIDATED) {
            Log.i(TAG, "probe.pending.environmentUnchanged");
            return;
        }
        boolean hasContext = guest != null, hasModules = sim || timezone, supportedZone = "Asia/Tokyo".equals(zone);
        Log.i(TAG, "guard.inputs context=" + hasContext + " modules=" + hasModules + " zone=" + supportedZone);
        if (!hasContext || !hasModules || !supportedZone) return;
        String stage = "guard";
        try {
            if (!guarded()) return;
            String pkg = guest.getPackageName();
            Object client = Class.forName("com.vlite.sdk.client.k").getMethod("getInst").invoke(null);
            String current = (String) client.getClass().getMethod("getVirtualClientPkgName").invoke(client);
            boolean selected = GuestPrivacy.selected(pkg), currentMatches = pkg != null && pkg.equals(current);
            boolean infoMatches = pkg != null && pkg.equals(guest.getApplicationInfo().packageName);
            Log.i(TAG, "guard.identity selected=" + selected + " current=" + currentMatches + " info=" + infoMatches);
            if (!selected || !currentMatches || !infoMatches)
                throw new IllegalStateException("Selected guest identity unavailable");
            stage = "hostAsset";
            // context.i.s stores the original host Context during VLite init;
            // c returns that same field without a PackageManager lookup.
            Context host = (Context) Class.forName("com.vlite.sdk.context.i").getMethod("c").invoke(null);
            boolean hostMatches = host != null && "com.cage.android".equals(host.getApplicationInfo().packageName);
            Log.i(TAG, "guard.host matches=" + hostMatches);
            if (!hostMatches)
                throw new IllegalStateException("Host identity unavailable");
            File library = extract(host);
            stage = "environment";
            for (String key : KEYS) saved.put(key, Os.getenv(key));
            String original = saved.get("LD_PRELOAD");
            String preload = library.getAbsolutePath() + (original == null || original.isEmpty() ? "" : " " + original);
            Os.setenv("CAGE_CHILD_SCOPE", pkg, true);
            Os.setenv("CAGE_CHILD_SIM", sim ? "1" : "0", true);
            Os.setenv("CAGE_CHILD_TIMEZONE", timezone ? "1" : "0", true);
            Os.setenv("CAGE_CHILD_ZONE", zone, true);
            Os.setenv("CAGE_CHILD_DIAGNOSTIC", "0", true);
            Os.setenv("CAGE_CHILD_POLICY", "1", true);
            Os.setenv("LD_PRELOAD", preload, true);
            active = true;
            Log.i(TAG, "environment.active x86_64Only=true originalPreloadPreserved=true");
        } catch (Exception | LinkageError failure) {
            deactivate();
            Log.w(TAG, "activation.unavailable stage=" + stage + " exception=" + failure.getClass().getSimpleName());
        }
    }

    private static boolean guarded() throws Exception {
        boolean sdk = Build.VERSION.SDK_INT == 31 || Build.VERSION.SDK_INT == 32;
        boolean is64 = Process.is64Bit();
        // VLite device/a writes these Java cache fields for the guest. They
        // are diagnostic observations, not an independent host profile gate.
        boolean fingerprint = "OPPO/pangu/pangu:12/V417IR/2721:user/release-keys".equals(Build.FINGERPRINT);
        boolean hardware = "OPPO".equals(Build.HARDWARE), board = "PHY110".equals(Build.BOARD);
        Method active = Class.forName("io.github.leexeo.cage.gbox.NativeCompat").getDeclaredMethod("isActive");
        active.setAccessible(true);
        // gate.cpp runtime_matches checks the real fingerprint/hardware/board,
        // libnb, SDK and mapped bridge/host ART. isActive requires its completed
        // native verification. The x86 child library independently repeats the
        // exact real-property profile when it is loaded in each child.
        boolean verified = Boolean.TRUE.equals(active.invoke(null));
        Log.i(TAG, "guard.runtime sdk=" + sdk + " process64=" + is64 + " nativeProfileVerified=" + verified
            + " javaFingerprintMatch=" + fingerprint + " javaHardwareMatch=" + hardware + " javaBoardMatch=" + board);
        return sdk && is64 && verified;
    }

    static synchronized void deactivate() {
        if (saved.isEmpty()) { active = false; return; }
        Exception failure = null;
        for (Map.Entry<String, String> entry : saved.entrySet()) {
            try {
                if (entry.getValue() == null) Os.unsetenv(entry.getKey());
                else Os.setenv(entry.getKey(), entry.getValue(), true);
            } catch (Exception problem) { if (failure == null) failure = problem; }
        }
        active = false;
        if (failure != null) throw new IllegalStateException("Cannot restore child policy environment", failure);
        saved.clear();
        Log.i(TAG, "environment.restored");
    }

    static synchronized boolean isActive() { return active; }

    private static String digest(byte[] data) throws Exception {
        StringBuilder result = new StringBuilder();
        for (byte value : MessageDigest.getInstance("SHA-256").digest(data))
            result.append(String.format(java.util.Locale.ROOT, "%02x", value & 255));
        return result.toString();
    }

    private static byte[] bytes(InputStream input) throws Exception {
        try (InputStream in = input; ByteArrayOutputStream out = new ByteArrayOutputStream()) {
            byte[] block = new byte[8192];
            for (int count; (count = in.read(block)) >= 0;) {
                if (out.size() + count > 2 * 1024 * 1024) throw new IllegalStateException("Unexpected child library size");
                out.write(block, 0, count);
            }
            return out.toByteArray();
        }
    }

    private static File extract(Context host) throws Exception {
        byte[] data = bytes(host.getAssets().open(ASSET));
        if (data.length < 64 || data[0] != 127 || data[1] != 'E' || data[2] != 'L' || data[3] != 'F'
                || data[4] != 2 || data[5] != 1 || data[18] != 62 || data[19] != 0)
            throw new IllegalStateException("Unexpected child library ABI");
        File root = host.getCodeCacheDir().getCanonicalFile();
        File directory = new File(root, "cage-child/x86_64").getCanonicalFile();
        if (!directory.getPath().startsWith(root.getPath() + "/")) throw new IllegalStateException("Child library root mismatch");
        if (!directory.isDirectory() && !directory.mkdirs()) throw new java.io.IOException("Child library directory unavailable");
        String expected = digest(data);
        File target = new File(directory, "libcage_child_" + expected + ".so");
        if (target.isFile() && expected.equals(digest(bytes(new FileInputStream(target))))) return target;
        File pending = File.createTempFile("policy-", ".tmp", directory);
        try {
            try (FileOutputStream out = new FileOutputStream(pending)) { out.write(data); out.getFD().sync(); }
            if (!pending.setReadable(true, true) || !pending.setReadOnly()) throw new java.io.IOException("Child library mode unavailable");
            if (!pending.renameTo(target)) throw new java.io.IOException("Child library publication unavailable");
        } finally { if (pending.exists()) pending.delete(); }
        return target;
    }
}
