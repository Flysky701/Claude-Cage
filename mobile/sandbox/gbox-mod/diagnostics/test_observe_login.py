import json
import unittest

from observe_login import summarize_logs, summarize_ui


class PrivacyTests(unittest.TestCase):
    def test_authentication_values_never_enter_event_output(self):
        secrets = ["person@example.invalid", "ya29.TEST_SECRET_VALUE", "eyJ_TEST.JWT.SIGNATURE"]
        raw = "11-15 14:10:23.888  1  2 I AssistedSignInActivity: loginResult: GoogleSignInAccount " + " ".join(secrets)
        encoded = json.dumps(summarize_logs(raw))
        self.assertIn("google_signin_account_returned", encoded)
        for value in secrets:
            self.assertNotIn(value, encoded)

    def test_unmatched_logs_are_not_retained(self):
        self.assertEqual(summarize_logs("authToken: secret\ngetAuthToken: secret")["events"], [])

    def test_ui_preserves_failure_without_retaining_account_text(self):
        raw = '<hierarchy><node text="Couldn’t sign in"/><node text="person@example.invalid"/><node text="opaque-secret" password="true"/></hierarchy>'
        result = summarize_ui(raw)
        self.assertTrue(result["couldNotSignInVisible"])
        self.assertNotIn("example.invalid", json.dumps(result))
        self.assertNotIn("opaque-secret", json.dumps(result))

    def test_service_diagnostic_accepts_only_fixed_message_shapes(self):
        raw = "11-15 14:47:21.701  1  2 I CageServiceDiag: create.return resultNull=true\n"
        raw += "11-15 14:47:21.702  1  2 I CageServiceDiag: create.return resultNull=true token=secret"
        result = summarize_logs(raw)
        self.assertEqual(len(result["events"]), 1)
        self.assertTrue(result["events"][0]["resultNull"])
        self.assertNotIn("secret", json.dumps(result))


if __name__ == "__main__":
    unittest.main()
