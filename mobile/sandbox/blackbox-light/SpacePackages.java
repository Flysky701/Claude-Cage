package io.github.leexeo.cage.space;

import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.content.pm.ResolveInfo;
import android.content.pm.Signature;
import android.content.res.XmlResourceParser;
import android.net.Uri;
import android.os.Build;
import android.util.Log;
import java.io.File;
import java.io.IOException;
import java.security.MessageDigest;
import java.util.List;

/** The preview APK extends the installed BlackBox runtime. Its classes live in the primary dex. */
final class SpacePackages {
    static final String FRAMEWORK = "com.google.android.gsf";
    static final String SERVICES = "com.google.android.gms";
    static final String STORE = "com.android.vending";
    static final String CLAUDE = "com.anthropic.claude";
    static final String[] GOOGLE = { FRAMEWORK, SERVICES, STORE };
    private static final String ROOT = "top.niunaijun.blackbox.";
    private static final int USER = 0;
    private final Context context;
    private final Object core, service;
    private final Class<?> api;

    SpacePackages(Context context) throws Exception {
        this.context = context;
        Class<?> type = Class.forName(ROOT + "BlackBoxCore");
        core = type.getMethod("get").invoke(null);
        Object manager = type.getMethod("getBPackageManager").invoke(null);
        service = manager.getClass().getMethod("getService").invoke(manager);
        if (service == null) throw new IOException("空间服务正在启动，请重试。");
        // The public wrappers can fall back to the personal package manager when the service dies.
        api = Class.forName(ROOT + "core.system.pm.IBPackageManagerService");
    }

    PackageInfo installed(String pkg) throws Exception {
        return (PackageInfo) api.getMethod("getPackageInfo", String.class, int.class, int.class)
                .invoke(service, pkg, 0, USER);
    }

    static String label(String pkg) {
        switch (pkg) {
            case FRAMEWORK: return "Google 服务框架";
            case SERVICES: return "Google Play 服务";
            case STORE: return "Play 商店";
            default: return "Claude";
        }
    }

    static boolean google(String name) {
        return FRAMEWORK.equals(name) || SERVICES.equals(name) || STORE.equals(name);
    }

    static long version(PackageInfo info) {
        return Build.VERSION.SDK_INT >= 28 ? info.getLongVersionCode() : info.versionCode;
    }

    boolean privateCopy(PackageInfo info) throws IOException {
        if (info == null || info.applicationInfo == null || info.applicationInfo.sourceDir == null) return false;
        File base = new File(info.applicationInfo.sourceDir).getCanonicalFile();
        File expected = new File(context.getDataDir(), "blackbox/data/app/" + info.packageName + "/base.apk");
        return base.equals(expected.getCanonicalFile()) && base.isFile();
    }

    static PackageInfo inspect(Context context, File apk) throws Exception {
        PackageInfo info = context.getPackageManager().getPackageArchiveInfo(apk.getPath(),
                Build.VERSION.SDK_INT >= 28 ? PackageManager.GET_SIGNING_CERTIFICATES : PackageManager.GET_SIGNATURES);
        if (info == null || info.applicationInfo == null || !google(info.packageName))
            throw new IOException("请选择 Google 服务框架、Play 服务或 Play 商店的完整 APK。");
        if (info.applicationInfo.minSdkVersion > Build.VERSION.SDK_INT)
            throw new IOException(label(info.packageName) + " 需要更高的 Android 版本。");
        info.applicationInfo.sourceDir = info.applicationInfo.publicSourceDir = apk.getPath();
        try (XmlResourceParser manifest = context.getPackageManager().getResourcesForApplication(info.applicationInfo)
                .getAssets().openXmlResourceParser("AndroidManifest.xml")) {
            String ns = "http://schemas.android.com/apk/res/android";
            for (int event; (event = manifest.next()) != XmlResourceParser.END_DOCUMENT;) {
                if (event != XmlResourceParser.START_TAG) continue;
                if ((manifest.getDepth() == 1 && manifest.getAttributeValue(null, "split") != null)
                        || manifest.getAttributeBooleanValue(ns, "isSplitRequired", false)
                        || manifest.getAttributeValue(ns, "requiredSplitTypes") != null
                        || "uses-split".equals(manifest.getName()))
                    throw new IOException(label(info.packageName) + " 是分拆安装包，请选择同版本的完整 APK。");
            }
        }
        // Android verifies the archive before returning its signing information, including key rotation.
        Signature[] certs;
        if (Build.VERSION.SDK_INT >= 28) {
            certs = info.signingInfo == null || info.signingInfo.hasMultipleSigners()
                    ? null : info.signingInfo.getSigningCertificateHistory();
        } else {
            certs = info.signatures != null && info.signatures.length == 1 ? info.signatures : null;
        }
        if (!trusted(info.packageName, certs)) throw new IOException(label(info.packageName) + " 的 Google 签名未通过验证。");
        return info;
    }

    static boolean trusted(String pkg, Signature[] certs) throws Exception {
        if (!google(pkg) || certs == null) return false;
        MessageDigest hash = MessageDigest.getInstance("SHA-256");
        for (Signature cert : certs) {
            StringBuilder hex = new StringBuilder(64);
            for (byte b : hash.digest(cert.toByteArray())) {
                hex.append(Character.forDigit((b >> 4) & 15, 16)).append(Character.forDigit(b & 15, 16));
            }
            String digest = hex.toString();
            // Release signing keys of the Google apps, including the newer Play services signer.
            if (digest.equals("f0fd6c5b410f25cb25c3b53346c8972fae30f8ee7411df910480ad6b2d60db83")
                    || digest.equals("7ce83c1b71f3d572fed04c8d40c5cb10ff75e6d87d9df6fbd53f0468c2905053")
                    || (SERVICES.equals(pkg) && digest.equals("5f2391277b1dbd489000467e4c2fa6af802430080457dce2f618992e9dfb5402"))) return true;
        }
        return false;
    }

    void install(File apk, PackageInfo selected) throws Exception {
        PackageInfo old = installed(selected.packageName);
        if (old != null && version(old) > version(selected))
            throw new IOException(label(selected.packageName) + " 已有更高版本。");
        if (old != null && version(old) == version(selected) && privateCopy(old)) {
            try {
                if (version(inspect(context, new File(old.applicationInfo.sourceDir))) == version(selected)) return;
            } catch (IOException unreadable) { /* Replace an incomplete or differently signed copy. */ }
        }
        // The URI overload stages into the shell's own cache and replaces its read-only base.apk by rename.
        // A private staging file is already readable by the shell service, via its file URI.
        Object result = core.getClass().getMethod("installPackageAsUser", Uri.class, int.class)
                .invoke(core, Uri.fromFile(apk), USER);
        PackageInfo saved = installed(selected.packageName);
        if (result == null || !result.getClass().getField("success").getBoolean(result)
                || !privateCopy(saved) || version(saved) != version(selected))
            throw new IOException(label(selected.packageName) + " 未完成安装，请重试。");
    }

    boolean open(String pkg, boolean listing) throws Exception {
        Intent target = listing ? new Intent(Intent.ACTION_VIEW, Uri.parse("market://details?id=" + CLAUDE))
                : new Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER);
        target.setPackage(pkg);
        // Play declares several equally ranked handlers. The single-result resolver returns null on ties.
        @SuppressWarnings("unchecked")
        List<ResolveInfo> matches = (List<ResolveInfo>) api.getMethod("queryIntentActivities",
                Intent.class, int.class, String.class, int.class).invoke(service, target,
                        listing ? PackageManager.MATCH_DEFAULT_ONLY : 0, null, USER);
        if (matches != null) for (ResolveInfo match : matches) {
            if (match.activityInfo == null || !pkg.equals(match.activityInfo.packageName)
                    || !match.activityInfo.exported || !match.activityInfo.enabled) continue;
            target.setComponent(new ComponentName(pkg, match.activityInfo.name)).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            core.getClass().getMethod("startActivity", Intent.class, int.class).invoke(core, target, USER);
            return true;
        }
        Log.i("CageSpace", "No eligible guest activity for " + pkg + ", matches=" + (matches == null ? 0 : matches.size()));
        return false;
    }
}
