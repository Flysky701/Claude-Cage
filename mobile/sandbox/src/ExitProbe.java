package io.github.leexeo.cage.sandbox;

import android.util.Patterns;
import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.net.Proxy;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.util.UUID;
import javax.net.ssl.HttpsURLConnection;

final class ExitProbe {
    static final String[] LABELS = {"域名 / IPv4", "IPv4 地址", "IPv6 地址"};
    private static final String[] URLS = {"https://ipv4.icanhazip.com/",
            "https://1.1.1.1/cdn-cgi/trace", "https://[2606:4700:4700::1111]/cdn-cgi/trace"};

    static String run(int index) {
        HttpsURLConnection connection = null;
        try {
            URL address = new URL(URLS[index] + "?cage=" + UUID.randomUUID());
            // Test the path available to native apps independently of optional HTTP proxy hints.
            connection = (HttpsURLConnection)address.openConnection(Proxy.NO_PROXY);
            connection.setConnectTimeout(5000);
            connection.setReadTimeout(5000);
            connection.setUseCaches(false);
            connection.setInstanceFollowRedirects(false);
            connection.setRequestProperty("Cache-Control", "no-store");
            connection.setRequestProperty("Connection", "close");
            int status = connection.getResponseCode();
            if (status != 200) return "已连至公网 · HTTP " + status;
            ByteArrayOutputStream bytes = new ByteArrayOutputStream();
            try (InputStream in = connection.getInputStream()) {
                byte[] buffer = new byte[512];
                int count;
                while (bytes.size() <= 4096 && (count = in.read(buffer)) != -1) bytes.write(buffer, 0, count);
            }
            String body = bytes.toString(StandardCharsets.UTF_8.name()).trim();
            if (bytes.size() <= 4096) {
                String value = index == 0 ? body : "";
                if (index != 0) for (String line : body.split("\n")) {
                    if (line.startsWith("ip=")) value = line.substring(3).trim();
                }
                if (Patterns.IP_ADDRESS.matcher(value).matches()) return value;
            }
            return "已连至公网 · 未取得 IP";
        } catch (java.net.SocketTimeoutException e) { return "连接超时"; }
        catch (java.net.UnknownHostException e) { return "域名解析失败"; }
        catch (javax.net.ssl.SSLException e) { return "TLS 未完成"; }
        catch (java.io.IOException | SecurityException e) { return "连接失败"; }
        finally { if (connection != null) connection.disconnect(); }
    }
    private ExitProbe() {}
}
