package io.github.leexeo.cage.space;

import android.app.Activity;
import android.content.ClipData;
import android.content.Intent;
import android.content.pm.PackageInfo;
import android.graphics.Typeface;
import android.net.Uri;
import android.os.Bundle;
import android.view.View;
import android.widget.*;
import java.io.*;
import java.util.*;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.zip.ZipEntry;
import java.util.zip.ZipFile;

public final class SpaceActivity extends Activity {
    private static final int PICK = 1;
    private static final String ACTION = "io.github.leexeo.cage.space.";
    // The package service and base APKs are shared across activity instances.
    private static final ExecutorService tasks = Executors.newSingleThreadExecutor();
    private boolean launchRequested;
    private boolean busy;
    private boolean resumed;
    private int refreshGeneration;
    private String notice = "";
    private LinearLayout content;
    private TextView status;

    @Override public void onCreate(Bundle state) {
        super.onCreate(state);
        String action = getIntent().getAction();
        launchRequested = (ACTION + "OPEN_CLAUDE").equals(action) || (ACTION + "OPEN_STORE").equals(action)
                || (ACTION + "INSTALL_CLAUDE").equals(action);
        if (state != null) launchRequested = state.getBoolean("launch");
        if (state != null) notice = state.getString("notice", "");
        ScrollView scroll = new ScrollView(this);
        scroll.setFitsSystemWindows(true);
        content = new LinearLayout(this);
        content.setOrientation(LinearLayout.VERTICAL);
        int pad = Math.round(20 * getResources().getDisplayMetrics().density);
        content.setPadding(pad, pad, pad, pad);
        scroll.addView(content);
        setContentView(scroll);
    }

    @Override protected void onResume() {
        super.onResume();
        resumed = true;
        if (!busy) refresh();
    }

    @Override protected void onSaveInstanceState(Bundle state) {
        super.onSaveInstanceState(state);
        state.putBoolean("launch", launchRequested);
        state.putString("notice", notice);
    }

    private TextView line(String value, int size) {
        TextView view = new TextView(this);
        view.setText(value);
        view.setTextSize(size);
        view.setPadding(0, 12, 0, 12);
        content.addView(view);
        return view;
    }

    private void action(String name, Runnable run) {
        Button button = new Button(this);
        button.setAllCaps(false);
        button.setText(name);
        content.addView(button);
        button.setOnClickListener(v -> { if (!busy) run.run(); });
    }

    private void header(String message) {
        content.removeAllViews();
        line("Google 套件", 26).setTypeface(Typeface.DEFAULT, Typeface.BOLD);
        status = line(message, 16);
        status.setAccessibilityLiveRegion(View.ACCESSIBILITY_LIVE_REGION_POLITE);
    }

    private void refresh() {
        int generation = ++refreshGeneration;
        busy = true;
        header("正在读取空间里的应用…");
        tasks.execute(() -> {
            try {
                SpacePackages space = new SpacePackages(this);
                List<String> rows = new ArrayList<>();
                boolean complete = true;
                for (String pkg : SpacePackages.GOOGLE) {
                    PackageInfo info = space.installed(pkg);
                    boolean present = space.privateCopy(info);
                    complete &= present;
                    String detail = present ? "已导入" + (info.versionName == null ? "" : " · " + info.versionName)
                            : info == null ? "待导入" : "需导入独立副本";
                    rows.add(SpacePackages.label(pkg) + "　" + detail);
                }
                boolean claude = space.installed(SpacePackages.CLAUDE) != null;
                boolean ready = complete;
                // Android 16's authenticator checks the account-service caller's platform signature.
                // Opening an already installed guest app does not require adding a Google account.
                boolean warnAboutSignIn = GuestAuthenticatorTypes.cannotAddAccount(this, "com.google");
                runOnUiThread(() -> {
                    if (isDestroyed() || isFinishing() || generation != refreshGeneration) return;
                    busy = false;
                    String summary = ready ? "三个组件已导入本机空间。" : "请导入适合这台手机的 Google 套件。";
                    header(notice.isEmpty() ? summary : notice);
                    for (String row : rows) line(row, 15);
                    action(ready ? "更新 Google 套件" : "导入 Google 套件", this::pick);
                    if (ready) {
                        if (warnAboutSignIn) line("Google 登录受限：在 Android 16 上，此空间暂时无法添加 Google 账号。", 15);
                        action(claude ? "打开 Claude" : "在 Play 商店安装 Claude",
                                () -> prepare(claude ? "OPEN_CLAUDE" : "INSTALL_CLAUDE"));
                        action("打开空间里的 Play 商店", () -> prepare("OPEN_STORE"));
                    } else line("选择三个完整 APK，也可以选择包含这三个组件的套件 ZIP。", 14);
                    if (notice.isEmpty() && launchRequested && ready && resumed) {
                        launchRequested = false;
                        boolean directClaude = claude && (ACTION + "OPEN_CLAUDE").equals(getIntent().getAction());
                        boolean listing = !directClaude && !(ACTION + "OPEN_STORE").equals(getIntent().getAction());
                        if (directClaude || !warnAboutSignIn || !(ACTION + "OPEN_CLAUDE").equals(getIntent().getAction())) {
                            open(directClaude ? SpacePackages.CLAUDE : SpacePackages.STORE, listing);
                        }
                    }
                });
            } catch (Exception unavailable) { failed("空间服务暂时无法读取，请重试。", generation); }
        });
    }

    @Override protected void onPause() { resumed = false; super.onPause(); }

    private void prepare(String action) {
        setResult(RESULT_OK, new Intent(ACTION + action));
        finish();
    }

    private void open(String pkg, boolean listing) {
        busy = true;
        launchRequested = false;
        status.setText("正在打开" + SpacePackages.label(pkg) + "…");
        tasks.execute(() -> {
            try {
                SpacePackages space = new SpacePackages(this);
                if (!space.open(pkg, listing)) throw new IOException("空间内没有可打开的" + SpacePackages.label(pkg) + "。");
                runOnUiThread(() -> {
                    busy = false;
                    notice = "";
                    if (!isDestroyed() && SpacePackages.CLAUDE.equals(pkg)) finish();
                });
            } catch (Exception e) {
                Throwable cause = e.getCause() != null ? e.getCause() : e;
                android.util.Log.w("CageSpace", "Guest launch failed for " + pkg + ": " + cause.getClass().getSimpleName());
                failed("空间里的" + SpacePackages.label(pkg) + "未能打开。", -1);
            }
        });
    }

    private void failed(String message, int generation) {
        runOnUiThread(() -> {
            if (isDestroyed() || isFinishing() || (generation >= 0 && generation != refreshGeneration)) return;
            busy = false;
            launchRequested = false;
            notice = message;
            header(message);
            action("重新读取空间", () -> { notice = ""; refresh(); });
            action("返回", this::finish);
        });
    }

    private void pick() {
        Intent picker = new Intent(Intent.ACTION_OPEN_DOCUMENT).addCategory(Intent.CATEGORY_OPENABLE)
                .setType("*/*").putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true);
        try { startActivityForResult(picker, PICK); }
        catch (android.content.ActivityNotFoundException missing) { status.setText("手机上没有可用的文件选择器。"); }
    }

    @Override protected void onActivityResult(int request, int result, Intent data) {
        super.onActivityResult(request, result, data);
        if (request != PICK || result != RESULT_OK || data == null) return;
        LinkedHashSet<Uri> files = new LinkedHashSet<>();
        if (data.getData() != null) files.add(data.getData());
        ClipData clip = data.getClipData();
        if (clip != null) for (int i = 0; i < clip.getItemCount(); i++) files.add(clip.getItemAt(i).getUri());
        if (files.isEmpty()) return;
        ++refreshGeneration;
        busy = true;
        header("正在检查安装包并导入本机空间…");
        tasks.execute(() -> {
            String resultText;
            boolean success = false;
            try {
                resultText = importFiles(files);
                success = true;
            }
            catch (IOException e) { resultText = e.getMessage() == null ? "无法读取安装包，请重新选择文件。" : e.getMessage(); }
            catch (Exception e) { resultText = "导入中断，请重新读取空间后重试。"; }
            final String feedback = resultText;
            final boolean completed = success;
            runOnUiThread(() -> {
                if (isDestroyed() || isFinishing()) return;
                busy = false;
                notice = completed && launchRequested ? "" : feedback;
                if (!completed) launchRequested = false;
                refresh();
            });
        });
    }

    private String importFiles(Set<Uri> uris) throws Exception {
        if (uris.size() > 3) throw new IOException("请选择一个套件 ZIP 或最多三个完整 APK。");
        SpacePackages space = new SpacePackages(this);
        File dir = java.nio.file.Files.createTempDirectory(getCacheDir().toPath(), "google-import-").toFile();
        Map<String, File> parts = new HashMap<>();
        Map<String, PackageInfo> info = new HashMap<>();
        try {
            for (Uri uri : uris) {
                if (uri == null || !"content".equals(uri.getScheme())) throw new IOException("无法读取所选文件。");
                File input = File.createTempFile("selection-", ".apk", dir);
                try (InputStream in = getContentResolver().openInputStream(uri)) { copy(in, input, 1024L << 20); }
                try (ZipFile zip = new ZipFile(input)) {
                    if (zip.getEntry("AndroidManifest.xml") != null) {
                        stage(input, parts, info);
                        continue;
                    }
                    int previous = parts.size();
                    Enumeration<? extends ZipEntry> entries = zip.entries();
                    while (entries.hasMoreElements()) {
                        ZipEntry entry = entries.nextElement();
                        if (entry.isDirectory() || !bundleApk(entry.getName())) continue;
                        File apk = File.createTempFile("component-", ".apk", dir);
                        try (InputStream in = zip.getInputStream(entry)) { copy(in, apk, 512L << 20); }
                        stage(apk, parts, info);
                    }
                    if (parts.size() == previous) throw new IOException("ZIP 中没有找到支持的 Google 组件 APK。");
                } catch (java.util.zip.ZipException invalid) { throw new IOException("请选择完整的 APK 或套件 ZIP。"); }
            }
            // Validate the whole selection before the first write. Each successful component is reusable on retry.
            for (String pkg : SpacePackages.GOOGLE) {
                if (parts.containsKey(pkg)) space.install(parts.get(pkg), info.get(pkg));
            }
            return "已导入所选组件。";
        } finally {
            File[] staged = dir.listFiles();
            if (staged != null) for (File file : staged) file.delete();
            dir.delete();
        }
    }

    private static boolean bundleApk(String path) {
        String base = path.substring(path.lastIndexOf('/') + 1).toLowerCase(Locale.ROOT);
        return base.equals("googleservicesframework.apk") || base.equals("gmscore.apk") || base.equals("phonesky.apk")
                || base.equals("prebuiltgmscore.apk") || base.equals(SpacePackages.SERVICES + ".apk")
                || base.equals(SpacePackages.FRAMEWORK + ".apk") || base.equals(SpacePackages.STORE + ".apk");
    }

    private void stage(File file, Map<String, File> parts, Map<String, PackageInfo> info)
            throws Exception {
        PackageInfo pkg = SpacePackages.inspect(this, file);
        if (parts.put(pkg.packageName, file) != null) throw new IOException("选择中有两份" + SpacePackages.label(pkg.packageName) + "。");
        info.put(pkg.packageName, pkg);
    }

    private static void copy(InputStream in, File target, long limit) throws IOException {
        if (in == null) throw new IOException("文件提供方未返回安装包。");
        try (OutputStream out = new FileOutputStream(target)) {
            byte[] buffer = new byte[65536];
            long count = 0;
            for (int n; (n = in.read(buffer)) != -1;) {
                count += n;
                if (count > limit) throw new IOException("安装包超过空间支持的大小。");
                out.write(buffer, 0, n);
            }
        }
    }
}
