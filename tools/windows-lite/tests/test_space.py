"""Admission, ownership and persistence tests; no Sandboxie/network mutation."""
import importlib.util
import io
import json
import os
from pathlib import Path
import struct
import sys
import tempfile
import unittest
from unittest.mock import patch


SOURCE = Path(__file__).resolve().parents[1] / "space.py"
spec = importlib.util.spec_from_file_location("cage_space", SOURCE)
space = importlib.util.module_from_spec(spec)
spec.loader.exec_module(space)


def write_exe(path):
    data = bytearray(256)
    data[:2] = b"MZ"
    struct.pack_into("<I", data, 0x3C, 0x80)
    data[0x80:0x86] = b"PE\0\0\x64\x86"
    struct.pack_into("<HH", data, 0x80 + 22, 2, 0x20B)
    path.write_bytes(data)
    return str(path)


class FakeControl:
    def __init__(self):
        self.calls = []
        self.name = ""
        self.exists = False
        self.identity = ""
        self.root = ""
        self.wfp = True
        self.processes = []

    def factory(self, directory, name):
        self.name = name
        return self

    def settings(self, *args):
        self.calls.append(args)
        if args == ("query", "*"):
            return [self.name] if self.exists else []
        if args == ("query", "GlobalSettings", "NetworkEnableWFP"):
            return ["y"] if self.wfp else []
        if args == ("query", self.name, "CageLiteSpaceId"):
            return [self.identity]
        if args == ("query", self.name, "FileRootPath"):
            return [self.root]
        if args == ("set", self.name, "NetworkAccess", "*,Block"):
            return []
        raise AssertionError("Unexpected Sandboxie operation: " + repr(args))

    def pids(self):
        self.calls.append(("pids",))
        return list(self.processes)

    def terminate(self):
        self.calls.append(("terminate",))
        self.processes.clear()


class SpaceTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory(prefix="cage-space-owned-")
        self.root = Path(self.directory.name)
        self.profile = self.root / "profile"
        self.control = FakeControl()
        self.worker = space.SpaceWorker(self.profile, control_factory=self.control.factory, platform="win32")
        self.sandboxie = self.root / "sandboxie"
        self.sandboxie.mkdir()
        for name in ("Start.exe", "SbieIni.exe", "SbieSvc.exe"):
            (self.sandboxie / name).write_bytes(b"test-owned-placeholder")
        self.exe = write_exe(self.root / "application.exe")
        self.core = write_exe(self.root / "mihomo.exe")
        self.connection = self.root / "connection.json"
        self.connection.write_text(json.dumps({"proxy_url": "socks5://secret-user:secret-value@127.0.0.1:1080",
                                                "dns_url": "https://1.1.1.1/dns-query"}), encoding="utf-8")

    def tearDown(self):
        if self.worker is not None:
            # A test of foreign ownership must never mutate that fake box.
            self.control.exists = False
            self.worker.close()
        self.directory.cleanup()

    def configure_ready_files(self):
        reply = self.worker.handle({"action": "configure", "settings": {
            "sandboxieDirectory": str(self.sandboxie), "proxyCore": self.core,
            "connectionFile": str(self.connection),
            "applications": {entry: {"program": self.exe, "arguments": []} for entry in space.APPLICATION_IDS},
        }})
        self.assertTrue(reply["ok"], reply)
        return reply

    def own_box(self, processes):
        self.control.exists = True
        self.control.identity = self.worker.identity
        self.control.root = str((self.profile / "state/files").resolve())
        self.control.processes = processes

    def test_fixed_identity_survives_app_path_changes_and_restart(self):
        self.configure_ready_files()
        identity, box = self.worker.identity, self.worker.box_name
        other = write_exe(self.root / "replacement.exe")
        self.assertTrue(self.worker.handle({"action": "configure", "settings": {
            "applications": {"browser": {"program": other}}}})["ok"])
        self.worker.close()
        self.worker = space.SpaceWorker(self.profile, control_factory=self.control.factory, platform="win32")
        self.assertEqual(self.worker.identity, identity)
        self.assertEqual(self.worker.box_name, box)
        self.assertEqual(self.worker.settings["applications"]["browser"]["program"], other)

    def test_second_controller_cannot_take_over_live_profile(self):
        before = (self.profile / "space.json").read_bytes()
        with self.assertRaises(RuntimeError):
            space.SpaceWorker(self.profile, control_factory=self.control.factory)
        self.assertEqual((self.profile / "space.json").read_bytes(), before)

    def test_corrupt_record_is_not_reinitialized(self):
        self.worker.close()
        self.worker = None
        record = self.profile / "space.json"
        record.write_bytes(b'{"id":"broken"}')
        with self.assertRaises(ValueError):
            space.SpaceWorker(self.profile, control_factory=self.control.factory)
        self.assertEqual(record.read_bytes(), b'{"id":"broken"}')

    def test_configure_invalid_update_keeps_original(self):
        before = (self.profile / "space.json").read_bytes()
        for update in ({"acceptance": "verified"}, {"proxyCore": "relative.exe"},
                       {"applications": {"browser": {"arguments": "--bad"}}}):
            self.assertFalse(self.worker.handle({"action": "configure", "settings": update})["ok"])
            self.assertEqual((self.profile / "space.json").read_bytes(), before)

    def test_start_requires_real_probe_even_with_all_dependencies_and_wfp(self):
        self.configure_ready_files()
        with patch.object(space.subprocess, "Popen", side_effect=AssertionError("must not launch")):
            reply = self.worker.handle({"action": "start"})
        self.assertFalse(reply["ok"])
        self.assertEqual(reply["state"]["phase"], "blocked")
        self.assertEqual(reply["state"]["network"], "closed")
        checks = {item["id"]: item for item in reply["state"]["checks"]}
        self.assertTrue(checks["wfp"]["ok"])
        self.assertFalse(checks["isolation"]["ok"])
        self.assertEqual(reply["state"]["acceptance"], "not-verified")
        self.assertTrue(all(call[0] == "query" for call in self.control.calls))

    def test_missing_wfp_blocks_without_changing_global_settings(self):
        self.configure_ready_files()
        self.control.wfp = False
        reply = self.worker.handle({"action": "start"})
        self.assertFalse(reply["ok"])
        self.assertIn("WFP", reply["error"])
        self.assertNotIn("set", [call[0] for call in self.control.calls])

    def test_other_platform_reports_unsupported_without_sandbox_calls(self):
        self.worker.platform = "linux"
        reply = self.worker.handle({"action": "start"})
        self.assertFalse(reply["ok"])
        self.assertFalse(next(c["ok"] for c in reply["state"]["checks"] if c["id"] == "platform"))
        self.assertEqual(self.control.calls, [])

    def test_connection_credentials_never_appear_in_response(self):
        self.configure_ready_files()
        text = json.dumps(self.worker.handle({"action": "start"}), ensure_ascii=False)
        self.assertNotIn("secret-user", text)
        self.assertNotIn("secret-value", text)

    def test_argument_secrets_redact_and_survive_settings_roundtrip(self):
        self.configure_ready_files()
        original = ["--api-key", "do-not-disclose", "--token=another-secret", "https://user:pass@example.test/"]
        reply = self.worker.handle({"action": "configure", "settings": {
            "applications": {"claude": {"arguments": original}}}})
        public = reply["state"]["settings"]
        self.assertNotIn("do-not-disclose", json.dumps(public))
        self.assertNotIn("another-secret", json.dumps(public))
        self.assertNotIn("user:pass", json.dumps(public))
        self.assertTrue(self.worker.handle({"action": "configure", "settings": public})["ok"])
        saved = json.loads((self.profile / "space.json").read_text(encoding="utf-8"))
        self.assertEqual(saved["settings"]["applications"]["claude"]["arguments"], original)

    def test_launch_never_falls_back_to_host(self):
        self.configure_ready_files()
        with patch.object(space.subprocess, "Popen", side_effect=AssertionError("must not launch")):
            for entry in space.ENTRY_LABELS:
                reply = self.worker.handle({"action": "launch", "entry": entry})
                self.assertFalse(reply["ok"])
            self.worker.phase = "running"
            self.worker._verified_session = object()
            self.assertFalse(self.worker.handle({"action": "launch", "entry": "shell"})["ok"])
        self.worker.phase = "stopped"

    def test_launch_mapping_uses_box_start_for_every_entry(self):
        self.configure_ready_files()
        for entry in space.ENTRY_LABELS:
            spec = self.worker.launch_spec(entry)
            self.assertEqual(spec["command"][0], str(self.sandboxie / "Start.exe"))
            self.assertEqual(spec["command"][1], "/box:" + self.worker.box_name)
            self.assertIn(self.exe, spec["command"])
        self.assertEqual(self.worker.launch_spec("claude_web")["arguments"][-1], "https://claude.ai/")

    def test_clean_environment_excludes_tokens_and_proxy_inheritance(self):
        with patch.dict(os.environ, {"ANTHROPIC_API_KEY": "secret", "HTTP_PROXY": "http://secret", "CUSTOM_SECRET": "secret"}):
            environment = space.clean_environment()
        self.assertNotIn("ANTHROPIC_API_KEY", environment)
        self.assertNotIn("HTTP_PROXY", environment)
        self.assertNotIn("CUSTOM_SECRET", environment)

    def test_stop_closes_network_before_terminating_and_keeps_data(self):
        self.configure_ready_files()
        self.own_box([123, 456])
        canary = self.profile / "persistent-personal-data.txt"
        canary.write_text("must survive", encoding="utf-8")
        reply = self.worker.handle({"action": "stop"})
        self.assertTrue(reply["ok"], reply)
        block = self.control.calls.index(("set", self.worker.box_name, "NetworkAccess", "*,Block"))
        terminate = self.control.calls.index(("terminate",))
        self.assertLess(block, terminate)
        self.assertEqual(canary.read_text(encoding="utf-8"), "must survive")
        self.assertTrue((self.profile / "space.json").is_file())
        self.assertEqual(reply["state"]["processCount"], 0)

    def test_foreign_box_cannot_be_terminated_or_reconfigured(self):
        self.configure_ready_files()
        self.own_box([123])
        self.control.identity = "someone-else"
        for action in ("stop", "configure"):
            reply = self.worker.handle({"action": action, "settings": {}})
            self.assertFalse(reply["ok"])
        self.assertTrue(all(call[0] in ("query", "pids") for call in self.control.calls))
        self.assertEqual(self.control.processes, [123])

    def test_incomplete_process_list_is_never_treated_as_empty(self):
        control = space.SandboxControl(str(self.sandboxie), "OwnedTestBox")
        for rows in (["2"], ["1", "0"], ["2", "123", "123"], ["1", "123", "456"]):
            with patch.object(control, "_run", return_value=rows):
                with self.assertRaises(RuntimeError):
                    control.pids()
        with patch.object(control, "_run", return_value=["0"]):
            self.assertEqual(control.pids(), [])

    def test_missing_control_preserves_uncertain_running_state(self):
        self.worker.settings["sandboxieDirectory"] = str(self.root/"absent-installation")
        self.worker.process_count, self.worker.network = 2, "unknown"
        reply = self.worker.handle({"action": "status"})
        self.assertEqual(reply["state"]["processCount"], -1)
        self.assertEqual(reply["state"]["network"], "unknown")
        self.assertFalse(self.worker.handle({"action": "stop"})["ok"])
        self.worker.process_count, self.worker.network = 0, "closed"

    def test_missing_project_does_not_destroy_record_or_block_settings_repair(self):
        missing = str(self.root / "missing-project")
        self.assertTrue(self.worker.handle({"action": "configure", "settings": {"projectDirectory": missing}})["ok"])
        self.worker.close()
        self.worker = space.SpaceWorker(self.profile, control_factory=self.control.factory, platform="win32")
        reply = self.worker.handle({"action": "status"})
        self.assertFalse(next(c["ok"] for c in reply["state"]["checks"] if c["id"] == "project"))
        self.assertTrue(self.worker.handle({"action": "configure", "settings": {"projectDirectory": ""}})["ok"])

    def test_protocol_recovers_from_bad_json_and_closes_on_eof(self):
        output = io.StringIO()
        space.serve(self.worker, io.StringIO('not-json\n{"action":"status"}\n'), output)
        replies = [json.loads(line) for line in output.getvalue().splitlines()]
        self.assertEqual(len(replies), 2)
        self.assertFalse(replies[0]["ok"])
        self.assertTrue(replies[1]["ok"])
        self.assertIsNone(self.worker._lock)


if __name__ == "__main__":
    unittest.main()
