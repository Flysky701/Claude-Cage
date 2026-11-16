package io.github.flysky701.cage.probe;

import android.app.Activity;
import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.content.pm.Signature;
import android.os.Bundle;
import android.webkit.WebView;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.TimeZone;
import java.util.Arrays;
import java.security.MessageDigest;

/** A real guest APK, built separately and installed only inside Cage. */
public final class ProbeActivity extends Activity {
    private TextView result;
    private WebView web;
    private final StringBuilder report = new StringBuilder();
    @Override public void onCreate(Bundle state) {
        super.onCreate(state);
        LinearLayout body = new LinearLayout(this); body.setOrientation(LinearLayout.VERTICAL);
        int pad = (int) (16 * getResources().getDisplayMetrics().density);
        body.setPadding(pad, pad, pad, pad);
        ScrollView scroll = new ScrollView(this); scroll.addView(body); setContentView(scroll);
        result = new TextView(this); result.setTextIsSelectable(true); result.setTextSize(16); body.addView(result);
        int count = getPreferences(0).getInt("launches", 0) + 1;
        boolean saved = getPreferences(0).edit().putInt("launches", count).commit();
        add("Cage 来宾测试应用已启动");
        add("Android API: " + android.os.Build.VERSION.SDK_INT);
        add("本地计数: " + count + " / 保存: " + saved);
        add("Java 时区: " + TimeZone.getDefault().getID());
        add("联网权限: " + (checkSelfPermission(android.Manifest.permission.INTERNET) == PackageManager.PERMISSION_GRANTED));
        add("未声明的通讯录权限仍拒绝: " + (checkSelfPermission(android.Manifest.permission.READ_CONTACTS) == PackageManager.PERMISSION_DENIED));
        boolean processIdentity = false;
        java.util.List<android.app.ActivityManager.RunningAppProcessInfo> processes =
                ((android.app.ActivityManager) getSystemService(ACTIVITY_SERVICE)).getRunningAppProcesses();
        if (processes != null) for (android.app.ActivityManager.RunningAppProcessInfo process : processes) {
            if (process.pid == android.os.Process.myPid()) processIdentity = process.uid == android.os.Process.myUid()
                    && process.pkgList != null && Arrays.asList(process.pkgList).contains(getPackageName());
        }
        add("进程所属应用与 UID 一致: " + processIdentity);
        add("网络沿用手机当前设置；本页不检测账号或完整性凭证。");
        for (String pkg : new String[]{"com.google.android.gms", "com.android.vending"}) {
            try {
                PackageManager pm = getPackageManager();
                PackageInfo info = pm.getPackageInfo(pkg, 0);
                add(pkg + ": " + info.versionName);
                int uid = pm.getPackageUid(pkg, 0);
                String[] names = pm.getPackagesForUid(uid);
                add("UID 映射: " + (uid == info.applicationInfo.uid && names != null
                        && Arrays.asList(names).contains(pkg)));
                PackageInfo legacy = pm.getPackageInfo(pkg, PackageManager.GET_SIGNATURES);
                PackageInfo modern = pm.getPackageInfo(pkg, PackageManager.GET_SIGNING_CERTIFICATES);
                String signer = digest(modern.signingInfo.getApkContentsSigners()[0]);
                Signature[] history = modern.signingInfo.hasMultipleSigners()
                        ? modern.signingInfo.getApkContentsSigners() : modern.signingInfo.getSigningCertificateHistory();
                boolean legacyInHistory = false;
                if (history != null) for (Signature past : history)
                    if (digest(past).equals(digest(legacy.signatures[0]))) legacyInHistory = true;
                if ("com.google.android.gms".equals(pkg)) {
                    PackageInfo original = pm.getPackageArchiveInfo(info.applicationInfo.sourceDir, PackageManager.GET_SIGNING_CERTIFICATES);
                    add("microG 原包签名未改: " + (original != null && original.signingInfo != null
                            && digest(original.signingInfo.getApkContentsSigners()[0]).equals("9bd06727e62796c0130eb6dab39b73157451582cbd138e86c468acc395d14165")));
                    add("microG 声明的兼容签名: " + (legacyInHistory
                            && signer.equals("f0fd6c5b410f25cb25c3b53346c8972fae30f8ee7411df910480ad6b2d60db83")));
                } else add("原包签名与查询一致: " + (info.versionName.equals(legacy.versionName)
                        && info.versionName.equals(modern.versionName)
                        && legacyInHistory
                        && "com.android.vending".equals(pkg)
                        && signer.equals("7ce83c1b71f3d572fed04c8d40c5cb10ff75e6d87d9df6fbd53f0468c2905053")));
                add("私有已安装标记: " + ((info.applicationInfo.flags & android.content.pm.ApplicationInfo.FLAG_INSTALLED) != 0));
                add("私有启用状态可读取: " + (pm.getApplicationEnabledSetting(pkg) == PackageManager.COMPONENT_ENABLED_STATE_DEFAULT));
            }
            catch (Exception error) { add(pkg + ": " + error.getClass().getSimpleName()); }
        }
        try {
            getPackageManager().getPackageInfo("com.google.android.gsf", 0);
            add("未安装的 GSF: 意外可见");
        } catch (PackageManager.NameNotFoundException expected) {
            add("未安装的 GSF: 正确返回不存在");
        }
        try {
            android.content.pm.InstallSourceInfo source = getPackageManager().getInstallSourceInfo(getPackageName());
            add("导入应用来源为未知: " + (source.getInstallingPackageName() == null
                    && source.getInitiatingPackageName() == null && source.getOriginatingPackageName() == null));
            try {
                getPackageManager().getInstallSourceInfo("io.github.flysky701.cage.absent");
                add("不存在应用的来源查询: 意外成功");
            } catch (PackageManager.NameNotFoundException expected) {
                add("不存在应用的来源查询: 正确拒绝");
            }
            add("Claude 私有启动入口可查询: " + (getPackageManager().getLaunchIntentForPackage("com.anthropic.claude") != null));
        } catch (Exception error) { add("安装来源与启动查询: " + error.getClass().getSimpleName()); }
        Button https = new Button(this); https.setText("测试 Google HTTPS 连接"); body.addView(https);
        https.setOnClickListener(v -> {
            https.setEnabled(false); add("HTTPS 请求中…");
            new Thread(() -> {
                HttpURLConnection connection = null;
                String line;
                try {
                    connection = (HttpURLConnection) new URL("https://accounts.google.com/").openConnection();
                    connection.setConnectTimeout(15000); connection.setReadTimeout(15000);
                    connection.setInstanceFollowRedirects(false); connection.setRequestMethod("HEAD");
                    line = "Google HTTPS: HTTP " + connection.getResponseCode();
                } catch (Exception error) { line = "Google HTTPS: " + error.getClass().getSimpleName(); }
                finally { if (connection != null) connection.disconnect(); }
                String finalLine = line;
                runOnUiThread(() -> { if (!isDestroyed()) { add(finalLine); https.setEnabled(true); } });
            }, "probe-https").start();
        });
        Button copy = new Button(this); copy.setText("复制测试结果"); body.addView(copy);
        copy.setOnClickListener(v -> ((ClipboardManager) getSystemService(CLIPBOARD_SERVICE))
                .setPrimaryClip(ClipData.newPlainText("Cage 测试", report.toString())));
        try {
            web = new WebView(this); web.getSettings().setJavaScriptEnabled(true);
            add("WebView 允许联网: " + !web.getSettings().getBlockNetworkLoads());
            body.addView(web, new LinearLayout.LayoutParams(-1, 230));
            web.loadDataWithBaseURL(null, "<meta name='viewport' content='width=device-width'><p>WebView 已显示本地页面</p>"
                + "<p id='js'></p><script>document.getElementById('js').textContent='JavaScript 时区: '+Intl.DateTimeFormat().resolvedOptions().timeZone</script>", "text/html", "UTF-8", null);
            add("WebView 已创建；请观察下方页面和 JavaScript 读数。");
        } catch (Exception error) { add("WebView: " + error.getClass().getSimpleName()); }
    }
    private void add(String line) { report.append(line).append('\n'); result.setText(report.toString()); }
    private static String digest(Signature signature) throws Exception {
        StringBuilder value = new StringBuilder();
        for (byte b : MessageDigest.getInstance("SHA-256").digest(signature.toByteArray()))
            value.append(String.format(java.util.Locale.ROOT, "%02x", b & 255));
        return value.toString();
    }
    @Override protected void onDestroy() { if (web != null) web.destroy(); super.onDestroy(); }
}
