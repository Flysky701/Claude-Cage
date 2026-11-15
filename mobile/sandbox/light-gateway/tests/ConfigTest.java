package io.github.leexeo.cage.localcore;

/** Host-only checks: credential preservation and preventing a URI/credential from changing routes. */
public final class ConfigTest {
    private static void require(boolean condition) {
        if (!condition) throw new AssertionError("configuration validation failed");
    }

    private static void reject(String uri) throws Exception {
        try { Upstream.parse(uri); }
        catch (IllegalArgumentException | java.net.URISyntaxException expected) { return; }
        throw new AssertionError("accepted invalid configuration");
    }

    public static void main(String[] args) throws Exception {
        Upstream config = Upstream.parse("socks5://u%3Aser:p%40ss%3A%23%2B%25%20word@proxy.example:1080");
        require(config.user().equals("u:ser"));
        require(config.secret().equals("p@ss:#+% word"));
        require(Upstream.parse("socks5://user:p+word@proxy.example:1080").secret().equals("p+word"));
        require(Upstream.parse("socks5://[2001:db8::1]:1080").host.equals("2001:db8::1"));
        require(Upstream.parse("socks5://127.0.0.1:1080").username == null);
        reject("https://proxy.example:1080");
        reject("socks5://proxy.example");
        reject("socks5://proxy.example:0");
        reject("socks5://proxy.example:65536");
        reject("socks5://user@proxy.example:1080");
        reject("socks5://user:@proxy.example:1080");
        reject("socks5://user:%00@proxy.example:1080");
        reject("socks5://proxy.example:1080/anything");
        reject("socks5://proxy.example:1080?direct=true");
        reject("socks5://proxy.example:1080#fragment");
        reject("socks5://" + new String(new char[256]).replace('\0', 'u') + ":password@proxy.example:1080");

        Upstream injection = new Upstream("proxy.example", 1080, "name", "'\"\\\nlog-file: stdout\n\u2028#");
        String yaml = TunnelConfig.render(injection, "2001:db8::1");
        require(yaml.contains("\\\"\\\\\\u000alog-file: stdout\\u000a\\u2028#"));
        require(!yaml.contains("\nlog-file: stdout"));
        require(yaml.contains("  password: \""));
        require(TunnelConfig.render(new Upstream("proxy.example", 1080, null, null), "192.0.2.1")
                .indexOf("username:") == -1);
        String vless = "mixed-port: 4567\nallow-lan: true\nproxies:\n  - name: cage-upstream\n    type: vless\n"
                + "    server: proxy.example\n    port: 443\n    uuid: private-value\n    tls: true\n    reality-opts:\n"
                + "      public-key: example\n    flow: xtls-rprx-vision\nrules:\n  - MATCH,DIRECT\n";
        String runtime = VlessConfig.render(vless, 30201, "00000000-0000-0000-0000-000000000000");
        require(!runtime.contains("MATCH,DIRECT"));
        require(!runtime.contains("allow-lan: true"));
        require(runtime.contains("reality-opts:\n      public-key: example"));
        require(runtime.contains("rules:\n  - \"MATCH,cage-upstream\"\n  - MATCH,REJECT\n"));
        require(runtime.contains("socks-port: 30201"));
        require(runtime.contains("authentication: ['cage:"));
        require(runtime.contains("mixed-port: 0"));
        require(TunnelConfig.render(config, "192.0.2.1").contains("max-session-count: 128"));
        rejectVless(vless.replace("type: vless", "type: direct"));
        rejectVless(vless.replace("    tls: true", "    skip-cert-verify: true"));
        rejectVless(vless + "proxy-groups:\n  - name: exit\n    type: select\n    proxies: [DIRECT, cage-upstream]\n");
        rejectVless(vless.replace("    tls: true", "    <<: *hidden"));
        rejectVless(vless.replace("    tls: true", "    dialer-proxy: DIRECT"));
        rejectVless(vless.replace("rules:", "  - name: second\n    type: vless\nrules:"));
        System.out.println("Passed: URI validation, complete credentials, IPv6, YAML injection boundaries");
        System.out.println("Passed: VLESS-only import, forced route/REJECT, no direct groups, disabled listeners, preserved Reality");
    }

    private static void rejectVless(String config) throws Exception {
        try { VlessConfig.render(config, 30201, "00000000-0000-0000-0000-000000000000"); }
        catch (java.io.IOException expected) { return; }
        throw new AssertionError("accepted unsafe VLESS configuration");
    }
}
