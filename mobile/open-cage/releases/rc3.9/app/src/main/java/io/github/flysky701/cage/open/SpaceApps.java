package io.github.flysky701.cage.open;

import android.accounts.Account;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.content.pm.ResolveInfo;
import android.content.pm.Signature;
import android.graphics.drawable.Drawable;
import android.net.Uri;

import io.github.leexeo.cage.space.CandidateClaudeRemoval;
import io.github.leexeo.cage.space.ClaudeBundle;
import io.github.flysky701.cage.privacy.GuestMicrogSetup;

import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.security.MessageDigest;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

import top.niunaijun.blackbox.BlackBoxCore;

final class SpaceApps {
    static final String CLAUDE = "com.anthropic.claude";
    static final String STORE = "com.android.vending";
    static final String GMS = "com.google.android.gms";
    static final String PROBE = PreflightRunner.PROBE_PKG;
    private static final String GOOGLE_SIGNER =
            "f0fd6c5b410f25cb25c3b53346c8972fae30f8ee7411df910480ad6b2d60db83";

    enum ImportKind { APP, STORE, CLAUDE }

    static final class App {
        final String pkg;
        final String label;
        final Drawable icon;

        App(ApplicationInfo info, PackageManager pm) {
            pkg = info.packageName;
            String name = pkg;
            Drawable picture = null;
            try {
                CharSequence value = info.loadLabel(pm);
                if (value != null && value.length() != 0) name = value.toString();
                picture = info.loadIcon(pm);
            } catch (RuntimeException unavailable) {
                // Some virtual packages lack resources the host package manager can read.
            }
            label = CLAUDE.equals(pkg) ? "Claude" : name;
            icon = picture;
        }
    }

    static final class Problem extends Exception {
        Problem(String message) { super(message); }
    }

    private SpaceApps() {}

    static List<App> list(Context context) throws Exception {
        List<App> apps = new ArrayList<>();
        PackageManager pm = context.getPackageManager();
        for (PackageInfo info : BundledApps.list()) {
            if (info.applicationInfo != null) apps.add(new App(info.applicationInfo, pm));
        }
        apps.sort(Comparator.comparing(app -> app.label.toLowerCase(Locale.ROOT)));
        return apps;
    }

    static List<App> importable(Context context) {
        PackageManager pm = context.getPackageManager();
        Intent launcher = new Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER);
        Map<String, App> apps = new LinkedHashMap<>();
        for (ResolveInfo match : pm.queryIntentActivities(launcher, 0)) {
            if (match.activityInfo == null) continue;
            ApplicationInfo info = match.activityInfo.applicationInfo;
            if (info == null || context.getPackageName().equals(info.packageName)
                    || GMS.equals(info.packageName) || CLAUDE.equals(info.packageName)
                    || STORE.equals(info.packageName) || PROBE.equals(info.packageName)) continue;
            if (info.splitSourceDirs == null || info.splitSourceDirs.length == 0)
                apps.putIfAbsent(info.packageName, new App(info, pm));
        }
        List<App> result = new ArrayList<>(apps.values());
        result.sort(Comparator.comparing(app -> app.label.toLowerCase(Locale.ROOT)));
        return result;
    }

    static void launch(Context context, String pkg) throws Exception {
        if (BundledApps.installed(context, pkg) == null || !BlackBoxCore.get().launchApk(pkg, 0))
            throw new Problem("当前空间找不到可启动的应用。");
    }

    static void openListing(Context context) throws Exception {
        if (BundledApps.installed(context, STORE) == null)
            throw new Problem("请先导入官方 Google Play。");
        Intent intent = new Intent(Intent.ACTION_VIEW, Uri.parse("market://details?id=" + CLAUDE))
                .setPackage(STORE);
        ResolveInfo match = BundledApps.service().resolveActivity(intent, 0, null, 0);
        if (match == null || match.activityInfo == null || !STORE.equals(match.activityInfo.packageName)) {
            launch(context, STORE);
            return;
        }
        intent.setComponent(new ComponentName(STORE, match.activityInfo.name));
        BlackBoxCore.get().startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK), 0);
    }

    static List<String> googleAccounts() {
        List<String> names = new ArrayList<>();
        try {
            Account[] accounts = top.niunaijun.blackbox.fake.frameworks.BAccountManager.get()
                    .getAccountsAsUser("com.google");
            if (accounts != null) {
                for (Account account : accounts) {
                    if (account != null && account.name != null && !account.name.isEmpty()) {
                        names.add(account.name);
                    }
                }
            }
        } catch (RuntimeException unavailable) {
            // Return empty when the account service is not yet ready.
        }
        return names;
    }

    static void accounts(Context context) throws Exception {
        if (BundledApps.installed(context, GMS) == null)
            throw new Problem("请先在启动检查中准备 microG Services。");
        Intent intent = new Intent("com.google.android.gms.auth.login.LOGIN")
                .setComponent(new ComponentName(GMS, "org.microg.gms.auth.login.LoginActivity"));
        BlackBoxCore.get().startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK), 0);
    }

    static void setupMicrog(Context context) throws Exception {
        BundledApps.prepare(context, ignored -> {});
        PackageInfo installed = BundledApps.installed(context, GMS);
        if (installed == null || installed.getLongVersionCode() != GuestMicrogSetup.VERSION) {
            throw new Problem("此 microG 版本需要在自己的设置页配置。");
        }
        BundledApps.service().stopPackage(GMS, 0);
        try {
            Thread.sleep(450);
        } catch (InterruptedException ignored) {
            Thread.currentThread().interrupt();
        }
        GuestMicrogSetup.request(context);
        Intent intent = new Intent(Intent.ACTION_MAIN)
                .setComponent(new ComponentName(GMS, "org.microg.gms.ui.MainSettingsActivity"))
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        BlackBoxCore.get().startActivity(intent, 0);
    }

    static void importInstalled(Context context, String pkg, ImportKind kind) throws Exception {
        ApplicationInfo info;
        try {
            info = context.getPackageManager().getApplicationInfo(pkg, 0);
        } catch (PackageManager.NameNotFoundException unavailable) {
            throw new Problem(kind == ImportKind.STORE
                    ? "手机上没有可导入的 Google Play，请选择官方完整单 APK。"
                    : "手机上已找不到该应用。");
        }
        if (info.splitSourceDirs != null && info.splitSourceDirs.length > 0)
            throw new Problem("这个应用在手机上使用分包。请提供完整单 APK。");
        importApk(context, new File(info.sourceDir), kind);
    }

    static void importFile(Context context, Uri uri, ImportKind kind) throws Exception {
        File file = File.createTempFile("import-", kind == ImportKind.CLAUDE ? ".zip" : ".apk",
                context.getCacheDir());
        try {
            try (InputStream in = context.getContentResolver().openInputStream(uri);
                 FileOutputStream out = new FileOutputStream(file)) {
                if (in == null) throw new Problem("无法读取选中的文件。");
                byte[] buffer = new byte[65536];
                long total = 0;
                int count;
                while ((count = in.read(buffer)) != -1) {
                    total += count;
                    if (kind == ImportKind.CLAUDE && total > ClaudeBundle.MAX_ARCHIVE)
                        throw new Problem("Claude 分包文件超过 256 MB。");
                    out.write(buffer, 0, count);
                }
            }
            if (kind == ImportKind.CLAUDE) {
                if (BundledApps.installed(context, CLAUDE) != null)
                    throw new Problem("Claude 已在空间内安装。");
                try {
                    ClaudeBundle.install(context, file);
                } catch (Exception rejected) {
                    throw new Problem("未能导入 Claude。请选择同版本、原签名的完整 ARM64 分包。");
                }
                if (BundledApps.installed(context, CLAUDE) == null)
                    throw new Problem("请再检查一次空间内的 Claude 安装状态。");
            } else {
                importApk(context, file, kind);
            }
        } finally {
            file.delete();
        }
    }

    private static void importApk(Context context, File apk, ImportKind kind) throws Exception {
        PackageInfo info = context.getPackageManager().getPackageArchiveInfo(apk.getPath(),
                PackageManager.GET_META_DATA | PackageManager.GET_SIGNING_CERTIFICATES);
        if (info == null || info.applicationInfo == null) throw new Problem("无法识别 APK。");
        String pkg = info.packageName;
        if (context.getPackageName().equals(pkg) || GMS.equals(pkg) || PROBE.equals(pkg))
            throw new Problem("这个组件由 Cage Open 管理。");
        if (kind == ImportKind.STORE && !STORE.equals(pkg))
            throw new Problem("请选择 Google Play 商店的完整单 APK。");
        if (CLAUDE.equals(pkg)) throw new Problem("请从空间商店安装 Claude，或使用 Claude 分包导入。");
        if (STORE.equals(pkg) && !officialStore(info))
            throw new Problem("该 APK 未通过官方 Google Play 签名检查。");
        if ((info.splitNames != null && info.splitNames.length > 0)
                || (info.applicationInfo.metaData != null
                    && info.applicationInfo.metaData.getBoolean("com.android.vending.splits.required")))
            throw new Problem("请选择完整单 APK。");
        if (BundledApps.installed(context, pkg) != null) throw new Problem("应用已在空间内安装。");
        BundledApps.install(apk);
        if (BundledApps.installed(context, pkg) == null)
            throw new Problem("安装后未在空间内找到该应用。");
    }

    private static boolean officialStore(PackageInfo info) throws Exception {
        if (info.signingInfo == null || info.signingInfo.hasMultipleSigners()) return false;
        Signature[] signers = info.signingInfo.getSigningCertificateHistory();
        if (signers == null) return false;
        MessageDigest sha = MessageDigest.getInstance("SHA-256");
        for (Signature signer : signers) {
            StringBuilder hex = new StringBuilder();
            for (byte b : sha.digest(signer.toByteArray()))
                hex.append(String.format(Locale.ROOT, "%02x", b & 255));
            if (GOOGLE_SIGNER.contentEquals(hex)) return true;
        }
        return false;
    }

    static void remove(Context context, String pkg) throws Exception {
        if (GMS.equals(pkg) || PROBE.equals(pkg) || context.getPackageName().equals(pkg))
            throw new Problem("这个组件由 Cage Open 管理。");
        if (CLAUDE.equals(pkg)) {
            CandidateClaudeRemoval.remove(context);
        } else if (BundledApps.installed(context, pkg) != null) {
            BundledApps.service().uninstallPackageAsUser(pkg, 0);
        }
        if (BundledApps.installed(context, pkg) != null)
            throw new Problem("移除未完成，应用仍在当前空间。");
    }
}
