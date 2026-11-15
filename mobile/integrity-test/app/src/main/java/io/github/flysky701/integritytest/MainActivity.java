package io.github.flysky701.integritytest;

import android.app.Activity;
import android.content.Intent;
import android.graphics.Color;
import android.os.Bundle;
import android.text.InputType;
import android.util.Base64;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;
import com.google.android.play.core.integrity.IntegrityManagerFactory;
import com.google.android.play.core.integrity.IntegrityServiceException;
import com.google.android.play.core.integrity.IntegrityTokenRequest;
import com.google.android.play.core.integrity.StandardIntegrityException;
import com.google.android.play.core.integrity.StandardIntegrityManager;
import org.json.JSONObject;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.security.SecureRandom;
import java.util.ArrayList;
import java.util.List;

/** A diagnostic client for this app's own Play Integrity requests. */
public final class MainActivity extends Activity {
    private static final String BACKEND = "http://127.0.0.1:8787";
    private final List<Button> actions = new ArrayList<>();
    private EditText project;
    private TextView status;
    private JSONObject currentRequest;
    private boolean busy;
    private long requestGeneration;

    @Override public void onCreate(Bundle state) {
        super.onCreate(state);
        LinearLayout body = new LinearLayout(this);
        body.setOrientation(LinearLayout.VERTICAL);
        int pad = (int) (20 * getResources().getDisplayMetrics().density);
        body.setPadding(pad, pad, pad, pad);
        body.setOnApplyWindowInsetsListener((view, insets) -> {
            view.setPadding(pad, pad + insets.getSystemWindowInsetTop(),
                    pad, pad + insets.getSystemWindowInsetBottom());
            return insets;
        });
        ScrollView scroll = new ScrollView(this);
        scroll.setFillViewport(true);
        scroll.addView(body);
        setContentView(scroll);
        TextView title = text(body, "Play Integrity 测试", 26);
        title.setTextColor(Color.rgb(24, 49, 80));
        text(body, "Flysky701 · 自有测试应用\n" + getPackageName(), 14);
        text(body, "Google Cloud 项目编号", 16);
        project = new EditText(this);
        project.setSingleLine(true);
        project.setInputType(InputType.TYPE_CLASS_NUMBER);
        project.setText(getPreferences(0).getString("project", Long.toString(BuildConfig.CLOUD_PROJECT_NUMBER)));
        body.addView(project);
        addButton(body, "标准请求", () -> request("standard"));
        addButton(body, "经典请求", () -> request("classic"));
        addButton(body, "读取判定（USB 连接电脑）", this::decode);
        text(body, "每次点击只发送一次请求。成功取得令牌后，连接本机解码助手可查看真实判定。", 14);
        status = text(body, "准备就绪。\n\n应用识别：未检查\n应用许可：未检查\n设备完整性：未检查", 16);
        status.setTextIsSelectable(true);
        text(body, "此应用只检测自己的包名。令牌成功不等于完整性通过；直接安装版的应用识别或许可可能为未识别、未许可或未评估。", 13);
        if (BuildConfig.DEBUG && getIntent().getBooleanExtra("run_classic", false)) {
            body.post(() -> request("classic"));
        }
    }

    private TextView text(LinearLayout parent, String value, int size) {
        TextView view = new TextView(this);
        view.setText(value);
        view.setTextSize(size);
        view.setPadding(0, 12, 0, 12);
        parent.addView(view);
        return view;
    }

    private void addButton(LinearLayout parent, String title, Runnable action) {
        Button button = new Button(this);
        button.setText(title);
        button.setAllCaps(false);
        button.setOnClickListener(v -> action.run());
        parent.addView(button);
        actions.add(button);
    }

    private void setBusy(boolean value) {
        busy = value;
        project.setEnabled(!value);
        for (Button button : actions) button.setEnabled(!value);
    }

    private void request(String mode) {
        if (busy) return;
        final long number;
        try {
            number = Long.parseLong(project.getText().toString().trim());
            if (number <= 0) throw new NumberFormatException();
        } catch (NumberFormatException error) {
            status.setText("请输入有效的 Google Cloud 项目编号（数字）。");
            return;
        }
        getPreferences(0).edit().putString("project", Long.toString(number)).apply();
        currentRequest = null;
        new File(getFilesDir(), "request.json").delete();
        new File(getFilesDir(), "verdict.json").delete();
        final long generation = ++requestGeneration;
        setBusy(true);
        status.setText("正在请求 " + mode + "…\n项目：" + number + "\n可能需要约一分钟。");
        byte[] bytes = new byte[32];
        new SecureRandom().nextBytes(bytes);
        String binding = Base64.encodeToString(bytes, Base64.URL_SAFE | Base64.NO_WRAP | Base64.NO_PADDING);
        try {
            if (mode.equals("classic")) {
                IntegrityManagerFactory.create(getApplicationContext()).requestIntegrityToken(
                    IntegrityTokenRequest.builder().setCloudProjectNumber(number).setNonce(binding).build())
                    .addOnSuccessListener(this, result -> received(mode, number, binding, result.token(), generation))
                    .addOnFailureListener(this, error -> failed(error, generation));
            } else {
                StandardIntegrityManager manager = IntegrityManagerFactory.createStandard(getApplicationContext());
                manager.prepareIntegrityToken(StandardIntegrityManager.PrepareIntegrityTokenRequest.builder()
                    .setCloudProjectNumber(number).build())
                    .addOnSuccessListener(this, provider -> provider.request(
                        StandardIntegrityManager.StandardIntegrityTokenRequest.builder().setRequestHash(binding).build())
                        .addOnSuccessListener(this, result -> received(mode, number, binding, result.token(), generation))
                        .addOnFailureListener(this, error -> failed(error, generation)))
                    .addOnFailureListener(this, error -> failed(error, generation));
            }
        } catch (Exception error) {
            failed(error, generation);
        }
    }

    private void received(String mode, long number, String binding, String token, long generation) {
        if (generation != requestGeneration || isDestroyed()) return;
        try {
            currentRequest = new JSONObject().put("mode", mode).put("packageName", getPackageName())
                .put("cloudProjectNumber", number).put("binding", binding)
                .put("createdAtMillis", System.currentTimeMillis()).put("integrityToken", token);
            save("request.json", currentRequest);
            status.setText("已取得 " + mode + " 令牌（" + token.length() + " 字符）。\n\n"
                + "应用识别：待解码\n应用许可：待解码\n设备完整性：待解码\n\n"
                + "启动电脑上的解码助手后，点击“读取判定”。令牌仅保存在本应用的私有目录。");
        } catch (Exception error) {
            status.setText("令牌已返回，但保存失败：" + error.getMessage());
        }
        setBusy(false);
    }

    private void failed(Exception error, long generation) {
        if (generation != requestGeneration || isDestroyed()) return;
        Integer code = error instanceof IntegrityServiceException
            ? ((IntegrityServiceException) error).getErrorCode()
            : error instanceof StandardIntegrityException ? ((StandardIntegrityException) error).getErrorCode() : null;
        String message = "请求失败" + (code == null ? "" : "，错误码 " + code) + "\n" + error.getMessage();
        status.setText(message + "\n\n没有取得判定，不能据此判定设备完整性通过或失败。");
        try { save("status.json", new JSONObject().put("errorCode", code).put("message", message)); }
        catch (Exception ignored) { }
        setBusy(false);
    }

    private void save(String name, JSONObject data) throws Exception {
        try (FileOutputStream stream = openFileOutput(name, MODE_PRIVATE)) {
            stream.write(data.toString(2).getBytes(StandardCharsets.UTF_8));
        }
    }

    private void decode() {
        if (currentRequest == null) {
            status.setText("请先生成一次标准或经典请求。");
            return;
        }
        setBusy(true);
        status.setText("正在通过 USB 连接本机解码助手…");
        final JSONObject request = currentRequest;
        new Thread(() -> {
            try {
                HttpURLConnection connection = (HttpURLConnection) new URL(BACKEND + "/decode").openConnection();
                connection.setConnectTimeout(5000);
                connection.setReadTimeout(60000);
                connection.setRequestMethod("POST");
                connection.setRequestProperty("Content-Type", "application/json; charset=utf-8");
                connection.setDoOutput(true);
                byte[] encoded = request.toString().getBytes(StandardCharsets.UTF_8);
                connection.setFixedLengthStreamingMode(encoded.length);
                try {
                    try (java.io.OutputStream output = connection.getOutputStream()) { output.write(encoded); }
                    int code = connection.getResponseCode();
                    InputStream input = code < 400 ? connection.getInputStream() : connection.getErrorStream();
                    if (input == null) throw new java.io.IOException("助手返回 HTTP " + code);
                    ByteArrayOutputStream result = new ByteArrayOutputStream();
                    try (InputStream stream = input) {
                        byte[] chunk = new byte[4096];
                        int read;
                        while ((read = stream.read(chunk)) != -1) {
                            if (result.size() + read > 262144) throw new java.io.IOException("响应过大");
                            result.write(chunk, 0, read);
                        }
                    }
                    JSONObject response = new JSONObject(result.toString("UTF-8"));
                    if (code >= 400) throw new java.io.IOException(response.optString("error", "HTTP " + code));
                    save("verdict.json", response);
                    String formatted = response.toString(2);
                    runOnUiThread(() -> { if (!isDestroyed()) { status.setText(formatted); setBusy(false); } });
                } finally { connection.disconnect(); }
            } catch (Exception error) {
                runOnUiThread(() -> {
                    if (!isDestroyed()) {
                        status.setText("尚未读到判定：" + error.getMessage()
                            + "\n\n请在电脑启动解码助手并保持 USB 调试连接。令牌已保存在应用私有目录。");
                        setBusy(false);
                    }
                });
            }
        }, "integrity-decode").start();
    }
}
