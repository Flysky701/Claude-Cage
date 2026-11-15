package io.github.leexeo.cage.preflight;

import android.net.IpPrefix;
import android.net.LinkAddress;
import android.net.LinkProperties;
import android.net.ProxyInfo;
import android.net.RouteInfo;
import android.os.Build;
import java.lang.reflect.InvocationTargetException;
import java.net.Inet4Address;
import java.net.Inet6Address;
import java.net.InetAddress;
import java.net.NetworkInterface;
import java.util.Arrays;
import java.util.Enumeration;
import java.util.List;
import org.json.JSONException;
import org.json.JSONObject;

/** Local counts only. No DNS lookup, connection, address, hostname or interface-name output. */
public final class NetworkMetadata {
    private static final String[] COUNTS = {"dnsServerCount", "routeCount", "routeInterfaceNameCount",
        "tunnelRouteCount", "gatewayRouteCount", "defaultRouteCount"};
    private static final String[] FLAGS = {"hasInterfaceName", "tunnelInterfaceName", "hasDomains",
        "hasProxy", "privateDnsActive", "hasPrivateDnsServerName", "hasNonDefaultMtu",
        "hasDhcpServerAddress", "hasNat64Prefix"};
    private static final String[] ADDRESS_COUNTS = {"total", "ipv4", "ipv6", "linkLocal", "loopback",
        "siteLocal", "uniqueLocal", "multicast", "unspecified", "publicCandidate"};
    private NetworkMetadata() {}

    /** Strict shape check: errors, absent getters and unsupported APIs are never empty success. */
    public static boolean complete(JSONObject reading) {
        if (reading == null || !"OK".equals(reading.optString("status"))) return false;
        JSONObject addresses = reading.optJSONObject("addressCounts");
        if (addresses == null || !"OK".equals(addresses.optString("status"))) return false;
        int total = count(addresses, "total");
        if (total < 0) return false;
        for (String key : ADDRESS_COUNTS)
            if (count(addresses, key) < 0 || count(addresses, key) > total) return false;
        if ((long) count(addresses, "ipv4") + count(addresses, "ipv6") != total) return false;
        for (String key : COUNTS) if (count(reading, key) < 0) return false;
        for (int i = 2; i < COUNTS.length; i++)
            if (count(reading, COUNTS[i]) > count(reading, "routeCount")) return false;
        for (String key : FLAGS) if (!(reading.opt(key) instanceof Boolean)) return false;
        for (String key : new String[]{"privateDnsStatus", "mtuStatus", "dhcpStatus", "nat64Status"})
            if (!"OK".equals(reading.optString(key))) return false;
        return true;
    }

    /** Positive metadata control; an interface name alone is insufficient. */
    public static boolean hasPayload(JSONObject reading) {
        if (!complete(reading)) return false;
        if (count(reading.optJSONObject("addressCounts"), "total") > 0) return true;
        for (String key : COUNTS) if (count(reading, key) > 0) return true;
        for (int i = 2; i < FLAGS.length; i++) if (reading.optBoolean(FLAGS[i])) return true;
        return false;
    }

    public static boolean empty(JSONObject reading) {
        return complete(reading) && !hasPayload(reading)
            && !reading.optBoolean("hasInterfaceName") && !reading.optBoolean("tunnelInterfaceName");
    }

    private static int count(JSONObject reading, String key) {
        Object value = reading == null ? null : reading.opt(key);
        if (!(value instanceof Integer) && !(value instanceof Long)) return -1;
        long number = ((Number) value).longValue();
        return number >= 0 && number <= Integer.MAX_VALUE ? (int) number : -1;
    }

    /** Summarizes a link without serializing any of its raw metadata. */
    public static JSONObject link(LinkProperties link) {
        if (link == null) return status("NO_LINK");
        String stage = "addresses";
        try {
            Counts counts = new Counts();
            List<LinkAddress> addresses = link.getLinkAddresses();
            if (addresses == null) throw new IllegalStateException();
            for (LinkAddress address : addresses) {
                if (address == null) throw new IllegalStateException();
                counts.add(address.getAddress());
            }
            JSONObject out = status("OK");
            out.put("addressCounts", counts.json());
            stage = "dnsServers";
            List<InetAddress> servers = link.getDnsServers();
            if (servers == null) throw new IllegalStateException();
            for (InetAddress server : servers) if (server == null) throw new IllegalStateException();
            out.put("dnsServerCount", servers.size());
            stage = "routes";
            List<RouteInfo> routes = link.getRoutes();
            if (routes == null) throw new IllegalStateException();
            int tunnelRoutes = 0, namedRoutes = 0, gatewayRoutes = 0, defaultRoutes = 0;
            for (RouteInfo route : routes) {
                if (route == null) throw new IllegalStateException();
                String name = route.getInterface();
                if (present(name)) namedRoutes++;
                if (tunnelName(name)) tunnelRoutes++;
                if (route.hasGateway()) gatewayRoutes++;
                if (route.isDefaultRoute()) defaultRoutes++;
            }
            out.put("routeCount", routes.size());
            out.put("routeInterfaceNameCount", namedRoutes);
            out.put("tunnelRouteCount", tunnelRoutes);
            out.put("gatewayRouteCount", gatewayRoutes);
            out.put("defaultRouteCount", defaultRoutes);
            stage = "interface";
            String name = link.getInterfaceName();
            out.put("hasInterfaceName", present(name));
            out.put("tunnelInterfaceName", tunnelName(name));
            stage = "domains";
            out.put("hasDomains", present(link.getDomains()));
            stage = "proxy";
            out.put("hasProxy", link.getHttpProxy() != null);
            stage = "privateDns";
            out.put("privateDnsStatus", Build.VERSION.SDK_INT >= 28 ? "OK" : "UNSUPPORTED_API");
            if (Build.VERSION.SDK_INT >= 28) {
                out.put("privateDnsActive", link.isPrivateDnsActive());
                out.put("hasPrivateDnsServerName", present(link.getPrivateDnsServerName()));
            }
            stage = "mtu";
            out.put("mtuStatus", Build.VERSION.SDK_INT >= 29 ? "OK" : "UNSUPPORTED_API");
            if (Build.VERSION.SDK_INT >= 29) out.put("hasNonDefaultMtu", link.getMtu() != 0);
            stage = "dhcp";
            out.put("dhcpStatus", Build.VERSION.SDK_INT >= 30 ? "OK" : "UNSUPPORTED_API");
            if (Build.VERSION.SDK_INT >= 30) out.put("hasDhcpServerAddress", link.getDhcpServerAddress() != null);
            stage = "nat64";
            out.put("nat64Status", Build.VERSION.SDK_INT >= 30 ? "OK" : "UNSUPPORTED_API");
            if (Build.VERSION.SDK_INT >= 30) out.put("hasNat64Prefix", link.getNat64Prefix() != null);
            return out;
        } catch (Exception | LinkageError failure) {
            // Discard partial counts: a failed getter must not become a zero-valued success.
            return error(stage, failure);
        }
    }

    /** Reads already-local interface addresses; does not resolve their names or query the network. */
    public static JSONObject addresses(NetworkInterface networkInterface) {
        if (networkInterface == null) return status("NULL");
        try {
            Enumeration<InetAddress> addresses = networkInterface.getInetAddresses();
            if (addresses == null) throw new IllegalStateException();
            Counts counts = new Counts();
            while (addresses.hasMoreElements()) counts.add(addresses.nextElement());
            return counts.json();
        } catch (Exception | LinkageError failure) {
            return error("interfaceAddresses", failure);
        }
    }

    private static final class Counts {
        int total, ipv4, ipv6, linkLocal, loopback, siteLocal, uniqueLocal, multicast, unspecified;
        int publicCandidate;

        void add(InetAddress address) {
            if (address == null) throw new IllegalStateException();
            byte[] bytes = address.getAddress();
            boolean v4 = address instanceof Inet4Address, v6 = address instanceof Inet6Address;
            if ((!v4 && !v6) || bytes == null || bytes.length != (v4 ? 4 : 16))
                throw new IllegalStateException();
            boolean link = address.isLinkLocalAddress(), loop = address.isLoopbackAddress();
            boolean site = address.isSiteLocalAddress(), multi = address.isMulticastAddress();
            boolean any = address.isAnyLocalAddress(), unique = v6 && (bytes[0] & 0xfe) == 0xfc;
            total++;
            if (v4) ipv4++;
            if (v6) ipv6++;
            if (link) linkLocal++;
            if (loop) loopback++;
            if (site) siteLocal++;
            if (unique) uniqueLocal++;
            if (multi) multicast++;
            if (any) unspecified++;
            if (!link && !loop && !site && !unique && !multi && !any) publicCandidate++;
        }

        JSONObject json() throws JSONException {
            JSONObject out = status("OK");
            out.put("total", total);
            out.put("ipv4", ipv4);
            out.put("ipv6", ipv6);
            out.put("linkLocal", linkLocal);
            out.put("loopback", loopback);
            out.put("siteLocal", siteLocal);
            out.put("uniqueLocal", uniqueLocal);
            out.put("multicast", multicast);
            out.put("unspecified", unspecified);
            out.put("publicCandidate", publicCandidate);
            // Includes special-use/documentation ranges; this is not a routing or egress test.
            out.put("publicCandidateMeaning", "NON_LOCAL_UNICAST_NOT_PROVEN_ROUTABLE");
            return out;
        }
    }

    private static boolean present(String value) { return value != null && !value.isEmpty(); }

    private static boolean tunnelName(String value) {
        // A bounded name heuristic, not discovery of every VPN/tunnel implementation.
        return value != null && value.matches("(?:tun|tap|ppp|wg|ipsec)[0-9]+");
    }

    private static JSONObject status(String value) {
        JSONObject out = new JSONObject();
        try { out.put("status", value); }
        catch (JSONException impossible) { throw new AssertionError("Fixed status encoding failed"); }
        return out;
    }

    private static JSONObject error(String stage, Throwable failure) {
        if (failure instanceof InvocationTargetException && failure.getCause() != null)
            failure = failure.getCause();
        JSONObject out = status("ERROR");
        try {
            out.put("stage", stage);
            // Never retain getMessage(), toString(), a stack trace, or the failed object's value.
            out.put("errorClass", failure.getClass().getSimpleName());
        } catch (JSONException impossible) { throw new AssertionError("Fixed error encoding failed"); }
        return out;
    }

    /**
     * Android-runtime redaction check using synthetic objects only, not real network state.
     * Hidden fixture constructors/setters may be denied; that is ERROR, never a successful test.
     */
    public static JSONObject selfTest() {
        String stage = "fixtureSetup";
        try {
            InetAddress ipv4 = InetAddress.getByAddress(new byte[]{(byte) 192, 0, 2, 17});
            InetAddress ipv6 = InetAddress.getByAddress(new byte[]{0x20, 1, 0x0d, (byte) 0xb8,
                0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 17});
            String domain = "fixture-domain.invalid", proxy = "fixture-proxy.invalid";
            String privateDns = "fixture-dns.invalid", iface = "tun731";
            stage = "fixtureLinkAddressConstructorLookup";
            java.lang.reflect.Constructor<LinkAddress> linkConstructor = LinkAddress.class
                .getDeclaredConstructor(InetAddress.class, int.class);
            stage = "fixtureIpv4AddressConstruct";
            LinkAddress v4Link = linkConstructor.newInstance(ipv4, 24);
            stage = "fixtureIpv6AddressConstruct";
            LinkAddress v6Link = linkConstructor.newInstance(ipv6, 64);
            stage = "fixtureLinkPropertiesSetup";
            LinkProperties fixture = new LinkProperties();
            fixture.setInterfaceName(iface);
            fixture.setLinkAddresses(Arrays.asList(v4Link, v6Link));
            fixture.setDnsServers(Arrays.asList(ipv4, ipv6));
            fixture.setDomains(domain);
            fixture.setHttpProxy(ProxyInfo.buildDirectProxy(proxy, 8080));
            // AOSP's three-argument IpPrefix constructor is limited to target SDK R.
            // The explicit-type constructor retains the same default unicast semantics.
            stage = "fixtureRouteConstructorLookup";
            java.lang.reflect.Constructor<RouteInfo> routeConstructor = RouteInfo.class
                .getDeclaredConstructor(IpPrefix.class, InetAddress.class, String.class, int.class);
            stage = "fixtureRouteConstruct";
            RouteInfo route = routeConstructor.newInstance(
                new IpPrefix(InetAddress.getByAddress(new byte[4]), 0), ipv4, iface, RouteInfo.RTN_UNICAST);
            stage = "fixtureRouteAdd";
            if (!fixture.addRoute(route)) throw new IllegalStateException();
            if (Build.VERSION.SDK_INT >= 28) {
                stage = "fixturePrivateDnsActiveSetterLookup";
                java.lang.reflect.Method activeSetter = LinkProperties.class
                    .getDeclaredMethod("setUsePrivateDns", boolean.class);
                stage = "fixturePrivateDnsActiveSet";
                activeSetter.invoke(fixture, true);
                stage = "fixturePrivateDnsNameSetterLookup";
                java.lang.reflect.Method nameSetter = LinkProperties.class
                    .getDeclaredMethod("setPrivateDnsServerName", String.class);
                stage = "fixturePrivateDnsNameSet";
                nameSetter.invoke(fixture, privateDns);
            }
            stage = "fixtureMtuSet";
            if (Build.VERSION.SDK_INT >= 29) fixture.setMtu(1400);
            if (Build.VERSION.SDK_INT >= 30) {
                stage = "fixtureDhcpSet";
                fixture.setDhcpServerAddress((Inet4Address) ipv4);
                stage = "fixtureNat64Set";
                fixture.setNat64Prefix(new IpPrefix(ipv6, 96));
            }
            stage = "fixtureSummary";
            JSONObject populated = link(fixture), empty = link(new LinkProperties());
            if (!"OK".equals(populated.optString("status")) || !"OK".equals(empty.optString("status")))
                throw new IllegalStateException();
            if (!complete(populated) || !complete(empty) || !hasPayload(populated)
                    || hasPayload(empty) || empty(populated) || !empty(empty)
                    || complete(link(null)) || empty(link(null))) throw new IllegalStateException();
            if (populated.getJSONObject("addressCounts").getInt("total") != 2
                    || populated.getInt("dnsServerCount") != 2 || populated.getInt("routeCount") != 1
                    || populated.getInt("tunnelRouteCount") != 1 || populated.getInt("gatewayRouteCount") != 1
                    || populated.getInt("defaultRouteCount") != 1
                    || !populated.getBoolean("hasDomains") || !populated.getBoolean("hasProxy")
                    || empty.getJSONObject("addressCounts").getInt("total") != 0
                    || empty.getBoolean("hasDomains") || empty.getBoolean("hasProxy")
                    || !"NO_LINK".equals(link(null).optString("status"))
                    || !"NULL".equals(addresses(null).optString("status"))) throw new IllegalStateException();
            if (Build.VERSION.SDK_INT >= 28 && (!populated.getBoolean("privateDnsActive")
                    || !populated.getBoolean("hasPrivateDnsServerName")
                    || empty.getBoolean("privateDnsActive") || empty.getBoolean("hasPrivateDnsServerName")))
                throw new IllegalStateException();
            if (Build.VERSION.SDK_INT >= 29 && (!populated.getBoolean("hasNonDefaultMtu")
                    || empty.getBoolean("hasNonDefaultMtu"))) throw new IllegalStateException();
            if (Build.VERSION.SDK_INT >= 30 && (!populated.getBoolean("hasDhcpServerAddress")
                    || !populated.getBoolean("hasNat64Prefix") || empty.getBoolean("hasDhcpServerAddress")
                    || empty.getBoolean("hasNat64Prefix"))) throw new IllegalStateException();
            stage = "fixtureRedaction";
            String encoded = populated.toString() + empty.toString()
                + error("fixture", new SecurityException(domain)).toString();
            for (String raw : new String[]{ipv4.getHostAddress(), ipv6.getHostAddress(), domain,
                    proxy, privateDns, iface, "192.0.2.", "2001:db8"}) {
                if (encoded.contains(raw)) throw new IllegalStateException();
            }
            JSONObject out = status("PASS");
            out.put("syntheticFixturesOnly", true);
            out.put("networkRequestsPerformed", false);
            out.put("rawFixtureValuesAbsent", true);
            out.put("runtimeIsolationVerified", false);
            return out;
        } catch (Exception | LinkageError failure) {
            return error(stage, failure);
        }
    }
}
