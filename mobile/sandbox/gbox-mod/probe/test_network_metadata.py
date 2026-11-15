import copy
import unittest
import compare_network_metadata as comparison


def metadata():
    return {"status": "OK", **{key: 0 for key in comparison.COUNTS},
            **{key: False for key in comparison.FLAGS},
            **{key: "OK" for key in comparison.API_STATUS},
            "addressCounts": {"status": "OK", **{key: 0 for key in comparison.ADDRESS_COUNTS}}}


def reports():
    source, hidden = metadata(), metadata()
    source.update(hasInterfaceName=True, tunnelInterfaceName=True, dnsServerCount=2)
    source["addressCounts"].update(total=1, ipv4=1, siteLocal=1)
    def report(link, vpn):
        return {"package": "synthetic.probe", "networkMetadataVersion": 1,
                "network": {"active": {"status": "OK", "value": {
                    "metadata": link, "capabilities": {"status": "OK", "value": {"vpn": vpn}}}}},
                "networkCallback": {"status": "OK", "linkProperties": [{"metadata": copy.deepcopy(link)}]}}
    return report(source, True), report(hidden, False)


class MetadataComparisonTests(unittest.TestCase):
    def test_positive_control_and_empty_presentation_are_scoped(self):
        result = comparison.compare(*reports())
        self.assertEqual(result["status"], "PASS_FOR_RECORDED_ACTIVE_TUNNEL")
        self.assertFalse(result["allNetworkIdentityIsolated"])
        self.assertFalse(result["trafficEnforcementVerified"])

    def test_old_probe_is_not_promoted(self):
        outer, guest = reports()
        guest.pop("networkMetadataVersion")
        self.assertEqual(comparison.compare(outer, guest)["status"], "NOT_MEASURED")

    def test_null_link_and_failed_getters_do_not_become_empty_success(self):
        for status in ("NO_LINK", "ERROR", "NULL"):
            with self.subTest(status=status):
                outer, guest = reports()
                guest["network"]["active"]["value"]["metadata"] = {"status": status}
                self.assertEqual(comparison.compare(outer, guest)["status"], "INCONCLUSIVE_MISSING_OR_INVALID_READINGS")

    def test_callback_absence_is_inconclusive(self):
        outer, guest = reports()
        guest["networkCallback"]["linkProperties"] = []
        self.assertEqual(comparison.compare(outer, guest)["status"], "INCONCLUSIVE_MISSING_OR_INVALID_READINGS")

    def test_callback_metadata_cannot_hide_behind_active_empty_link(self):
        outer, guest = reports()
        guest["networkCallback"]["linkProperties"][0]["metadata"]["dnsServerCount"] = 1
        result = comparison.compare(outer, guest)
        self.assertEqual(result["status"], "METADATA_REMAINS_REQUIRES_REVIEW")
        self.assertEqual(result["remainingFields"], {"callback0": ["dnsServerCount"]})

    def test_no_outer_vpn_is_not_a_pass(self):
        outer, guest = reports()
        outer["network"]["active"]["value"]["capabilities"]["value"]["vpn"] = False
        self.assertEqual(comparison.compare(outer, guest)["status"], "INCONCLUSIVE_NO_OUTER_ACTIVE_TUNNEL_CONTROL")

    def test_name_only_control_does_not_prove_metadata_filtering(self):
        outer, guest = reports()
        source = metadata()
        source.update(hasInterfaceName=True, tunnelInterfaceName=True)
        outer["network"]["active"]["value"]["metadata"] = source
        self.assertEqual(comparison.compare(outer, guest)["status"], "INCONCLUSIVE_NO_OUTER_ACTIVE_TUNNEL_CONTROL")

    def test_malformed_counts_or_missing_api_cannot_pass(self):
        for key, value in (("dnsServerCount", False), ("routeCount", -1), ("nat64Status", "UNSUPPORTED_API")):
            outer, guest = reports()
            guest["network"]["active"]["value"]["metadata"][key] = value
            self.assertEqual(comparison.compare(outer, guest)["status"], "INCONCLUSIVE_MISSING_OR_INVALID_READINGS")

    def test_non_tunnel_networks_are_not_claimed_hidden(self):
        outer, guest = reports()
        guest["network"]["allNetworks"] = {"status": "OK", "value": [{"metadata": metadata()}]}
        self.assertFalse(comparison.compare(outer, guest)["allNetworkIdentityIsolated"])

    def test_package_mismatch_is_rejected(self):
        outer, guest = reports()
        guest["package"] = "different.probe"
        with self.assertRaises(ValueError):
            comparison.compare(outer, guest)


if __name__ == "__main__":
    unittest.main()
