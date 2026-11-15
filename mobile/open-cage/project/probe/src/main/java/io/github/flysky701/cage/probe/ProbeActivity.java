package io.github.flysky701.cage.probe;

import android.app.Activity;
import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.pm.PackageInfo;
import android.os.Bundle;
import android.webkit.WebView;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.TimeZone;

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
        add("网络沿用手机当前设置；本页不检测账号或完整性凭证。");
        for (String pkg : new String[]{"com.google.android.gms", "com.android.vending"}) {
            try { PackageInfo info = getPackageManager().getPackageInfo(pkg, 0); add(pkg + ": " + info.versionName); }
            catch (Exception error) { add(pkg + ": " + error.getClass().getSimpleName()); }
        }
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
            body.addView(web, new LinearLayout.LayoutParams(-1, 230));
            web.loadDataWithBaseURL(null, "<meta name='viewport' content='width=device-width'><p>WebView 已显示本地页面</p>"
                + "<p id='js'></p><script>document.getElementById('js').textContent='JavaScript 时区: '+Intl.DateTimeFormat().resolvedOptions().timeZone</script>", "text/html", "UTF-8", null);
            add("WebView 已创建；请观察下方页面和 JavaScript 读数。");
        } catch (Exception error) { add("WebView: " + error.getClass().getSimpleName()); }
    }
    private void add(String line) { report.append(line).append('\n'); result.setText(report.toString()); }
    @Override protected void onDestroy() { if (web != null) web.destroy(); super.onDestroy(); }
}
