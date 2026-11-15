package io.github.leexeo.cage.shell;

import android.content.Context;
import android.content.Intent;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.security.MessageDigest;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

/** Exact API mapping for the retained 1.8.4.02 container. Never reinitializes its data. */
final class ContainerBridge {
    static final String PROBE = "io.github.leexeo.cage.gboxprobe";
    static final String CLAUDE = "com.anthropic.claude";
    final Context context;
    private final Class<?> contract;
    private final Object api;

    ContainerBridge(Context context) throws Exception {
        this.context = context.getApplicationContext();
        if (!"com.cage.android".equals(this.context.getPackageName())) throw new IllegalStateException("Host identity");
        contract = Class.forName("com.vlite.sdk.c");
        api = Class.forName("com.vlite.sdk.i").getMethod("r").invoke(null);
        if (!contract.isInstance(api)) throw new IllegalStateException("Container unavailable");
    }

    Object call(String method, Class<?>[] signature, Object... args) throws Exception {
        return contract.getMethod(method, signature).invoke(api, args);
    }
    boolean installed(String pkg) throws Exception {
        return Boolean.TRUE.equals(call("isPackageInstalled", new Class<?>[]{String.class}, pkg));
    }
    void launch(String pkg, String request) throws Exception {
        if (!installed(pkg)) throw new IllegalStateException("Application missing");
        Intent intent = (Intent) call("getLaunchIntentForPackage", new Class<?>[]{String.class}, pkg);
        if (intent == null || intent.getComponent() == null
                || !pkg.equals(intent.getComponent().getPackageName())) throw new IllegalStateException("Application identity");
        if (request != null) intent.putExtra("cage.preflight.request", request);
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        call("G", new Class<?>[]{Intent.class}, intent);
    }
    void stopProbe() throws Exception {
        // Only the owned diagnostic app is restarted. Claude/Google are not stopped.
        call("killApplication", new Class<?>[]{String.class}, PROBE);
    }
    File reportFile() throws Exception {
        File data = (File) Class.forName("com.vlite.sdk.context.j").getMethod("t", String.class).invoke(null, PROBE);
        String expected = new File(context.getApplicationInfo().dataDir, "_root/data/user/").getAbsolutePath() + "/";
        String path = data.getAbsolutePath();
        if (!path.startsWith(expected) || !path.endsWith("/" + PROBE) || path.contains("/../"))
            throw new IllegalStateException("Diagnostic directory");
        String user = path.substring(expected.length(), path.length() - PROBE.length() - 1);
        if (!user.matches("[0-9]+")) throw new IllegalStateException("Diagnostic user");
        return new File(data, "files/cage-preflight-result.json");
    }
    void ensureProbe() throws Exception {
        String recorded = context.getSharedPreferences("cage-android-ui", 0).getString("probeAsset", "");
        if (BuildInfo.PROBE_SHA.equals(recorded) && installed(PROBE)) return;
        File dir = new File(context.getCodeCacheDir(), "cage-preflight");
        if (!dir.isDirectory() && !dir.mkdirs()) throw new java.io.IOException("Diagnostic cache");
        File apk = new File(dir, "probe-" + BuildInfo.PROBE_SHA + ".apk");
        try (InputStream in = context.getAssets().open("cage-android/preflight.apk");
             FileOutputStream out = new FileOutputStream(apk)) {
            byte[] bytes = new byte[8192];
            for (int n; (n = in.read(bytes)) >= 0;) out.write(bytes, 0, n);
            out.getFD().sync();
        }
        if (!BuildInfo.PROBE_SHA.equals(sha(apk))) throw new IllegalStateException("Diagnostic digest");
        PackageInfo info = context.getPackageManager().getPackageArchiveInfo(apk.getPath(), 0);
        if (info == null || !PROBE.equals(info.packageName) || info.versionCode != 6)
            throw new IllegalStateException("Diagnostic package");
        // Existing diagnostic package is updated, never uninstalled or cleared.
        Class<?> config = Class.forName("com.vlite.sdk.model.InstallConfig");
        Object result = call("y", new Class<?>[]{String.class, config}, apk.getPath(), null);
        if (result == null || !Boolean.TRUE.equals(result.getClass().getMethod("g").invoke(result)) || !installed(PROBE))
            throw new IllegalStateException("Diagnostic update failed");
        context.getSharedPreferences("cage-android-ui", 0).edit().putString("probeAsset", BuildInfo.PROBE_SHA).apply();
    }
    static String sha(File file) throws Exception {
        MessageDigest digest = MessageDigest.getInstance("SHA-256");
        try (InputStream in = new FileInputStream(file)) {
            byte[] bytes = new byte[8192];
            for (int n; (n = in.read(bytes)) >= 0;) digest.update(bytes, 0, n);
        }
        StringBuilder hex = new StringBuilder();
        for (byte value : digest.digest()) hex.append(String.format(java.util.Locale.ROOT, "%02x", value & 255));
        return hex.toString();
    }
    static final class App {
        final String pkg, label;
        final ApplicationInfo info;
        App(String pkg, String label, ApplicationInfo info) { this.pkg = pkg; this.label = label; this.info = info; }
    }
    List<App> applications() throws Exception {
        List<?> values = (List<?>) call("getInstalledPackages", new Class<?>[]{int.class}, 0);
        List<App> result = new ArrayList<>();
        if (values == null) throw new IllegalStateException("Application list unavailable");
        for (Object value : values) {
            if (!(value instanceof PackageInfo)) continue;
            PackageInfo p = (PackageInfo) value;
            if (p.packageName == null || PROBE.equals(p.packageName)
                    || p.packageName.startsWith("com.google.") || p.packageName.equals("com.android.vending")) continue;
            Intent launch = (Intent) call("getLaunchIntentForPackage", new Class<?>[]{String.class}, p.packageName);
            if (launch == null) continue;
            String label = p.packageName;
            if (CLAUDE.equals(p.packageName)) label = "Claude";
            else if (p.applicationInfo != null) {
                try { label = p.applicationInfo.loadLabel(context.getPackageManager()).toString(); }
                catch (RuntimeException ignored) { }
            }
            result.add(new App(p.packageName, label, p.applicationInfo));
        }
        Collections.sort(result, (a, b) -> CLAUDE.equals(a.pkg) ? -1 : CLAUDE.equals(b.pkg) ? 1 : a.label.compareToIgnoreCase(b.label));
        return result;
    }
}
