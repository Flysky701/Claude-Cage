"""Local, USB-only diagnostic decoder for this test application's own tokens.

No service account credentials are distributed to the Android app. This is a
development tool, not a production authentication or authorization service.
"""
import argparse
import base64
import hashlib
import hmac
from http.server import BaseHTTPRequestHandler, HTTPServer
import json
import os
from pathlib import Path
import re
import sys
import time

PACKAGE = "io.github.flysky701.integritytest"
PROJECT_ID = "flysky701-integrity-test"
PROJECT_NUMBER = 650458347604
BUILD = Path(__file__).resolve().parents[1] / ".build/integrity-test"
sys.path.insert(0, str(BUILD / "python"))


def validate_request(data):
    if data.get("packageName") != PACKAGE:
        raise ValueError("Only this test application's package is accepted.")
    if data.get("cloudProjectNumber") != PROJECT_NUMBER:
        raise ValueError("The token must use this test project's number.")
    if data.get("mode") not in ("standard", "classic"):
        raise ValueError("Unknown request mode.")
    binding = data.get("binding")
    if not isinstance(binding, str) or not 16 <= len(binding) <= 500:
        raise ValueError("Missing request binding.")
    token = data.get("integrityToken")
    if not isinstance(token, str) or not 20 <= len(token) <= 65536:
        raise ValueError("Missing or invalid integrity token.")
    return token


def validate_verdict(data, payload):
    details = payload.get("requestDetails", {})
    if details.get("requestPackageName") != PACKAGE:
        raise ValueError("Google returned a different request package.")
    field = "nonce" if data["mode"] == "classic" else "requestHash"
    actual = details.get(field)
    expected = data["binding"]
    if field == "nonce":
        # Google can return padded base64url for an unpadded client nonce.
        # Compare the decoded bytes, never ignore a differing nonce value.
        def nonce_bytes(value):
            if not isinstance(value, str) or not re.fullmatch(r"[A-Za-z0-9_-]+={0,2}", value):
                raise ValueError("Google returned an invalid nonce encoding.")
            try:
                return base64.b64decode(value + "=" * (-len(value) % 4), altchars=b"-_", validate=True)
            except ValueError:
                raise ValueError("Google returned an invalid nonce encoding.") from None
        matches = hmac.compare_digest(nonce_bytes(actual), nonce_bytes(expected))
    else:
        matches = isinstance(actual, str) and hmac.compare_digest(actual.encode(), expected.encode())
    if not matches:
        raise ValueError("Google returned a different request binding.")
    try:
        age = time.time() - int(details["timestampMillis"]) / 1000
    except (KeyError, ValueError, TypeError):
        raise ValueError("Google returned no valid request timestamp.") from None
    if not -60 <= age <= 600:
        raise ValueError("The verdict is older than 10 minutes. Make a new request.")
    return {
        "应用识别": payload.get("appIntegrity", {}).get("appRecognitionVerdict", "未返回"),
        "应用许可": payload.get("accountDetails", {}).get("appLicensingVerdict", "未返回"),
        "设备完整性": payload.get("deviceIntegrity", {}).get("deviceRecognitionVerdict", []),
        "设备标签字段存在": "deviceRecognitionVerdict" in payload.get("deviceIntegrity", {}),
        "说明": "这是本测试应用的判定。设备标签缺失以 [] 展示；BASIC/STRONG 是可选标签，返回还受配置和 Play 许可条件约束，缺失不等于检测失败。未上架应用的识别和许可结果不能代表其他应用。",
        "tokenPayloadExternal": payload,
    }


class Decoder:
    def __init__(self, credentials_path):
        from google.oauth2 import service_account
        from google.auth.transport.requests import AuthorizedSession

        credentials = service_account.Credentials.from_service_account_file(
            str(credentials_path), scopes=["https://www.googleapis.com/auth/playintegrity"]
        )
        if credentials.project_id != PROJECT_ID:
            raise ValueError("The service account must belong to the dedicated test project.")
        self.session = AuthorizedSession(credentials)
        self.cache = {}

    def decode(self, data):
        token = validate_request(data)
        cache_key = hashlib.sha256(token.encode()).hexdigest()
        if cache_key in self.cache:
            # Standard tokens should only be decoded once. Validate again locally.
            result = validate_verdict(data, self.cache[cache_key])
            result["已读取过此令牌"] = True
            return result
        response = self.session.post(
            f"https://playintegrity.googleapis.com/v1/{PACKAGE}:decodeIntegrityToken",
            json={"integrity_token": token}, timeout=45,
        )
        if response.status_code != 200:
            try:
                message = response.json().get("error", {}).get("message", "Google API request failed")
            except ValueError:
                message = "Google API returned a non-JSON response"
            raise ValueError(f"Google HTTP {response.status_code}: {message}")
        payload = response.json().get("tokenPayloadExternal")
        if not isinstance(payload, dict):
            raise ValueError("Google returned no integrity verdict.")
        # Preserve the authenticated Google response for diagnosing validation
        # failures; this file is explicitly not an accepted verdict.
        BUILD.mkdir(parents=True, exist_ok=True)
        (BUILD / "latest-google-response.json").write_text(
            json.dumps({"validation": "not_yet_validated", "tokenPayloadExternal": payload},
                       ensure_ascii=False, indent=2), encoding="utf-8"
        )
        result = validate_verdict(data, payload)
        if len(self.cache) >= 100:
            self.cache.pop(next(iter(self.cache)))
        self.cache[cache_key] = payload
        BUILD.mkdir(parents=True, exist_ok=True)
        (BUILD / "latest-verdict.json").write_text(
            json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8"
        )
        return result


def serve(decoder):
    class Handler(BaseHTTPRequestHandler):
        def log_message(self, *_):
            pass  # Do not log request bodies or tokens.

        def reply(self, status, data):
            body = json.dumps(data, ensure_ascii=False).encode("utf-8")
            self.send_response(status)
            self.send_header("Content-Type", "application/json; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.send_header("Cache-Control", "no-store")
            self.end_headers()
            self.wfile.write(body)

        def do_GET(self):
            self.reply(200 if self.path == "/health" else 404,
                       {"ready": True, "project": PROJECT_ID} if self.path == "/health" else {"error": "Not found"})

        def do_POST(self):
            if self.path != "/decode":
                self.reply(404, {"error": "Not found"})
                return
            try:
                if self.headers.get("Origin"):
                    raise ValueError("Browser-origin requests are not accepted.")
                if not self.headers.get("Content-Type", "").startswith("application/json"):
                    raise ValueError("JSON required.")
                length = int(self.headers.get("Content-Length", "0"))
                if not 0 < length <= 131072:
                    raise ValueError("Invalid request size.")
                self.connection.settimeout(10)
                data = json.loads(self.rfile.read(length))
                if not isinstance(data, dict):
                    raise ValueError("JSON object required.")
                result = decoder.decode(data)
            except (ValueError, TimeoutError) as error:
                self.reply(400, {"error": str(error)})
                return
            except Exception:
                self.reply(502, {"error": "Google authentication or network request failed. Check local credentials and network."})
                return
            self.reply(200, result)
            print("Decoded one request; verdict saved locally.", flush=True)

    print("USB decoder ready at 127.0.0.1:8787. Press Ctrl+C to stop.", flush=True)
    with HTTPServer(("127.0.0.1", 8787), Handler) as server:
        try:
            server.serve_forever()
        except KeyboardInterrupt:
            pass


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--credentials", type=Path,
                        default=os.environ.get("GOOGLE_APPLICATION_CREDENTIALS"))
    parser.add_argument("--request", type=Path, help="Decode a private exported request instead of starting the USB helper")
    args = parser.parse_args()
    if not args.credentials or not args.credentials.is_file():
        parser.error("Provide this project's service account JSON using --credentials.")
    decoder = Decoder(args.credentials)
    if args.request:
        result = decoder.decode(json.loads(args.request.read_text(encoding="utf-8")))
        print(json.dumps(result, ensure_ascii=False, indent=2))
    else:
        serve(decoder)


if __name__ == "__main__":
    main()
