package io.github.leexeo.cage.localcore;

import java.io.IOException;
import java.util.*;
import java.util.regex.*;

/** Narrow import of the existing single-node block YAML, never a general executable core config. */
final class VlessConfig {
    private static final Pattern SECTION = Pattern.compile("^([A-Za-z0-9_-]+)\\s*:(.*)$");
    private static final Pattern FIELD = Pattern.compile("^(name|type)\\s*:\\s*(.*)$");

    static String render(String source, int port, String password) throws IOException {
        if (source == null || source.length() > 262144 || port < 1 || port > 65535
                || !password.matches("[0-9a-f-]{36}")) throw new IOException("invalid private config");
        Map<String, List<String>> sections = new HashMap<>();
        String section = null;
        for (String original : source.replace("\r\n", "\n").replace("\uFEFF", "").split("\n", -1)) {
            if (original.indexOf('\t') >= 0 || original.indexOf('\0') >= 0) throw new IOException("unsupported YAML");
            String trimmed = original.trim();
            if (trimmed.isEmpty() || trimmed.startsWith("#") || trimmed.equals("---")) continue;
            Matcher header = SECTION.matcher(original);
            if (header.matches()) {
                section = header.group(1);
                if (section.equals("proxies") || section.equals("proxy-groups")) {
                    if (sections.containsKey(section) || !header.group(2).trim().isEmpty())
                        throw new IOException("block YAML required");
                    sections.put(section, new ArrayList<>(Collections.singletonList(section + ":")));
                }
                continue;
            }
            if (original.charAt(0) != ' ' && original.charAt(0) != '-') throw new IOException("unsupported YAML");
            if (section != null && sections.containsKey(section)) {
                // No aliases, merges or custom YAML types may import hidden global/listener fields.
                if (trimmed.startsWith("<<:") || trimmed.startsWith("!")
                        || trimmed.matches(".*(?:^|[ :\\[,])[*&!][A-Za-z0-9_-]+.*"))
                    throw new IOException("YAML aliases not accepted");
                if (trimmed.matches("(?i)(?:-\\s*)?dialer-proxy\\s*:.*")
                        || trimmed.matches("(?i)skip-cert-verify\\s*:\\s*['\"]?true['\"]?(?:\\s*#.*)?"))
                    throw new IOException("unsafe proxy option");
                sections.get(section).add(original);
            }
        }
        List<String> proxies = sections.get("proxies");
        if (proxies == null) throw new IOException("missing proxy");
        int entryIndent = Integer.MAX_VALUE;
        for (String line : proxies) if (line.trim().startsWith("- ")) entryIndent = Math.min(entryIndent, indent(line));
        if (entryIndent == Integer.MAX_VALUE) throw new IOException("missing proxy");
        int entries = 0;
        String name = null, type = null;
        for (String line : proxies) {
            String field = null;
            if (indent(line) == entryIndent && line.trim().startsWith("- ")) {
                entries++; field = line.trim().substring(2).trim();
            } else if (indent(line) == entryIndent + 2) field = line.trim();
            if (field == null) continue;
            Matcher match = FIELD.matcher(field);
            if (!match.matches()) continue;
            String value = scalar(match.group(2));
            if (match.group(1).equals("name")) {
                if (name != null) throw new IOException("duplicate proxy name");
                name = value;
            } else {
                if (type != null) throw new IOException("duplicate proxy type");
                type = value;
            }
        }
        if (entries != 1 || !"vless".equalsIgnoreCase(type) || name == null || name.length() > 128
                || !name.matches("[\\p{L}\\p{N}_. +()\\[\\]-]+")
                || name.equalsIgnoreCase("DIRECT") || name.equalsIgnoreCase("REJECT"))
            throw new IOException("one named VLESS proxy required");
        List<String> groups = sections.get("proxy-groups");
        if (groups != null) {
            for (String line : groups)
                if (Pattern.compile("(?i)(?:^|[^A-Za-z0-9_-])(DIRECT|COMPATIBLE)(?:$|[^A-Za-z0-9_-])").matcher(line).find())
                    throw new IOException("group direct option denied");
        }
        StringBuilder runtime = new StringBuilder("mode: rule\nallow-lan: false\nbind-address: 127.0.0.1\n")
                .append("port: 0\nmixed-port: 0\nsocks-port: ").append(port)
                .append("\nredir-port: 0\ntproxy-port: 0\nauthentication: ['cage:").append(password)
                .append("']\nskip-auth-prefixes: []\nlisteners: []\nexternal-controller: ''\n")
                .append("external-controller-unix: ''\nexternal-controller-pipe: ''\n")
                .append("tun: {enable: false}\ndns: {enable: false}\nipv6: true\nlog-level: silent\n")
                .append("geo-auto-update: false\nprofile: {store-selected: false, store-fake-ip: false}\nfind-process-mode: off\n");
        for (String line : proxies) runtime.append(line).append('\n');
        if (groups != null) for (String line : groups) runtime.append(line).append('\n');
        // Select the actual sole VLESS node, never a group that can choose DIRECT.
        // Unsupported UDP must reach REJECT rather than Mihomo's implicit DIRECT fallback.
        runtime.append("rules:\n  - \"MATCH,").append(name).append("\"\n  - MATCH,REJECT\n");
        return runtime.toString();
    }

    private static int indent(String line) {
        int spaces = 0; while (spaces < line.length() && line.charAt(spaces) == ' ') spaces++; return spaces;
    }

    private static String scalar(String value) throws IOException {
        value = value.trim();
        if (value.startsWith("'") && value.endsWith("'")) return value.substring(1, value.length() - 1).replace("''", "'");
        if (value.startsWith("\"") && value.endsWith("\"")) {
            value = value.substring(1, value.length() - 1);
            if (value.indexOf('\\') >= 0 || value.indexOf('"') >= 0) throw new IOException("unsupported proxy label");
            return value;
        }
        int comment = value.indexOf(" #");
        return comment < 0 ? value : value.substring(0, comment).trim();
    }
}
