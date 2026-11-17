"""Focused validation for the launcher trust boundary; no real credentials."""
import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from policy import build_policy, safe_environment


class PolicyTest(unittest.TestCase):
    def setUp(self):
        work = Path(__file__).resolve().parents[2] / "tmp" / "windows-lite-policy-tests"
        work.mkdir(parents=True, exist_ok=True)
        self.temp = tempfile.TemporaryDirectory(dir=work)
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name).resolve()
        self.profile = self.base / "profile"
        self.env = {
            "USERPROFILE": str(self.profile),
            "LOCALAPPDATA": str(self.profile / "AppData" / "Local"),
            "APPDATA": str(self.profile / "AppData" / "Roaming"),
            "TEMP": str(self.profile / "AppData" / "Local" / "Temp"),
            "TMP": str(self.profile / "AppData" / "Local" / "Temp"),
        }
        self.env_patch = patch.dict(os.environ, self.env)
        self.env_patch.start()
        self.addCleanup(self.env_patch.stop)
        self.app = self.base / "app" / "app.exe"
        self.app.parent.mkdir()
        self.home = self.base / "state"
        self.output = self.home / "output" / "one"
        self.source = self.base / "control" / "connection.json"
        self.sbie = self.base / "sandboxie"
        self.root = self.base / "launcher"

    def build(self, spec=None, **kwargs):
        args = dict(program=self.app, helpers=[], home=self.home, output=self.output,
                    source=self.source, sbie=self.sbie, spec=spec or {},
                    config_dir=self.base, root=self.root)
        args.update(kwargs)
        return build_policy(**args)

    def test_host_secret_environment_is_not_inherited(self):
        raw = dict(self.env, SYSTEMROOT=r"C:\Windows", PATH=r"C:\untrusted",
                   ANTHROPIC_API_KEY="fake", AWS_SECRET_ACCESS_KEY="fake",
                   HTTP_PROXY="http://secret", NODE_OPTIONS="--require secret.js",
                   CLAUDE_CAGE_CONFIG="secret", GIT_CONFIG_COUNT="1")
        env = safe_environment(self.app, [], source_env=raw,
                               extra={"HTTPS_PROXY": "http://session:fake@127.0.0.1:1"})
        self.assertEqual(env["USERPROFILE"], self.env["USERPROFILE"])
        self.assertNotIn("untrusted", env["PATH"])
        for key in ("ANTHROPIC_API_KEY", "AWS_SECRET_ACCESS_KEY", "HTTP_PROXY",
                    "NODE_OPTIONS", "CLAUDE_CAGE_CONFIG", "GIT_CONFIG_COUNT"):
            self.assertNotIn(key, env)
        self.assertEqual(env["HTTPS_PROXY"], "http://session:fake@127.0.0.1:1")

    def test_explicit_share_modes_are_preserved(self):
        for name in ("readonly", "writable"):
            (self.base / name).mkdir()
        pairs = self.build({"sharedFolders": [
            {"path": "readonly", "access": "read-only"},
            {"path": "writable", "access": "read-write"},
        ]})
        self.assertIn(("ReadFilePath", str(self.base / "readonly") + "\\"), pairs)
        self.assertIn(("OpenPipePath", str(self.base / "writable") + "\\"), pairs)
        self.assertIn(("WriteFilePath", str(self.profile / ".ssh")), pairs)
        self.assertIn(("ClosedFilePath", str(self.source)), pairs)
        self.assertIn(("WriteKeyPath", "HKEY_CURRENT_USER\\*"), pairs)
        self.assertNotIn(("UseRuleSpecificity", "y"), pairs)
        self.assertFalse(any(key == "UsePrivacyMode" for key, _ in pairs))

    def test_protected_or_control_shares_fail_before_configuration(self):
        private = self.profile / ".ssh"
        private.mkdir(parents=True)
        self.home.mkdir()
        for path in (private, self.profile, self.home, self.base):
            with self.subTest(path=path), self.assertRaises(ValueError):
                self.build({"sharedFolders": [{"path": str(path), "access": "read-write"}]})

    def test_path_patterns_and_rule_selectors_are_rejected(self):
        for value in ("*,C:\\", "C:\\data*", "C:\\data\nOpenFilePath=*",
                      "%CAGE_UNDEFINED_PATH%", "C:\\"):
            with self.subTest(value=value), self.assertRaises(ValueError):
                self.build({"sharedFolders": [{"path": value, "access": "read-only"}]})

    def test_overlapping_shares_and_runtime_paths_are_rejected(self):
        project = self.base / "project"
        nested = project / "nested"
        nested.mkdir(parents=True)
        with self.assertRaises(ValueError):
            self.build({"sharedFolders": [
                {"path": str(project), "access": "read-write"},
                {"path": str(nested), "access": "read-only"},
            ]})
        with self.assertRaises(ValueError):
            self.build({"sharedFolders": [{"path": str(self.app.parent), "access": "read-write"}]})

    def test_source_inside_app_directory_still_stays_closed(self):
        source = self.app.parent / "connection.json"
        self.assertIn(("ClosedFilePath", str(source)), self.build(source=source))

    def test_offline_policy_does_not_need_saved_connection(self):
        pairs = self.build(source=None)
        self.assertIn(("WriteFilePath", str(self.home / "profiles")), pairs)
        self.assertIn(("OpenPipePath", str(self.output) + "\\"), pairs)
        self.assertTrue(all(isinstance(value, str) for _, value in pairs))


if __name__ == "__main__":
    unittest.main()
