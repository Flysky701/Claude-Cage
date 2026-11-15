package io.github.leexeo.cage.privacy;

import android.content.Context;
import android.content.pm.ApplicationInfo;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.os.Process;
import android.util.Log;
import java.io.File;
import java.io.FileOutputStream;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashSet;
import java.util.Set;

/** ARM library read policy. Installation is not a claim that every native path is covered. */
final class NativePrivacy {
    private static boolean loaded;
    private static boolean active;
    private static int diagnosticGeneration;
    private static volatile boolean loadBridgeBroken;

    private NativePrivacy() {}

    static synchronized boolean bind(Context guest, String packageName, String zone,
            boolean sim, boolean timezone, boolean vpn, Set<String> observedInterfaces) {
        Log.i("CageNativePrivacy", "java.bind.enter");
        assertProcessUsable();
        deactivate();
        Log.i("CageNativePrivacy", "java.bind.after.deactivate");
        boolean nativeAndroid16 = Build.VERSION.SDK_INT == 36 && Build.SUPPORTED_ABIS.length > 0
            && "arm64-v8a".equals(Build.SUPPORTED_ABIS[0]);
        if (!GuestPrivacy.selected(packageName) || (Build.VERSION.SDK_INT != 31 && Build.VERSION.SDK_INT != 32 && !nativeAndroid16)
                || !Process.is64Bit() || !"Asia/Tokyo".equals(zone)) return false;
        try {
            Log.i("CageNativePrivacy", "java.bind.before.applicationInfo");
            ApplicationInfo info = guest.getApplicationInfo();
            Log.i("CageNativePrivacy", "java.bind.after.applicationInfo");
            boolean contextMatches = packageName.equals(guest.getPackageName());
            boolean infoMatches = info != null && packageName.equals(info.packageName);
            boolean sourceReady = info != null && info.sourceDir != null && !info.sourceDir.isEmpty();
            boolean dataReady = info != null && info.dataDir != null && !info.dataDir.isEmpty();
            Log.i("CageNativePrivacy", "java.bind.identity context=" + contextMatches + " info=" + infoMatches
                + " source=" + sourceReady + " data=" + dataReady);
            if (!contextMatches || !infoMatches || !sourceReady || !dataReady)
                throw new IllegalStateException("Guest native policy identity unavailable");
            LinkedHashSet<String> roots = new LinkedHashSet<>();
            Log.i("CageNativePrivacy", "java.bind.before.roots");
            if (nativeAndroid16) {
                addAndroid16Roots(roots, info, packageName);
            } else {
                File code = new File(info.sourceDir).getCanonicalFile().getParentFile();
                if (code == null || !(code.getName().equals(packageName) || code.getName().startsWith(packageName + "-")))
                    throw new IllegalStateException("Guest native code root unavailable");
                addRoot(roots, code);
                addDataRoot(roots, info.dataDir, packageName);
                if (info.deviceProtectedDataDir != null) addDataRoot(roots, info.deviceProtectedDataDir, packageName);
            }
            Log.i("CageNativePrivacy", "java.bind.after.roots");
            if (!loaded) {
                Log.i("CageNativePrivacy", "java.bind.before.loadLibrary");
                System.loadLibrary("cage_privacy");
                Log.i("CageNativePrivacy", "java.bind.after.loadLibrary");
                loaded = true;
            }
            Log.i("CageNativePrivacy", "java.bind.before.apiTable");
            long api = (Long) Class.forName("com.vlite.sdk.jni.Native").getMethod("getBhookApi").invoke(null);
            Log.i("CageNativePrivacy", "java.bind.after.apiTable");
            int flags = (sim ? 1 : 0) | (timezone ? 2 : 0) | (vpn ? 4 : 0);
            String[] interfaces;
            synchronized (observedInterfaces) { interfaces = observedInterfaces.toArray(new String[0]); }
            boolean synchronizeLoads = verifiedCompatibility();
            String absentPath = synchronizeLoads ? absentPrivateLibrary(guest, info) : null;
            Log.i("CageNativePrivacy", "java.bind.before.nativeBind");
            int result = nativeBind(api, roots.toArray(new String[0]), interfaces, flags, synchronizeLoads, nativeAndroid16);
            Log.i("CageNativePrivacy", "java.bind.after.nativeBind");
            if (result > 0 && synchronizeLoads) {
                // The original engine and ARM refresh are already verified.
                // Only now may the separate host loader register its wrapper.
                int host = HostLoadPolicy.install(guest, packageName, absentPath, NativePrivacy.class);
                Log.i("CageNativePrivacy", "host.install.result=" + host);
                if (host < 0) {
                    loadBridgeBroken = true;
                    throw new NativeLoadBridgeFailure();
                }
                if (host == 0) {
                    nativeDeactivate();
                    result = -7;
                }
            }
            active = result > 0;
            Log.i("CageNativePrivacy", "bind.result=" + result);
            if (active) scheduleDiagnostics(guest, info, packageName);
            return active;
        } catch (Exception | LinkageError failure) {
            deactivate();
            if (loadBridgeBroken) throw new NativeLoadBridgeFailure();
            Log.w("CageNativePrivacy", "bind.unavailable." + failure.getClass().getSimpleName()
                + (failure instanceof IllegalStateException ? "." + failure.getMessage() : ""));
            return false;
        }
    }

    static final class NativeLoadBridgeFailure extends IllegalStateException {
        NativeLoadBridgeFailure() { super("Native loader bridge validation failed; a fresh process is required"); }
    }

    static void assertProcessUsable() {
        if (loadBridgeBroken) throw new NativeLoadBridgeFailure();
    }

    private static boolean verifiedCompatibility() throws ReflectiveOperationException {
        try {
            return Integer.valueOf(2).equals(Class.forName("io.github.leexeo.cage.gbox.NativeCompat")
                .getMethod("privacyPreparationState").invoke(null));
        } catch (ClassNotFoundException originalBuild) { return false; }
    }

    private static String absentPrivateLibrary(Context guest, ApplicationInfo info) throws java.io.IOException {
        File data = new File(info.dataDir).getCanonicalFile();
        File directory = guest.getFilesDir().getCanonicalFile();
        if (!directory.getPath().startsWith(data.getPath() + File.separator))
            throw new IllegalStateException("Missing-library check directory outside guest data");
        File missing = new File(directory, ".cage-absent-load-" + Long.toHexString(System.nanoTime()) + ".so").getCanonicalFile();
        if (!directory.equals(missing.getParentFile()) || missing.exists())
            throw new IllegalStateException("Missing-library check path is not absent");
        return missing.getPath();
    }

    private static void addRoot(Set<String> roots, File root) throws java.io.IOException {
        String path = root.getCanonicalPath();
        if (!path.startsWith("/data/") || path.equals("/data/app") || path.equals("/data/user"))
            throw new IllegalStateException("Guest native root rejected");
        roots.add(path);
    }

    private static void addDataRoot(Set<String> roots, String path, String packageName) throws java.io.IOException {
        File root = new File(path).getCanonicalFile();
        if (!root.getName().equals(packageName)) throw new IllegalStateException("Guest native data root rejected");
        addRoot(roots, root);
    }

    private static void addAndroid16Roots(Set<String> roots, ApplicationInfo info, String pkg) throws Exception {
        // On the native phone, VLite keeps virtual Framework paths but the
        // linker enumerates physical container paths. Query its existing mapping;
        // never broaden the policy to the entire host or all of /data.
        Context host = (Context) Class.forName("com.vlite.sdk.context.i").getMethod("c").invoke(null);
        if (host == null || !"com.cage.android".equals(host.getApplicationInfo().packageName))
            throw new IllegalStateException("Native policy host unavailable");
        // VLite's realpath hook maps canonical physical guest paths back to
        // virtual paths. Keep lexical absolute paths from its trusted environment
        // and validate every segment below, instead of calling getCanonicalPath.
        String expected = physicalPath(new File(host.getApplicationInfo().dataDir, "_root"));
        Class<?> environment = Class.forName("com.vlite.sdk.context.j");
        String actual = physicalPath((File) environment.getMethod("x").invoke(null));
        if (!expected.equals(actual)) throw new IllegalStateException("Native policy container root mismatch");
        // Use the same host environment instance as x()/t()/q(). The deprecated
        // context.l builds another instance through the guest-visible package manager.
        String internal = physicalPath((File) environment.getMethod("a").invoke(null));
        if (!internal.equals(expected + "/data/internal_app"))
            throw new IllegalStateException("Native policy code root mismatch");
        java.lang.reflect.Method query = Class.forName("com.vlite.sdk.jni.Native").getMethod("a", String.class);
        String source = info.sourceDir;
        if (!source.startsWith(internal + "/")) source = (String) query.invoke(null, source);
        File code = source == null ? null : new File(physicalPath(new File(source))).getParentFile();
        if (code == null || !internal.equals(code.getParent())
                || !(code.getName().equals(pkg) || code.getName().startsWith(pkg + "-"))
                || !code.isDirectory()) throw new IllegalStateException("Mapped native policy code root rejected");
        roots.add(code.getPath());
        String[] methods = {"t", "q"}, kinds = {"user", "user_de"};
        String selectedUser = null;
        for (int i = 0; i < methods.length; ++i) {
            File data = new File(physicalPath((File) environment.getMethod(methods[i], String.class).invoke(null, pkg)));
            String path = data.getPath(), prefix = expected + "/data/" + kinds[i] + "/";
            if (!path.startsWith(prefix) || !path.endsWith("/" + pkg) || !data.isDirectory())
                throw new IllegalStateException("Mapped native policy data root rejected");
            String user = path.substring(prefix.length(), path.length() - pkg.length() - 1);
            if (!user.matches("[0-9]+") || (selectedUser != null && !selectedUser.equals(user)))
                throw new IllegalStateException("Mapped native policy user mismatch");
            selectedUser = user;
            roots.add(data.getPath());
        }
        Log.i("CageNativePrivacy", "java.bind.physicalRoots.verified");
    }

    private static String physicalPath(File path) {
        if (path == null || !path.isAbsolute()) throw new IllegalStateException("Missing physical path");
        String value = path.getAbsolutePath();
        if (!value.startsWith("/data/") || value.endsWith("/") || value.contains("//")
                || value.contains("/../") || value.endsWith("/..")
                || value.contains("/./") || value.endsWith("/.") || value.indexOf('\0') >= 0)
            throw new IllegalStateException("Invalid physical path");
        return value;
    }

    static synchronized void observeInterface(String name) {
        if (loaded && active && name != null) nativeObserveInterface(name);
    }

    static synchronized void deactivate() {
        ++diagnosticGeneration;
        if (loaded) nativeDeactivate();
        active = false;
    }

    private static void scheduleDiagnostics(Context guest, ApplicationInfo info, final String packageName) {
        try {
            File data = new File(info.dataDir).getCanonicalFile();
            File files = guest.getFilesDir().getCanonicalFile();
            if (!files.getPath().startsWith(data.getPath() + File.separator)) throw new IllegalStateException("Diagnostic data root mismatch");
            final File output = new File(files, "cage-native-privacy-diagnostic.txt").getCanonicalFile();
            if (!files.equals(output.getParentFile())) throw new IllegalStateException("Diagnostic file root mismatch");
            final String context = "context.package=" + packageName + "\ncontext.source=" + info.sourceDir
                + "\ncontext.data=" + info.dataDir + "\ncontext.nativeLibrary=" + info.nativeLibraryDir + "\n";
            final int generation = ++diagnosticGeneration;
            Handler handler = new Handler(Looper.getMainLooper());
            int[] delays = {0, 1000, 4000, 8000};
            for (int index = 0; index < delays.length; ++index) {
                final int sequence = index;
                handler.postDelayed(new Runnable() {
                    @Override public void run() { captureDiagnostics(output, context, packageName, generation, sequence); }
                }, delays[index]);
            }
            Log.i("CageNativePrivacy", "observation.schedule.0_1_4_8seconds");
        } catch (Exception failure) {
            Log.i("CageNativePrivacy", "observation.schedule.unavailable." + failure.getClass().getSimpleName());
        }
    }

    private static synchronized void captureDiagnostics(File output, String context, String packageName,
            int generation, int sequence) {
        if (!active || generation != diagnosticGeneration) return;
        try {
            Object client = Class.forName("com.vlite.sdk.client.k").getMethod("getInst").invoke(null);
            String current = (String) client.getClass().getMethod("getVirtualClientPkgName").invoke(client);
            if (!GuestPrivacy.selected(packageName) || !packageName.equals(current)) return;
            String host = HostLoadPolicy.diagnostics();
            Log.i("CageNativePrivacy", "host.observation." + sequence + " " + host);
            String observation = (sequence == 0 ? context + nativeCapture(-1) : "") + nativeCapture(sequence)
                + "host.loader=" + host + "\n";
            try (FileOutputStream stream = new FileOutputStream(output, sequence != 0)) {
                stream.write(observation.getBytes(StandardCharsets.UTF_8));
                stream.getFD().sync();
            }
            Log.i("CageNativePrivacy", "observation.privateFile.written." + sequence);
        } catch (Exception | LinkageError failure) {
            Log.i("CageNativePrivacy", "observation.unavailable." + sequence + "." + failure.getClass().getSimpleName());
        }
    }

    static synchronized String diagnostics() {
        return loaded ? nativeDiagnostics() + "\n" + HostLoadPolicy.diagnostics() : "library.not.loaded";
    }

    private static native int nativeBind(long api, String[] roots, String[] interfaces, int flags,
        boolean synchronizeLoads, boolean android16Native);
    private static native void afterNativeLoad(String filename);
    private static native void nativeObserveInterface(String name);
    private static native void nativeDeactivate();
    private static native String nativeDiagnostics();
    private static native String nativeCapture(int sequence);
}
