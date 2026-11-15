package io.github.leexeo.cage.localcore;

import android.content.*;
import android.content.pm.PackageManager;
import android.database.Cursor;
import android.net.Uri;
import android.os.Binder;
import android.os.Bundle;

/** Synchronous Binder-thread state check, with no configuration disclosure or network startup. */
public final class StatusProvider extends ContentProvider {
    @Override public boolean onCreate() { return true; }

    @Override public Bundle call(String method, String argument, Bundle extras) {
        int uid = Binder.getCallingUid();
        try {
            PackageManager packages = getContext().getPackageManager();
            if (packages.getApplicationInfo("top.niunaijun.microdem", 0).uid != uid
                    || packages.checkSignatures(android.os.Process.myUid(), uid) != PackageManager.SIGNATURE_MATCH)
                throw new SecurityException("caller rejected");
        } catch (PackageManager.NameNotFoundException absent) { throw new SecurityException("caller rejected"); }
        if (!"status".equals(method) || argument != null || extras != null)
            throw new UnsupportedOperationException("status only");
        long identity = Binder.clearCallingIdentity();
        try {
            CoreService service = CoreService.current;
            Bundle result = new Bundle();
            result.putBoolean("protectionReady", service != null && service.safeReady());
            return result;
        } finally { Binder.restoreCallingIdentity(identity); }
    }

    @Override public Cursor query(Uri uri, String[] projection, String selection, String[] args, String sort) { throw unavailable(); }
    @Override public String getType(Uri uri) { throw unavailable(); }
    @Override public Uri insert(Uri uri, ContentValues values) { throw unavailable(); }
    @Override public int delete(Uri uri, String selection, String[] args) { throw unavailable(); }
    @Override public int update(Uri uri, ContentValues values, String selection, String[] args) { throw unavailable(); }
    private static UnsupportedOperationException unavailable() { return new UnsupportedOperationException("status only"); }
}
