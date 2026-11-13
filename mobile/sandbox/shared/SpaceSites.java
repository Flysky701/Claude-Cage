package io.github.leexeo.cage.space;

import java.util.Locale;

/** HTTPS domains used by the space apps. No arbitrary IP addresses or ports are accepted. */
public final class SpaceSites {
    private static final String[] DOMAINS = {
            "google.com", "googleapis.com", "gstatic.com", "googleusercontent.com", "gvt1.com",
            "ggpht.com", "anthropic.com", "claude.ai", "claude.com", "claudeusercontent.com"
    };

    public static boolean allows(String host) {
        if (host == null || host.length() > 253) return false;
        String name = host.toLowerCase(Locale.ROOT);
        // Labels must form a DNS name before it can be used in a CONNECT header or SOCKS request.
        if (!name.matches("[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?(?:\\.[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?)+")) return false;
        for (String domain : DOMAINS) {
            if (name.equals(domain) || name.endsWith("." + domain)) return true;
        }
        return false;
    }
}
