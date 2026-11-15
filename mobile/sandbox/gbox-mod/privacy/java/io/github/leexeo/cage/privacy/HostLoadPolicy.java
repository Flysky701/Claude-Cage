package io.github.leexeo.cage.privacy;

import android.content.Context;
import android.content.pm.ApplicationInfo;
import android.os.Build;
import android.os.Process;
import android.util.Log;
import dalvik.system.DexClassLoader;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.security.MessageDigest;
import java.util.Arrays;
import java.util.Locale;

/** Loads the tested host-ISA adapter without adding a host ABI to the APK. */
final class HostLoadPolicy {
    private static final String TAG = "CageHostLoadPolicy";
    private static final String HELPER = "io.github.leexeo.cage.privacy.host.HostBridge";
    private static Class<?> helper, retainedCallback;
    private static DexClassLoader retainedLoader;
    private static Method query;
    private static boolean installed;
    private static String status = "not.prepared";

    private HostLoadPolicy() {}

    static synchronized int install(Context guest, String verifiedPackage, String missingPath, Class<?> callbackClass) {
        boolean attempted = false;
        try {
            if (guest == null || !GuestPrivacy.selected(verifiedPackage) || callbackClass != NativePrivacy.class
                    || (Build.VERSION.SDK_INT != 31 && Build.VERSION.SDK_INT != 32) || !Process.is64Bit())
                return refuse("guard.inputs", false);
            Object preparation = Class.forName("io.github.leexeo.cage.gbox.NativeCompat")
                .getMethod("privacyPreparationState").invoke(null);
            if (!Integer.valueOf(2).equals(preparation)) return refuse("guard.compatibilityNotVerified", false);
            Object client = Class.forName("com.vlite.sdk.client.k").getMethod("getInst").invoke(null);
            String current = (String) client.getClass().getMethod("getVirtualClientPkgName").invoke(client);
            ApplicationInfo info = guest.getApplicationInfo();
            if (!verifiedPackage.equals(current) || !verifiedPackage.equals(guest.getPackageName())
                    || info == null || !verifiedPackage.equals(info.packageName) || info.dataDir == null)
                return refuse("guard.guestIdentity", false);
            File data = new File(info.dataDir).getCanonicalFile();
            File files = guest.getFilesDir().getCanonicalFile();
            File missing = missingPath == null ? null : new File(missingPath).getCanonicalFile();
            if (!files.getPath().startsWith(data.getPath() + File.separator) || missing == null
                    || !files.equals(missing.getParentFile()) || missing.exists())
                return refuse("guard.missingPrivatePath", false);
            if (installed) {
                long[] state = state();
                if (retainedCallback == callbackClass && healthy(state)) {
                    status = "installed.reused";
                    Log.i(TAG, status);
                    return 1;
                }
                return refuse("guard.installedStateChanged", true);
            }
            Context host = (Context) Class.forName("com.vlite.sdk.context.i").getMethod("c").invoke(null);
            if (host == null || !"com.cage.android".equals(host.getApplicationInfo().packageName))
                return refuse("guard.hostIdentity", false);
            byte[] dexBytes = bytes(host.getAssets().open("cage-host/host-bridge.dex"));
            byte[] nativeBytes = bytes(host.getAssets().open("cage-host/x86_64/libcage_host_load_bridge.so"));
            if (dexBytes.length < 112 || dexBytes[0] != 'd' || dexBytes[1] != 'e' || dexBytes[2] != 'x'
                    || dexBytes[3] != '\n' || nativeBytes.length < 64 || nativeBytes[0] != 127
                    || nativeBytes[1] != 'E' || nativeBytes[2] != 'L' || nativeBytes[3] != 'F'
                    || nativeBytes[4] != 2 || nativeBytes[5] != 1 || nativeBytes[18] != 62 || nativeBytes[19] != 0)
                return refuse("guard.assetFormat", false);
            File root = host.getCodeCacheDir().getCanonicalFile();
            File directory = new File(root, "cage-host-load").getCanonicalFile();
            if (!directory.getPath().startsWith(root.getPath() + File.separator)
                    || (!directory.isDirectory() && !directory.mkdirs()))
                return refuse("guard.assetDirectory", false);
            File dex = publish(directory, "host-", ".dex", dexBytes);
            File library = publish(directory, "libcage_host_load_", ".so", nativeBytes);
            ClassLoader boot = Object.class.getClassLoader();
            retainedLoader = new DexClassLoader(dex.getAbsolutePath(), directory.getAbsolutePath(), null, boot);
            if (retainedLoader.getParent() != boot) return refuse("guard.parent", false);
            try {
                Class.forName(callbackClass.getName(), false, retainedLoader);
                return refuse("guard.applicationVisibleToHostLoader", false);
            } catch (ClassNotFoundException expected) {
                // App classes are supplied as explicit JNI Class objects, never inherited.
            }
            helper = Class.forName(HELPER, true, retainedLoader);
            if (helper.getClassLoader() != retainedLoader) return refuse("guard.helperLoader", false);
            String profile = (String) invoke(helper.getMethod("open", String.class), library.getAbsolutePath());
            Log.i(TAG, "open=" + profile);
            if (profile == null || !profile.startsWith("PASS ")) return refuse("guard.hostProfile", false);
            query = helper.getMethod("diagnostics");
            Method install = helper.getMethod("install", Class.class, String.class);
            attempted = true;
            String outcome = (String) invoke(install, callbackClass, missing.getAbsolutePath());
            Log.i(TAG, "install=" + outcome);
            long[] state = state();
            Log.i(TAG, "install.state=" + Arrays.toString(state));
            if (outcome != null && outcome.startsWith("PASS ") && healthy(state)) {
                installed = true;
                retainedCallback = callbackClass;
                status = "installed.hostOriginalMethod";
                Log.i(TAG, status);
                return 1;
            }
            boolean registered = state == null || state.length != 8 || state[0] != 0
                || (outcome != null && outcome.contains("registered=1"));
            return refuse("install.rejected", registered);
        } catch (Throwable failure) {
            boolean registered = installed;
            if (attempted) {
                try {
                    long[] state = state();
                    registered |= state == null || state.length != 8 || state[0] != 0;
                } catch (Throwable unavailable) { registered = true; }
            }
            Log.i(TAG, "exception=" + failure.getClass().getSimpleName());
            return refuse("install.unavailable", registered);
        }
    }

    private static int refuse(String reason, boolean registered) {
        status = reason;
        Log.i(TAG, reason + " registered=" + registered);
        return registered ? -1 : 0;
    }

    private static boolean healthy(long[] values) {
        return values != null && values.length == 8 && values[0] == 1 && values[5] == 0 && values[7] == 1;
    }

    private static Object invoke(Method method, Object... args) throws Throwable {
        try { return method.invoke(null, args); }
        catch (InvocationTargetException wrapped) { throw wrapped.getCause(); }
    }

    private static long[] state() throws Throwable {
        return query == null ? null : (long[]) invoke(query);
    }

    static synchronized String diagnostics() {
        try { return "status=" + status + " state=" + Arrays.toString(state()); }
        catch (Throwable failure) { return "status=" + status + " query=" + failure.getClass().getSimpleName(); }
    }

    private static byte[] bytes(InputStream source) throws Exception {
        try (InputStream input = source; ByteArrayOutputStream output = new ByteArrayOutputStream()) {
            byte[] buffer = new byte[8192];
            for (int count; (count = input.read(buffer)) != -1;) {
                if (output.size() + count > 2 * 1024 * 1024) throw new IllegalStateException("Host asset size limit");
                output.write(buffer, 0, count);
            }
            return output.toByteArray();
        }
    }

    private static String digest(byte[] data) throws Exception {
        StringBuilder value = new StringBuilder();
        for (byte part : MessageDigest.getInstance("SHA-256").digest(data))
            value.append(String.format(Locale.ROOT, "%02x", part & 255));
        return value.toString();
    }

    private static File publish(File directory, String prefix, String suffix, byte[] data) throws Exception {
        String expected = digest(data);
        File target = new File(directory, prefix + expected + suffix);
        if (target.exists()) {
            if (target.isFile() && expected.equals(digest(bytes(new FileInputStream(target))))) return target;
            throw new IllegalStateException("Host asset cache contents differ");
        }
        File pending = File.createTempFile("host-", ".tmp", directory);
        try {
            try (FileOutputStream output = new FileOutputStream(pending)) {
                output.write(data);
                output.getFD().sync();
            }
            if (!pending.setReadable(true, true) || !pending.setReadOnly())
                throw new IllegalStateException("Host asset mode unavailable");
            if (!pending.renameTo(target) && !(target.isFile()
                    && expected.equals(digest(bytes(new FileInputStream(target))))))
                throw new IllegalStateException("Host asset publication unavailable");
        } finally { if (pending.exists()) pending.delete(); }
        return target;
    }
}
