package io.github.leexeo.cage.privacy;

import android.net.LinkAddress;
import android.net.LinkProperties;
import android.net.ProxyInfo;
import java.net.InetAddress;
import java.util.Arrays;
import java.util.Collections;
import io.github.leexeo.cage.preflight.NetworkMetadata;
import org.json.JSONObject;

/** Android-runtime tests over synthetic values only; no interfaces or sockets are used. */
public final class LinkPropertiesPrivacyTest {
    private static int checks;

    private static void check(boolean condition) {
        ++checks;
        if (!condition) throw new AssertionError("Synthetic network policy check " + checks);
    }

    private static LinkAddress link(byte[] address, int prefix) throws Exception {
        return LinkAddress.class.getDeclaredConstructor(InetAddress.class, int.class)
            .newInstance(InetAddress.getByAddress(address), prefix);
    }

    public static void main(String[] args) throws Exception {
        try {
            runChecks();
        } catch (Throwable failure) {
            System.out.println("{\"status\":\"FAIL_SYNTHETIC_ANDROID_RUNTIME\",\"checks\":" + checks
                + ",\"errorClass\":\"" + failure.getClass().getSimpleName() + "\"}");
        }
    }

    private static void runChecks() throws Exception {
        System.out.println("SYNTHETIC_STAGE|main.enter");
        LinkProperties original = new LinkProperties();
        original.setInterfaceName("tun3977");
        original.setLinkAddresses(Arrays.asList(link(new byte[]{(byte)192, 0, 2, 14}, 24),
            link(new byte[]{0x20, 1, 0x0d, (byte)0xb8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 14}, 64)));
        original.setDnsServers(Collections.singletonList(InetAddress.getByAddress(new byte[]{(byte)192, 0, 2, 53})));
        original.setDomains("synthetic.invalid");
        original.setHttpProxy(ProxyInfo.buildDirectProxy("192.0.2.15", 8080));
        original.setMtu(1400);
        LinkProperties before = LinkPropertiesPrivacy.copyForGuest(original, false);
        LinkProperties hidden = LinkPropertiesPrivacy.copyForGuest(original, true);
        check(hidden != original);
        check(hidden.equals(new LinkProperties()));
        check(hidden.getInterfaceName() == null);
        check(hidden.getLinkAddresses().isEmpty() && hidden.getDnsServers().isEmpty());
        check(hidden.getRoutes().isEmpty() && hidden.getDomains() == null && hidden.getHttpProxy() == null);
        check(original.equals(before));

        // Non-tunnel data must survive and must not alias the system-owned object.
        LinkProperties visible = LinkPropertiesPrivacy.copyForGuest(original, false);
        check(visible != original && visible.equals(original));
        visible.setDomains("changed.invalid");
        visible.setLinkAddresses(Collections.emptyList());
        check(original.equals(before));
        hidden.setInterfaceName("local-test");
        check(original.equals(before));
        check(LinkPropertiesPrivacy.copyForGuest(null, true) == null);
        check(LinkPropertiesPrivacy.copyForGuest(null, false) == null);
        System.out.println("SYNTHETIC_STAGE|metadata.before");
        JSONObject redaction = NetworkMetadata.selfTest();
        System.out.println("SYNTHETIC_STAGE|metadata.after");
        System.out.println("SYNTHETIC_METADATA|" + redaction.toString());
        check("PASS".equals(redaction.optString("status")));
        check(redaction.optBoolean("rawFixtureValuesAbsent"));
        JSONObject measured = NetworkMetadata.link(hidden);
        check("OK".equals(measured.optString("status")) && measured.getInt("dnsServerCount") == 0
            && measured.getJSONObject("addressCounts").getInt("total") == 0);
        System.out.println("{\"status\":\"PASS_SYNTHETIC_ANDROID_RUNTIME\",\"checks\":" + checks
            + ",\"networkOperations\":0,\"realAddressesCollected\":false,\"guestHookIntegrationVerified\":false}");
    }
}
