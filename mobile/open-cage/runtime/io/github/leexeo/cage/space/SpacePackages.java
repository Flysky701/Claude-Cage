package io.github.leexeo.cage.space;

import android.content.Context;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import java.io.File;
import java.io.IOException;
import top.niunaijun.blackbox.BlackBoxCore;

/** Package access for the existing original-APK split importer. */
final class SpacePackages {
    private final Context host;
    SpacePackages(Context host) { this.host = host; }
    PackageInfo installed(String packageName) throws Exception {
        return BlackBoxCore.getBPackageManager().getService().getPackageInfo(packageName, 0, 0);
    }
    boolean privateCopy(PackageInfo info) throws IOException {
        if (info == null || info.applicationInfo == null || info.applicationInfo.sourceDir == null) return false;
        return new File(host.getDataDir(), "blackbox/data/app/" + info.packageName + "/base.apk")
                .getCanonicalFile().equals(new File(info.applicationInfo.sourceDir).getCanonicalFile());
    }
    static long version(PackageInfo info) { return info.getLongVersionCode(); }

    /** The login capability may only target the original upstream microG APK. */
    static void inspect(Context host, File source) throws Exception {
        PackageInfo info = BlackBoxCore.getPackageManager().getPackageArchiveInfo(source.getCanonicalPath(),
                PackageManager.GET_SIGNING_CERTIFICATES);
        if (info == null || !"com.google.android.gms".equals(info.packageName) || info.signingInfo == null
                || info.signingInfo.hasMultipleSigners()) throw new SecurityException("Original microG required");
        byte[] digest = java.security.MessageDigest.getInstance("SHA-256")
                .digest(info.signingInfo.getApkContentsSigners()[0].toByteArray());
        StringBuilder hex = new StringBuilder();
        for (byte b : digest) {
            hex.append(Character.forDigit((b >>> 4) & 15, 16));
            hex.append(Character.forDigit(b & 15, 16));
        }
        if (!"9bd06727e62796c0130eb6dab39b73157451582cbd138e86c468acc395d14165".equals(hex.toString()))
            throw new SecurityException("Original microG required");
    }
}
