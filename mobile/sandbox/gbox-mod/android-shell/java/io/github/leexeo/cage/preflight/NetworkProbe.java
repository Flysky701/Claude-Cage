package io.github.leexeo.cage.preflight;

import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.InetAddress;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import org.json.JSONObject;

/** Fixed requests only, no account, cookie, arbitrary target or user headers. */
public final class NetworkProbe {
    private NetworkProbe() {}

    public static JSONObject measure() {
        JSONObject out = new JSONObject();
        try {
            String ip = null;
            String[] endpoints = {"https://ipv4.icanhazip.com/", "https://api.ipify.org/"};
            for (String endpoint : endpoints) {
                try {
                    String candidate = get(endpoint, 256).trim();
                    if (publicIpv4(candidate)) { ip = candidate; break; }
                } catch (Exception ignored) { }
            }
            if (ip == null) { out.put("status", "UNAVAILABLE"); return out; }
            out.put("status", "OK").put("ip", ip);
            try {
                JSONObject location = new JSONObject(get("https://ipwho.is/" + ip
                    + "?fields=success,ip,country_code,timezone.id", 4096));
                if (location.optBoolean("success") && ip.equals(location.optString("ip"))) {
                    String country = location.optString("country_code");
                    String zone = location.optJSONObject("timezone") == null ? ""
                        : location.getJSONObject("timezone").optString("id");
                    if (country.matches("[A-Z]{2}")) out.put("country", country);
                    if (zone.length() < 80) out.put("timezone", zone);
                }
            } catch (Exception ignored) { }
        } catch (Exception ignored) { }
        return out;
    }

    private static String get(String endpoint, int limit) throws Exception {
        HttpURLConnection connection = (HttpURLConnection) new URL(endpoint).openConnection();
        connection.setConnectTimeout(3500);
        connection.setReadTimeout(3500);
        connection.setInstanceFollowRedirects(false);
        connection.setUseCaches(false);
        connection.setRequestProperty("User-Agent", "Cage-Android-Check");
        connection.setRequestProperty("Accept", "text/plain, application/json");
        try {
            if (connection.getResponseCode() != 200) throw new java.io.IOException("HTTP status");
            try (InputStream in = connection.getInputStream(); ByteArrayOutputStream out = new ByteArrayOutputStream()) {
                byte[] bytes = new byte[512];
                for (int n; (n = in.read(bytes)) >= 0;) {
                    if (out.size() + n > limit) throw new java.io.IOException("Response too large");
                    out.write(bytes, 0, n);
                }
                return new String(out.toByteArray(), StandardCharsets.UTF_8);
            }
        } finally { connection.disconnect(); }
    }

    public static boolean publicIpv4(String value) {
        if (value == null || !value.matches("[0-9]{1,3}(\\.[0-9]{1,3}){3}")) return false;
        String[] parts = value.split("\\.");
        for (String part : parts) if (Integer.parseInt(part) > 255) return false;
        try {
            InetAddress ip = InetAddress.getByName(value);
            int first = Integer.parseInt(parts[0]), second = Integer.parseInt(parts[1]);
            return !ip.isAnyLocalAddress() && !ip.isLoopbackAddress() && !ip.isSiteLocalAddress()
                && !ip.isLinkLocalAddress() && !ip.isMulticastAddress() && first < 224
                && first != 0 && !(first == 100 && second >= 64 && second <= 127)
                && !(first == 192 && second == 0) && !(first == 198 && (second == 18 || second == 19));
        } catch (Exception ignored) { return false; }
    }
}
