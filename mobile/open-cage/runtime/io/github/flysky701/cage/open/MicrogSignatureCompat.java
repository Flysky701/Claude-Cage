package io.github.flysky701.cage.open;

import android.content.pm.ApplicationInfo;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.content.pm.Signature;
import android.content.pm.SigningInfo;
import android.os.Build;
import android.os.Parcel;
import java.io.ByteArrayInputStream;
import java.io.File;
import java.security.MessageDigest;
import java.security.cert.CertificateFactory;
import java.security.cert.X509Certificate;
import java.util.Collections;
import top.niunaijun.blackbox.BlackBoxCore;

/** microG's declared compatibility identity, only in guest PackageManager responses.
 * Archive verification, private package storage, other packages and integrity verdicts are unchanged.
 */
public final class MicrogSignatureCompat {
    private static final String GMS = "com.google.android.gms";
    private static final String COMPANION = "com.android.vending";
    private static final String MICROG = "9bd06727e62796c0130eb6dab39b73157451582cbd138e86c468acc395d14165";
    private static final String DECLARED = "f0fd6c5b410f25cb25c3b53346c8972fae30f8ee7411df910480ad6b2d60db83";
    private static String cachedSource;
    private static Signature cachedSignature;

    private MicrogSignatureCompat() {}

    public static PackageInfo forGuest(PackageInfo info, int flags) {
        if (info == null || (!GMS.equals(info.packageName) && !COMPANION.equals(info.packageName)) || Build.VERSION.SDK_INT < 35
                || (flags & (PackageManager.GET_SIGNATURES | PackageManager.GET_SIGNING_CERTIFICATES)) == 0)
            return info;
        try {
            Signature compatible = declaredSignature(info);
            if (compatible == null) return info;
            PackageInfo answer;
            Parcel copy = Parcel.obtain();
            try {
                info.writeToParcel(copy, 0); copy.setDataPosition(0);
                answer = PackageInfo.CREATOR.createFromParcel(copy);
            } finally { copy.recycle(); }
            if ((flags & PackageManager.GET_SIGNATURES) != 0)
                answer.signatures = new Signature[]{new Signature(compatible.toByteArray())};
            if ((flags & PackageManager.GET_SIGNING_CERTIFICATES) != 0) {
                X509Certificate cert = (X509Certificate) CertificateFactory.getInstance("X.509")
                        .generateCertificate(new ByteArrayInputStream(compatible.toByteArray()));
                answer.signingInfo = new SigningInfo(SigningInfo.VERSION_JAR,
                        Collections.singletonList(compatible), Collections.singletonList(cert.getPublicKey()),
                        Collections.singletonList(compatible));
            }
            return answer;
        } catch (Exception unavailable) {
            android.util.Log.w("CageMicrogCompat", "Compatibility identity unavailable: " + unavailable.getClass().getSimpleName());
            return info;
        }
    }

    private static synchronized Signature declaredSignature(PackageInfo info) throws Exception {
        if (info.applicationInfo == null || info.applicationInfo.sourceDir == null) return null;
        File source = new File(info.applicationInfo.sourceDir).getCanonicalFile();
        File expected = new File(BlackBoxCore.getContext().getDataDir(), "blackbox/data/app/" + info.packageName + "/base.apk").getCanonicalFile();
        if (!source.equals(expected) || !source.isFile()) return null;
        String key = source.getPath() + ":" + source.length() + ":" + source.lastModified();
        if (key.equals(cachedSource)) return cachedSignature;
        PackageManager pm = BlackBoxCore.getPackageManager();
        PackageInfo original = pm.getPackageArchiveInfo(source.getPath(),
                PackageManager.GET_SIGNING_CERTIFICATES | PackageManager.GET_META_DATA | PackageManager.GET_PERMISSIONS);
        if (original == null || !info.packageName.equals(original.packageName) || original.signingInfo == null
                || original.signingInfo.hasMultipleSigners()
                || !MICROG.equals(digest(original.signingInfo.getApkContentsSigners()[0]))) return null;
        boolean requested = false;
        if (original.requestedPermissions != null) for (String permission : original.requestedPermissions)
            if ("android.permission.FAKE_PACKAGE_SIGNATURE".equals(permission)) requested = true;
        if (!requested || original.applicationInfo == null || original.applicationInfo.metaData == null) return null;
        Object declaration = original.applicationInfo.metaData.get("fake-signature");
        String encoded;
        if (declaration instanceof String) encoded = (String) declaration;
        else if (declaration instanceof Integer) {
            ApplicationInfo resources = new ApplicationInfo(original.applicationInfo);
            resources.sourceDir = source.getPath(); resources.publicSourceDir = source.getPath();
            encoded = pm.getResourcesForApplication(resources).getString((Integer) declaration);
        } else return null;
        Signature signature = new Signature(encoded);
        if (!DECLARED.equals(digest(signature))) return null;
        cachedSource = key; cachedSignature = signature;
        return signature;
    }

    private static String digest(Signature signature) throws Exception {
        StringBuilder text = new StringBuilder();
        for (byte b : MessageDigest.getInstance("SHA-256").digest(signature.toByteArray())) {
            text.append(Character.forDigit((b >>> 4) & 15, 16));
            text.append(Character.forDigit(b & 15, 16));
        }
        return text.toString();
    }
}
