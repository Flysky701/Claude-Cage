package io.github.flysky701.cage.open;

import android.app.Activity;
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
import java.util.List;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import top.niunaijun.blackbox.BlackBoxCore;
import top.niunaijun.blackbox.entity.pm.InstallResult;

/** First source-build milestone: single-APK import and guest launch, not login acceptance. */
public final class HomeActivity extends Activity {
    private static final int IMPORT_APK = 1;
    private final ExecutorService worker = Executors.newSingleThreadExecutor();
    private LinearLayout apps;
    private TextView status;
    private Button add;

    @Override public void onCreate(Bundle state) {
        super.onCreate(state);
        LinearLayout body = new LinearLayout(this);
        body.setOrientation(LinearLayout.VERTICAL);
        int padding = (int) (20 * getResources().getDisplayMetrics().density);
        body.setPadding(padding, padding, padding, padding);
        ScrollView scroll = new ScrollView(this);
        scroll.addView(body);
        setContentView(scroll);
        TextView title = new TextView(this);
        title.setText("Cage Open"); title.setTextSize(30); body.addView(title);
        TextView note = new TextView(this);
        note.setText("独立源码实验版\n\n支持单个 APK 导入与启动。Google / Claude 登录、分包安装和隐私保护尚未验收。网络沿用手机当前设置。请仅使用测试应用与测试账号。\n");
        note.setTextSize(16); body.addView(note);
        add = new Button(this); add.setText("导入 APK"); body.addView(add);
        add.setOnClickListener(v -> {
            Intent pick = new Intent(Intent.ACTION_OPEN_DOCUMENT);
            pick.setType("application/vnd.android.package-archive");
            pick.addCategory(Intent.CATEGORY_OPENABLE);
            startActivityForResult(pick, IMPORT_APK);
        });
        Button refresh = new Button(this); refresh.setText("刷新应用"); body.addView(refresh);
        refresh.setOnClickListener(v -> refresh());
        status = new TextView(this); body.addView(status);
        apps = new LinearLayout(this); apps.setOrientation(LinearLayout.VERTICAL); body.addView(apps);
        refresh();
    }

    @Override protected void onActivityResult(int request, int result, Intent data) {
        super.onActivityResult(request, result, data);
        if (request != IMPORT_APK || result != RESULT_OK || data == null || data.getData() == null) return;
        Uri uri = data.getData();
        add.setEnabled(false); status.setText("正在导入…");
        worker.execute(() -> {
            File apk = null;
            try {
                apk = File.createTempFile("guest-", ".apk", getCacheDir());
                try (InputStream in = getContentResolver().openInputStream(uri);
                     FileOutputStream out = new FileOutputStream(apk)) {
                    if (in == null) throw new IllegalArgumentException("无法读取所选文件");
                    byte[] buffer = new byte[65536]; int n;
                    while ((n = in.read(buffer)) != -1) out.write(buffer, 0, n);
                }
                PackageInfo info = getPackageManager().getPackageArchiveInfo(apk.getPath(), PackageManager.GET_META_DATA);
                if (info == null || info.applicationInfo == null) throw new IllegalArgumentException("无法识别 APK");
                if (getPackageName().equals(info.packageName)) throw new IllegalArgumentException("不能导入容器自身");
                if ((info.splitNames != null && info.splitNames.length > 0)
                        || (info.applicationInfo.metaData != null
                        && info.applicationInfo.metaData.getBoolean("com.android.vending.splits.required")))
                    throw new IllegalArgumentException("本阶段尚不支持分包应用");
                if (BlackBoxCore.get().isInstalled(info.packageName, 0))
                    throw new IllegalArgumentException("已存在该应用；本阶段不执行覆盖升级");
                InstallResult installed = BlackBoxCore.get().installPackageAsUser(apk, 0);
                if (!installed.success) throw new IllegalStateException(installed.msg);
                runOnUiThread(() -> { add.setEnabled(true); refresh(); });
            } catch (Exception error) {
                String message = error.getMessage() == null ? error.getClass().getSimpleName() : error.getMessage();
                runOnUiThread(() -> { add.setEnabled(true); status.setText("导入失败：" + message); });
            } finally { if (apk != null) apk.delete(); }
        });
    }

    private void refresh() {
        status.setText("正在读取空间…");
        worker.execute(() -> {
            try {
                List<PackageInfo> installed = BlackBoxCore.get().getInstalledPackages(0, 0);
                runOnUiThread(() -> {
                    if (isFinishing() || isDestroyed()) return;
                    apps.removeAllViews(); status.setText("已导入 " + installed.size() + " 个应用");
                    for (PackageInfo app : installed) {
                        Button launch = new Button(this); launch.setText(app.packageName);
                        launch.setOnClickListener(v -> worker.execute(() -> {
                            try {
                                boolean started = BlackBoxCore.get().launchApk(app.packageName, 0);
                                if (!started) runOnUiThread(() -> status.setText("无法启动：" + app.packageName));
                            } catch (Exception error) {
                                runOnUiThread(() -> status.setText("启动失败：" + error.getClass().getSimpleName()));
                            }
                        }));
                        apps.addView(launch);
                    }
                });
            } catch (Exception error) {
                runOnUiThread(() -> status.setText("空间未就绪：" + error.getClass().getSimpleName()));
            }
        });
    }
    @Override protected void onDestroy() { worker.shutdown(); super.onDestroy(); }
}
