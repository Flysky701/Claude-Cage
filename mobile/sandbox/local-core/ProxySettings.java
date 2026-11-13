package io.github.leexeo.cage.localcore;

import org.json.JSONObject;
import java.io.File;
import java.io.IOException;
import java.net.URI;
import java.net.URISyntaxException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.StandardCopyOption;
import java.util.Locale;

final class ProxySettings {
    static File file(File directory) { return new File(directory, "upstream.yaml"); }

    static String configuration(String address) throws URISyntaxException {
        URI uri = new URI(address.trim());
        String scheme = uri.getScheme() == null ? "" : uri.getScheme().toLowerCase(Locale.ROOT);
        if (!(scheme.equals("socks5") || scheme.equals("socks5h")) || uri.getHost() == null
                || uri.getPort() < 1 || uri.getPort() > 65535 || uri.getRawQuery() != null
                || uri.getRawFragment() != null || !(uri.getRawPath().isEmpty() || uri.getRawPath().equals("/"))) {
            throw new IllegalArgumentException("Invalid SOCKS5 endpoint");
        }
        String host = uri.getHost();
        if (host.startsWith("[")) host = host.substring(1, host.length() - 1);
        StringBuilder route = new StringBuilder("proxies:\n  - name: cage-local\n    type: socks5\n    server: ")
                .append(JSONObject.quote(host)).append("\n    port: ").append(uri.getPort()).append('\n');
        String raw = uri.getRawUserInfo();
        if (raw != null) {
            int split = raw.indexOf(':');
            if (split < 1) throw new IllegalArgumentException("Expected proxy credentials");
            // Split before decoding so an encoded colon belongs to the credential itself.
            String name = URI.create("socks5://" + raw.substring(0, split) + "@host").getUserInfo();
            String password = URI.create("socks5://" + raw.substring(split + 1) + "@host").getUserInfo();
            if (password == null || password.isEmpty()) throw new IllegalArgumentException("Expected password");
            route.append("    username: ").append(JSONObject.quote(name))
                    .append("\n    password: ").append(JSONObject.quote(password)).append('\n');
        }
        return route.append("    udp: true\nrules:\n  - MATCH,cage-local\n").toString();
    }

    static String runtimeRoute(File directory) throws IOException {
        StringBuilder result = new StringBuilder();
        boolean inRules = false, guarded = false;
        for (String line : Files.readAllLines(file(directory).toPath(), StandardCharsets.UTF_8)) {
            result.append(line).append('\n');
            String value = line.trim();
            if (value.isEmpty() || value.startsWith("#")) continue;
            if (line.equals("rules:")) { inRules = true; continue; }
            if (!inRules) continue;
            if (!value.matches("(?i)-\\s*[\"']?MATCH,[^,]+[\"']?"))
                throw new IOException("Expected a single catch-all upstream rule");
            // Mihomo skips a proxy that cannot carry UDP. Terminate matching before its implicit DIRECT fallback.
            result.append(line.substring(0, line.indexOf('-'))).append("- MATCH,REJECT\n");
            inRules = false;
            guarded = true;
        }
        if (!guarded) throw new IOException("Missing upstream rule");
        return result.toString();
    }

    static void save(File directory, String configuration) throws IOException {
        File temp = File.createTempFile("upstream-", ".tmp", directory);
        try {
            Files.write(temp.toPath(), configuration.getBytes(StandardCharsets.UTF_8));
            Files.move(temp.toPath(), file(directory).toPath(), StandardCopyOption.ATOMIC_MOVE,
                    StandardCopyOption.REPLACE_EXISTING);
        } finally {
            temp.delete();
        }
    }
}
