package io.github.leexeo.cage.space;

import android.app.Activity;
import android.util.Log;
import android.widget.TextView;
import java.net.HttpURLConnection;
import java.net.URL;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;

/** Fixed, unauthenticated HTTPS checks from the same app UID; stores no IP or response body. */
public final class DemoNetworkCheck {
    public static void start(Activity activity, TextView status, Runnable finished) {
        new Thread(() -> {
            String expected = activity.getIntent().getStringExtra("expected_exit_sha256");
            if (expected != null && !expected.matches("[0-9a-f]{64}")) expected = null;
            String exit = exitDigest();
            boolean domain = exit != null;
            Log.i("CageDemo", "network_check domain=" + domain);
            final Boolean matches = expected == null ? null : expected.equals(exit);
            if (matches != null) Log.i("CageDemo", "network_check expected_exit_match=" + matches);
            boolean numeric = check("numeric_ipv4", "https://1.1.1.1/cdn-cgi/trace");
            activity.runOnUiThread(() -> {
                if (!activity.isDestroyed()) status.setText("域名连接：" + (domain ? "成功" : "未连接")
                        + "\n数字 IPv4 连接：" + (numeric ? "成功" : "未连接")
                        + (matches == null ? "" : "\n预期出口：" + (matches ? "匹配" : "未匹配"))
                        + "\n此结果只代表本次连接。网关停止后，两项都应未连接；重新启动后应恢复。");
                finished.run();
            });
        }, "Cage-network-check").start();
    }

    private static String exitDigest() {
        HttpURLConnection connection = null;
        try {
            connection = (HttpURLConnection) new URL("https://ipv4.icanhazip.com").openConnection();
            connection.setConnectTimeout(5000); connection.setReadTimeout(5000);
            connection.setUseCaches(false); connection.setInstanceFollowRedirects(false);
            connection.setRequestProperty("Connection", "close");
            if (connection.getResponseCode() != 200) return null;
            byte[] body = new byte[64]; int length = 0;
            try (InputStream input = connection.getInputStream()) {
                for (int read; length < body.length && (read = input.read(body, length, body.length - length)) != -1;) length += read;
            }
            if (length == body.length) return null;
            String address = new String(body, 0, length, StandardCharsets.US_ASCII).trim();
            if (!address.matches("(?:[0-9]{1,3}\\.){3}[0-9]{1,3}")) return null;
            for (String octet : address.split("\\.")) if (Integer.parseInt(octet) > 255) return null;
            byte[] digest = MessageDigest.getInstance("SHA-256").digest(address.getBytes(StandardCharsets.US_ASCII));
            StringBuilder hex = new StringBuilder(64);
            for (byte value : digest) hex.append(String.format(java.util.Locale.ROOT, "%02x", value & 255));
            return hex.toString();
        } catch (Exception unavailable) { return null; }
        finally { if (connection != null) connection.disconnect(); }
    }

    private static boolean check(String label, String address) {
        HttpURLConnection connection = null;
        boolean connected = false;
        try {
            connection = (HttpURLConnection) new URL(address).openConnection();
            connection.setConnectTimeout(5000); connection.setReadTimeout(5000);
            connection.setUseCaches(false); connection.setInstanceFollowRedirects(false);
            connection.setRequestMethod("HEAD"); connection.setRequestProperty("Connection", "close");
            int status = connection.getResponseCode();
            connected = status >= 200 && status < 400;
        } catch (java.io.IOException blocked) { /* Only connection status is reported. */ }
        finally { if (connection != null) connection.disconnect(); }
        Log.i("CageDemo", "network_check " + label + "=" + connected);
        return connected;
    }
}
