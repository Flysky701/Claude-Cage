package io.github.flysky701.cage.open;

import java.lang.reflect.Field;
import java.security.Provider;
import java.security.Security;
import java.util.Map;

/** Restore platform algorithms omitted by microG's replacement provider.
 * Its KeyStore SPI and certificate-chain blocking policy remain in charge.
 */
public final class MicrogKeystoreCompat {
    private static final String PROVIDER = "org.microg.gms.droidguard.core.HardwareAttestationBlockingProvider";
    private static final String BLOCKER = "org.microg.gms.droidguard.core.HardwareAttestationBlockingKeyStore";
    private static final String STORE = "KeyStore.AndroidKeyStore";

    private MicrogKeystoreCompat() {}

    // Called only after the Android 16 guest microG DroidGuard START service binds.
    public static void restoreAlgorithms() {
        Provider active = Security.getProvider("AndroidKeyStore");
        if (active == null || !PROVIDER.equals(active.getClass().getName())
                || !BLOCKER.equals(active.get(STORE))) return;
        try {
            Field field = active.getClass().getDeclaredField("originalProvider");
            field.setAccessible(true);
            Object value = field.get(null);
            if (!(value instanceof Provider)) return;
            Provider original = (Provider) value;
            if (!"AndroidKeyStore".equals(original.getName())
                    || !"android.security.keystore2.AndroidKeyStoreProvider".equals(original.getClass().getName())) return;
            int restored = 0;
            synchronized (active) {
                // Preserve the original provider's registrations, as the upstream
                // ProxyProvider constructor does, without replacing microG's KeyStore SPI.
                // Reference: kdrag0n/safetynet-fix, 89a4cf49360a1fc4c10a09e9ff56deda08e922e4,
                // java/app/src/main/java/dev/kdrag0n/safetynetfix/proxy/ProxyProvider.kt.
                for (Map.Entry<Object, Object> entry : original.entrySet()) {
                    if (STORE.equals(entry.getKey())) continue;
                    if (active.putIfAbsent(entry.getKey(), entry.getValue()) == null) restored++;
                }
            }
            if (restored != 0) android.util.Log.i("CageMicrogKeystore", "Restored platform algorithm entries: " + restored
                    + "; EC=" + (active.getService("KeyPairGenerator", "EC") != null)
                    + "; RSA=" + (active.getService("KeyPairGenerator", "RSA") != null)
                    + "; blocker=" + BLOCKER.equals(active.getService("KeyStore", "AndroidKeyStore").getClassName()));
        } catch (ReflectiveOperationException | RuntimeException unavailable) {
            android.util.Log.w("CageMicrogKeystore", "Algorithm compatibility unavailable: "
                    + unavailable.getClass().getSimpleName());
        }
    }
}
