"""Offline, fail-closed interpretation of bounded network observations.

This reads normalized evidence; it does not generate traffic or infer observations
from a timeout. Output deliberately excludes addresses, command output and paths.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re

CASES = (
    "https-domain-new", "https-v4-new", "https-v6-new",
    "dns-udp-v4-new", "dns-udp-v6-new", "udp-v4-new", "udp-v6-new",
    "quic-v4-new", "quic-v6-new", "tcp-v4-established", "tcp-v6-established",
    "udp-v4-established", "udp-v6-established",
)
SCENARIOS = ("gateway-stop", "gateway-crash", "gateway-startup", "network-switch", "device-restart", "background-resume")
DIGEST = re.compile(r"[0-9a-f]{64}\Z")


def digest_file(path):
    value = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            value.update(block)
    return value.hexdigest()


def evidence_valid(reference, directory):
    if not isinstance(reference, dict) or set(reference) != {"path", "sha256"}:
        return False
    digest, path = reference.get("sha256"), reference.get("path")
    if not isinstance(digest, str) or not DIGEST.fullmatch(digest) or not isinstance(path, str):
        return False
    try:
        source = directory / path
        return source.is_file() and digest_file(source) == digest
    except (OSError, ValueError):
        return False


def evaluate_case(case_id, row, context_ok, directory):
    result = {"id": case_id, "status": "NOT_RUN", "reason": "MISSING_CASE"}
    if row is None:
        return result
    online, blocked, capture = (row.get(key, {}) for key in ("online", "blocked", "egressObservation"))
    if not all(isinstance(value, dict) for value in (online, blocked, capture)):
        return dict(result, status="INCONCLUSIVE", reason="INVALID_CASE_SHAPE")
    # Failure evidence must be attributable and retained; a guessed outcome cannot fail/pass.
    online_valid = evidence_valid(online.get("evidence"), directory)
    blocked_valid = evidence_valid(blocked.get("evidence"), directory)
    capture_valid = evidence_valid(capture.get("evidence"), directory)
    direct_count = capture.get("directPacketCount")
    direct_observed = (type(direct_count) is int and direct_count > 0
                       and capture.get("attributedToGuest") is True and capture_valid)
    response_observed = (blocked.get("outcome") == "PUBLIC_RESPONSE"
                         and blocked.get("freshResponseCorrelated") is True and blocked_valid)
    if direct_observed or response_observed:
        observation = "DIRECT_TRAFFIC" if direct_observed else "PUBLIC_RESPONSE_AFTER_BLOCK"
        if not context_ok:
            return dict(result, status="INCONCLUSIVE", reason="OBSERVED_TRAFFIC_UNVERIFIED_CONTEXT",
                        trafficObservation=observation)
        return dict(result, status="FAIL_OBSERVED", reason=observation,
                    trafficObservation=observation)
    if online.get("outcome") in (None, "NOT_RUN") and blocked.get("outcome") in (None, "NOT_RUN"):
        return dict(result, reason="NO_OBSERVATIONS")
    if not context_ok:
        return dict(result, status="INCONCLUSIVE", reason="CONTEXT_OR_GUARD_NOT_VERIFIED")
    if online.get("outcome") == "UNSUPPORTED":
        return dict(result, status="INCONCLUSIVE", reason="PROTOCOL_UNSUPPORTED_NOT_A_BLOCK_PASS")
    if not online_valid or not blocked_valid:
        return dict(result, status="INCONCLUSIVE", reason="MISSING_OR_CHANGED_SOURCE_EVIDENCE")
    if online.get("outcome") != "EXPECTED_EGRESS" or online.get("freshResponseCorrelated") is not True:
        return dict(result, status="INCONCLUSIVE", reason="NO_VALID_ONLINE_POSITIVE_CONTROL")
    if blocked.get("outcome") != "NO_PUBLIC_RESPONSE":
        return dict(result, status="INCONCLUSIVE", reason="NO_VALID_BLOCKED_OBSERVATION")
    if "established" in case_id and row.get("sameFlowAcrossTransition") is not True:
        return dict(result, status="INCONCLUSIVE", reason="ESTABLISHED_FLOW_NOT_TESTED")
    if not capture_valid:
        return dict(result, status="INCONCLUSIVE", reason="NO_RESPONSE_IS_NOT_NO_EGRESS")
    complete = all(capture.get(key) is True for key in
                   ("attributedToGuest", "coversFullWindow", "allRelevantInterfaces", "lossFree"))
    attempts = blocked.get("attemptCount")
    duration = blocked.get("durationMs")
    if not complete or type(direct_count) is not int or direct_count != 0:
        return dict(result, status="INCONCLUSIVE", reason="EGRESS_OBSERVATION_INCOMPLETE")
    if type(attempts) is not int or not 1 <= attempts <= 20 or type(duration) is not int or not 1 <= duration <= 60000:
        return dict(result, status="INCONCLUSIVE", reason="BOUNDED_ATTEMPTS_NOT_RECORDED")
    return dict(result, status="PASS_FOR_RECORDED_CASE", reason="BOUNDED_EGRESS_OBSERVATION_PASSED")


def evaluate(document, directory):
    if not isinstance(document, dict) or document.get("schemaVersion") != 1:
        raise ValueError("Unsupported normalized evidence schema")
    scenario = document.get("scenario")
    if scenario not in SCENARIOS:
        raise ValueError("Unknown controlled scenario")
    rows = document.get("cases", [])
    if not isinstance(rows, list) or any(not isinstance(row, dict) for row in rows):
        raise ValueError("Invalid cases")
    if any(row.get("id") not in CASES for row in rows) or len({row["id"] for row in rows}) != len(rows):
        raise ValueError("Unknown or duplicate case IDs")
    context = document.get("context", {})
    if not isinstance(context, dict):
        raise ValueError("Invalid context")
    hashes = ("artifactSha256", "policySha256", "probeSha256")
    identity_ok = all(isinstance(context.get(key), str) and DIGEST.fullmatch(context[key]) for key in hashes)
    guard_ok = all(context.get(key) is True for key in
                   ("guestIdentityVerified", "sameArtifactAndPolicy", "blockConditionVerified", "lockdownVerified"))
    context_ok = bool(identity_ok and guard_ok and evidence_valid(context.get("evidence"), directory))
    by_id = {row["id"]: row for row in rows}
    findings = [evaluate_case(case_id, by_id.get(case_id), context_ok, directory) for case_id in CASES]
    statuses = {row["status"] for row in findings}
    if "FAIL_OBSERVED" in statuses:
        status = "FAIL_OBSERVED"
    elif statuses == {"NOT_RUN"}:
        status = "NOT_RUN"
    elif statuses == {"PASS_FOR_RECORDED_CASE"}:
        status = "PASS_FOR_RECORDED_MATRIX"
    else:
        status = "INCONCLUSIVE"
    return {"schemaVersion": 1, "scenario": scenario, "status": status,
            "contextVerified": context_ok, "cases": findings,
            "universalZeroLeakClaim": False,
            "untestedScenarios": [item for item in SCENARIOS if item != scenario],
            "scope": "Only this artifact, policy, guest, protocol matrix and recorded observation window."}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("input", type=Path)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    if args.output.exists():
        raise FileExistsError("Output exists; choose a new evidence filename")
    result = evaluate(json.loads(args.input.read_text(encoding="utf-8-sig")), args.input.resolve().parent)
    result["inputSha256"] = digest_file(args.input)
    with args.output.open("x", encoding="utf-8") as stream:
        json.dump(result, stream, indent=2)
        stream.write("\n")
    print(json.dumps({"status": result["status"], "contextVerified": result["contextVerified"],
                      "caseCount": len(result["cases"]), "universalZeroLeakClaim": False}))
    return 0 if result["status"] == "PASS_FOR_RECORDED_MATRIX" else 2


if __name__ == "__main__":
    raise SystemExit(main())
