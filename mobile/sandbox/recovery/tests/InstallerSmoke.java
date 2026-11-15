package io.github.leexeo.cage.test;

import android.app.Instrumentation;
import android.app.PendingIntent;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.pm.PackageInstaller;
import android.os.Bundle;
import android.os.Handler;
import android.os.IBinder;
import android.os.Looper;
import java.io.File;
import java.io.InputStream;
import java.io.OutputStream;
import java.lang.reflect.Constructor;
import java.lang.reflect.Field;
import java.lang.reflect.Method;
import java.util.Arrays;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;

/** A separately signed instrumentation APK; never shipped in the space application. */
public final class InstallerSmoke extends Instrumentation {
    private boolean gatewayOnly;
    @Override public void onCreate(Bundle arguments) { super.onCreate(arguments); gatewayOnly = arguments != null && "true".equals(arguments.getString("gatewayOnly")); start(); }

    private static Object get(Object object, String name) throws Exception {
        Field field = object.getClass().getDeclaredField(name);
        field.setAccessible(true);
        return field.get(object);
    }

    private static void require(boolean value, String message) {
        if (!value) throw new AssertionError(message);
    }

    @Override public void onStart() {
        Bundle result = new Bundle();
        Context context = getTargetContext();
        try {
            Class<?> gateway = Class.forName("io.github.leexeo.cage.space.SharedGateway");
            result.putBoolean("gatewayProtected", (Boolean) gateway.getMethod("ready", Context.class).invoke(null, context));
            if (gatewayOnly) {
                require(result.getBoolean("gatewayProtected"), "Gateway protection required");
                result.putString("result", "PASS"); finish(-1, result); return;
            }
            Class<?> engineClass = Class.forName("io.github.leexeo.cage.space.GuestInstaller$Engine");
            Constructor<?> constructor = engineClass.getDeclaredConstructor(Context.class, File.class);
            constructor.setAccessible(true);
            Object engine = constructor.newInstance(context, new File(context.getFilesDir(), "installer-smoke"));
            IBinder service = (IBinder) get(engine, "service");
            Class<?> api = Class.forName("android.content.pm.IPackageInstaller");
            Object iface = Class.forName(api.getName() + "$Stub").getMethod("asInterface", IBinder.class).invoke(null, service);
            PackageInstaller installer = (PackageInstaller) PackageInstaller.class
                .getConstructor(api, String.class, String.class, int.class).newInstance(iface, context.getPackageName(), null, 0);
            CountDownLatch finished = new CountDownLatch(1);
            final boolean[] callbackSuccess = {true};
            PackageInstaller.SessionCallback callback = new PackageInstaller.SessionCallback() {
                public void onCreated(int id) { }
                public void onBadgingChanged(int id) { }
                public void onActiveChanged(int id, boolean active) { }
                public void onProgressChanged(int id, float progress) { }
                public void onFinished(int id, boolean success) { callbackSuccess[0] = success; finished.countDown(); }
            };
            installer.registerSessionCallback(callback, new Handler(Looper.getMainLooper()));
            PackageInstaller.SessionParams params = new PackageInstaller.SessionParams(PackageInstaller.SessionParams.MODE_FULL_INSTALL);
            params.setAppPackageName("com.anthropic.claude");
            params.setSize(4);
            int id = installer.createSession(params);
            require(installer.getSessionInfo(id).getAppPackageName().equals("com.anthropic.claude"), "Session info");
            require(installer.getMySessions().size() >= 1, "Session list");
            try (PackageInstaller.Session session = installer.openSession(id)) {
                byte[] expected = {1,2,3,4};
                try (OutputStream out = session.openWrite("base.apk", 0, 4)) { out.write(expected); session.fsync(out); }
                try (OutputStream out = session.openWrite("base.apk", 2, 2)) { out.write(new byte[]{5,6}); session.fsync(out); }
                try (InputStream in = session.openRead("base.apk")) {
                    byte[] actual = new byte[4]; require(in.read(actual) == 4 && Arrays.equals(actual, new byte[]{1,2,5,6}), "File bridge/read/resume");
                }
                result.putBoolean("writeFsyncReadResume", true);
                boolean pathDenied = false;
                try (OutputStream ignored = session.openWrite("../outside.apk", 0, 1)) { }
                catch (Exception e) { pathDenied = true; }
                require(pathDenied, "Path traversal denied");
                result.putBoolean("pathDenied", pathDenied);
                Method dispatch = engineClass.getDeclaredMethod("invoke", String.class, int.class, String.class, Object[].class);
                dispatch.setAccessible(true);
                boolean ownerDenied = false;
                try { dispatch.invoke(engine, "com.android.vending", id, "getNames", new Object[0]); }
                catch (java.lang.reflect.InvocationTargetException e) { ownerDenied = e.getCause() instanceof SecurityException; }
                require(ownerDenied, "Session owner enforced"); result.putBoolean("ownerDenied", true);
                CountDownLatch delivered = new CountDownLatch(1);
                final int[] status = {-99};
                String action = context.getPackageName() + ".INSTALLER_SMOKE_RESULT";
                BroadcastReceiver receiver = new BroadcastReceiver() {
                    public void onReceive(Context c, Intent intent) { status[0] = intent.getIntExtra(PackageInstaller.EXTRA_STATUS, -98); delivered.countDown(); }
                };
                context.registerReceiver(receiver, new IntentFilter(action), Context.RECEIVER_NOT_EXPORTED);
                PendingIntent pending = PendingIntent.getBroadcast(context, id, new Intent(action).setPackage(context.getPackageName()), PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_MUTABLE);
                try {
                    session.commit(pending.getIntentSender());
                    require(delivered.await(30, TimeUnit.SECONDS), "Install result delivery");
                    require(finished.await(5, TimeUnit.SECONDS) && !callbackSuccess[0], "Failure callback");
                    require(status[0] == PackageInstaller.STATUS_FAILURE_INVALID, "Invalid APK rejected");
                    result.putBoolean("invalidApkRejectedAndResultDelivered", true);
                } finally { context.unregisterReceiver(receiver); pending.cancel(); }
            }
            installer.unregisterSessionCallback(callback);
            int abandoned = installer.createSession(params);
            installer.abandonSession(abandoned);
            boolean sealed = false;
            try (PackageInstaller.Session ignored = installer.openSession(abandoned)) { }
            catch (Exception e) { sealed = true; }
            require(sealed, "Abandoned session sealed"); result.putBoolean("abandon", true);
            result.putString("result", "PASS");
            finish(-1, result);
        } catch (Throwable error) {
            while (error instanceof java.lang.reflect.InvocationTargetException && error.getCause() != null) error = error.getCause();
            result.putString("result", "FAIL");
            result.putString("failure", error.getClass().getSimpleName() + ": " + error.getMessage());
            android.util.Log.e("CageInstallTest", "Installer smoke failed", error);
            finish(0, result);
        }
    }
}
