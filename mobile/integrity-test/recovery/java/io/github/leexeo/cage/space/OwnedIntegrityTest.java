package io.github.leexeo.cage.space;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.content.pm.Signature;
import android.net.Uri;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.Toast;
import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.security.MessageDigest;

/** Admission and launch only: no changes to Integrity requests, responses or verdicts. */
public final class OwnedIntegrityTest {
    private static final String HOST = "top.niunaijun.microrec";
    private static final String PACKAGE = "io.github.flysky701.integritytest";
    private static final String CERT = "6f364045cb06dc86bd1eaba22f81799fc5dda403c172b9789cd7fb72471be3bc";

    public static boolean isOwn(Object value) { return PACKAGE.equals(value); }
    public static boolean integrityClient(Object value) {
        return isOwn(value) || "com.anthropic.claude".equals(value);
    }

    private static void host(Context context) {
        if (!HOST.equals(context.getPackageName())) throw new SecurityException("Recovery copy only");
    }

    private static Object core() throws Exception {
        return Class.forName("top.niunaijun.blackbox.BlackBoxCore").getMethod("get").invoke(null);
    }

    private static PackageInfo installed() throws Exception {
        Object manager = Class.forName("top.niunaijun.blackbox.BlackBoxCore")
            .getMethod("getBPackageManager").invoke(null);
        Object service = manager.getClass().getMethod("getService").invoke(manager);
        return (PackageInfo) Class.forName("top.niunaijun.blackbox.core.system.pm.IBPackageManagerService")
            .getMethod("getPackageInfo", String.class, int.class, int.class)
            .invoke(service, PACKAGE, PackageManager.GET_SIGNING_CERTIFICATES, 0);
    }

    private static void archive(Context context, File file) throws Exception {
        PackageInfo info = context.getPackageManager().getPackageArchiveInfo(file.getPath(),
            PackageManager.GET_SIGNING_CERTIFICATES);
        if (info == null || !PACKAGE.equals(info.packageName) || info.getLongVersionCode() != 1
                || info.signingInfo == null) throw new SecurityException("Wrong test APK");
        Signature[] signs = info.signingInfo.getApkContentsSigners();
        if (signs == null || signs.length != 1) throw new SecurityException("Wrong test signer");
        StringBuilder hex = new StringBuilder();
        for (byte b : MessageDigest.getInstance("SHA-256").digest(signs[0].toByteArray()))
            hex.append(Character.forDigit((b >> 4) & 15, 16)).append(Character.forDigit(b & 15, 16));
        if (!CERT.equals(hex.toString())) throw new SecurityException("Wrong test signer");
    }

    private static boolean verified(Context context) throws Exception {
        host(context);
        PackageInfo info = installed();
        if (info == null) return false;
        File expected = new File(context.getDataDir(), "blackbox/data/app/" + PACKAGE + "/base.apk").getCanonicalFile();
        if (info.applicationInfo == null || info.applicationInfo.sourceDir == null
                || !expected.equals(new File(info.applicationInfo.sourceDir).getCanonicalFile()))
            throw new SecurityException("Test app is outside the recovery space");
        archive(context, expected);
        return true;
    }

    public static boolean verifiedGuest(Context context, Context guest) {
        if (!isOwn(guest.getPackageName())) return false;
        try {
            if (!verified(context)) throw new SecurityException("Test app missing");
            return true;
        } catch (Exception e) { throw new SecurityException("Test app validation failed", e); }
    }

    public static synchronized void launch(Context context, boolean runClassic) throws Exception {
        host(context);
        Object runtime = core();
        if (!verified(context)) {
            File stage = new File(context.getCacheDir(), "owned-integrity-test.apk");
            try (InputStream in = context.getAssets().open("owned-integrity/test.apk");
                 FileOutputStream out = new FileOutputStream(stage)) {
                byte[] buffer = new byte[65536];
                for (int n; (n = in.read(buffer)) != -1;) out.write(buffer, 0, n);
            }
            archive(context, stage);
            Object result = runtime.getClass().getMethod("installPackageAsUser", Uri.class, int.class)
                .invoke(runtime, Uri.fromFile(stage), 0);
            if (result == null || !result.getClass().getField("success").getBoolean(result) || !verified(context))
                throw new IllegalStateException("Private test app import failed");
            stage.delete();
        }
        if (runClassic) {
            runtime.getClass().getMethod("stopPackage", String.class, int.class).invoke(runtime, PACKAGE, 0);
            File files = resultDirectory(context);
            for (String name : new String[]{"request.json", "status.json", "verdict.json"}) {
                File file = new File(files, name);
                if (file.exists() && !file.delete()) throw new IllegalStateException("Cannot clear prior test result");
            }
        }
        Intent intent = new Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
            .setClassName(PACKAGE, PACKAGE + ".MainActivity")
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK).putExtra("run_classic", runClassic);
        runtime.getClass().getMethod("startActivity", Intent.class, int.class).invoke(runtime, intent, 0);
    }

    public static File resultDirectory(Context context) throws Exception {
        host(context);
        return new File(context.getDataDir(), "blackbox/data/user/0/" + PACKAGE + "/files");
    }

    public static void controls(Activity activity, LinearLayout parent) {
        if (!HOST.equals(activity.getPackageName())) return;
        Button button = new Button(activity);
        button.setText("打开自有完整性测试");
        button.setOnClickListener(v -> {
            button.setEnabled(false);
            new Thread(() -> {
                try { launch(activity, false); }
                catch (Exception e) {
                    activity.runOnUiThread(() -> Toast.makeText(activity,
                        "测试应用未打开：" + e.getMessage(), Toast.LENGTH_LONG).show());
                } finally { activity.runOnUiThread(() -> button.setEnabled(true)); }
            }, "owned-integrity-launch").start();
        });
        parent.addView(button);
    }
}
