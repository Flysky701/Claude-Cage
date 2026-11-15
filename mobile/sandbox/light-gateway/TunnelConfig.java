package io.github.leexeo.cage.localcore;

/** HEV's public YAML format; no shell, script paths, direct route or plaintext traffic logs. */
final class TunnelConfig {
    static final String IPV4 = "198.18.0.1", IPV6 = "fc00::1", DNS = "198.18.0.2";

    static String render(Upstream upstream, String numericAddress) {
        if (numericAddress == null || !numericAddress.matches("[0-9a-fA-F:.]+"))
            throw new IllegalArgumentException("numeric upstream required");
        String yaml = "tunnel:\n  name: cage\n  mtu: 1500\n  ipv4: " + IPV4
                + "\n  ipv6: '" + IPV6 + "'\n  icmp: 'off'\nsocks5:\n  address: "
                + quote(numericAddress) + "\n  port: " + upstream.port + "\n  udp: 'udp'\n  pipeline: false\n";
        if (upstream.username != null)
            yaml += "  username: " + quote(upstream.user()) + "\n  password: " + quote(upstream.secret()) + "\n";
        return yaml + "mapdns:\n  address: " + DNS + "\n  port: 53\n  network: 100.64.0.0\n"
                + "  netmask: 255.192.0.0\n  cache-size: 2048\nmisc:\n  max-session-count: 128\n"
                + "  connect-timeout: 10000\n  tcp-read-write-timeout: 120000\n  udp-read-write-timeout: 120000\n"
                // Keep HEV 2.19.3's default: UDP batches also allocate nested arrays on this stack.
                + "  task-stack-size: 86016\n  tcp-buffer-size: 8192\n  log-file: null\n  log-level: error\n";
    }

    private static String quote(String text) {
        StringBuilder yaml = new StringBuilder("\"");
        for (int i = 0; i < text.length(); i++) {
            char value = text.charAt(i);
            if (value == '\\' || value == '"') yaml.append('\\').append(value);
            else if (value < 0x20 || value == 0x7f || value == 0x85 || value == 0x2028 || value == 0x2029)
                yaml.append(String.format(java.util.Locale.ROOT, "\\u%04x", (int) value));
            else yaml.append(value);
        }
        return yaml.append('"').toString();
    }
}
