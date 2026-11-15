package io.github.leexeo.cage.gbox;

import android.accounts.Account;
import android.os.Bundle;
import android.util.Log;
import java.util.List;
import java.util.Map;

/**
 * Privacy-safe diagnostics and virtual account visibility resolution for virtual
 * account queries and saves. Logs only fixed stage names, safe package categories,
 * booleans, counts, visibility integers, and exception class names. Never logs
 * Account.name, passwords, extras contents, tokens, or Throwable.getMessage().
 */
public final class AccountDiag {
    private static final String TAG = "CageAccountDiag";

    private AccountDiag() {}

    private static String pkgCat(String pkg) {
        if (pkg == null) {
            return "null";
        }
        if ("com.android.vending".equals(pkg)) {
            return "vending";
        }
        if ("com.google.android.gms".equals(pkg)) {
            return "gms";
        }
        if ("com.android.vending.mgc".equals(pkg)) {
            return "mgc";
        }
        if ("com.anthropic.claude".equals(pkg)) {
            return "claude";
        }
        if ("com.cage.android".equals(pkg) || "com.gbox.android".equals(pkg)) {
            return "host";
        }
        return "other";
    }

    private static boolean typeIsGoogle(String type) {
        return "com.google".equals(type);
    }

    private static boolean typeIsGoogle(Account acct) {
        return acct != null && "com.google".equals(acct.type);
    }

    private static int count(Account[] accounts) {
        return accounts == null ? -1 : accounts.length;
    }

    private static int googleCount(Account[] accounts) {
        if (accounts == null) {
            return -1;
        }
        int total = 0;
        for (int i = 0; i < accounts.length; i++) {
            if (accounts[i] != null && "com.google".equals(accounts[i].type)) {
                total++;
            }
        }
        return total;
    }

    private static int safeBundleSize(Bundle extras) {
        if (extras == null) {
            return -1;
        }
        try {
            return extras.size();
        } catch (Throwable ignored) {
            return -2;
        }
    }

    private static int safeMapSize(Map map) {
        if (map == null) {
            return -1;
        }
        try {
            return map.size();
        } catch (Throwable ignored) {
            return -2;
        }
    }

    public static void logS(String type, String opPkg, Account[] result) {
        Log.i(TAG, "S typeIsGoogle=" + typeIsGoogle(type)
                + " opPkg=" + pkgCat(opPkg)
                + " count=" + count(result)
                + " gCount=" + googleCount(result));
    }

    public static void logSCatch(Throwable error) {
        String name = error == null ? "null" : error.getClass().getSimpleName();
        Log.i(TAG, "S.catch ex=" + name);
    }

    public static void logZ(int userId, int callingUid, String callingPkg, List list) {
        int size = -1;
        boolean hasGoogle = false;
        if (list != null) {
            size = list.size();
            for (int i = 0; i < size; i++) {
                if ("com.google".equals(list.get(i))) {
                    hasGoogle = true;
                    break;
                }
            }
        }
        Log.i(TAG, "z user=" + userId
                + " uid=" + callingUid
                + " pkg=" + pkgCat(callingPkg)
                + " authCount=" + size
                + " hasGoogle=" + hasGoogle);
    }

    public static void logV0(
            String type,
            int callingUid,
            String callingPkg,
            int userId,
            String opPkg,
            boolean includeUndefined,
            Account[] result) {
        Log.i(TAG, "V0 typeIsGoogle=" + typeIsGoogle(type)
                + " uid=" + callingUid
                + " callingPkg=" + pkgCat(callingPkg)
                + " user=" + userId
                + " opPkg=" + pkgCat(opPkg)
                + " undef=" + includeUndefined
                + " count=" + count(result)
                + " gCount=" + googleCount(result));
    }

    public static void logT(String type, int callingUid, String pkg, boolean visibleOnly, Account[] result) {
        Log.i(TAG, "t typeIsGoogle=" + typeIsGoogle(type)
                + " uid=" + callingUid
                + " pkg=" + pkgCat(pkg)
                + " visOnly=" + visibleOnly
                + " count=" + count(result)
                + " gCount=" + googleCount(result));
    }

    public static void logTNullTypeMap() {
        Log.i(TAG, "t.branch=nullTypeMap");
    }

    public static void logTEmptyAllMap() {
        Log.i(TAG, "t.branch=emptyAllMap");
    }

    public static void logX1(Account[] inAccounts, int callingUid, String pkg, boolean visibleOnly, Account[] outAccounts) {
        Log.i(TAG, "x1 inCount=" + count(inAccounts)
                + " inG=" + googleCount(inAccounts)
                + " uid=" + callingUid
                + " pkg=" + pkgCat(pkg)
                + " visOnly=" + visibleOnly
                + " outCount=" + count(outAccounts)
                + " outG=" + googleCount(outAccounts));
    }

    public static void logY(Account account, String packageName, Integer vis) {
        Log.i(TAG, "Y acctNull=" + (account == null)
                + " typeIsGoogle=" + typeIsGoogle(account)
                + " pkg=" + pkgCat(packageName)
                + " vis=" + (vis == null ? "null" : vis.toString()));
    }

    public static Integer resolveY(Account account, String packageName, Integer rawVis) {
        Integer resolved = rawVis;
        if (typeIsGoogle(account) && rawVis != null) {
            if ("com.android.vending".equals(packageName)
                    || "com.android.vending.mgc".equals(packageName)
                    || "com.cage.android".equals(packageName)
                    || "com.gbox.android".equals(packageName)) {
                resolved = Integer.valueOf(1);
            } else if (rawVis.intValue() == 4 || rawVis.intValue() == 2) {
                resolved = Integer.valueOf(1);
            }
        }
        Log.i(TAG, "Y acctNull=" + (account == null)
                + " typeIsGoogle=" + typeIsGoogle(account)
                + " pkg=" + pkgCat(packageName)
                + " rawVis=" + (rawVis == null ? "null" : rawVis.toString())
                + " vis=" + (resolved == null ? "null" : resolved.toString()));
        return resolved;
    }

    public static void logYNameNotFound(String packageName) {
        Log.i(TAG, "Y.catch=NameNotFoundException pkg=" + pkgCat(packageName));
    }

    public static void logO(Account account, Bundle extras, Map visMap, boolean ok) {
        Log.i(TAG, "O acctNull=" + (account == null)
                + " typeIsGoogle=" + typeIsGoogle(account)
                + " extrasSize=" + safeBundleSize(extras)
                + " visSize=" + safeMapSize(visMap)
                + " ok=" + ok);
    }

    public static void logT0(Account account, int userId, Map visMap, boolean ok) {
        Log.i(TAG, "t0 acctNull=" + (account == null)
                + " typeIsGoogle=" + typeIsGoogle(account)
                + " user=" + userId
                + " visSize=" + safeMapSize(visMap)
                + " ok=" + ok);
    }
}
