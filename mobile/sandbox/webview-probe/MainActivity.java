package io.github.leexeo.cage.webviewprobe;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.TextView;

/** Only a mode selector: never initializes WebView in the launcher process. */
public final class MainActivity extends Activity {
    @Override public void onCreate(Bundle saved) {
        super.onCreate(saved);
        String mode = getIntent().getStringExtra("mode");
        if ("plain".equals(mode) || "wrapped".equals(mode)) {
            open(mode);
            finish();
            return;
        }
        LinearLayout page = new LinearLayout(this);
        page.setOrientation(LinearLayout.VERTICAL);
        int padding = (int) (20 * getResources().getDisplayMetrics().density);
        page.setPadding(padding, padding, padding, padding);
        TextView intro = new TextView(this);
        intro.setText("WebView 第一层诊断\n\n应用不申请联网权限。两个模式分别在独立进程中运行，只检查 WebView 加载开关和内核套接字限制。\n\n未接入代理，不涉及登录。网页加载失败属于预期对照。");
        page.addView(intro);
        for (String choice : new String[]{"plain", "wrapped"}) {
            Button button = new Button(this);
            button.setText("plain".equals(choice) ? "普通 Activity Context" : "WebView 专用 ContextWrapper");
            button.setOnClickListener(view -> open(choice));
            page.addView(button);
        }
        setContentView(page);
    }

    private void open(String mode) {
        Class<?> target = "wrapped".equals(mode) ? ProbeActivity.Wrapped.class : ProbeActivity.Plain.class;
        Intent intent = new Intent(this, target);
        intent.putExtra("load_page", getIntent().getBooleanExtra("load_page", true));
        startActivity(intent);
    }
}
