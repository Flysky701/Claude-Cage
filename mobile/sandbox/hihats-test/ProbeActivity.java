package io.github.flysky701.hihatsprobe;

import android.app.Activity;
import android.content.*;
import android.os.*;
import android.webkit.*;
import android.widget.*;
import org.json.JSONObject;
import java.io.FileOutputStream;

/** Local fixture: no accounts, device identifiers, or external network requests. */
public class ProbeActivity extends Activity {
    private final JSONObject result = new JSONObject();
    private TextView status;
    private WebView web;
    private final ServiceConnection connection = new ServiceConnection() {
        public void onServiceConnected(ComponentName name, IBinder binder) {
            try {
                Parcel request = Parcel.obtain(), reply = Parcel.obtain();
                try {
                    request.writeInterfaceToken("cage.hihats.probe");
                    binder.transact(1, request, reply, 0);
                    mark("remote_service", "HIHATS_SERVICE_OK".equals(reply.readString()));
                } finally { request.recycle(); reply.recycle(); }
            } catch (Throwable e) { mark("remote_service_error", e.getClass().getSimpleName()); }
        }
        public void onServiceDisconnected(ComponentName name) { }
    };

    @Override public void onCreate(Bundle state) {
        super.onCreate(state);
        LinearLayout layout = new LinearLayout(this);
        layout.setOrientation(LinearLayout.VERTICAL);
        status = new TextView(this);
        status.setTextSize(18);
        status.setPadding(24, 24, 24, 24);
        layout.addView(status);
        setContentView(layout);
        mark("activity", true);
        SharedPreferences prefs = getSharedPreferences("probe", MODE_PRIVATE);
        int count = prefs.getInt("launches", 0) + 1;
        mark("storage_commit", prefs.edit().putInt("launches", count).commit());
        mark("launches", count);
        mark("bind_requested", bindService(new Intent(this, ProbeService.class), connection, BIND_AUTO_CREATE));
        try (android.database.Cursor cursor = getContentResolver().query(android.net.Uri.parse("content://io.github.flysky701.hihatsprobe.data/test"), null, null, null, null)) {
            mark("remote_provider", cursor != null && cursor.moveToFirst() && "HIHATS_PROVIDER_OK".equals(cursor.getString(0)));
        } catch (Throwable e) { mark("remote_provider_error", e.getClass().getSimpleName()); }
        try {
            web = new WebView(this);
            layout.addView(web, new LinearLayout.LayoutParams(-1, 0, 1));
            web.getSettings().setJavaScriptEnabled(true);
            web.setWebViewClient(new WebViewClient() {
                @Override public void onPageFinished(WebView view, String url) {
                    view.evaluateJavascript("document.title", value -> mark("webview_javascript", "\"HIHATS_WEBVIEW_OK\"".equals(value)));
                }
                @Override public boolean onRenderProcessGone(WebView view, RenderProcessGoneDetail detail) {
                    mark("renderer_gone", true); view.destroy(); return true;
                }
            });
            web.loadDataWithBaseURL("https://probe.invalid/", "<html><body><h2>Local WebView probe</h2><script>document.title='HIHATS_WEBVIEW_OK';document.body.append('JavaScript OK');</script></body></html>", "text/html", "UTF-8", null);
            mark("webview_created", true);
        } catch (Throwable e) { mark("webview_error", e.getClass().getSimpleName()); }
    }

    private void mark(String name, Object value) {
        try {
            result.put(name, value);
            String json = result.toString(2);
            status.setText(json);
            try (FileOutputStream out = openFileOutput("result.json", MODE_PRIVATE)) { out.write(json.getBytes("UTF-8")); }
        } catch (Exception e) { status.setText("Report error: " + e.getClass().getSimpleName()); }
    }
}
