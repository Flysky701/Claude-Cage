"""Run the actual guest version probe with deterministic command output."""
import contextlib
import io
import json
from pathlib import Path
import subprocess
import unittest
from unittest.mock import patch


SOURCE = (Path(__file__).resolve().parents[1] / "internal/workbench/environment_versions.go").read_text(encoding="utf-8")
PROBE = SOURCE.split("<<'CAGE_VERSIONS'\n", 1)[1].split("\nCAGE_VERSIONS", 1)[0]
VERSION = "4.145.0 2cb3ad3e258891fbb51001ba465c2348d5021644 with Code 1.145.0"
LOG = "[2026-11-15T12:00:00.000Z] info Wrote default config file to /home/cage/.config/code-server/config.yaml"


class EnvironmentVersionsTest(unittest.TestCase):
    def probe(self, output, returncode=0):
        def run(args, **kwargs):
            if args[0] == "code-server":
                if isinstance(output, Exception):
                    raise output
                return subprocess.CompletedProcess(args, returncode, output, "")
            return subprocess.CompletedProcess(args, 0, "other tool version\nextra information\n", "")

        captured = io.StringIO()
        with patch("subprocess.run", side_effect=run), patch.object(Path, "read_text", return_value="{}"), contextlib.redirect_stdout(captured):
            exec(compile(PROBE, "guest-version-probe", "exec"), {})
        tools = json.loads(captured.getvalue())["tools"]
        self.assertEqual(tools["git"], "other tool version")
        return tools["code_server"]

    def test_first_and_subsequent_invocations_agree(self):
        self.assertEqual(self.probe(LOG + "\n" + VERSION + "\n"), VERSION)
        self.assertEqual(self.probe(VERSION + "\n"), VERSION)

    def test_logs_without_version_remain_unknown(self):
        self.assertEqual(self.probe(LOG + "\n"), "")
        self.assertEqual(self.probe(""), "")

    def test_failed_command_does_not_report_a_version(self):
        self.assertEqual(self.probe(VERSION, returncode=1), "")
        self.assertEqual(self.probe(FileNotFoundError()), "")
        self.assertEqual(self.probe(subprocess.TimeoutExpired("code-server", 4)), "")

    def test_prerelease_and_surrounding_whitespace(self):
        self.assertEqual(self.probe(LOG + "\n  4.145.0-rc.1+build.2 commit with Code 1.145.0  \n"), "4.145.0-rc.1+build.2 commit with Code 1.145.0")


if __name__ == "__main__":
    unittest.main()
