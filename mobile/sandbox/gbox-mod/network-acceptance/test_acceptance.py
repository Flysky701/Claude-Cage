import copy
import json
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

import evaluate
import preflight


class EvidenceInterpretation(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.source = self.root / "synthetic-test-evidence.json"
        self.source.write_text('{"syntheticUnitTest":true}', encoding="utf-8")
        self.ref = {"path": self.source.name, "sha256": evaluate.digest_file(self.source)}
        self.data = {"schemaVersion": 1, "scenario": "gateway-stop", "context": {
            "artifactSha256": "a" * 64, "policySha256": "b" * 64, "probeSha256": "c" * 64,
            "guestIdentityVerified": True, "sameArtifactAndPolicy": True,
            "blockConditionVerified": True, "lockdownVerified": True, "evidence": self.ref},
            "cases": []}
        for case_id in evaluate.CASES:
            self.data["cases"].append({"id": case_id, "sameFlowAcrossTransition": True,
                "online": {"outcome": "EXPECTED_EGRESS", "freshResponseCorrelated": True, "evidence": self.ref},
                "blocked": {"outcome": "NO_PUBLIC_RESPONSE", "attemptCount": 2, "durationMs": 4000, "evidence": self.ref},
                "egressObservation": {"attributedToGuest": True, "coversFullWindow": True,
                    "allRelevantInterfaces": True, "lossFree": True, "directPacketCount": 0, "evidence": self.ref}})

    def result(self):
        return evaluate.evaluate(self.data, self.root)

    def test_complete_matrix_is_still_scoped(self):
        report = self.result()
        self.assertEqual(report["status"], "PASS_FOR_RECORDED_MATRIX")
        self.assertFalse(report["universalZeroLeakClaim"])
        self.assertIn("device-restart", report["untestedScenarios"])

    def test_no_evidence_is_not_run(self):
        self.data["cases"] = []
        self.assertEqual(self.result()["status"], "NOT_RUN")

    def test_absent_source_does_not_reuse_historical_claim(self):
        self.source.unlink()
        self.assertEqual(self.result()["status"], "INCONCLUSIVE")

    def test_modified_evidence_cannot_pass(self):
        self.source.write_text("different evidence", encoding="utf-8")
        self.assertEqual(self.result()["status"], "INCONCLUSIVE")

    def test_missing_positive_control_cannot_pass(self):
        self.data["cases"][0]["online"]["outcome"] = "NO_PUBLIC_RESPONSE"
        self.assertEqual(self.result()["cases"][0]["reason"], "NO_VALID_ONLINE_POSITIVE_CONTROL")

    def test_http_timeout_alone_is_inconclusive(self):
        del self.data["cases"][0]["egressObservation"]
        self.assertEqual(self.result()["cases"][0]["reason"], "NO_RESPONSE_IS_NOT_NO_EGRESS")

    def test_unsupported_ipv6_cannot_be_called_blocked(self):
        row = next(x for x in self.data["cases"] if x["id"] == "https-v6-new")
        row["online"]["outcome"] = "UNSUPPORTED"
        self.assertEqual(self.result()["status"], "INCONCLUSIVE")

    def test_omitted_established_flows_cannot_pass(self):
        self.data["cases"] = [x for x in self.data["cases"] if "established" not in x["id"]]
        self.assertEqual(self.result()["status"], "INCONCLUSIVE")

    def test_new_connection_does_not_count_as_established(self):
        row = next(x for x in self.data["cases"] if x["id"] == "tcp-v4-established")
        row["sameFlowAcrossTransition"] = False
        self.assertIn("ESTABLISHED_FLOW_NOT_TESTED", [x["reason"] for x in self.result()["cases"]])

    def test_missing_lockdown_prevents_pass(self):
        self.data["context"]["lockdownVerified"] = False
        self.assertEqual(self.result()["status"], "INCONCLUSIVE")

    def test_lossy_observer_cannot_pass(self):
        self.data["cases"][0]["egressObservation"]["lossFree"] = False
        self.assertEqual(self.result()["cases"][0]["reason"], "EGRESS_OBSERVATION_INCOMPLETE")

    def test_direct_packet_is_failure_even_without_positive_control(self):
        row = self.data["cases"][0]
        row["online"]["outcome"] = "NOT_RUN"
        row["egressObservation"]["directPacketCount"] = 1
        self.assertEqual(self.result()["status"], "FAIL_OBSERVED")

    def test_direct_capture_not_hidden_by_missing_application_response(self):
        row = self.data["cases"][0]
        row["online"]["outcome"] = "NOT_RUN"
        row["blocked"]["outcome"] = "NOT_RUN"
        row["egressObservation"]["directPacketCount"] = 1
        self.assertEqual(self.result()["status"], "FAIL_OBSERVED")

    def test_direct_observation_with_unverified_artifact_is_inconclusive(self):
        self.data["context"]["sameArtifactAndPolicy"] = False
        self.data["cases"][0]["egressObservation"]["directPacketCount"] = 1
        report = self.result()
        self.assertEqual(report["status"], "INCONCLUSIVE")
        self.assertEqual(report["cases"][0]["reason"], "OBSERVED_TRAFFIC_UNVERIFIED_CONTEXT")
        self.assertEqual(report["cases"][0]["trafficObservation"], "DIRECT_TRAFFIC")

    def test_public_response_without_context_stays_an_unattributed_observation(self):
        del self.data["context"]["evidence"]
        row = self.data["cases"][0]
        row["blocked"]["outcome"] = "PUBLIC_RESPONSE"
        row["blocked"]["freshResponseCorrelated"] = True
        report = self.result()
        self.assertEqual(report["status"], "INCONCLUSIVE")
        self.assertEqual(report["cases"][0]["reason"], "OBSERVED_TRAFFIC_UNVERIFIED_CONTEXT")
        self.assertEqual(report["cases"][0]["trafficObservation"], "PUBLIC_RESPONSE_AFTER_BLOCK")

    def test_public_response_is_not_called_direct_bypass(self):
        row = self.data["cases"][0]
        row["blocked"]["outcome"] = "PUBLIC_RESPONSE"
        row["blocked"]["freshResponseCorrelated"] = True
        del row["egressObservation"]
        report = self.result()
        self.assertEqual(report["status"], "FAIL_OBSERVED")
        self.assertEqual(report["cases"][0]["reason"], "PUBLIC_RESPONSE_AFTER_BLOCK")
        self.assertEqual(report["cases"][0]["trafficObservation"], "PUBLIC_RESPONSE_AFTER_BLOCK")

    def test_uncorrelated_cached_response_is_not_a_failure_proof(self):
        row = self.data["cases"][0]
        row["blocked"]["outcome"] = "PUBLIC_RESPONSE"
        row["blocked"]["freshResponseCorrelated"] = False
        self.assertEqual(self.result()["status"], "INCONCLUSIVE")

    def test_duplicates_rejected(self):
        self.data["cases"].append(copy.deepcopy(self.data["cases"][0]))
        with self.assertRaises(ValueError):
            self.result()

    def test_boolean_is_not_a_packet_count(self):
        self.data["cases"][0]["egressObservation"]["directPacketCount"] = False
        self.assertEqual(self.result()["status"], "INCONCLUSIVE")


class ReadOnlyPreflight(unittest.TestCase):
    def responses(self, lockdown="1"):
        return ["device", "36", "package:/data/app/~~sample/container/base.apk",
                "a" * 64 + " /data/app/~~sample/container/base.apk", "com.example.vpn", lockdown,
                "Transports: VPN\nLinkAddresses: SECRET_ADDRESS"]

    def test_does_not_mutate_or_claim_enforcement(self):
        commands, outputs = [], iter(self.responses())
        def fake(command, **kwargs):
            commands.append(command)
            return subprocess.CompletedProcess(command, 0, next(outputs).encode(), b"")
        with patch("preflight.subprocess.run", side_effect=fake):
            result = preflight.inspect(Path("adb"), "private-serial", 5041, "a" * 64, "com.example.vpn")
        self.assertEqual(result["status"], "REQUIRES_ONLINE_CONTROL")
        self.assertFalse(result["networkEnforcementVerified"])
        self.assertFalse(result["activeVpnVerified"])
        self.assertEqual(result["deviceMutations"], 0)
        self.assertNotIn("SECRET_ADDRESS", json.dumps(result))
        self.assertNotIn("private-serial", json.dumps(result))
        self.assertFalse(any("put" in command or "am" in command or "force-stop" in command for command in commands))

    def test_lockdown_disabled_blocks_precondition(self):
        outputs = iter(self.responses("0"))
        with patch("preflight.subprocess.run", side_effect=lambda command, **kw: subprocess.CompletedProcess(command, 0, next(outputs).encode(), b"")):
            result = preflight.inspect(Path("adb"), "private-serial", 5041, "a" * 64, "com.example.vpn")
        self.assertEqual(result["status"], "BLOCKED_PRECONDITION")

    def test_timeout_does_not_expose_serial(self):
        with patch("preflight.subprocess.run", side_effect=subprocess.TimeoutExpired(["adb", "private-serial"], 20)):
            with self.assertRaises(RuntimeError) as caught:
                preflight.inspect(Path("adb"), "private-serial", 5041, "a" * 64, "com.example.vpn")
        self.assertNotIn("private-serial", str(caught.exception))


if __name__ == "__main__":
    unittest.main()
