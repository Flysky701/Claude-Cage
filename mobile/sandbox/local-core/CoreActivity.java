package io.github.leexeo.cage.localcore;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.text.InputType;
import android.view.View;
import android.widget.*;
import java.io.IOException;
import java.net.URISyntaxException;

public final class CoreActivity extends Activity {
    private final Handler handler = new Handler(Looper.getMainLooper());
    private TextView state, feedback;
    private EditText address;
    private Button start, stop, forget;
    private boolean prepareForLaunch, autoStarted, prepareGuest;
    private final Runnable update = new Runnable() {
        @Override public void run() {
            refresh();
            handler.postDelayed(this, 1000);
        }
    };

    @Override public void onCreate(Bundle saved) {
        super.onCreate(saved);
        prepareForLaunch = "io.github.leexeo.cage.space.ENSURE_NETWORK".equals(getIntent().getAction())
                && "io.github.leexeo.cage.mobile.preview".equals(getCallingPackage());
        String caller=getCallingPackage();
        prepareGuest=CoreService.microG(this) && "io.github.leexeo.cage.fullguest.PREPARE_NETWORK".equals(getIntent().getAction())
                && "io.github.leexeo.cage.fullguest".equals(caller)
                && getPackageManager().checkSignatures(getPackageName(),caller)==android.content.pm.PackageManager.SIGNATURE_MATCH;
        prepareForLaunch |= prepareGuest;
        autoStarted = saved != null && saved.getBoolean("auto-started");
        setTitle("本地代理");
        ScrollView scroll = new ScrollView(this);
        scroll.setFitsSystemWindows(true);
        LinearLayout layout = new LinearLayout(this);
        layout.setOrientation(LinearLayout.VERTICAL);
        int padding = Math.round(20 * getResources().getDisplayMetrics().density);
        layout.setPadding(padding, padding, padding, padding);
        layout.setFocusableInTouchMode(true);
        scroll.addView(layout);
        setContentView(scroll);
        TextView title = new TextView(this);
        title.setText("本地代理");
        title.setTextSize(26);
        layout.addView(title);
        state = new TextView(this);
        state.setPadding(0, padding / 2, 0, padding);
        layout.addView(state);
        address = new EditText(this);
        address.setSingleLine(true);
        address.setHint("socks5://[用户名:密码@]服务器:端口");
        address.setContentDescription("SOCKS5 出口地址");
        address.setInputType(InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_VARIATION_PASSWORD);
        address.setSaveEnabled(false);
        address.setImportantForAutofill(View.IMPORTANT_FOR_AUTOFILL_NO);
        layout.addView(address);
        Button save = button(layout, "保存出口");
        save.setOnClickListener(v -> {
            try {
                ProxySettings.save(getFilesDir(), ProxySettings.configuration(address.getText().toString()));
                address.setText("");
                feedback.setText("出口已保存，下次启动核心时使用。");
                if (prepareForLaunch) autoStarted = false;
            } catch (IllegalArgumentException | URISyntaxException invalid) {
                feedback.setText("请填写含主机和端口的 SOCKS5 地址；如需认证，请同时填写用户名和密码。");
            } catch (IOException unavailable) {
                feedback.setText("保存失败，请检查手机存储后重试。");
            }
            refresh();
        });
        feedback = new TextView(this);
        feedback.setAccessibilityLiveRegion(View.ACCESSIBILITY_LIVE_REGION_POLITE);
        layout.addView(feedback);
        start = button(layout, "启动本地核心");
        start.setOnClickListener(v -> {
            feedback.setText("");
            startNetwork();
        });
        stop = button(layout, "停止本地核心");
        stop.setOnClickListener(v -> stopService(new Intent(this, CoreService.class)));
        forget = button(layout, "清除已保存出口");
        forget.setOnClickListener(v -> {
            boolean removed = ProxySettings.file(getFilesDir()).delete();
            if (removed && CoreService.microG(this))
                new android.util.AtomicFile(new java.io.File(getFilesDir(),"guest-gateway-session")).delete();
            feedback.setText(removed ? "已清除保存的出口。" : "清除失败，请重试。");
            refresh();
        });
        layout.requestFocus();
    }

    private Button button(LinearLayout layout, String caption) {
        Button button = new Button(this);
        button.setText(caption);
        layout.addView(button);
        return button;
    }

    private void refresh() {
        boolean configured = ProxySettings.file(getFilesDir()).isFile();
        CoreService core=CoreService.readyCore;
        boolean ready = core != null;
        boolean running = CoreService.running;
        if (prepareForLaunch && ready && !isFinishing()) {
            if(prepareGuest) setResult(RESULT_OK,new Intent().putExtra("loopbackPassword",core.guestGatewayPassword()));
            else setResult(RESULT_OK);
            finish();
            return;
        }
        if (prepareForLaunch && configured && !running && !autoStarted) startNetwork();
        state.setText(ready ? "核心运行中 · 启动时已验证出口" : running ? "正在启动或停止核心…"
                : CoreService.startFailed ? "启动失败，请核对出口或网络后重试。"
                : configured ? "已配置出口 · 核心已停止" : "请先填写并保存 SOCKS5 出口。");
        start.setEnabled(configured && !running);
        stop.setEnabled(running);
        forget.setEnabled(configured && !running);
    }

    private void startNetwork() {
        autoStarted = true;
        try { startForegroundService(new Intent(this, CoreService.class)); }
        catch (IllegalStateException | SecurityException e) { feedback.setText("系统暂时无法启动空间网络，请重试。"); }
    }

    @Override protected void onSaveInstanceState(Bundle state) {
        super.onSaveInstanceState(state);
        state.putBoolean("auto-started", autoStarted);
    }
    @Override protected void onResume() { super.onResume(); update.run(); }
    @Override protected void onPause() { handler.removeCallbacks(update); super.onPause(); }
}
