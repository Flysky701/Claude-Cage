package io.github.leexeo.cage.test;

import android.app.Instrumentation;
import android.app.PendingIntent;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.pm.PackageInstaller;
import android.os.Bundle;
import android.os.IBinder;
import java.io.File;
import java.io.OutputStream;
import java.lang.reflect.Constructor;
import java.lang.reflect.Field;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;

/** Validate a successful host-owned session with the already available original APKs. */
public final class ExistingClaudeInstall extends Instrumentation {
    @Override public void onCreate(Bundle args) { super.onCreate(args); start(); }
    @Override public void onStart() {
        Bundle result = new Bundle();
        try {
            Context context = getTargetContext();
            if (!"top.niunaijun.microrec".equals(context.getPackageName())) throw new SecurityException("Recovery copy only");
            Class<?> engineClass = Class.forName("io.github.leexeo.cage.space.GuestInstaller$Engine");
            Constructor<?> ctor = engineClass.getDeclaredConstructor(Context.class, File.class); ctor.setAccessible(true);
            Object engine = ctor.newInstance(context, new File(context.getFilesDir(), "installer-smoke"));
            Field service = engineClass.getDeclaredField("service"); service.setAccessible(true);
            Class<?> api = Class.forName("android.content.pm.IPackageInstaller");
            Object iface = Class.forName(api.getName()+"$Stub").getMethod("asInterface",IBinder.class).invoke(null,service.get(engine));
            PackageInstaller installer = (PackageInstaller) PackageInstaller.class.getConstructor(api,String.class,String.class,int.class)
                .newInstance(iface,context.getPackageName(),null,0);
            PackageInstaller.SessionParams params = new PackageInstaller.SessionParams(PackageInstaller.SessionParams.MODE_FULL_INSTALL);
            params.setAppPackageName("com.anthropic.claude");
            int id = installer.createSession(params);
            int parts = 0;
            try (PackageInstaller.Session session = installer.openSession(id);
                 ZipInputStream in = new ZipInputStream(getContext().getAssets().open("claude-original.xapk"))) {
                byte[] buffer = new byte[65536];
                for (ZipEntry entry; (entry=in.getNextEntry())!=null;) {
                    if (entry.isDirectory() || !entry.getName().endsWith(".apk")) continue;
                    String name=entry.getName();
                    if (name.contains("/") || name.contains("\\") || ++parts>16) throw new SecurityException("Unexpected test bundle structure");
                    try (OutputStream out=session.openWrite(name,0,entry.getSize())) {
                        for (int n;(n=in.read(buffer))>=0;) out.write(buffer,0,n);
                        session.fsync(out);
                    }
                    in.closeEntry();
                }
                if (parts<3) throw new IllegalStateException("Expected original split APKs");
                CountDownLatch done=new CountDownLatch(1);
                final int[] status={-99};
                String action=context.getPackageName()+".CLAUDE_EXISTING_INSTALL_RESULT";
                BroadcastReceiver receiver=new BroadcastReceiver() {
                    public void onReceive(Context c,Intent intent) {status[0]=intent.getIntExtra(PackageInstaller.EXTRA_STATUS,-98);done.countDown();}
                };
                context.registerReceiver(receiver,new IntentFilter(action),Context.RECEIVER_NOT_EXPORTED);
                PendingIntent pending=PendingIntent.getBroadcast(context,id,new Intent(action).setPackage(context.getPackageName()),PendingIntent.FLAG_MUTABLE|PendingIntent.FLAG_UPDATE_CURRENT);
                try {
                    session.commit(pending.getIntentSender());
                    if (!done.await(120,TimeUnit.SECONDS)) throw new IllegalStateException("Install result timeout");
                    result.putInt("installStatus",status[0]);
                    if (status[0]!=PackageInstaller.STATUS_SUCCESS) throw new IllegalStateException("Private session did not succeed");
                } finally {context.unregisterReceiver(receiver);pending.cancel();}
            }
            result.putInt("originalApkParts",parts);
            result.putString("installSource","space import; not a Play download");
            result.putString("result","PASS");finish(-1,result);
        } catch (Throwable error) {
            while(error instanceof java.lang.reflect.InvocationTargetException && error.getCause()!=null) error=error.getCause();
            result.putString("result","FAIL");result.putString("failure",error.getClass().getSimpleName()+": "+error.getMessage());finish(0,result);
        }
    }
}
