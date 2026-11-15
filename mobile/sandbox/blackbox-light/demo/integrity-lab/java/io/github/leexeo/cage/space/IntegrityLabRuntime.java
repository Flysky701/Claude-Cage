package io.github.leexeo.cage.space;

import android.app.Activity;
import android.content.ComponentName;
import android.content.ContentProvider;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.content.pm.ResolveInfo;
import android.content.pm.Signature;
import android.net.Uri;
import android.os.Binder;
import android.os.Bundle;
import android.util.Log;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.TextView;
import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.security.MessageDigest;

/** Integration for the separately installed, empty-data MGC laboratory only. */
public final class IntegrityLabRuntime {
    static final String LAB = "top.niunaijun.mgclab00";
    static final String STORE = "com.android.vending";
    static final String MGC = "com.android.vending.mgc";
    static final String GMS = "com.google.android.gms";
    static final String PROBE = "io.github.leexeo.cage.integrityprobe";
    static final String CLASSIC = "com.google.android.play.core.integrityservice.BIND_INTEGRITY_SERVICE";
    static final String STANDARD = "com.google.android.play.core.expressintegrityservice.BIND_EXPRESS_INTEGRITY_SERVICE";
    static final String CLASSIC_CLASS = "com.google.android.finsky.integrityservice.IntegrityService";
    static final String STANDARD_CLASS = "com.google.android.finsky.expressintegrityservice.ExpressIntegrityService";
    private static final String CUSTOM_CERT = "bfb3464ed3343b8ce5825b8d3606a3a7fc64a7433ff6eb7fccff6aacfa971335";
    private static final String GOOGLE_CERT = "f0fd6c5b410f25cb25c3b53346c8972fae30f8ee7411df910480ad6b2d60db83";
    private static final String[] PACKAGES = {GMS, STORE, MGC, PROBE};
    private static final String[] FILES = {"MG-250952077.apk", "gpstore400013.apk", "MGC.apk", "integrity-probe.apk"};
    private static final long[] VERSIONS = {250952077L, 84001300L, 84024869L, 1L};

    static Context host() throws Exception {
        return (Context) Class.forName("top.niunaijun.blackbox.BlackBoxCore")
            .getMethod("getContext").invoke(null);
    }

    static Object core() throws Exception {
        return Class.forName("top.niunaijun.blackbox.BlackBoxCore").getMethod("get").invoke(null);
    }

    static Object packages() throws Exception {
        Object manager = Class.forName("top.niunaijun.blackbox.BlackBoxCore")
            .getMethod("getBPackageManager").invoke(null);
        Object service = manager.getClass().getMethod("getService").invoke(manager);
        if (service == null) throw new IllegalStateException("Private package service unavailable");
        return service;
    }

    static Object packageCall(String method, Class<?>[] types, Object... args) throws Exception {
        return Class.forName("top.niunaijun.blackbox.core.system.pm.IBPackageManagerService")
            .getMethod(method, types).invoke(packages(), args);
    }

    static PackageInfo installed(String pkg) throws Exception {
        return (PackageInfo) packageCall("getPackageInfo", new Class<?>[]{String.class, int.class, int.class},
            pkg, PackageManager.GET_SIGNING_CERTIFICATES, 0);
    }

    static String signer(PackageInfo info) throws Exception {
        if (info == null || info.signingInfo == null) return "";
        Signature[] signs = info.signingInfo.getApkContentsSigners();
        if (signs == null || signs.length != 1) return "";
        StringBuilder hex = new StringBuilder();
        for (byte b : MessageDigest.getInstance("SHA-256").digest(signs[0].toByteArray()))
            hex.append(Character.forDigit((b >> 4) & 15, 16)).append(Character.forDigit(b & 15, 16));
        return hex.toString();
    }

    static int index(String pkg) {
        for (int i = 0; i < PACKAGES.length; i++) if (PACKAGES[i].equals(pkg)) return i;
        return -1;
    }

    static void checkArchive(Context context, File file, String pkg) throws Exception {
        int i = index(pkg);
        if (!LAB.equals(context.getPackageName()) || i < 0) throw new SecurityException("Not a lab component");
        PackageInfo info = context.getPackageManager().getPackageArchiveInfo(file.getPath(),
            PackageManager.GET_SIGNING_CERTIFICATES);
        String expected = i == 1 ? GOOGLE_CERT : CUSTOM_CERT;
        if (i == 3) expected = signer(context.getPackageManager().getPackageInfo(
            context.getPackageName(), PackageManager.GET_SIGNING_CERTIFICATES));
        if (info == null || !pkg.equals(info.packageName) || info.getLongVersionCode() != VERSIONS[i]
                || expected.isEmpty() || !expected.equals(signer(info)))
            throw new SecurityException("Lab component identity mismatch");
    }

    static boolean verifyInstalled(Context context, String pkg) throws Exception {
        PackageInfo info = installed(pkg);
        if (info == null) return false;
        File expected = new File(context.getDataDir(), "blackbox/data/app/" + pkg + "/base.apk").getCanonicalFile();
        if (info.applicationInfo == null || info.applicationInfo.sourceDir == null
                || !expected.equals(new File(info.applicationInfo.sourceDir).getCanonicalFile()))
            throw new SecurityException("Component is outside the private lab");
        checkArchive(context, expected, pkg);
        return true;
    }

    public static boolean extraPackage(String pkg) {
        return MGC.equals(pkg) || PROBE.equals(pkg);
    }

    public static Object networkInvoke(Object target, Method method, Object[] args) throws Throwable {
        try {
            Object runtime = core();
            boolean guest = (Boolean) runtime.getClass().getMethod("isBlackProcess").invoke(runtime);
            if (!guest) return method.invoke(target, args);
            return Class.forName("io.github.leexeo.cage.space.GuestNetwork")
                .getMethod("invoke", Object.class, Method.class, Object[].class).invoke(null, target, method, args);
        } catch (InvocationTargetException e) { throw e.getCause(); }
    }

    public static boolean componentGuest(Context context, Context guest) {
        String pkg = guest.getPackageName();
        if (!LAB.equals(context.getPackageName()) || !(extraPackage(pkg) || GMS.equals(pkg))) return false;
        try {
            if (!verifyInstalled(context, pkg)) throw new SecurityException("Lab component missing");
            return true;
        } catch (Exception e) {
            throw new SecurityException("Lab component validation failed", e);
        }
    }

    /** Preserve unrelated bindings, explicit foreign targets, the store itself and other users. */
    static Intent candidate(Intent request, String caller, int user) {
        if (request == null || user != 0 || !(PROBE.equals(caller) || "com.anthropic.claude".equals(caller)))
            return request;
        String cls = CLASSIC.equals(request.getAction()) ? CLASSIC_CLASS
            : STANDARD.equals(request.getAction()) ? STANDARD_CLASS : null;
        if (cls == null || request.getSelector() != null) return request;
        ComponentName component = request.getComponent();
        if (component != null && (!STORE.equals(component.getPackageName()) || !cls.equals(component.getClassName())))
            return request;
        if (request.getPackage() != null && !STORE.equals(request.getPackage())) return request;
        return new Intent(request).setPackage(MGC).setComponent(new ComponentName(MGC, cls));
    }

    public static Intent route(Intent request, int user) {
        try {
            Context context = host();
            if (!LAB.equals(context.getPackageName())) return request;
            String caller = (String) Class.forName("top.niunaijun.blackbox.app.BActivityThread")
                .getMethod("getAppPackageName").invoke(null);
            Intent next = candidate(request, caller, user);
            if (next == request) return request;
            if (!verifyInstalled(context, MGC)) return request;
            ResolveInfo resolved = (ResolveInfo) packageCall("resolveService",
                new Class<?>[]{Intent.class, int.class, String.class, int.class}, next, 0, null, user);
            if (resolved == null || resolved.serviceInfo == null || !resolved.serviceInfo.enabled
                    || !resolved.serviceInfo.exported || !MGC.equals(resolved.serviceInfo.packageName))
                throw new SecurityException("Private Integrity service unavailable");
            Log.i("CageIntegrity", "route mode=" + (CLASSIC.equals(request.getAction()) ? "classic" : "standard")
                + " target=companion");
            return next;
        } catch (Exception e) {
            throw new SecurityException("Private Integrity route failed", e);
        }
    }

    private static synchronized void installComponents(Context context) throws Exception {
        if (!LAB.equals(context.getPackageName())) throw new SecurityException("Independent lab required");
        // Validate all existing slots before installing anything. Never replace a different suite or account store.
        for (String pkg : PACKAGES) if (installed(pkg) != null) verifyInstalled(context, pkg);
        File stage = new File(context.getCacheDir(), "integrity-components");
        if (!stage.isDirectory() && !stage.mkdirs()) throw new IllegalStateException("Cannot stage components");
        for (int i = 0; i < PACKAGES.length; i++) {
            String pkg = PACKAGES[i];
            if (verifyInstalled(context, pkg)) continue;
            File apk = new File(stage, FILES[i]);
            try (InputStream in = context.getAssets().open("cage-integrity/" + FILES[i]);
                 FileOutputStream out = new FileOutputStream(apk)) {
                byte[] buffer = new byte[65536];
                for (int read; (read = in.read(buffer)) != -1;) out.write(buffer, 0, read);
            }
            checkArchive(context, apk, pkg);
            Object core = core();
            Object result = core.getClass().getMethod("installPackageAsUser", Uri.class, int.class)
                .invoke(core, Uri.fromFile(apk), 0);
            if (result == null || !result.getClass().getField("success").getBoolean(result)
                    || !verifyInstalled(context, pkg)) throw new IllegalStateException("Component import failed");
            if (!apk.delete()) Log.i("CageIntegrity", "staging_cleanup=pending");
        }
        Log.i("CageIntegrity", "components_verified=4");
    }

    private static void openProbe() throws Exception {
        Context context = host();
        if (!verifyInstalled(context, PROBE)) throw new IllegalStateException("Import lab components first");
        if (!SharedGateway.ready(context)) throw new IllegalStateException("Existing protected gateway is required");
        Object core = core();
        Intent intent = new Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
            .setPackage(PROBE).setComponent(new ComponentName(PROBE, PROBE + ".ProbeActivity"))
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        core.getClass().getMethod("startActivity", Intent.class, int.class).invoke(core, intent, 0);
        Log.i("CageIntegrity", "probe_launch=requested");
    }

    public static Bundle call(ContentProvider provider, String method) {
        Context context = provider.getContext();
        if (context == null || !LAB.equals(context.getPackageName())) return null;
        if (!SharedGateway.METHOD.equals(method)) return null;
        int uid = Binder.getCallingUid();
        if (uid != android.os.Process.myUid())
            throw new SecurityException("Lab caller is not authorized");
        long identity = Binder.clearCallingIdentity();
        try {
            return SharedGateway.localStatus(context);
        } finally {
            Binder.restoreCallingIdentity(identity);
        }
    }

    public static void controls(Activity activity, LinearLayout content) {
        if (!LAB.equals(activity.getPackageName())) return;
        TextView note = new TextView(activity);
        note.setText("完整性实验使用独立数据。先导入组件，再检查两种服务连接。连接成功不代表完整性判定通过。");
        content.addView(note);
        Button prepare = new Button(activity);
        prepare.setText("导入完整性实验组件");
        content.addView(prepare);
        prepare.setOnClickListener(v -> {
            prepare.setEnabled(false);
            new Thread(() -> {
                String message;
                try { installComponents(activity); message = "四个实验组件已导入，可检查服务连接。"; }
                catch (Exception e) { message = "组件导入未完成：" + e.getClass().getSimpleName(); }
                final String text = message;
                activity.runOnUiThread(() -> {
                    note.setText(text); prepare.setEnabled(true);
                    if (text.startsWith("四个")) activity.recreate();
                });
            }, "integrity-component-import").start();
        });
        Button probe = new Button(activity);
        probe.setText("检查 Classic / Standard 连接");
        content.addView(probe);
        probe.setOnClickListener(v -> {
            try { openProbe(); }
            catch (Exception e) {
                Log.w("CageIntegrity", "probe_launch=failed type=" + e.getClass().getSimpleName());
                note.setText("连接检查未打开。请确认组件已导入、原网关和系统断网保护已开启。");
            }
        });
    }
}
