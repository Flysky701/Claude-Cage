package io.github.leexeo.cage.integrityprobe;

import android.app.Activity;
import android.content.ComponentName;
import android.content.Intent;
import android.content.ServiceConnection;
import android.os.Bundle;
import android.os.Handler;
import android.os.IBinder;
import android.util.Log;
import android.widget.LinearLayout;
import android.widget.TextView;
import java.util.ArrayList;
import java.util.List;

/** Exercises the guest's normal bindService path without an account or a token request. */
public final class ProbeActivity extends Activity {
    final List<ServiceConnection> bindings = new ArrayList<>();
    final Handler handler = new Handler();
    LinearLayout content;

    @Override public void onCreate(Bundle state) {
        super.onCreate(state);
        content = new LinearLayout(this);
        content.setOrientation(LinearLayout.VERTICAL);
        content.setPadding(24, 48, 24, 24);
        setContentView(content);
        TextView note = new TextView(this);
        note.setText("检查服务路由与接口连接。此检查不请求验证令牌，也不代表 Basic、Device 或 Strong 通过。");
        content.addView(note);
        check("classic", "com.google.android.play.core.integrityservice.BIND_INTEGRITY_SERVICE",
            "com.google.android.play.core.integrity.protocol.IIntegrityService");
        check("standard", "com.google.android.play.core.expressintegrityservice.BIND_EXPRESS_INTEGRITY_SERVICE",
            "com.google.android.play.core.integrity.protocol.IExpressIntegrityService");
    }

    void check(String mode, String action, String descriptor) {
        TextView status = new TextView(this);
        status.setText(mode + "：连接中");
        content.addView(status);
        ServiceConnection connection = new ServiceConnection() {
            boolean complete;
            void report(String result) {
                if (complete) return;
                complete = true;
                status.setText(mode + "：" + result);
                Log.i("CageIntegrityProbe", "mode=" + mode + " result=" + result);
            }
            @Override public void onServiceConnected(ComponentName name, IBinder service) {
                try {
                    boolean target = "com.android.vending.mgc".equals(name.getPackageName());
                    boolean protocol = descriptor.equals(service.getInterfaceDescriptor());
                    report(target && protocol ? "connected_companion" : "unexpected_service");
                } catch (Exception e) { report("descriptor_failed"); }
            }
            @Override public void onServiceDisconnected(ComponentName name) { report("disconnected"); }
            @Override public void onNullBinding(ComponentName name) { report("null_binding"); }
            @Override public void onBindingDied(ComponentName name) { report("binding_died"); }
        };
        try {
            if (bindService(new Intent(action).setPackage("com.android.vending"), connection, BIND_AUTO_CREATE)) {
                bindings.add(connection);
                handler.postDelayed(() -> {
                    if (status.getText().toString().endsWith("连接中")) {
                        status.setText(mode + "：timeout");
                        Log.i("CageIntegrityProbe", "mode=" + mode + " result=timeout");
                    }
                }, 20000L);
            } else {
                status.setText(mode + "：bind_rejected");
                Log.i("CageIntegrityProbe", "mode=" + mode + " result=bind_rejected");
            }
        } catch (Exception e) {
            status.setText(mode + "：" + e.getClass().getSimpleName());
            Log.i("CageIntegrityProbe", "mode=" + mode + " result=" + e.getClass().getSimpleName());
        }
    }

    @Override public void onDestroy() {
        handler.removeCallbacksAndMessages(null);
        for (ServiceConnection connection : bindings) {
            try { unbindService(connection); } catch (RuntimeException ignored) { }
        }
        super.onDestroy();
    }
}
