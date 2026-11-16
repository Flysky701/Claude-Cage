"""Inspect private diagnostic output. This is not a production attestation verifier."""
import argparse
import base64
import json
from pathlib import Path
import sys

p = argparse.ArgumentParser(description=__doc__)
p.add_argument("record", type=Path)
p.add_argument("--python-deps", type=Path, required=True)
p.add_argument("--summary", type=Path, required=True)
args = p.parse_args()
sys.path.insert(0, str(args.python_deps))
from cryptography import x509
from pyasn1.codec.der.decoder import decode

record = json.loads(args.record.read_text(encoding="utf-8-sig"))
result = {key: record[key] for key in ("requestedPackage", "visibleUid", "ephemeralKeyRemoved", "error", "cleanupError") if key in record}
result["isPlayIntegrityVerdict"] = False
result["rootTrustAndRevocationChecked"] = False
if "certificates" in record:
    chain = [x509.load_der_x509_certificate(base64.b64decode(item)) for item in record["certificates"]]
    if len(chain) < 2:
        raise ValueError("Incomplete certificate chain")
    result["certificateCount"] = len(chain)
    for child, parent in zip(chain, chain[1:]):
        child.verify_directly_issued_by(parent)
    result["chainSignaturesValid"] = True
    oid = x509.ObjectIdentifier("1.3.6.1.4.1.11129.2.1.17")
    # Start at the root end, as Android's attestation guidance requires.
    description = None
    for cert in reversed(chain):
        try:
            description, rest = decode(cert.extensions.get_extension_for_oid(oid).value.value)
            if rest:
                raise ValueError("Trailing extension data")
            break
        except x509.ExtensionNotFound:
            continue
    if description is None:
        raise ValueError("No attestation extension")
    result["attestationSecurityLevel"] = int(description[1])
    result["keyMintSecurityLevel"] = int(description[3])
    result["challengeMatches"] = bytes(description[4]) == base64.b64decode(record["challenge"])
    for location, authorizations in (("software", description[6]), ("hardware", description[7])):
        for entry in authorizations.values():
            tag = entry.tagSet[-1].tagId
            if tag == 709:
                app_id, rest = decode(bytes(entry))
                if rest:
                    raise ValueError("Trailing application ID data")
                result["applicationIdentityLocation"] = location
                result["attestedPackages"] = [
                    {"package": bytes(info[0]).decode("utf-8"), "version": int(info[1])}
                    for info in app_id[0]
                ]
                result["signerDigests"] = [bytes(item).hex() for item in app_id[1]]
            elif tag == 704:
                result["deviceLocked"] = bool(entry[1])
                result["verifiedBootState"] = int(entry[2])
args.summary.write_text(json.dumps(result, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
print(json.dumps(result, indent=2, ensure_ascii=False))
