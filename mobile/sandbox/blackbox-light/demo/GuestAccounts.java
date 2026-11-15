package io.github.leexeo.cage.space;

import android.accounts.Account;
import android.accounts.AccountManager;
import android.accounts.AbstractAccountAuthenticator;
import android.app.Service;
import android.content.ContentProvider;
import android.content.Context;
import android.content.ContextWrapper;
import android.content.pm.PackageManager;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageInfo;
import android.net.Uri;
import android.os.*;
import java.lang.reflect.Field;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.HashMap;

/** Permit the space's own live account service to call its private microG authenticator. */
public final class GuestAccounts {
    private static final String IDENTITY = "cage_demo_account_service";
    private static final String AUTHORITY = "top.niunaijun.microdem.blackbox.SystemCallProvider";
    private static volatile Peer peer;
    private static final class Peer {
        final int pid, uid;
        final IBinder service;
        Peer(int pid, int uid, IBinder service) { this.pid = pid; this.uid = uid; this.service = service; }
    }

    public static Bundle identity(ContentProvider provider, String method, String argument, Bundle extras) {
        if (!IDENTITY.equals(method)) return null;
        Context context = provider.getContext();
        if (argument != null || extras != null || Binder.getCallingUid() != context.getApplicationInfo().uid)
            throw new SecurityException("Private account service identity only");
        try {
            IInterface service = (IInterface) Class.forName("top.niunaijun.blackbox.core.system.accounts.BAccountManagerService")
                    .getMethod("get").invoke(null);
            Bundle result = new Bundle();
            result.putInt("pid", android.os.Process.myPid());
            result.putBinder("service", service.asBinder());
            return result;
        } catch (ReflectiveOperationException unavailable) { throw new IllegalStateException(unavailable); }
    }

    public static void bind(Context host, Context guest) {
        if (!"com.google.android.gms".equals(guest.getPackageName())) return;
        Bundle identity = host.getContentResolver().call(Uri.parse("content://" + AUTHORITY), IDENTITY, null, null);
        if (identity == null || identity.getInt("pid") <= 0 || identity.getBinder("service") == null)
            throw new IllegalStateException("Private account service unavailable");
        peer = new Peer(identity.getInt("pid"), host.getApplicationInfo().uid, identity.getBinder("service"));
        // This separate DEMO is intended to use its Google account in the imported,
        // signature-checked Play Store. No other package gains account visibility.
        AccountManager accounts = AccountManager.get(guest);
        try {
            SpacePackages packages = new SpacePackages(host);
            PackageInfo play = packages.installed("com.android.vending");
            if (!packages.privateCopy(play)) throw new IllegalStateException("Private Play Store missing");
            SpacePackages.inspect(host, new java.io.File(play.applicationInfo.sourceDir));
        } catch (Exception invalidStore) { throw new IllegalStateException("Private Play Store signature unavailable", invalidStore); }
        int visible = 0;
        for (Account account : accounts.getAccountsByType("com.google")) {
            Map<String, Integer> existing = accounts.getPackagesAndVisibilityForAccount(account);
            if (!existing.containsKey("com.android.vending"))
                accounts.setAccountVisibility(account, "com.android.vending", AccountManager.VISIBILITY_VISIBLE);
            int state = accounts.getAccountVisibility(account, "com.android.vending");
            if (state == AccountManager.VISIBILITY_VISIBLE || state == AccountManager.VISIBILITY_USER_MANAGED_VISIBLE) visible++;
        }
        android.util.Log.i("CageDemo", "Google accounts visible to space Play Store: " + visible);
    }

    public static Account[] accounts(Object service, String type, int user, String requestedPackage) {
        List<Account> visible = new ArrayList<>();
        try {
            Class<?> processes = Class.forName("top.niunaijun.blackbox.core.system.BProcessManagerService");
            Object caller = processes.getMethod("findProcessByPid", int.class)
                    .invoke(processes.getMethod("get").invoke(null), Binder.getCallingPid());
            if (caller == null || caller.getClass().getField("userId").getInt(caller) != user) return new Account[0];
            ApplicationInfo app = (ApplicationInfo) caller.getClass().getField("info").get(caller);
            String target = requestedPackage == null ? app.packageName : requestedPackage;
            boolean owner = "com.google.android.gms".equals(app.packageName);
            if (!owner && !target.equals(app.packageName)) return new Account[0];
            Object stored = service.getClass().getMethod("getUserAccounts", int.class).invoke(service, user);
            Object lock = stored.getClass().getField("lock").get(stored);
            synchronized (lock) {
                for (Object record : (List<?>) stored.getClass().getField("accounts").get(stored)) {
                    Account account = (Account) record.getClass().getField("account").get(record);
                    if (type != null && !type.equals(account.type)) continue;
                    Map<?, ?> permissions = (Map<?, ?>) record.getClass().getField("visibility").get(record);
                    Object access = permissions.get(target);
                    if ((owner && target.equals(app.packageName) && "com.google".equals(account.type))
                            || Integer.valueOf(AccountManager.VISIBILITY_VISIBLE).equals(access)
                            || Integer.valueOf(AccountManager.VISIBILITY_USER_MANAGED_VISIBLE).equals(access)) visible.add(account);
                }
            }
        } catch (ReflectiveOperationException | RuntimeException unavailable) { return new Account[0]; }
        return visible.toArray(new Account[0]);
    }

    private static Object caller() throws ReflectiveOperationException {
        Class<?> processes = Class.forName("top.niunaijun.blackbox.core.system.BProcessManagerService");
        Object record = processes.getMethod("findProcessByPid", int.class)
                .invoke(processes.getMethod("get").invoke(null), Binder.getCallingPid());
        if (record == null) throw new SecurityException("Unknown private account caller");
        return record;
    }

    public static void requireOwner(int user) {
        try {
            Object record = caller();
            ApplicationInfo app = (ApplicationInfo) record.getClass().getField("info").get(record);
            if (record.getClass().getField("userId").getInt(record) != user
                    || !"com.google.android.gms".equals(app.packageName))
                throw new SecurityException("Private Google account owner required");
        } catch (ReflectiveOperationException unavailable) { throw new SecurityException("Account owner unavailable", unavailable); }
    }

    public static Map<Account, Integer> accountVisibility(Object service, String pkg, String type, int user) {
        Map<Account, Integer> result = new HashMap<>();
        try {
            Object record = caller();
            ApplicationInfo app = (ApplicationInfo) record.getClass().getField("info").get(record);
            if (record.getClass().getField("userId").getInt(record) != user) return result;
            boolean owner = "com.google.android.gms".equals(app.packageName);
            String target = pkg == null ? app.packageName : pkg;
            Account[] allowed = owner ? new Account[0] : accounts(service, type, user, target);
            Object stored = service.getClass().getMethod("getUserAccounts", int.class).invoke(service, user);
            synchronized (stored.getClass().getField("lock").get(stored)) {
                for (Object entry : (List<?>) stored.getClass().getField("accounts").get(stored)) {
                    Account account = (Account) entry.getClass().getField("account").get(entry);
                    boolean readable = owner && "com.google".equals(account.type) && (type == null || type.equals(account.type));
                    for (Account visible : allowed) if (visible.equals(account)) readable = true;
                    if (readable) {
                        Object permission = ((Map<?, ?>) entry.getClass().getField("visibility").get(entry)).get(target);
                        result.put(account, permission instanceof Integer ? (Integer) permission : AccountManager.VISIBILITY_NOT_VISIBLE);
                    }
                }
            }
        } catch (ReflectiveOperationException | RuntimeException unavailable) { result.clear(); }
        return result;
    }

    /** A successful new Google account is immediately usable by the signature-checked private Play Store. */
    public static void accountAdded(Object service, Account account, int user) {
        requireOwner(user);
        if (account == null || !"com.google".equals(account.type)) return;
        try {
            Context host = (Context) Class.forName("top.niunaijun.blackbox.BlackBoxCore").getMethod("getContext").invoke(null);
            SpacePackages packages = new SpacePackages(host);
            PackageInfo play = packages.installed("com.android.vending");
            if (!packages.privateCopy(play)) return;
            SpacePackages.inspect(host, new java.io.File(play.applicationInfo.sourceDir));
            Object stored = service.getClass().getMethod("getUserAccounts", int.class).invoke(service, user);
            synchronized (stored.getClass().getField("lock").get(stored)) {
                for (Object entry : (List<?>) stored.getClass().getField("accounts").get(stored)) {
                    if (!account.equals(entry.getClass().getField("account").get(entry))) continue;
                    Map<?, ?> visibility = (Map<?, ?>) entry.getClass().getField("visibility").get(entry);
                    if (visibility.containsKey("com.android.vending")) return;
                    service.getClass().getMethod("setAccountVisibility", Account.class, String.class, int.class, int.class)
                            .invoke(service, account, "com.android.vending", AccountManager.VISIBILITY_VISIBLE, user);
                    return;
                }
            }
        } catch (Exception unavailable) {
            // Account creation has already succeeded. Preserve it; a later microG bind can resync visibility.
            android.util.Log.w("CageDemo", "New account visibility unavailable: " + unavailable.getClass().getSimpleName());
        }
    }

    public static int visibility(Object service, Account account, String pkg, int user) {
        if (account == null) return AccountManager.VISIBILITY_NOT_VISIBLE;
        Integer result = accountVisibility(service, pkg, account.type, user).get(account);
        return result == null ? AccountManager.VISIBILITY_NOT_VISIBLE : result;
    }

    public static Map<String, Integer> ownerVisibility(Object service, Account account, int user) {
        requireOwner(user);
        Map<String, Integer> result = new HashMap<>();
        if (account == null || !"com.google".equals(account.type)) return result;
        try {
            Object stored = service.getClass().getMethod("getUserAccounts", int.class).invoke(service, user);
            synchronized (stored.getClass().getField("lock").get(stored)) {
                for (Object entry : (List<?>) stored.getClass().getField("accounts").get(stored)) {
                    if (!account.equals(entry.getClass().getField("account").get(entry))) continue;
                    Map<?, ?> visibility = (Map<?, ?>) entry.getClass().getField("visibility").get(entry);
                    for (Map.Entry<?, ?> value : visibility.entrySet()) {
                        if (value.getKey() instanceof String && value.getValue() instanceof Integer)
                            result.put((String) value.getKey(), (Integer) value.getValue());
                    }
                    return result;
                }
            }
        } catch (ReflectiveOperationException unavailable) { throw new IllegalStateException("Account visibility unavailable", unavailable); }
        return result;
    }

    public static int callerUid() {
        try {
            Object record = caller();
            int uid = ((ApplicationInfo) record.getClass().getField("info").get(record)).uid;
            if (uid < 10000) throw new SecurityException("Invalid private account caller");
            return uid;
        } catch (ReflectiveOperationException unavailable) { throw new SecurityException("Account caller unavailable", unavailable); }
    }

    public static Bundle authorize(Object service, Account account, Bundle supplied, int user) {
        try {
            Object record = caller();
            if (record.getClass().getField("userId").getInt(record) != user)
                throw new SecurityException("Account user mismatch");
            ApplicationInfo app = (ApplicationInfo) record.getClass().getField("info").get(record);
            Bundle options = supplied == null ? new Bundle() : new Bundle(supplied);
            String claimed = options.getString(AccountManager.KEY_ANDROID_PACKAGE_NAME);
            if (claimed != null && !app.packageName.equals(claimed))
                throw new SecurityException("Account package mismatch");
            boolean visible = false;
            for (Account allowed : accounts(service, account == null ? null : account.type, user, null))
                if (allowed.equals(account)) visible = true;
            if (!visible) throw new SecurityException("Account is not visible to caller");
            options.putString(AccountManager.KEY_ANDROID_PACKAGE_NAME, app.packageName);
            return options;
        } catch (ReflectiveOperationException unavailable) { throw new SecurityException("Account caller unavailable", unavailable); }
    }

    private static boolean trustedCaller(int pid, int uid) {
        Peer expected = peer;
        return expected != null && pid == expected.pid && uid == expected.uid
                && Binder.getCallingPid() == expected.pid && expected.service.isBinderAlive();
    }

    public static void serviceCreated(Service service) {
        if (Build.VERSION.SDK_INT < 36 || !"org.microg.gms.auth.loginservice.GoogleLoginService".equals(service.getClass().getName())) return;
        try {
            Field field = service.getClass().getDeclaredField("authenticator"); field.setAccessible(true);
            IBinder transport = ((AbstractAccountAuthenticator) field.get(service)).getIBinder();
            Context context = new ContextWrapper(service) {
                @Override public int checkPermission(String permission, int pid, int uid) {
                    if ("android.permission.ACCOUNT_MANAGER".equals(permission))
                        return trustedCaller(pid, uid) ? PackageManager.PERMISSION_GRANTED : PackageManager.PERMISSION_DENIED;
                    return super.checkPermission(permission, pid, uid);
                }
            };
            Object enforcer = Class.forName("android.os.PermissionEnforcer").getConstructor(Context.class).newInstance(context);
            Field target = Class.forName("android.accounts.IAccountAuthenticator$Stub").getDeclaredField("mEnforcer");
            target.setAccessible(true); target.set(transport, enforcer);
            android.util.Log.i("CageDemo", "Private microG authenticator transport ready");
        } catch (ReflectiveOperationException unavailable) { throw new IllegalStateException("Private authenticator unavailable", unavailable); }
    }
}
