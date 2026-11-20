package io.github.flysky701.cage.privacy;

import android.content.Context;
import android.preference.PreferenceManager;
import android.util.Log;

import java.io.File;
import java.io.IOException;
import java.io.RandomAccessFile;
import java.nio.channels.FileLock;

/** One explicit device-registration preference write for the pinned microG APK. */
public final class GuestMicrogSetup {
    public static final long VERSION = 252432036L;
    private static final String PACKAGE = "com.google.android.gms";
    private static final String REGISTRATION = "checkin_enable_service";

    private GuestMicrogSetup() {}

    public static void request(Context host) throws IOException {
        try (RandomAccessFile file = new RandomAccessFile(marker(host), "rw");
             FileLock lock = file.getChannel().lock()) {
            file.setLength(1);
        }
    }

    public static void apply(Context host, Context guest, String pkg, long version) {
        if (!PACKAGE.equals(pkg) || version != VERSION) return;
        File pending = marker(host);
        if (pending.length() == 0) return;
        try (RandomAccessFile file = new RandomAccessFile(pending, "rw");
             FileLock lock = file.getChannel().lock()) {
            if (file.length() == 0) return;
            if (PreferenceManager.getDefaultSharedPreferences(guest).edit()
                    .putBoolean(REGISTRATION, true).commit()) file.setLength(0);
        } catch (IOException | RuntimeException failed) {
            Log.w("CageMicrog", "Could not save the requested registration preference.");
        }
    }

    private static File marker(Context host) {
        return new File(host.getNoBackupFilesDir(), "cage-microg-setup.request");
    }
}
