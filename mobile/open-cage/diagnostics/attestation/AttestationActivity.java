package io.github.flysky701.cage.attestationprobe;

import android.app.Activity;
import android.os.Bundle;
import android.security.keystore.KeyGenParameterSpec;
import android.security.keystore.KeyProperties;
import android.util.Base64;
import android.widget.TextView;
import java.nio.charset.StandardCharsets;
import java.security.KeyPairGenerator;
import java.security.KeyStore;
import java.security.SecureRandom;
import java.security.cert.Certificate;
import java.security.spec.ECGenParameterSpec;
import org.json.JSONArray;
import org.json.JSONObject;

/** Diagnostic only: request a real, ephemeral key and export its public certificates.
 * No private key, device IDs or account data are exported; this is not a Play Integrity request.
 */
public final class AttestationActivity extends Activity {
    @Override public void onCreate(Bundle state) {
        super.onCreate(state);
        TextView status = new TextView(this);
        status.setPadding(32, 80, 32, 32);
        status.setText("正在读取测试密钥的硬件证明…");
        setContentView(status);
        new Thread(() -> {
            JSONObject result = new JSONObject();
            KeyStore store = null;
            String alias = getPackageName() + ".diagnostic." + java.util.UUID.randomUUID();
            try {
                result.put("requestedPackage", getPackageName());
                result.put("visibleUid", android.os.Process.myUid());
                byte[] challenge = new byte[32];
                new SecureRandom().nextBytes(challenge);
                result.put("challenge", Base64.encodeToString(challenge, Base64.NO_WRAP));
                store = KeyStore.getInstance("AndroidKeyStore");
                store.load(null);
                KeyPairGenerator generator = KeyPairGenerator.getInstance(KeyProperties.KEY_ALGORITHM_EC, "AndroidKeyStore");
                generator.initialize(new KeyGenParameterSpec.Builder(alias, KeyProperties.PURPOSE_SIGN | KeyProperties.PURPOSE_VERIFY)
                        .setAlgorithmParameterSpec(new ECGenParameterSpec("secp256r1"))
                        .setDigests(KeyProperties.DIGEST_SHA256)
                        .setAttestationChallenge(challenge).build());
                generator.generateKeyPair();
                JSONArray certificates = new JSONArray();
                for (Certificate cert : store.getCertificateChain(alias))
                    certificates.put(Base64.encodeToString(cert.getEncoded(), Base64.NO_WRAP));
                result.put("certificates", certificates);
            } catch (Exception error) {
                try { result.put("error", error.getClass().getName() + ": " + error.getMessage()); }
                catch (Exception ignored) { }
            } finally {
                try {
                    if (store != null && store.containsAlias(alias)) store.deleteEntry(alias);
                    result.put("ephemeralKeyRemoved", store != null && !store.containsAlias(alias));
                } catch (Exception error) {
                    try { result.put("cleanupError", error.getClass().getName()); } catch (Exception ignored) { }
                }
                try (java.io.FileOutputStream output = openFileOutput("attestation.json", MODE_PRIVATE)) {
                    output.write(result.toString(2).getBytes(StandardCharsets.UTF_8));
                    runOnUiThread(() -> status.setText("硬件证明诊断已完成，结果已保存到测试应用私有目录。"));
                } catch (Exception error) {
                    runOnUiThread(() -> status.setText("诊断记录保存失败：" + error.getClass().getSimpleName()));
                }
            }
        }, "attestation-diagnostic").start();
    }
}
