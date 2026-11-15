package io.github.leexeo.cage.localcore;

import android.content.Context;
import android.util.AtomicFile;
import org.json.JSONObject;
import java.io.*;
import java.nio.charset.StandardCharsets;

final class Settings {
    static File file(Context context) { return new File(context.getFilesDir(), "upstream.json"); }
    static File vlessFile(Context context) { return new File(context.getFilesDir(), "upstream-vless.yaml"); }

    static boolean configured(Context context) { return file(context).isFile() || vlessFile(context).isFile(); }

    static String loadVless(Context context) throws IOException {
        try (InputStream input = new FileInputStream(vlessFile(context)); ByteArrayOutputStream bytes = new ByteArrayOutputStream()) {
            byte[] buffer = new byte[4096];
            for (int size; (size = input.read(buffer)) != -1;) {
                if (bytes.size() + size > 262144) throw new IOException("oversized config");
                bytes.write(buffer, 0, size);
            }
            return new String(bytes.toByteArray(), StandardCharsets.UTF_8);
        }
    }

    static Upstream load(Context context) throws Exception {
        AtomicFile file = new AtomicFile(file(context));
        // Reject unreasonable ADB input before allocating its full contents.
        try (InputStream input = file.openRead(); ByteArrayOutputStream bytes = new ByteArrayOutputStream()) {
            byte[] buffer = new byte[1024];
            for (int size; (size = input.read(buffer)) != -1;) {
                if (bytes.size() + size > 8192) throw new IOException("oversized config");
                bytes.write(buffer, 0, size);
            }
            JSONObject json = new JSONObject(new String(bytes.toByteArray(), StandardCharsets.UTF_8));
            String user = optionalString(json, "username");
            String password = optionalString(json, "password");
            Object port = json.get("port");
            if (!(port instanceof Integer)) throw new IOException("integer port required");
            Object host = json.get("host");
            if (!(host instanceof String)) throw new IOException("string host required");
            return new Upstream((String) host, (Integer) port, user, password);
        }
    }

    private static String optionalString(JSONObject json, String key) throws Exception {
        if (!json.has(key) || json.isNull(key)) return null;
        Object value = json.get(key);
        if (!(value instanceof String)) throw new IOException("string credential required");
        return (String) value;
    }

    static void save(Context context, Upstream upstream) throws Exception {
        JSONObject json = new JSONObject();
        json.put("host", upstream.host);
        json.put("port", upstream.port);
        if (upstream.username != null) {
            json.put("username", upstream.user());
            json.put("password", upstream.secret());
        }
        AtomicFile file = new AtomicFile(file(context));
        FileOutputStream output = file.startWrite();
        try {
            output.write((json.toString() + "\n").getBytes(StandardCharsets.UTF_8));
            file.finishWrite(output);
        } catch (Exception failure) { file.failWrite(output); throw failure; }
    }
}
