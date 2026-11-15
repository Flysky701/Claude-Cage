package io.github.leexeo.cage.localcore;

import android.app.Activity;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.net.VpnService;
import android.os.*;
import android.text.InputType;
import android.view.View;
import android.widget.*;

public final class CoreActivity extends Activity {
    private static final int VPN_CONSENT = 110;
    private final Handler main = new Handler(Looper.getMainLooper());
    private TextView state, feedback;
    private EditText input;
    private Button save, start, stop;
    private boolean prepare, autoStarted, saving;
    private final Runnable refresh = new Runnable() {
        @Override public void run() { update(); main.postDelayed(this, 400); }
    };

    @Override public void onCreate(Bundle saved) {
        super.onCreate(saved);
        prepare = "io.github.leexeo.cage.space.ENSURE_NETWORK".equals(getIntent().getAction());
        setResult(RESULT_CANCELED);
        if (prepare && (!"top.niunaijun.microdem".equals(getCallingPackage())
                || getPackageManager().checkSignatures(getPackageName(), getCallingPackage())
                != PackageManager.SIGNATURE_MATCH)) { finish(); return; }
        autoStarted = saved != null && saved.getBoolean("autoStarted");
        setTitle("Cage 空间网关");
        ScrollView scroll = new ScrollView(this);
        scroll.setFitsSystemWindows(true);
        LinearLayout layout = new LinearLayout(this);
        layout.setOrientation(LinearLayout.VERTICAL);
        int pad = Math.round(20 * getResources().getDisplayMetrics().density);
        layout.setPadding(pad, pad, pad, pad);
        layout.setFocusableInTouchMode(true);
        scroll.addView(layout); setContentView(scroll);
        TextView title = new TextView(this); title.setText("空间网关"); title.setTextSize(26); layout.addView(title);
        state = new TextView(this); state.setPadding(0, pad, 0, pad); layout.addView(state);
        input = new EditText(this);
        input.setHint("socks5://用户名:密码@服务器:端口");
        input.setContentDescription("SOCKS5 出口地址，凭据已遮盖");
        input.setInputType(InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_VARIATION_PASSWORD);
        input.setSingleLine(true); input.setSaveEnabled(false);
        input.setImportantForAutofill(View.IMPORTANT_FOR_AUTOFILL_NO_EXCLUDE_DESCENDANTS);
        layout.addView(input);
        save = button(layout, "保存出口");
        save.setOnClickListener(view -> {
            final Upstream config;
            try { config = Upstream.parse(input.getText().toString()); }
            catch (Exception invalid) { feedback.setText("请输入含主机和端口的 socks5:// 地址；认证需同时填写用户名和密码。"); return; }
            input.setText(""); saving = true; update();
            new Thread(() -> {
                boolean success;
                try { Settings.save(this, config); success = true; }
                catch (Exception unavailable) { success = false; }
                final boolean savedOk = success;
                main.post(() -> {
                    saving = false;
                    if (savedOk) autoStarted = false;
                    feedback.setText(savedOk ? "出口已保存。" : "保存失败，请重试。");
                    update();
                });
            }, "Cage-save-upstream").start();
        });
        feedback = new TextView(this);
        feedback.setAccessibilityLiveRegion(View.ACCESSIBILITY_LIVE_REGION_POLITE); layout.addView(feedback);
        start = button(layout, "开始"); start.setOnClickListener(view -> startNetwork());
        stop = button(layout, "停止"); stop.setOnClickListener(view -> {
            autoStarted = true;
            startService(new Intent(this, CoreService.class).setAction("STOP")); update();
        });
        Button protection = button(layout, "打开系统 VPN 设置");
        protection.setOnClickListener(view -> {
            try { startActivity(new Intent(android.provider.Settings.ACTION_VPN_SETTINGS)); }
            catch (RuntimeException unavailable) { feedback.setText("请手动打开系统设置 → VPN。"); }
        });
        TextView note = new TextView(this);
        note.setText("这是全手机 VPN 网关，会接管本用户下其他应用的流量。\n"
                + "请在系统 VPN 设置中为本应用开启“始终开启”与“阻止未连接流量”。开启后，网关停机时手机其他应用也会断网。\n"
                + "只有这两项保护及隧道均已开启，配套空间才可继续。Android 每个用户只能启用一个 VPN。\n"
                + "隧道已启动不代表 Google 或 Claude 已成功联网；出口不可用时连接失败。\n"
                + "已导入 VLESS 配置时优先使用兼容核心；单独保存 SOCKS5 地址不会覆盖或移除 VLESS 配置。");
        layout.addView(note); layout.requestFocus();
    }

    private Button button(LinearLayout layout, String text) {
        Button button = new Button(this); button.setText(text); layout.addView(button); return button;
    }

    private void startNetwork() {
        autoStarted = true; feedback.setText("");
        try {
            Intent consent = VpnService.prepare(this);
            if (consent != null) startActivityForResult(consent, VPN_CONSENT);
            else startPreparedNetwork();
        }
        catch (RuntimeException denied) { feedback.setText("系统暂时无法启动网关，请重试。"); }
        update();
    }

    private void startPreparedNetwork() {
        startForegroundService(new Intent(this, CoreService.class));
    }

    @Override protected void onActivityResult(int request, int result, Intent data) {
        super.onActivityResult(request, result, data);
        if (request != VPN_CONSENT) return;
        if (result == RESULT_OK) {
            try { startPreparedNetwork(); }
            catch (RuntimeException denied) { feedback.setText("系统暂时无法启动网关，请重试。"); }
        } else feedback.setText("尚未授予系统 VPN 权限，空间无法继续。");
    }

    private void update() {
        if (state == null) return;
        boolean configured = Settings.configured(this);
        boolean vless = Settings.vlessFile(this).isFile();
        CoreService service = CoreService.current;
        boolean running = CoreService.running;
        boolean tunnel = service != null && service.tunnelReady();
        boolean alwaysOn = service != null && service.isAlwaysOn();
        boolean lockdown = service != null && service.isLockdownEnabled();
        boolean ready = service != null && service.safeReady();
        if (prepare && ready && !isFinishing()) {
            setResult(RESULT_OK, new Intent().putExtra("protectionReady", true).putExtra("wholeDevice", true));
            finish(); return;
        }
        if (prepare && configured && !running && !autoStarted && !saving) { startNetwork(); return; }
        state.setText((vless ? "出口模式：VLESS 兼容核心\n" : "出口模式：SOCKS5\n") + (ready ? "安全保护已就绪 · 全手机 VPN 隧道已启动"
                : tunnel ? "隧道已启动 · 尚未开启完整断网保护"
                    + "\n始终开启：" + (alwaysOn ? "已开启" : "未开启")
                    + "\n阻止未连接流量：" + (lockdown ? "已开启" : "未开启")
                : running ? "正在建立全手机 VPN 隧道…"
                : CoreService.startFailed ? "启动失败，请核对出口和网络。"
                : configured ? "出口已保存 · 网关已停止" : "请先保存 SOCKS5 出口。"));
        start.setEnabled(configured && !running && !saving);
        stop.setEnabled(running);
        save.setEnabled(!running && !saving); input.setEnabled(!running && !saving);
    }

    @Override protected void onSaveInstanceState(Bundle state) {
        super.onSaveInstanceState(state); state.putBoolean("autoStarted", autoStarted);
    }
    @Override protected void onResume() { super.onResume(); refresh.run(); }
    @Override protected void onPause() { main.removeCallbacks(refresh); super.onPause(); }
}
