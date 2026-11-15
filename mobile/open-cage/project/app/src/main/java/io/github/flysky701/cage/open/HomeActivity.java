package io.github.flysky701.cage.open;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.ComponentName;
import android.content.Intent;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.os.Bundle;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;
import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import top.niunaijun.blackbox.BlackBoxCore;

public final class HomeActivity extends Activity {
    private static final int IMPORT_APK = 1;
    private static final String GMS = "com.google.android.gms";
    private static final String PROBE = "io.github.flysky701.cage.probe";
    private final ExecutorService worker = Executors.newSingleThreadExecutor();
    private final List<Button> controls = new ArrayList<>();
    private final StringBuilder log = new StringBuilder("Cage Open 0.0.2 / Android API " + android.os.Build.VERSION.SDK_INT + "\n");
    private LinearLayout body, apps;
    private TextView status;
    interface Job { void run() throws Exception; }

    @Override public void onCreate(Bundle state) {
        super.onCreate(state);
        body = new LinearLayout(this); body.setOrientation(LinearLayout.VERTICAL);
        int pad = (int) (20 * getResources().getDisplayMetrics().density);
        body.setPadding(pad, pad, pad, pad);
        ScrollView scroll = new ScrollView(this); scroll.addView(body); setContentView(scroll);
        TextView title = new TextView(this); title.setText("Cage Open · 集成测试版"); title.setTextSize(25); body.addView(title);
        TextView note = new TextView(this); note.setTextSize(15);
        note.setText("已内置 microG Services、Companion 和测试应用，首次打开自动准备。\n"
            + "网络沿用手机当前设置；Google / Claude 登录及隐私保护仍待实测。\n"
            + "Companion 提供兼容服务，不是可下载应用的 Play 商店。Claude 原包需另行导入。\n");
        body.addView(note);
        button("1 · 运行内置测试应用", () -> launch(PROBE));
        button("2 · 打开 microG 设置", () -> start(GMS, "org.microg.gms.ui.MainSettingsActivity", Intent.ACTION_MAIN));
        button("3 · 添加 Google 测试账号", () -> start(GMS, "org.microg.gms.auth.login.LoginActivity", "com.google.android.gms.auth.login.LOGIN"));
        button("打开 Companion", () -> start("com.android.vending", "org.microg.vending.ui.MainActivity", Intent.ACTION_MAIN));
        Button importApk = new Button(this); importApk.setText("导入其他单个 APK"); body.addView(importApk); controls.add(importApk);
        importApk.setOnClickListener(v -> {
            Intent pick = new Intent(Intent.ACTION_OPEN_DOCUMENT).setType("application/vnd.android.package-archive");
            pick.addCategory(Intent.CATEGORY_OPENABLE); startActivityForResult(pick, IMPORT_APK);
        });
        button("重试准备 / 刷新应用", this::prepare);
        Button copy = new Button(this); copy.setText("复制准备记录"); body.addView(copy);
        copy.setOnClickListener(v -> ((ClipboardManager) getSystemService(CLIPBOARD_SERVICE))
            .setPrimaryClip(ClipData.newPlainText("Cage 准备记录", log.toString())));
        Button notices = new Button(this); notices.setText("组件版本与开源说明"); body.addView(notices);
        notices.setOnClickListener(v -> {
            try { new AlertDialog.Builder(this).setTitle("内置组件")
                .setMessage(BundledApps.readAsset(this, "bundle/NOTICE.txt")).setPositiveButton("关闭", null).show(); }
            catch (Exception error) { say("读取说明失败：" + error.getClass().getSimpleName()); }
        });
        status = new TextView(this); status.setTextIsSelectable(true); body.addView(status);
        apps = new LinearLayout(this); apps.setOrientation(LinearLayout.VERTICAL); body.addView(apps);
        runTask(this::prepare);
    }
    private void button(String title, Job job) {
        Button button = new Button(this); button.setText(title); body.addView(button); controls.add(button);
        button.setOnClickListener(v -> runTask(job));
    }
    private void say(String line) {
        runOnUiThread(() -> { if (!isDestroyed()) { log.append(line).append('\n'); status.setText(log.toString()); } });
    }
    private void runTask(Job job) {
        controls.forEach(v -> v.setEnabled(false));
        worker.execute(() -> {
            try { job.run(); }
            catch (Exception error) { say("未完成：" + error.getClass().getSimpleName() + " · " + error.getMessage()); }
            finally { runOnUiThread(() -> { if (!isDestroyed()) controls.forEach(v -> v.setEnabled(true)); }); }
        });
    }
    private void prepare() throws Exception {
        try { BundledApps.prepare(getApplicationContext(), this::say); say("准备完成，可以从上方开始测试。"); }
        finally { refresh(); }
    }
    private void start(String pkg, String activity, String action) throws Exception {
        if (BundledApps.installed(this, pkg) == null) throw new IllegalStateException("组件尚未准备好，请重试准备");
        Intent intent = new Intent(action).setComponent(new ComponentName(pkg, activity));
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        BlackBoxCore.get().startActivity(intent, 0);
        say("已请求打开 " + pkg + "；页面是否成功显示请以手机实际结果为准。");
    }
    private void launch(String pkg) throws Exception {
        if (GMS.equals(pkg)) { start(pkg, "org.microg.gms.ui.MainSettingsActivity", Intent.ACTION_MAIN); return; }
        if ("com.android.vending".equals(pkg)) { start(pkg, "org.microg.vending.ui.MainActivity", Intent.ACTION_MAIN); return; }
        if (BundledApps.installed(this, pkg) == null) throw new IllegalStateException("应用尚未导入当前空间");
        if (!BlackBoxCore.get().launchApk(pkg, 0)) throw new IllegalStateException("找不到启动入口：" + pkg);
        say("已请求启动 " + pkg);
    }
    private void refresh() throws Exception {
        List<PackageInfo> installed = BundledApps.list();
        runOnUiThread(() -> {
            if (isDestroyed()) return;
            apps.removeAllViews();
            for (PackageInfo app : installed) {
                Button launch = new Button(this); launch.setText(app.packageName + " · " + app.versionName);
                launch.setOnClickListener(v -> runTask(() -> launch(app.packageName))); apps.addView(launch);
            }
        });
    }
    @Override protected void onActivityResult(int request, int result, Intent data) {
        super.onActivityResult(request, result, data);
        if (request != IMPORT_APK || result != RESULT_OK || data == null || data.getData() == null) return;
        Uri uri = data.getData();
        runTask(() -> {
            File apk = File.createTempFile("guest-", ".apk", getCacheDir());
            try {
                try (InputStream in = getContentResolver().openInputStream(uri); FileOutputStream out = new FileOutputStream(apk)) {
                    if (in == null) throw new IllegalArgumentException("无法读取所选文件");
                    byte[] buffer = new byte[65536]; int count;
                    while ((count = in.read(buffer)) != -1) out.write(buffer, 0, count);
                }
                PackageInfo info = getPackageManager().getPackageArchiveInfo(apk.getPath(), PackageManager.GET_META_DATA);
                if (info == null || info.applicationInfo == null) throw new IllegalArgumentException("无法识别 APK");
                if (getPackageName().equals(info.packageName)) throw new IllegalArgumentException("不能导入容器自身");
                if ((info.splitNames != null && info.splitNames.length > 0) || (info.applicationInfo.metaData != null
                        && info.applicationInfo.metaData.getBoolean("com.android.vending.splits.required")))
                    throw new IllegalArgumentException("当前入口仅支持完整单 APK，尚不支持分包应用");
                if (BundledApps.installed(this, info.packageName) != null) throw new IllegalArgumentException("应用已存在，保留现有版本和数据");
                BundledApps.install(apk); say("导入完成：" + info.packageName); refresh();
            } finally { apk.delete(); }
        });
    }
    @Override protected void onDestroy() { worker.shutdown(); super.onDestroy(); }
}
