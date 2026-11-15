package io.github.leexeo.cage.localcore;

import java.net.URI;
import java.net.URISyntaxException;
import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;

/** Immutable, validated configuration. Never render this object or its URI in logs. */
final class Upstream {
    final String host;
    final int port;
    final byte[] username, password;
    private final String userText, passwordText;

    Upstream(String host, int port, String user, String password) {
        if (host == null || host.length() == 0 || host.length() > 253 || port < 1 || port > 65535
                || !host.matches("[A-Za-z0-9.:_-]+") || host.contains("%"))
            throw new IllegalArgumentException("invalid upstream");
        if ((user == null) != (password == null)) throw new IllegalArgumentException("incomplete credentials");
        if (user != null && (user.indexOf('\0') >= 0 || password.indexOf('\0') >= 0))
            throw new IllegalArgumentException("NUL is not supported by native credentials");
        this.host = host;
        this.port = port;
        userText = user;
        passwordText = password;
        username = user == null ? null : user.getBytes(StandardCharsets.UTF_8);
        this.password = password == null ? null : password.getBytes(StandardCharsets.UTF_8);
        if (username != null && (username.length < 1 || username.length > 255
                || this.password.length < 1 || this.password.length > 255))
            throw new IllegalArgumentException("invalid credential length");
    }

    static Upstream parse(String text) throws URISyntaxException {
        URI uri = new URI(text.trim());
        if (!"socks5".equalsIgnoreCase(uri.getScheme()) || uri.getHost() == null
                || (uri.getRawPath() != null && !uri.getRawPath().isEmpty())
                || uri.getRawQuery() != null || uri.getRawFragment() != null)
            throw new IllegalArgumentException("SOCKS5 URI required");
        String host = uri.getHost();
        if (host.startsWith("[") && host.endsWith("]")) host = host.substring(1, host.length() - 1);
        String user = null, password = null;
        String info = uri.getRawUserInfo();
        if (info != null) {
            int colon = info.indexOf(':');
            if (colon < 0) throw new IllegalArgumentException("both credentials required");
            user = decode(info.substring(0, colon));
            password = decode(info.substring(colon + 1));
        }
        return new Upstream(host, uri.getPort(), user, password);
    }

    private static String decode(String text) {
        try { return URLDecoder.decode(text.replace("+", "%2B"), "UTF-8"); }
        catch (java.io.UnsupportedEncodingException impossible) { throw new AssertionError(impossible); }
    }

    String user() { return userText; }
    String secret() { return passwordText; }
}
