package io.github.leexeo.cage.gbox;

import android.content.Context;
import android.content.pm.ApplicationInfo;
import android.util.Base64;
import android.util.Log;
import java.io.File;
import java.io.FileInputStream;
import java.lang.reflect.Method;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;

/** One read-only diagnostic at the GMS Context boundary. No paths or bytes are logged. */
public final class AssetPathTrace {
    private static final String TAG = "CageAssetPathTrace";
    private static boolean attempted;

    private AssetPathTrace() {}

    public static synchronized void beforeContext(Context host, Object bindData) {
        if (attempted || !NativeCompat.isActive()) return;
        String stage = "binding";
        try {
            ApplicationInfo binding = (ApplicationInfo) bindData.getClass().getField("c").get(bindData);
            if (binding == null || !"com.google.android.gms".equals(binding.packageName)) return;
            attempted = true;
            Log.i(TAG, "begin.gms.readOnly");
            stage = "packageInfo";
            // The existing VLite PM hook adds its own synthetic-view flag for this guest.
            ApplicationInfo visible = host.getPackageManager().getApplicationInfo(binding.packageName, 0);
            String source = visible.sourceDir;
            String raw = binding.sourceDir;
            stage = "queryMapping";
            String mapped = query(source);
            stage = "hostPrefix";
            String hostSource = host.getApplicationInfo().sourceDir;
            String prefix = "/data/app/~~" + Base64.encodeToString(
                    MessageDigest.getInstance("MD5").digest((hostSource + binding.packageName)
                    .getBytes(StandardCharsets.UTF_8)), Base64.NO_WRAP | Base64.URL_SAFE);
            stage = "privateRoot";
            File root = (File) Class.forName("com.vlite.sdk.context.l").getMethod("b").invoke(null);
            String physicalRoot = root.getAbsolutePath() + "/";
            Log.i(TAG, "metadata packageMatches=" + binding.packageName.equals(visible.packageName)
                    + " sourcePresent=" + (source != null)
                    + " sourceIsSynthetic=" + starts(source, "/data/app/~~")
                    + " syntheticPrefixMatchesCurrentHost=" + starts(source, prefix + "/")
                    + " publicSourceMatches=" + same(source, visible.publicSourceDir)
                    + " bindingSourceMatches=" + same(source, raw)
                    + " bindingInsidePrivateRoot=" + starts(raw, physicalRoot)
                    + " splitCount=" + (visible.splitSourceDirs == null ? 0 : visible.splitSourceDirs.length));
            Log.i(TAG, "mapping queryReturned=" + (mapped != null)
                    + " changed=" + (mapped != null && !same(source, mapped))
                    + " insidePrivateRoot=" + starts(mapped, physicalRoot)
                    + " matchesBindingSource=" + same(mapped, raw));
            stage = "readPaths";
            observe("virtual", source);
            if (mapped != null && !same(source, mapped)) observe("mapped", mapped);
            else Log.i(TAG, "mapped.read.skipped.noDistinctMapping");
            if (raw != null && !same(raw, source) && !same(raw, mapped)) observe("binding", raw);
            Log.i(TAG, "end.gms.readOnly");
        } catch (Throwable unavailable) {
            // The actual createPackageContext call remains outside this diagnostic.
            Log.i(TAG, "diagnostic.unavailable stage=" + stage
                    + " exception=" + unavailable.getClass().getSimpleName()
                    + " originalContextCallContinues=true");
        }
    }

    private static boolean same(String first, String second) {
        return first != null && first.equals(second);
    }

    private static boolean starts(String value, String prefix) {
        return value != null && value.startsWith(prefix);
    }

    private static String query(String path) throws Exception {
        if (path == null) return null;
        return (String) Class.forName("com.vlite.sdk.jni.Native").getMethod("a", String.class)
                .invoke(null, path);
    }

    private static void observe(String label, String path) {
        if (path == null) {
            Log.i(TAG, label + " absent=true");
            return;
        }
        boolean exists = false, readable = false;
        try {
            File file = new File(path);
            exists = file.isFile();
            readable = file.canRead();
        } catch (Throwable unavailable) { /* Report false without recording exception text. */ }
        int javaRead = javaPrefix(path);
        Log.i(TAG, label + " fileExists=" + exists + " fileReadable=" + readable
                + " javaOpened=" + ((javaRead & 1) != 0)
                + " javaRead4=" + ((javaRead & 2) != 0)
                + " javaZipHeader=" + ((javaRead & 4) != 0));
        int nativeRead = -10000;
        Log.i(TAG, label + ".arm.beforeRead");
        try { nativeRead = readApkPrefix(path); } catch (Throwable unavailable) { /* Fixed code only. */ }
        Log.i(TAG, label + " armStatus=" + nativeRead
                + " armOpened=" + (nativeRead > 0 && (nativeRead & 1) != 0)
                + " armRead4=" + (nativeRead > 0 && (nativeRead & 2) != 0)
                + " armZipHeader=" + (nativeRead > 0 && (nativeRead & 4) != 0));
        Log.i(TAG, label + ".apkAssets.beforeRead");
        int assets = apkAssets(path);
        Log.i(TAG, label + " apkAssetsApi=" + ((assets & 1) != 0)
                + " apkAssetsLoaded=" + ((assets & 2) != 0)
                + " apkAssetsClosed=" + ((assets & 4) != 0));
    }

    private static int javaPrefix(String path) {
        int result = 0;
        try (FileInputStream stream = new FileInputStream(path)) {
            result = 1;
            byte[] header = new byte[4];
            int count = 0;
            while (count < header.length) {
                int got = stream.read(header, count, header.length - count);
                if (got <= 0) break;
                count += got;
            }
            if (count == 4) {
                result |= 2;
                if (header[0] == 0x50 && header[1] == 0x4b && header[2] == 3 && header[3] == 4) result |= 4;
            }
        } catch (Throwable unavailable) { /* No file contents or paths are logged. */ }
        return result;
    }

    private static int apkAssets(String path) {
        int result = 0;
        Object asset = null;
        Method close = null;
        try {
            Class<?> type = Class.forName("android.content.res.ApkAssets");
            Method load = type.getDeclaredMethod("loadFromPath", String.class);
            close = type.getDeclaredMethod("close");
            load.setAccessible(true);
            close.setAccessible(true);
            result = 1;
            asset = load.invoke(null, path);
            if (asset != null) result |= 2;
        } catch (Throwable unavailable) { /* The original resource load is still executed afterward. */ }
        finally {
            if (asset != null && close != null) {
                try { close.invoke(asset); result |= 4; } catch (Throwable unavailable) { /* Fixed booleans only. */ }
            }
        }
        return result;
    }

    private static native int readApkPrefix(String path);
}
