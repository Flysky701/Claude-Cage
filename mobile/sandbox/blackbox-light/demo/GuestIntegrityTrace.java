package io.github.leexeo.cage.space;

import android.content.ComponentName;
import android.content.Context;
import android.content.pm.PackageManager;
import android.content.pm.PackageInfo;
import android.content.pm.Signature;
import android.os.Binder;
import android.os.Bundle;
import android.os.IBinder;
import android.os.Parcel;
import android.os.RemoteException;
import android.util.Log;
import java.util.HashSet;
import java.util.Set;

/** Opt-in local diagnostics. Never changes a verdict or records token contents. */
public final class GuestIntegrityTrace {
    private static final boolean ENABLED = false;
    private static final String SERVICE = "com.google.android.play.core.integrity.protocol.IIntegrityService";
    private static final String CALLBACK = SERVICE + "Callback";
    private static final Set<String> uidEvents = new HashSet<>();

    private GuestIntegrityTrace() {}

    private static String identityRecipient() {
        if (!ENABLED) return null;
        try {
            String pkg = (String) Class.forName("top.niunaijun.blackbox.app.BActivityThread")
                    .getMethod("getAppPackageName").invoke(null);
            if ("com.android.vending".equals(pkg)) return "Play";
            if ("com.google.android.gms".equals(pkg)) return "microG";
        } catch (ReflectiveOperationException | RuntimeException ignored) {}
        return null;
    }

    private static void identityEvent(String event) {
        synchronized (uidEvents) {
            if (uidEvents.size() >= 64 || !uidEvents.add(event)) return;
        }
        Log.i("CageIntegrity", event);
    }

    public static void callerUid(int realUid, int pid, int mappedUid, String stage) {
        String recipient = identityRecipient();
        if (recipient != null) identityEvent("Caller recipient=" + recipient + " real=" + realUid
                + " pid=" + pid + " mapped=" + mappedUid + " stage=" + stage);
    }

    public static void uidLookup(Object[] args, String[] packages) {
        String recipient = identityRecipient();
        if (recipient == null || args == null || args.length == 0 || !(args[0] instanceof Integer)) return;
        boolean claude = false, play = false, microg = false;
        if (packages != null) for (String pkg : packages) {
            claude |= "com.anthropic.claude".equals(pkg);
            play |= "com.android.vending".equals(pkg);
            microg |= "com.google.android.gms".equals(pkg);
        }
        identityEvent("Lookup recipient=" + recipient + " uid=" + args[0]
                + " count=" + (packages == null ? -1 : packages.length)
                + " claude=" + claude + " play=" + play + " microG=" + microg);
    }

    public static void identitySnapshot(Context guest) {
        if (!ENABLED || !"com.android.vending".equals(guest.getPackageName())) return;
        try {
            PackageManager packages = guest.getPackageManager();
            int uid = packages.getApplicationInfo(ClaudeBundle.PACKAGE, 0).uid;
            snapshot("cached", uid, packages.getPackagesForUid(uid));
            Object manager = Class.forName("android.app.ActivityThread").getMethod("getPackageManager").invoke(null);
            boolean proxy = java.lang.reflect.Proxy.isProxyClass(manager.getClass());
            boolean privateHandler = proxy && java.lang.reflect.Proxy.getInvocationHandler(manager).getClass().getName()
                    .equals("top.niunaijun.blackbox.fake.service.IPackageManagerProxy");
            java.lang.reflect.Field pmField = Class.forName("android.app.ApplicationPackageManager").getDeclaredField("mPM");
            pmField.setAccessible(true);
            Object contextManager = pmField.get(packages);
            identityEvent("Manager proxy=" + proxy + " private=" + privateHandler + " contextMatches=" + (contextManager == manager));
            if (privateHandler) {
                Object handler = java.lang.reflect.Proxy.getInvocationHandler(manager);
                java.lang.reflect.Field hooks = Class.forName("top.niunaijun.blackbox.fake.hook.ClassInvocationStub")
                        .getDeclaredField("mMethodHookMap");
                hooks.setAccessible(true);
                Object hook = ((java.util.Map<?, ?>) hooks.get(handler)).get("getPackagesForUid");
                identityEvent("UidHook registered=" + (hook != null) + " enabled="
                        + (hook != null && (Boolean) hook.getClass().getMethod("isEnable").invoke(hook)));
            }
            String[] direct = (String[]) Class.forName("android.content.pm.IPackageManager")
                    .getMethod("getPackagesForUid", int.class).invoke(manager, uid);
            snapshot("direct", uid, direct);
            Object virtual = Class.forName("top.niunaijun.blackbox.BlackBoxCore").getMethod("getBPackageManager").invoke(null);
            snapshot("private_record", uid, (String[]) virtual.getClass().getMethod("getPackagesForUid", int.class).invoke(virtual, uid));
            snapshot("unknown", 19999, packages.getPackagesForUid(19999));
            int reverseUid = (Integer) Class.forName("android.content.pm.IPackageManager")
                    .getMethod("getPackageUid", String.class, long.class, int.class).invoke(manager, ClaudeBundle.PACKAGE, 0L, 0);
            identityEvent("UidRoundTrip matches=" + (reverseUid == uid));
            packageSnapshot(packages);
        } catch (Exception unavailable) {
            identityEvent("Snapshot unavailable=" + unavailable.getClass().getSimpleName());
        }
    }

    private static void packageSnapshot(PackageManager packages) {
        try {
            PackageInfo legacy = packages.getPackageInfo(ClaudeBundle.PACKAGE, PackageManager.GET_SIGNATURES);
            identityEvent("Package version=" + legacy.getLongVersionCode()
                    + " legacySigners=" + (legacy.signatures == null ? 0 : legacy.signatures.length)
                    + " legacyMatch=" + expectedSigner(legacy.signatures));
            PackageInfo modern = packages.getPackageInfo(ClaudeBundle.PACKAGE, PackageManager.GET_SIGNING_CERTIFICATES);
            Signature[] signers = modern.signingInfo == null ? null : modern.signingInfo.getApkContentsSigners();
            identityEvent("Package modernSigners=" + (signers == null ? 0 : signers.length)
                    + " modernMatch=" + expectedSigner(signers));
        } catch (Exception failure) {
            identityEvent("Package snapshot unavailable=" + failure.getClass().getSimpleName());
        }
        try {
            String installer = packages.getInstallerPackageName(ClaudeBundle.PACKAGE);
            identityEvent("Installer legacy=" + installerLabel(installer));
            if (android.os.Build.VERSION.SDK_INT >= 30)
                identityEvent("Installer modern=" + installerLabel(packages.getInstallSourceInfo(ClaudeBundle.PACKAGE)
                        .getInstallingPackageName()));
        } catch (Exception failure) {
            identityEvent("Installer snapshot unavailable=" + failure.getClass().getSimpleName());
        }
    }

    private static String installerLabel(String pkg) {
        if (pkg == null) return "none";
        if ("com.android.vending".equals(pkg)) return "Play";
        if (ClaudeBundle.HOST.equals(pkg)) return "space";
        return "other";
    }

    private static boolean expectedSigner(Signature[] signatures) throws Exception {
        if (signatures == null || signatures.length != 1) return false;
        byte[] digest = java.security.MessageDigest.getInstance("SHA-256").digest(signatures[0].toByteArray());
        StringBuilder hex = new StringBuilder();
        for (byte value : digest) hex.append(String.format(java.util.Locale.ROOT, "%02x", value & 255));
        return "305a1e8a432e5ec0c612b2465359c3b88e3c95d6253599ac6088562b818b64a0".equals(hex.toString());
    }

    private static void snapshot(String phase, int uid, String[] packages) {
        boolean claude = false;
        if (packages != null) for (String pkg : packages) claude |= ClaudeBundle.PACKAGE.equals(pkg);
        identityEvent("Snapshot phase=" + phase + " uid=" + uid
                + " count=" + (packages == null ? -1 : packages.length) + " claude=" + claude);
    }

    public static IBinder observe(ComponentName component, IBinder remote) {
        if (!ENABLED || component == null || remote == null
                || !"com.android.vending".equals(component.getPackageName())
                || !"com.google.android.finsky.integrityservice.IntegrityService".equals(component.getClassName()))
            return remote;
        try {
            Class<?> core = Class.forName("top.niunaijun.blackbox.BlackBoxCore");
            Context host = (Context) core.getMethod("getContext").invoke(null);
            Object instance = core.getMethod("get").invoke(null);
            if (!ClaudeBundle.HOST.equals(host.getPackageName())
                    || !(Boolean) core.getMethod("isBlackProcess").invoke(instance)) return remote;
            Class<?> thread = Class.forName("top.niunaijun.blackbox.app.BActivityThread");
            if (!ClaudeBundle.PACKAGE.equals(thread.getMethod("getAppPackageName").invoke(null))
                    || (Integer) thread.getMethod("getUserId").invoke(null) != 0
                    || !SERVICE.equals(remote.getInterfaceDescriptor())) return remote;
            Log.i("CageIntegrity", "Private classic service connected; observer enabled");
            return new Service(remote);
        } catch (ReflectiveOperationException | RemoteException | RuntimeException unavailable) {
            Log.i("CageIntegrity", "Observer unavailable; original service retained");
            return remote;
        }
    }

    static final class Service extends Binder {
        private final IBinder remote;
        Service(IBinder remote) {
            this.remote = remote;
            attachInterface(null, SERVICE);
        }

        @Override protected boolean onTransact(int code, Parcel data, Parcel reply, int flags)
                throws RemoteException {
            Parcel forwarded = code == 2 ? withObservedCallback(data) : null;
            try {
                // Forward exactly once, including exceptions and the original flags.
                return remote.transact(code, forwarded == null ? data : forwarded, reply, flags);
            } finally {
                if (forwarded != null) forwarded.recycle();
            }
        }

        private Parcel withObservedCallback(Parcel data) {
            Parcel probe = Parcel.obtain();
            Parcel forwarded = null;
            try {
                probe.appendFrom(data, 0, data.dataSize());
                probe.setDataPosition(0);
                probe.enforceInterface(SERVICE);
                if (probe.readInt() != 1) return null;
                Bundle.CREATOR.createFromParcel(probe);
                int offset = probe.dataPosition();
                IBinder callback = probe.readStrongBinder();
                if (callback == null || probe.dataAvail() != 0) return null;
                forwarded = Parcel.obtain();
                // Preserve the complete request prefix, including its original Bundle bytes.
                forwarded.appendFrom(data, 0, offset);
                forwarded.setDataPosition(offset);
                forwarded.writeStrongBinder(new Callback(callback));
                Log.i("CageIntegrity", "Classic request forwarded with original payload");
                return forwarded;
            } catch (RuntimeException unsupported) {
                if (forwarded != null) forwarded.recycle();
                Log.i("CageIntegrity", "Unknown request shape; original request retained");
                return null;
            } finally {
                probe.recycle();
            }
        }
    }

    static final class Callback extends Binder {
        private final IBinder remote;
        Callback(IBinder remote) {
            this.remote = remote;
            attachInterface(null, CALLBACK);
        }

        @Override protected boolean onTransact(int code, Parcel data, Parcel reply, int flags)
                throws RemoteException {
            if (code == 2) inspect(data);
            return remote.transact(code, data, reply, flags);
        }

        private void inspect(Parcel data) {
            Parcel probe = Parcel.obtain();
            try {
                probe.appendFrom(data, 0, data.dataSize());
                probe.setDataPosition(0);
                probe.enforceInterface(CALLBACK);
                if (probe.readInt() != 1) return;
                Bundle result = Bundle.CREATOR.createFromParcel(probe);
                if (probe.dataAvail() != 0) return;
                int error = result.getInt("error");
                String token = result.getString("token");
                Log.i("CageIntegrity", "Classic response error=" + error
                        + " tokenPresent=" + (token != null && !token.isEmpty()));
            } catch (RuntimeException unsupported) {
                Log.i("CageIntegrity", "Unknown callback shape; original result retained");
            } finally {
                probe.recycle();
            }
        }
    }
}
