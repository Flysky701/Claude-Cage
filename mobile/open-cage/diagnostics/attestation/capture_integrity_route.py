"""Bounded logcat observer; emitted records contain only allowlisted metadata.

No login or UI action, debugger attachment, data mutation, or network request.
Raw log lines and proof material are never saved or printed.

Historical 2026-11-16 success/failure metadata retained total token length and
segment count only; the original two JWE structures cannot be reconstructed.
New JWE fields describe shape, not decrypted verdicts or certificate chains.
Format reference: https://www.rfc-editor.org/rfc/rfc7516#section-3.1
"""
import argparse
import base64
import datetime
import json
import queue
import re
import subprocess
import threading
import time
from pathlib import Path

LINE = re.compile(r"^(\d\d-\d\d \d\d:\d\d:\d\d\.\d+)\s+(\d+)\s+\d+\s+[VDIWEF]\s+([^:]+):\s?(.*)$")
EVENTS = {
    "classic_requested": r"requestIntegrityToken\(",
    "classic_callback": r"OnRequestIntegrityTokenCallback.*onRequestIntegrityToken",
    "mgc_service_connected": r"onServiceConnected.*com\.android\.vending\.mgc.*IntegrityService",
    "droidguard_local_selected": r"initWithRequest: 执行本地方案",
    "droidguard_remote_selected": r"initWithRequest: 执行云机方案",
    "droidguard_embedded_initialized": r"EmbeddedDroidGuard.*step3: after init",
    "droidguard_low_latency": r"Using low-latency handle",
    "droidguard_certificate_blocked": r"Block DroidGuard from accessing engineGetCertificateChain|HardwareAttestationBlockingKeyStore.*engineGetCertificateChain|(?:KeyStore|keystore).*UnsupportedOperationException",
    "upstream_provider_control": r"CageProviderControl.*Using unchanged upstream provider registrations",
    "privacy_selection_disabled": r"CagePrivacyControl.*Guest privacy selection disabled",
    "upstream_android13_profile_loaded": r"ProfileManager.*Overwrite from profile: Build\.PRODUCT = sdk_gphone64_arm64$",
    "hardware_attestation_blocking_enabled": r"Hardware attestation blocking enabled",
    "hardware_attestation_blocking_disabled": r"DroidGuard\s*: Hardware attestation blocking disabled$",
    "hardware_attestation_provider_replace_failed": r"DroidGuard\s*: Failed replacing the security provider$",
    "companion_certificate_policy_installed": r"CageCompanionKeyStore.*Upstream certificate policy installed",
    "companion_certificate_policy_unavailable": r"CageCompanionKeyStore.*Certificate policy unavailable",
    "droidguard_init_failed": r"Error during handle init|init failed",
    "droidguard_fallback": r"DGFallback",
    "integrity_failure": r"requestIntegrityToken has exception|requestIntegrityToken\(\) failed|DroidGuard failed",
    "google_credential_returned": r"loginResult:.*GoogleSignInAccount",
    "verify_google_http400": r"HTTP 400 /auth/verify_google_mobile",
    "fatal_exception": r"AndroidRuntime.*FATAL EXCEPTION|Fatal signal 11",
    "cross_mgc_routed": r"CageCrossRoute.*Integrity routed to installed MGC",
    "cross_apache_dependency_resolved": r"CageCrossRoute.*Platform Apache dependency resolved",
    "cross_apache_dependency_unavailable": r"CageCrossRoute.*Platform Apache dependency unavailable",
}


JWE_HEADER_VALUES = {
    "alg": {"RSA1_5", "RSA-OAEP", "RSA-OAEP-256", "dir", "A128KW", "A192KW", "A256KW",
            "ECDH-ES", "ECDH-ES+A128KW", "ECDH-ES+A192KW", "ECDH-ES+A256KW",
            "A128GCMKW", "A192GCMKW", "A256GCMKW", "PBES2-HS256+A128KW",
            "PBES2-HS384+A192KW", "PBES2-HS512+A256KW"},
    "enc": {"A128CBC-HS256", "A192CBC-HS384", "A256CBC-HS512", "A128GCM", "A192GCM", "A256GCM"},
    "typ": {"JWT", "JOSE", "JOSE+JSON", "application/jwt", "application/jose", "application/jose+json"},
    "cty": {"JWT", "application/jwt", "application/json"},
}
JWE_SEGMENT_NAMES = ("protectedHeader", "encryptedKey", "initializationVector", "ciphertext", "authenticationTag")
BASE64URL_ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"


def jwe_metadata(token):
    """JWE shape only: never retain proof bytes or unknown header names/values.

    Byte lengths follow unpadded base64url. Only the bounded protected header
    is decoded, and its authenticity is not verified by this observer.
    """
    parts = token.split(".")
    if len(parts) != 5:
        return {}
    segments = {}
    for name, part in zip(JWE_SEGMENT_NAMES, parts):
        remainder = len(part) % 4
        valid = re.fullmatch(r"[A-Za-z0-9_-]*", part) is not None and remainder != 1
        if valid and remainder:
            unused_bits = 15 if remainder == 2 else 3
            valid = (BASE64URL_ALPHABET.index(part[-1]) & unused_bits) == 0
        segments[name] = dict(encodedChars=len(part), decodedBytes=len(part) * 3 // 4 if valid else None,
                              canonicalBase64url=valid)
    header = dict(status="unavailable", authenticationChecked=False)
    result = dict(jweSegments=segments, jweProtectedHeader=header)
    if not segments["protectedHeader"]["canonicalBase64url"]:
        header["status"] = "invalid_base64url"
        return result
    if len(parts[0]) > 4096:
        header["status"] = "too_large"
        return result
    try:
        decoded = base64.urlsafe_b64decode(parts[0] + "=" * (-len(parts[0]) % 4))
        values = json.loads(decoded.decode("utf-8"))
    except (ValueError, UnicodeError, RecursionError):
        header["status"] = "invalid_json"
        return result
    if not isinstance(values, dict):
        header["status"] = "not_object"
        return result
    header["status"] = "parsed"
    header["unknownFieldCount"] = len(set(values) - JWE_HEADER_VALUES.keys())
    header["fields"] = {}
    for name, allowed in JWE_HEADER_VALUES.items():
        if name not in values:
            continue
        value = values[name]
        kind = ("null" if value is None else "boolean" if isinstance(value, bool)
                else "number" if isinstance(value, (int, float)) else "string" if isinstance(value, str)
                else "array" if isinstance(value, list) else "object")
        field = dict(type=kind, allowlisted=isinstance(value, str) and value in allowed)
        if field["allowlisted"]:
            field["value"] = value
        header["fields"][name] = field
    return result


def metadata(line, expected_cert=None):
    match = LINE.match(line.rstrip("\r\n"))
    if not match:
        return []
    stamp, pid, tag, message = match.groups()
    records = []
    def emit(event, **values):
        records.append(dict(time=stamp, pid=int(pid), event=event, **values))
    for event, expression in EVENTS.items():
        if re.search(expression, tag + ": " + message):
            emit(event)
    if tag.strip() == "CageCrossRoute":
        verified = re.fullmatch(r"Declared service identity verified: (com\.google\.android\.gms|com\.android\.vending(?:\.mgc)?)", message)
        if verified:
            emit("cross_declared_service_identity", package=verified[1])
    if tag.strip() == "CageSeccompControl":
        installed = re.fullmatch(r"allowAllInstalled=(true|false)", message)
        if installed:
            emit("seccomp_allow_all_control", installed=installed[1] == "true")
    if tag.strip() == "CageNativeIOControl":
        installed = re.fullmatch(r"nativeIoInstalled=(true|false)", message)
        if installed:
            emit("native_io_control", installed=installed[1] == "true")
        counts = re.fullmatch(r"openCalls=(\d+) mappedCalls=(\d+)", message)
        if counts:
            emit("native_io_counts", openCalls=int(counts[1]), mappedCalls=int(counts[2]))
    if tag.strip() == "CageMicrogBinder":
        adapted = re.fullmatch(r"Adapted native service calls: (\d+)", message)
        if adapted:
            emit("native_service_adapted", count=int(adapted[1]))
    if tag.strip() == "CageCrossProviderControl":
        category = r"(android_platform|vlite_wrapper|microg_blocker|other|missing)"
        state = re.fullmatch(r"provider=" + category + r" ecService=(true|false) rsaService=(true|false) keyStoreService=" + category, message)
        if state:
            emit("cross_provider_state", provider=state[1], ecService=state[2] == "true",
                 rsaService=state[3] == "true", keyStoreService=state[4])
        elif message == "observation=unavailable":
            emit("cross_provider_state_unavailable")
    if tag.strip() == "CageProfileControl":
        counts = re.fullmatch(r"Upstream profile strings aligned: matched=(\d+) changed=(\d+) failed=(\d+) sdkUnchanged=(true|false)", message)
        if counts:
            emit("profile_strings_aligned", matched=int(counts[1]), changed=int(counts[2]),
                 failed=int(counts[3]), sdkUnchanged=counts[4] == "true")
        elif message.startswith("Skipped:"):
            emit("profile_alignment_skipped")
        elif message.startswith("Profile alignment unavailable:"):
            emit("profile_alignment_unavailable")
    if tag.strip() == "CageProfileTrace":
        status = re.fullmatch(r"(activeBefore|activeAfter|configured)=(uninitialized|target|auto|native|real|remote|user|system|other)", message)
        failure = re.fullmatch(r"configurationFailure=(queryNull|queryEmpty|other)", message)
        query = re.fullmatch(r"providerQueryNull=(true|false)", message)
        if status:
            emit("profile_configuration_state", stage=status[1], value=status[2])
        elif failure:
            emit("profile_configuration_failure", reason=failure[1])
        elif query:
            emit("profile_provider_query", returnedNull=query[1] == "true")
    if tag.strip() == "CageServiceContext":
        fields = re.fullmatch(r"oldPackage=(true|false) oldApplication=(true|false) oldLoader=(true|false) oldResource=(true|false) newPackage=(true|false) newSource=(true|false) newApplication=(true|false) newLoader=(true|false)", message)
        if fields:
            names = ("oldPackage", "oldApplication", "oldLoader", "oldResource", "newPackage", "newSource", "newApplication", "newLoader")
            emit("service_context_comparison", **dict(zip(names, (value == "true" for value in fields.groups()))))
        elif message == "Context replacement unavailable":
            emit("service_context_replacement_unavailable")
        elif message == "Profile audit unavailable":
            emit("service_context_audit_unavailable")
    if tag.strip() == "CageCompanionKeyStore":
        chain = re.fullmatch(r"Certificate chain request: droidguard=(true|false)", message)
        if chain:
            emit("companion_certificate_chain_request", droidguard=chain[1] == "true")
    if tag.strip() == "CageProfileData":
        values = re.fullmatch(r"api31=(true|false) initial29=(true|false) userProfile=(true|false)", message)
        if values:
            emit("api31_profile_control", api31=values[1] == "true", initial29=values[2] == "true", userProfile=values[3] == "true")
    if tag.strip() in {"IntegrityService", "DroidGuard", "GmsDroidGuard", "DroidGuardHandleImpl", "GmsGuardHandleImpl"}:
        flow = re.search(r"\b(?:flow[=:] ?|flowName=)(pia_attest_e1|pia_attest|pia_express|play_verdict_registry)\b", message)
        if flow:
            emit("droidguard_flow", flow=flow[1], claudeMentioned="com.anthropic.claude" in message)
        if "piaFromMGC=true" in message:
            emit("droidguard_mgc_origin_observed")
    if tag.strip() == "IntegrityService" and "integrityRequest:" in message:
        version = re.search(r"VersionCodeWrapper\{value_=(\d+)", message)
        nonce = re.search(r"\bnonce=([A-Za-z0-9_+/=-]+)", message)
        certs = re.search(r"certificateSha256Digests=\[([^]]*)\]", message)
        values = dict(claudePackage="PackageNameWrapper{value_=com.anthropic.claude}" in message)
        # ByteString's explicit size survives logcat truncation of proof bytes.
        # Do not infer VM output size from a possibly truncated Base64 string.
        guard_size = re.search(r"droidGuardTokenRaw=\[size=(\d+)\b", message)
        if guard_size:
            values["droidGuardRawBytes"] = int(guard_size[1])
        if version:
            values["versionCode"] = int(version[1])
        if nonce:
            try:
                values["nonceBytes"] = len(base64.urlsafe_b64decode(nonce[1] + "=" * (-len(nonce[1]) % 4)))
            except ValueError:
                values["nonceDecoded"] = False
        if certs:
            parsed = [s.strip() for s in certs[1].split(",") if s.strip()]
            values["certificateCount"] = len(parsed)
            if expected_cert:
                values["originalClaudeCertificateMatches"] = parsed == [expected_cert]
        emit("integrity_request_metadata", **values)
    if tag.strip() == "IntegrityService":
        token = re.search(r"requestIntegrityToken integrityToken: (\S+)\s*$", message)
        if token:
            emit("classic_token_returned", tokenChars=len(token[1]), dotSegments=len(token[1].split(".")),
                 **jwe_metadata(token[1]))
        guard = re.search(r"droidGuardToken: ([A-Za-z0-9_+/=-]+)\)", message)
        if guard:
            emit("droidguard_result", encodedChars=len(guard[1]))
    return records

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--adb", required=True)
    parser.add_argument("--serial", required=True)
    parser.add_argument("--uid", type=int, required=True)
    parser.add_argument("--seconds", type=int, default=180)
    parser.add_argument("--expected-cert")
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    if not 1 <= args.seconds <= 300 or args.uid < 10000:
        parser.error("Expected application UID and duration 1..300 seconds")
    if args.output.exists():
        parser.error("Output already exists")
    args.output.parent.mkdir(parents=True, exist_ok=True)
    process = subprocess.Popen([args.adb, "-s", args.serial, "logcat", "--uid=" + str(args.uid),
                                "-v", "threadtime", "-T", "1"],
                               stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
    records = queue.Queue()
    def read():
        for raw in iter(process.stdout.readline, b""):
            for record in metadata(raw.decode("utf-8", "replace"), args.expected_cert):
                records.put(record)
    worker = threading.Thread(target=read, daemon=True)
    worker.start()
    deadline = time.monotonic() + args.seconds
    count = 0
    try:
        with args.output.open("x", encoding="utf-8") as stream:
            stream.write(json.dumps(dict(event="capture_started", utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),
                                         uid=args.uid, rawLogsRetained=False)) + "\n")
            stream.flush()
            print("Metadata capture ready", flush=True)
            while time.monotonic() < deadline and process.poll() is None:
                try:
                    record = records.get(timeout=min(0.5, max(0.01, deadline-time.monotonic())))
                except queue.Empty:
                    continue
                stream.write(json.dumps(record, ensure_ascii=False) + "\n")
                stream.flush()
                count += 1
            process.terminate()
            process.wait(timeout=10)
            worker.join(timeout=5)
            while not records.empty():
                stream.write(json.dumps(records.get(), ensure_ascii=False) + "\n")
                count += 1
            stream.write(json.dumps(dict(event="capture_finished", records=count)) + "\n")
    finally:
        if process.poll() is None:
            process.kill()
    print(json.dumps(dict(records=count, rawLogsRetained=False)))

if __name__ == "__main__":
    main()
