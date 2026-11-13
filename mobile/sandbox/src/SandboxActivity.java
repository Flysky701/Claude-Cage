package io.github.leexeo.cage.sandbox;

import android.app.Activity;
import android.app.admin.DevicePolicyManager;
import android.content.ActivityNotFoundException;
import android.content.ComponentName;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.pm.CrossProfileApps;
import android.content.pm.PackageManager;
import android.graphics.Typeface;
import android.net.ConnectivityManager;
import android.net.NetworkCapabilities;
import android.os.Build;
import android.os.Bundle;
import android.os.UserHandle;
import android.os.UserManager;
import android.telephony.SubscriptionInfo;
import android.telephony.SubscriptionManager;
import android.telephony.TelephonyManager;
import android.view.View;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;

import java.util.ArrayList;
import java.util.List;
import java.util.TimeZone;
import java.util.UUID;
import java.util.function.Supplier;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public final class SandboxActivity extends Activity {
    private static final int PROVISION = 1;
    private static final String CLAUDE = "com.anthropic.claude";
    private LinearLayout body;
    private String notice = "";
    private final ExecutorService checks = Executors.newFixedThreadPool(3);

    @Override public void onCreate(Bundle state) {
        super.onCreate(state);
        if (state != null) notice = state.getString("notice", "");
    }

    @Override protected void onSaveInstanceState(Bundle state) {
        super.onSaveInstanceState(state);
        state.putString("notice", notice);
    }

    @Override public void onResume() {
        super.onResume();
        boolean managed = getSystemService(UserManager.class).isManagedProfile();
        ScrollView scroll = new ScrollView(this);
        scroll.setBackgroundColor(0xfffaf9f6);
        scroll.setFitsSystemWindows(true);
        body = new LinearLayout(this);
        body.setOrientation(LinearLayout.VERTICAL);
        body.setPadding(dp(22), dp(20), dp(22), dp(24));
        scroll.addView(body);
        setContentView(scroll);

        text(managed ? "工作资料" : "普通资料（个人区或次用户）", 15);
        text("Cage 空间测试", 28).setTypeface(Typeface.DEFAULT, Typeface.BOLD);
        heading("SIM 与订阅");
        TextView sim = text(simSnapshot(), 16);
        action("重新读取 SIM", v -> sim.setText(simSnapshot()));
        if (!notice.isEmpty()) text(notice, 15);
        boolean canSwitch = Build.VERSION.SDK_INT >= 28 && addProfileSwitches();
        if (!managed && !canSwitch) {
            DevicePolicyManager policy = getSystemService(DevicePolicyManager.class);
            if (!getPackageManager().hasSystemFeature(PackageManager.FEATURE_MANAGED_USERS)) {
                text("本机没有提供 Android 工作资料功能。", 15);
            } else if (policy != null && policy.isProvisioningAllowed(DevicePolicyManager.ACTION_PROVISION_MANAGED_PROFILE)) {
                action("创建测试工作资料", v -> createWorkProfile());
            } else {
                text("系统暂不允许创建工作资料。若已创建，请从应用列表的工作区打开带公文包标记的「Cage 空间测试」。", 15);
            }
        }

        heading("应用私有数据");
        SharedPreferences prefs = getSharedPreferences("sandbox-test", MODE_PRIVATE);
        TextView marker = text("本区标记 · " + prefs.getString("marker", "尚未写入"), 17);
        action("写入新的测试标记", v -> {
            String value = UUID.randomUUID().toString().substring(0, 8);
            prefs.edit().putString("marker", value).apply();
            marker.setText("本区标记 · " + value);
        });
        text("分别在两区写入，重新打开各自的图标核对标记。", 14);

        heading("应用读到的系统状态");
        TextView readings = text("", 16);
        action("读取语言、时区与网络", v -> readings.setText(snapshot()));
        TextView exits = text("", 16);
        exits.setVisibility(View.GONE);
        action("检测本区公网出口", v -> {
            v.setEnabled(false);
            readings.setText(snapshot());
            exits.setVisibility(View.VISIBLE);
            exits.setText("正在新建 HTTPS 连接…");
            String[] replies = new String[ExitProbe.LABELS.length];
            for (int n = 0; n < replies.length; n++) {
                final int index = n;
                checks.execute(() -> {
                    String result = ExitProbe.run(index);
                    runOnUiThread(() -> {
                        if (!v.isAttachedToWindow()) return;
                        replies[index] = result;
                        StringBuilder report = new StringBuilder();
                        for (int i = 0; i < replies.length; i++) {
                            if (i > 0) report.append('\n');
                            report.append(ExitProbe.LABELS[i]).append(" · ").append(replies[i] == null ? "检测中" : replies[i]);
                        }
                        exits.setText(report);
                        if (!java.util.Arrays.asList(replies).contains(null)) v.setEnabled(true);
                    });
                });
            }
        });
        if (managed) {
            heading("原生应用测试");
            Intent launch = getPackageManager().getLaunchIntentForPackage(CLAUDE);
            if (launch == null) text("当前工作资料中没有可启动的 Claude。可先用上方读数完成隔离测试。", 15);
            else action("打开工作区的 Claude", v -> {
                try { startActivity(launch); }
                catch (ActivityNotFoundException | SecurityException ex) {
                    ((Button)v).setEnabled(false);
                    text("Claude 当前不可启动，请检查工作区中的安装状态。", 15);
                }
            });
        }
    }

    @android.annotation.TargetApi(28)
    private boolean addProfileSwitches() {
        CrossProfileApps profiles = getSystemService(CrossProfileApps.class);
        if (profiles == null) return false;
        java.util.List<UserHandle> targets = profiles.getTargetUserProfiles();
        for (UserHandle target : targets) {
            action(profiles.getProfileSwitchingLabel(target).toString(), v -> {
                try { profiles.startMainActivity(getComponentName(), target); }
                catch (ActivityNotFoundException | SecurityException ex) {
                    text("资料切换失败。可从系统应用列表打开另一份「Cage 空间测试」。", 15);
                }
            });
        }
        return !targets.isEmpty();
    }

    private void createWorkProfile() {
        Intent setup = new Intent(DevicePolicyManager.ACTION_PROVISION_MANAGED_PROFILE);
        setup.putExtra(DevicePolicyManager.EXTRA_PROVISIONING_DEVICE_ADMIN_COMPONENT_NAME,
                new ComponentName(this, SandboxAdmin.class));
        try { startActivityForResult(setup, PROVISION); }
        catch (ActivityNotFoundException | SecurityException ex) {
            text("系统未能打开工作资料设置。请查看手机是否允许创建工作资料。", 15);
        }
    }

    @Override protected void onDestroy() {
        checks.shutdownNow();
        super.onDestroy();
    }

    @Override protected void onActivityResult(int request, int result, Intent data) {
        super.onActivityResult(request, result, data);
        if (request == PROVISION) notice = result == RESULT_OK
                ? "已提交创建请求。请等系统设置完成，再从带公文包的应用图标进入工作资料。"
                : "本次工作资料设置未完成。";
    }

    private String snapshot() {
        StringBuilder values = new StringBuilder();
        values.append("系统语言 · ").append(getResources().getConfiguration().getLocales().toLanguageTags());
        values.append("\n时区 · ").append(TimeZone.getDefault().getID());
        values.append("\n当前网络 · ").append(read(this::network));
        return values.toString();
    }

    private String simSnapshot() {
        StringBuilder values = new StringBuilder();
        TelephonyManager phone = getSystemService(TelephonyManager.class);
        if (phone != null) {
            values.append("默认 SIM · ").append(read(() -> simState(phone.getSimState())));
            values.append("\n卡槽 · ").append(read(() -> {
                int count = Build.VERSION.SDK_INT >= 30 ? phone.getActiveModemCount() : phone.getPhoneCount();
                ArrayList<String> slots = new ArrayList<>();
                for (int i = 0; i < count; i++) {
                    final int slot = i;
                    slots.add((slot + 1) + "：" + read(() -> simState(phone.getSimState(slot))));
                }
                return count == 0 ? "0 个活动卡槽" : String.join("，", slots);
            }));
            values.append("\n默认 SIM 归属地 · ").append(read(phone::getSimCountryIso));
            values.append("\n默认 SIM 运营商名称 · ").append(read(phone::getSimOperatorName));
            values.append("\n默认 SIM 运营商 MCC/MNC · ").append(read(phone::getSimOperator));
            values.append("\n注册网络国家 · ").append(read(phone::getNetworkCountryIso));
            values.append("\n注册网络运营商名称 · ").append(read(phone::getNetworkOperatorName));
            values.append("\n注册网络 MCC/MNC · ").append(read(phone::getNetworkOperator));
        } else {
            values.append("电话服务 · 不可用");
        }
        values.append("\n默认订阅 · ").append(read(() -> subscription(SubscriptionManager.getDefaultSubscriptionId())));
        values.append("\n默认数据订阅 · ").append(read(() -> subscription(SubscriptionManager.getDefaultDataSubscriptionId())));
        values.append("\n默认语音订阅 · ").append(read(() -> subscription(SubscriptionManager.getDefaultVoiceSubscriptionId())));
        values.append("\n默认短信订阅 · ").append(read(() -> subscription(SubscriptionManager.getDefaultSmsSubscriptionId())));
        values.append("\n活动订阅 · ").append(read(() -> {
            SubscriptionManager manager = getSystemService(SubscriptionManager.class);
            if (manager == null) return "订阅服务不可用";
            List<SubscriptionInfo> active = manager.getActiveSubscriptionInfoList();
            if (active == null) return "系统未返回";
            ArrayList<String> entries = new ArrayList<>();
            for (SubscriptionInfo info : active) {
                entries.add("槽 " + (info.getSimSlotIndex() + 1) + " · " + subscription(info.getSubscriptionId()));
            }
            return active.isEmpty() ? "0 项" : active.size() + " 项（" + String.join("，", entries) + "）";
        }));
        return values.toString();
    }

    private static String subscription(int id) {
        // These are local Android subscription indexes, not subscriber or SIM serial numbers.
        if (id == SubscriptionManager.DEFAULT_SUBSCRIPTION_ID) return "默认占位值";
        return id < 0 ? "无有效订阅" : "ID " + id;
    }

    private String network() {
        ConnectivityManager manager = getSystemService(ConnectivityManager.class);
        android.net.Network active = manager.getActiveNetwork();
        if (active == null) return "无默认网络";
        NetworkCapabilities caps = manager.getNetworkCapabilities(active);
        if (caps == null) return "系统未返回";
        ArrayList<String> transports = new ArrayList<>();
        if (caps.hasTransport(NetworkCapabilities.TRANSPORT_WIFI)) transports.add("Wi-Fi");
        if (caps.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR)) transports.add("移动网络");
        if (caps.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET)) transports.add("以太网");
        if (caps.hasTransport(NetworkCapabilities.TRANSPORT_VPN)) transports.add("VPN");
        return transports.isEmpty() ? "其他" : String.join(" + ", transports);
    }

    private static String simState(int state) {
        switch (state) {
            case TelephonyManager.SIM_STATE_UNKNOWN: return "未知";
            case TelephonyManager.SIM_STATE_ABSENT: return "无卡";
            case TelephonyManager.SIM_STATE_READY: return "就绪";
            case TelephonyManager.SIM_STATE_PIN_REQUIRED: return "需要 PIN";
            case TelephonyManager.SIM_STATE_PUK_REQUIRED: return "需要 PUK";
            case TelephonyManager.SIM_STATE_NETWORK_LOCKED: return "网络锁定";
            case TelephonyManager.SIM_STATE_NOT_READY: return "未就绪";
            case TelephonyManager.SIM_STATE_PERM_DISABLED: return "已停用";
            case TelephonyManager.SIM_STATE_CARD_IO_ERROR: return "读卡异常";
            case TelephonyManager.SIM_STATE_CARD_RESTRICTED: return "卡受限";
            default: return "系统状态 " + state;
        }
    }

    private static String read(Supplier<String> reader) {
        try {
            String value = reader.get();
            return value == null || value.trim().isEmpty() ? "系统未返回" : value;
        } catch (SecurityException ex) { return "权限受限"; }
        catch (UnsupportedOperationException | IllegalStateException ex) { return "系统不支持或暂时不可用"; }
    }

    private int dp(int value) { return Math.round(getResources().getDisplayMetrics().density * value); }
    private TextView text(String value, int size) {
        TextView view = new TextView(this);
        view.setText(value);
        view.setTextSize(size);
        view.setTextColor(0xff292a27);
        view.setPadding(0, dp(4), 0, dp(4));
        body.addView(view);
        return view;
    }
    private void heading(String title) {
        TextView view = text(title, 19);
        view.setPadding(0, dp(16), 0, dp(4));
        view.setTypeface(Typeface.DEFAULT, Typeface.BOLD);
    }
    private void action(String title, View.OnClickListener listener) {
        Button button = new Button(this);
        button.setText(title);
        button.setOnClickListener(listener);
        body.addView(button);
    }
}
