package io.github.leexeo.cage.test;

import android.app.Instrumentation;
import android.content.Context;
import android.content.pm.PackageInfo;
import android.os.Bundle;
import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.lang.reflect.Constructor;
import java.lang.reflect.Method;
import java.nio.file.Files;

/** Test preparation only: preserve the fresh test store's data and use the report's version. */
public final class ReportStoreSetup extends Instrumentation {
    @Override public void onCreate(Bundle args) { super.onCreate(args); start(); }

    private static File owned(File root, String relative) throws Exception {
        File path = new File(root, relative).getAbsoluteFile();
        if (!path.getCanonicalFile().equals(path) || !path.toPath().startsWith(root.toPath()))
            throw new SecurityException("Unexpected recovery path");
        return path;
    }

    @Override public void onStart() {
        Bundle result = new Bundle();
        try {
            Context context = getTargetContext();
            if (!"top.niunaijun.microrec".equals(context.getPackageName())) throw new SecurityException("Recovery copy only");
            File root = context.getDataDir().getCanonicalFile();
            Class<?> packages = Class.forName("io.github.leexeo.cage.space.SpacePackages");
            Constructor<?> ctor = packages.getDeclaredConstructor(Context.class); ctor.setAccessible(true);
            Object manager = ctor.newInstance(context);
            Method installed = packages.getDeclaredMethod("installed", String.class); installed.setAccessible(true);
            PackageInfo previous = (PackageInfo) installed.invoke(manager, "com.android.vending");
            if (previous == null || !previous.versionName.startsWith("45.7.17-31")) throw new IllegalStateException("Expected fresh test store 45.7.17");
            File apk = owned(root, "cache/report-store.apk");
            try (InputStream in = getContext().getAssets().open("report-store.apk"); FileOutputStream out = new FileOutputStream(apk)) {
                byte[] buffer = new byte[65536]; for (int n; (n=in.read(buffer))>=0;) out.write(buffer,0,n);
            }
            Method inspect = packages.getDeclaredMethod("inspect", Context.class, File.class); inspect.setAccessible(true);
            PackageInfo replacement = (PackageInfo) inspect.invoke(null, context, apk);
            if (!"com.android.vending".equals(replacement.packageName) || replacement.getLongVersionCode()!=83842210L)
                throw new SecurityException("Report store signature/version required");
            Class<?> coreClass = Class.forName("top.niunaijun.blackbox.BlackBoxCore");
            Object core = coreClass.getMethod("get").invoke(null);
            coreClass.getMethod("stopPackage", String.class, int.class).invoke(core, "com.android.vending", 0);
            File backup = owned(root, "files/store-compat-backup-" + System.currentTimeMillis());
            if (!backup.mkdir()) throw new IllegalStateException("Backup directory unavailable");
            Files.copy(owned(root, "blackbox/data/app/com.android.vending/base.apk").toPath(), new File(backup,"previous.apk").toPath());
            for (String area : new String[]{"user", "user_de"}) {
                File data = owned(root, "blackbox/data/"+area+"/0/com.android.vending");
                if (data.exists()) Files.move(data.toPath(), new File(backup,area).toPath());
            }
            // Only the newly imported Play copy is removed. microG owns the
            // Google account store and is never touched by this operation.
            coreClass.getMethod("uninstallPackageAsUser", String.class, int.class).invoke(core, "com.android.vending", 0);
            Method install = packages.getDeclaredMethod("install", File.class, PackageInfo.class); install.setAccessible(true);
            install.invoke(manager, apk, replacement);
            PackageInfo actual = (PackageInfo) installed.invoke(manager, "com.android.vending");
            if (actual == null || actual.getLongVersionCode()!=83842210L) throw new IllegalStateException("Report store was not installed");
            result.putBoolean("previousTestStoreBackedUp", true);
            result.putString("storeVersion", "38.4.22-21"); result.putString("result", "PASS");
            finish(-1,result);
        } catch (Throwable error) {
            while(error instanceof java.lang.reflect.InvocationTargetException && error.getCause()!=null) error=error.getCause();
            result.putString("result","FAIL"); result.putString("failure",error.getClass().getSimpleName()+": "+error.getMessage());
            finish(0,result);
        }
    }
}
