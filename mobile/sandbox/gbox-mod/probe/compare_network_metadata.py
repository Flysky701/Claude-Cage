"""Compare redacted LinkProperties observations; no network or device operations."""
import argparse
import json
from pathlib import Path
from compare_reports import load_report, value

COUNTS = ("dnsServerCount", "routeCount", "routeInterfaceNameCount", "tunnelRouteCount",
          "gatewayRouteCount", "defaultRouteCount")
FLAGS = ("hasInterfaceName", "tunnelInterfaceName", "hasDomains", "hasProxy", "privateDnsActive",
         "hasPrivateDnsServerName", "hasNonDefaultMtu", "hasDhcpServerAddress", "hasNat64Prefix")
API_STATUS = ("privateDnsStatus", "mtuStatus", "dhcpStatus", "nat64Status")
ADDRESS_COUNTS = ("total", "ipv4", "ipv6", "linkLocal", "loopback", "siteLocal", "uniqueLocal",
                  "multicast", "unspecified", "publicCandidate")


def valid(reading):
    if not isinstance(reading, dict) or reading.get("status") != "OK":
        return False
    addresses = reading.get("addressCounts", {})
    if not isinstance(addresses, dict) or addresses.get("status") != "OK":
        return False
    if not all(type(addresses.get(key)) is int and addresses[key] >= 0 for key in ADDRESS_COUNTS):
        return False
    if addresses["ipv4"] + addresses["ipv6"] != addresses["total"]:
        return False
    if any(addresses[key] > addresses["total"] for key in ADDRESS_COUNTS):
        return False
    if not all(type(reading.get(key)) is int and reading[key] >= 0 for key in COUNTS):
        return False
    if any(reading[key] > reading["routeCount"] for key in COUNTS[2:]):
        return False
    return (all(type(reading.get(key)) is bool for key in FLAGS)
            and all(reading.get(key) == "OK" for key in API_STATUS))


def nonempty(reading):
    return ([key for key in COUNTS if reading[key] != 0]
            + [key for key in FLAGS if reading[key]]
            + (["addressCounts.total"] if reading["addressCounts"]["total"] != 0 else []))


def compare(outer, guest):
    if outer.get("package") != guest.get("package"):
        raise ValueError("Outer and guest package identity differs")
    result = {"schemaVersion": 1, "status": "NOT_MEASURED", "missing": [],
              "scope": "Recorded active VPN LinkProperties and default callbacks only; non-tunnel networks remain unchanged.",
              "allNetworkIdentityIsolated": False, "trafficEnforcementVerified": False,
              "rawAddressesRetained": False}
    if outer.get("networkMetadataVersion") != 1 or guest.get("networkMetadataVersion") != 1:
        return result
    source_active = value(outer.get("network", {}).get("active")) or {}
    guest_active = value(guest.get("network", {}).get("active")) or {}
    source = source_active.get("metadata")
    measured = guest_active.get("metadata")
    links = guest.get("networkCallback", {}).get("linkProperties")
    if not valid(source):
        result["missing"].append("outer.active.metadata")
    if not valid(measured):
        result["missing"].append("guest.active.metadata")
    if (guest.get("networkCallback", {}).get("status") != "OK" or not isinstance(links, list)
            or not links or any(not isinstance(row, dict) or not valid(row.get("metadata")) for row in links)):
        result["missing"].append("guest.callback.metadata")
    if result["missing"]:
        result["status"] = "INCONCLUSIVE_MISSING_OR_INVALID_READINGS"
        return result
    caps = value(source_active.get("capabilities")) or {}
    metadata_positive = set(nonempty(source)) - {"hasInterfaceName", "tunnelInterfaceName"}
    if caps.get("vpn") is not True or not source["tunnelInterfaceName"] or not metadata_positive:
        result["status"] = "INCONCLUSIVE_NO_OUTER_ACTIVE_TUNNEL_CONTROL"
        return result
    visible = {"active": nonempty(measured)}
    visible.update({"callback" + str(i): nonempty(row["metadata"]) for i, row in enumerate(links)})
    visible = {path: keys for path, keys in visible.items() if keys}
    result["remainingFields"] = visible
    result["status"] = "METADATA_REMAINS_REQUIRES_REVIEW" if visible else "PASS_FOR_RECORDED_ACTIVE_TUNNEL"
    # These snapshots cannot independently correlate network IDs across processes or
    # rule out a network transition. A non-empty result is not a claim of exfiltration.
    result["crossProcessNetworkIdentityVerified"] = False
    result["outerMetadataPresent"] = nonempty(source)
    result["callbackSamples"] = len(links)
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--outer", type=Path, required=True)
    parser.add_argument("--guest", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    result = compare(load_report(args.outer), load_report(args.guest))
    with args.output.open("x", encoding="utf-8") as stream:
        json.dump(result, stream, indent=2)
        stream.write("\n")
    print(json.dumps(result))


if __name__ == "__main__":
    main()
