package io.github.leexeo.cage.gboxprobe;

import android.app.Activity;
import android.content.SharedPreferences;
import android.net.ConnectivityManager;
import android.net.LinkProperties;
import android.net.Network;
import android.net.NetworkCapabilities;
import android.os.Build;
import android.os.Bundle;
import android.telephony.SubscriptionInfo;
import android.telephony.SubscriptionManager;
import android.telephony.TelephonyManager;
import android.util.Log;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;
import org.json.JSONArray;
import org.json.JSONObject;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.net.NetworkInterface;
import java.nio.charset.StandardCharsets;
import java.util.Collections;
import java.util.HashSet;
import java.util.List;
import java.util.TimeZone;
import java.util.UUID;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;

/** Measurements only: absence in an emulator is never reported as isolation success. */
public final class ProbeActivity extends Activity {
    private static final String TAG = "CageGBoxProbe";
    private static final String PROCESS_SESSION = UUID.randomUUID().toString();
    private static JSONObject firstNativeTime;
    private static volatile boolean nativeTzsetRequested;
    private final ExecutorService worker = Executors.newSingleThreadExecutor();
    private JSONObject report;
    private TextView result;
    private WebView web;
    private volatile String run;
    private int pending;
    private final HashSet<String> completedSections = new HashSet<>();
    private boolean nativeQueued;
    private ConnectivityManager networks;
    private ConnectivityManager.NetworkCallback callback;

    @Override public void onCreate(Bundle saved) {
        super.onCreate(saved);
        LinearLayout body = new LinearLayout(this);
        body.setOrientation(LinearLayout.VERTICAL);
        int pad = (int) (16 * getResources().getDisplayMetrics().density);
        body.setPadding(pad, pad, pad, pad);
        ScrollView scroll = new ScrollView(this);
        scroll.addView(body);
        setContentView(scroll);
        TextView title = new TextView(this);
        title.setText("Cage GBox 隔离验收\n这里只记录读数。需要外层与来宾对照；无 SIM／无 VPN 不代表屏蔽通过。");
        title.setTextSize(18);
        body.addView(title);
        Button read = new Button(this);
        read.setText("重新读取本区状态");
        read.setOnClickListener(v -> capture());
        body.addView(read);
        Button marker = new Button(this);
        marker.setText("写入新的本区测试标记");
        marker.setOnClickListener(v -> {
            preferences().edit().putString("marker", UUID.randomUUID().toString()).commit();
            capture();
        });
        body.addView(marker);
        result = new TextView(this);
        result.setTextSize(12);
        result.setTextIsSelectable(true);
        body.addView(result);
        capture();
    }

    private SharedPreferences preferences() { return getSharedPreferences("privacy-probe", MODE_PRIVATE); }

    private void capture() {
        stopCallback();
        if (web != null) { web.destroy(); web = null; }
        run = UUID.randomUUID().toString();
        final String current = run;
        pending = 4;
        completedSections.clear();
        nativeQueued = false;
        report = new JSONObject();
        put(report, "schemaVersion", 1);
        put(report, "probeVersion", 6);
        put(report, "installedVersion", read(() -> getPackageManager().getPackageInfo(getPackageName(), 0).versionCode));
        put(report, "run", current);
        put(report, "processSessionId", PROCESS_SESSION);
        put(report, "processStartElapsedRealtimeMillis", android.os.Process.getStartElapsedRealtime());
        put(report, "package", getPackageName());
        put(report, "epochMillis", System.currentTimeMillis());
        put(report, "sdk", Build.VERSION.SDK_INT);
        put(report, "timezoneProbePreviouslyRefreshed", nativeTzsetRequested);
        put(report, "assessment", "MEASUREMENTS_ONLY_COMPARE_OUTER_AND_GUEST");
        JSONObject permissions = new JSONObject();
        put(permissions, "readPhoneState", checkSelfPermission(android.Manifest.permission.READ_PHONE_STATE)
                == android.content.pm.PackageManager.PERMISSION_GRANTED);
        put(report, "permissions", permissions);
        put(report, "marker", read(() -> preferences().getString("marker", null)));
        put(report, "sim", sim());
        put(report, "timezone", timezone());
        put(report, "network", networkSnapshot());
        put(report, "webview", status("PENDING"));
        put(report, "nativeSubprocess", status("PENDING"));
        put(report, "nativeInProcess", status("PENDING"));
        put(report, "networkCallback", status("PENDING"));
        publish(false);
        worker.execute(() -> {
            JSONObject nativeData = nativeSnapshot();
            runOnUiThread(() -> complete(current, "nativeSubprocess", nativeData));
        });
        readWebView(current);
        readCallback(current);
    }

    private JSONObject sim() {
        JSONObject data = new JSONObject();
        TelephonyManager phone = getSystemService(TelephonyManager.class);
        if (phone == null) return status("SERVICE_UNAVAILABLE");
        put(data, "defaultState", read(phone::getSimState));
        put(data, "activeModemCount", read(() -> Build.VERSION.SDK_INT >= 30 ? phone.getActiveModemCount() : phone.getPhoneCount()));
        put(data, "phoneCount", read(phone::getPhoneCount));
        put(data, "simCountry", read(phone::getSimCountryIso));
        put(data, "simOperator", read(phone::getSimOperator));
        put(data, "simOperatorName", read(phone::getSimOperatorName));
        put(data, "networkCountry", read(phone::getNetworkCountryIso));
        put(data, "networkOperator", read(phone::getNetworkOperator));
        put(data, "networkOperatorName", read(phone::getNetworkOperatorName));
        JSONArray slots = new JSONArray();
        // Query two fixed positions even when the reported count is hidden.
        for (int i = 0; i < 2; i++) {
            final int slot = i;
            JSONObject item = new JSONObject();
            put(item, "slot", slot);
            put(item, "state", read(() -> phone.getSimState(slot)));
            slots.put(item);
        }
        put(data, "slots", slots);
        put(data, "defaultSubscription", read(() -> validSubscription(SubscriptionManager.getDefaultSubscriptionId())));
        put(data, "dataSubscription", read(() -> validSubscription(SubscriptionManager.getDefaultDataSubscriptionId())));
        put(data, "voiceSubscription", read(() -> validSubscription(SubscriptionManager.getDefaultVoiceSubscriptionId())));
        put(data, "smsSubscription", read(() -> validSubscription(SubscriptionManager.getDefaultSmsSubscriptionId())));
        put(data, "activeSubscriptions", read(() -> {
            SubscriptionManager manager = getSystemService(SubscriptionManager.class);
            if (manager == null) return null;
            List<SubscriptionInfo> list = manager.getActiveSubscriptionInfoList();
            if (list == null) return null;
            JSONArray entries = new JSONArray();
            for (SubscriptionInfo info : list) {
                JSONObject item = new JSONObject();
                put(item, "slot", info.getSimSlotIndex());
                // Store validity, never SIM serial numbers, phone numbers or subscriber identifiers.
                put(item, "subscriptionValid", validSubscription(info.getSubscriptionId()));
                entries.put(item);
            }
            return entries;
        }));
        return data;
    }

    private static boolean validSubscription(int id) {
        return id >= 0 && id != SubscriptionManager.DEFAULT_SUBSCRIPTION_ID;
    }

    private JSONObject timezone() {
        JSONObject data = new JSONObject();
        put(data, "javaId", read(() -> TimeZone.getDefault().getID()));
        put(data, "javaOffsetMinutes", read(() -> TimeZone.getDefault().getOffset(System.currentTimeMillis()) / 60000));
        put(data, "icuId", read(() -> android.icu.util.TimeZone.getDefault().getID()));
        put(data, "icuOffsetMinutes", read(() -> android.icu.util.TimeZone.getDefault().getOffset(System.currentTimeMillis()) / 60000));
        put(data, "environmentTZ", read(() -> System.getenv("TZ")));
        return data;
    }

    private JSONObject networkSnapshot() {
        JSONObject data = new JSONObject();
        networks = getSystemService(ConnectivityManager.class);
        if (networks == null) return status("SERVICE_UNAVAILABLE");
        put(data, "active", read(() -> describeNetwork(networks.getActiveNetwork())));
        put(data, "allNetworks", read(() -> {
            JSONArray list = new JSONArray();
            for (Network network : networks.getAllNetworks()) list.put(describeNetwork(network));
            return list;
        }));
        put(data, "interfaces", read(() -> {
            JSONArray list = new JSONArray();
            java.util.Enumeration<NetworkInterface> interfaces = NetworkInterface.getNetworkInterfaces();
            if (interfaces == null) return null;
            for (NetworkInterface it : Collections.list(interfaces)) {
                JSONObject item = new JSONObject();
                put(item, "name", it.getName());
                put(item, "up", it.isUp());
                put(item, "loopback", it.isLoopback());
                put(item, "virtual", it.isVirtual());
                // Do not collect network addresses, MAC addresses or hardware identifiers.
                list.put(item);
            }
            return list;
        }));
        return data;
    }

    private JSONObject describeNetwork(Network network) {
        if (network == null) return status("NO_NETWORK");
        JSONObject data = new JSONObject();
        put(data, "capabilities", read(() -> capabilities(networks.getNetworkCapabilities(network))));
        put(data, "interface", read(() -> {
            LinkProperties link = networks.getLinkProperties(network);
            return link == null ? null : link.getInterfaceName();
        }));
        return data;
    }

    private JSONObject capabilities(NetworkCapabilities caps) {
        if (caps == null) return status("NO_CAPABILITIES");
        JSONObject data = new JSONObject();
        put(data, "vpn", caps.hasTransport(NetworkCapabilities.TRANSPORT_VPN));
        put(data, "wifi", caps.hasTransport(NetworkCapabilities.TRANSPORT_WIFI));
        put(data, "cellular", caps.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR));
        put(data, "ethernet", caps.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET));
        put(data, "notVpn", caps.hasCapability(NetworkCapabilities.NET_CAPABILITY_NOT_VPN));
        put(data, "internet", caps.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET));
        put(data, "validated", caps.hasCapability(NetworkCapabilities.NET_CAPABILITY_VALIDATED));
        return data;
    }

    private void readCallback(String current) {
        if (networks == null) { complete(current, "networkCallback", status("SERVICE_UNAVAILABLE")); return; }
        final JSONArray events = new JSONArray();
        final JSONArray links = new JSONArray();
        callback = new ConnectivityManager.NetworkCallback() {
            @Override public void onCapabilitiesChanged(Network network, NetworkCapabilities caps) {
                runOnUiThread(() -> { if (current.equals(run)) events.put(capabilities(caps)); });
            }
            @Override public void onLinkPropertiesChanged(Network network, LinkProperties properties) {
                runOnUiThread(() -> {
                    if (!current.equals(run)) return;
                    JSONObject link = new JSONObject();
                    put(link, "interface", read(() -> properties == null ? null : properties.getInterfaceName()));
                    links.put(link);
                });
            }
        };
        try { networks.registerDefaultNetworkCallback(callback); }
        catch (RuntimeException error) { complete(current, "networkCallback", error(error)); stopCallback(); return; }
        result.postDelayed(() -> {
            if (!current.equals(run)) return;
            stopCallback();
            JSONObject value = status(events.length() == 0 ? "NO_EVENT_WITHIN_2_SECONDS" : "OK");
            put(value, "events", events);
            put(value, "linkProperties", links);
            complete(current, "networkCallback", value);
        }, 2000);
    }

    private void readWebView(String current) {
        try {
            web = new WebView(this);
            web.getSettings().setJavaScriptEnabled(true);
            web.getSettings().setBlockNetworkLoads(true);
            final long pageRequested = System.currentTimeMillis();
            web.setWebViewClient(new WebViewClient() {
                @Override public void onPageFinished(WebView view, String url) {
                    if (!current.equals(run)) return;
                    view.evaluateJavascript("JSON.stringify({timezone:Intl.DateTimeFormat().resolvedOptions().timeZone,offsetMinutes:-new Date().getTimezoneOffset(),epochMillis:Date.now(),firstScript:window.cageFirstRead})", value -> {
                        if (!current.equals(run) || !"PENDING".equals(report.optJSONObject("webview").optString("status"))) return;
                        try {
                            String json = new JSONArray("[" + value + "]").getString(0);
                            JSONObject data = status("OK");
                            put(data, "value", new JSONObject(json));
                            put(data, "javaRequestEpochMillis", pageRequested);
                            put(data, "javaReceivedEpochMillis", System.currentTimeMillis());
                            complete(current, "webview", data);
                        } catch (Exception error) { complete(current, "webview", error(error)); }
                    });
                }
            });
            // Capture real Date/Intl values in the first page script. Nothing replaces those APIs.
            web.loadDataWithBaseURL(null, "<!doctype html><html><head><script>window.cageFirstRead={timezone:Intl.DateTimeFormat().resolvedOptions().timeZone,offsetMinutes:-new Date().getTimezoneOffset(),epochMillis:Date.now()};</script></head><body>local timezone check</body></html>", "text/html", "UTF-8", null);
            result.postDelayed(() -> {
                if (current.equals(run) && "PENDING".equals(report.optJSONObject("webview").optString("status")))
                    complete(current, "webview", status("NO_RESULT_WITHIN_5_SECONDS"));
            }, 5000);
        } catch (RuntimeException error) { complete(current, "webview", error(error)); }
    }

    private JSONObject nativeSnapshot() {
        JSONObject data = new JSONObject();
        put(data, "javaDateBeforeEpochMillis", System.currentTimeMillis());
        put(data, "date", read(() -> command("/system/bin/date", "+%Z|%z|%s")));
        put(data, "javaDateAfterEpochMillis", System.currentTimeMillis());
        JSONObject props = new JSONObject();
        String[] keys = {"persist.sys.timezone", "gsm.sim.operator.iso-country", "gsm.sim.operator.alpha", "gsm.sim.operator.numeric",
                "gsm.operator.iso-country", "gsm.operator.alpha", "gsm.operator.numeric"};
        for (String key : keys) put(props, key, read(() -> command("/system/bin/getprop", key)));
        put(data, "properties", props);
        put(data, "diagnosticChildElf", read(ProbeActivity::diagnosticChildElf));
        put(data, "elfScope", "SELF_OF_DIAGNOSTIC_CHILD_ONLY_NOT_DATE_OR_GETPROP");
        return data;
    }

    private static JSONObject diagnosticChildElf() throws Exception {
        // The actual exec child opens its own executable, avoiding the parent's translated file view.
        String[] words = command("/system/bin/toybox", "od", "-An", "-tu1", "-N20", "/proc/self/exe").split("\\s+");
        if (words.length != 20) throw new IllegalStateException("InvalidElfHeader");
        int[] header = new int[20];
        for (int i = 0; i < header.length; i++) {
            header[i] = Integer.parseInt(words[i]);
            if (header[i] < 0 || header[i] > 255) throw new IllegalStateException("InvalidElfHeader");
        }
        if (header[0] != 127 || header[1] != 69 || header[2] != 76 || header[3] != 70
                || (header[4] != 1 && header[4] != 2) || (header[5] != 1 && header[5] != 2))
            throw new IllegalStateException("InvalidElfHeader");
        JSONObject data = new JSONObject();
        put(data, "magicOk", true);
        put(data, "elfClass", header[4]);
        put(data, "byteOrder", header[5]);
        put(data, "eMachine", header[5] == 1 ? header[18] | header[19] << 8 : header[18] << 8 | header[19]);
        return data;
    }

    private static native byte[] nativeState();
    private static native byte[] nativeClock(boolean refreshTimezone);

    private static JSONObject nativeTime(boolean refresh) {
        long before = System.currentTimeMillis();
        JSONObject data;
        try { data = new JSONObject(new String(nativeClock(refresh), StandardCharsets.UTF_8)); }
        catch (Exception failure) { data = error(failure); }
        catch (LinkageError failure) { data = error(failure); }
        put(data, "javaBeforeEpochMillis", before);
        put(data, "javaAfterEpochMillis", System.currentTimeMillis());
        return data;
    }

    private static synchronized JSONObject nativeInProcessSnapshot() {
        try { System.loadLibrary("cage_privacy_probe"); }
        catch (RuntimeException failure) { return error(failure); }
        catch (LinkageError failure) { return error(failure); }
        boolean retained = firstNativeTime != null;
        if (!retained) firstNativeTime = nativeTime(false);
        JSONObject data;
        try { data = new JSONObject(new String(nativeState(), StandardCharsets.UTF_8)); }
        catch (Exception failure) { data = error(failure); }
        catch (LinkageError failure) { data = error(failure); }
        put(data, "initialTime", firstNativeTime);
        put(data, "initialTimeRetainedFromEarlierCapture", retained);
        nativeTzsetRequested = true;
        put(data, "afterTzsetTime", nativeTime(true));
        put(data, "scope", "LIBC_CALLS_ONLY_DIRECT_SYSCALL_AND_NETLINK_NOT_COVERED");
        put(data, "processElfScope", "PROCESS_MAIN_ELF_READ_VIA_LIBC_NOT_ALL_MAPPED_CODE");
        return data;
    }

    private static String command(String... arguments) throws Exception {
        Process process = new ProcessBuilder(arguments).redirectErrorStream(true).start();
        if (!process.waitFor(2, TimeUnit.SECONDS)) { process.destroy(); throw new IllegalStateException("ProcessTimeout"); }
        if (process.exitValue() != 0) throw new IllegalStateException("ProcessExit" + process.exitValue());
        ByteArrayOutputStream output = new ByteArrayOutputStream();
        try (InputStream in = process.getInputStream()) {
            byte[] buffer = new byte[256];
            int length;
            while (output.size() < 2048 && (length = in.read(buffer)) >= 0) output.write(buffer, 0, length);
        }
        return output.toString("UTF-8").trim();
    }

    private void complete(String current, String section, JSONObject value) {
        if (!current.equals(run) || !completedSections.add(section)) return;
        put(report, section, value);
        pending--;
        // Refresh libc only after the initial Java/WebView/child measurements are finished.
        if (!nativeQueued && completedSections.contains("webview")
                && completedSections.contains("networkCallback") && completedSections.contains("nativeSubprocess")) {
            nativeQueued = true;
            worker.execute(() -> {
                if (!current.equals(run)) return;
                JSONObject nativeData = nativeInProcessSnapshot();
                runOnUiThread(() -> complete(current, "nativeInProcess", nativeData));
            });
        }
        publish(pending == 0);
    }

    private void publish(boolean done) {
        put(report, "complete", done);
        try {
            String json = report.toString(2);
            result.setText((done ? "读取完成；尚未判定隔离结果。\n" : "正在读取…\n") + json);
            try (FileOutputStream out = new FileOutputStream(new File(getFilesDir(), "latest-report.json"))) {
                out.write(json.getBytes(StandardCharsets.UTF_8));
            }
            if (done) {
                java.util.Iterator<String> keys = report.keys();
                while (keys.hasNext()) {
                    String key = keys.next();
                    Log.i(TAG, "REPORT|" + run + "|" + key + "|" + report.get(key).toString());
                }
                Log.i(TAG, "END|" + run);
            }
        } catch (Exception failure) { result.append("\n保存报告失败：" + failure.getClass().getSimpleName()); }
    }

    private void stopCallback() {
        if (networks != null && callback != null) {
            try { networks.unregisterNetworkCallback(callback); } catch (RuntimeException ignored) { }
        }
        callback = null;
    }

    private interface Reader { Object get() throws Exception; }
    private static JSONObject read(Reader reader) {
        try {
            Object value = reader.get();
            JSONObject data = status(value == null ? "NULL" : value instanceof String && ((String)value).isEmpty() ? "EMPTY" : "OK");
            put(data, "value", value == null ? JSONObject.NULL : value);
            return data;
        } catch (Exception failure) { return error(failure); }
        catch (LinkageError failure) { return error(failure); }
    }
    private static JSONObject status(String name) { JSONObject data = new JSONObject(); put(data, "status", name); return data; }
    private static JSONObject error(Throwable error) { JSONObject data = status("ERROR"); put(data, "type", error.getClass().getSimpleName()); return data; }
    private static void put(JSONObject data, String key, Object value) { try { data.put(key, value); } catch (org.json.JSONException impossible) { throw new IllegalStateException(impossible); } }

    @Override protected void onDestroy() {
        run = "destroyed";
        stopCallback();
        if (web != null) web.destroy();
        worker.shutdownNow();
        super.onDestroy();
    }
}
