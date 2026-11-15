"""Setup failure and preservation tests; no service or system mutation."""
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

spec = importlib.util.spec_from_file_location("cage_setup", Path(__file__).resolve().parents[1]/"setup.py")
setup = importlib.util.module_from_spec(spec)
spec.loader.exec_module(setup)


class FakeBackend:
    def __init__(self, ini):
        self.ini, self.configured, self.enabled, self.active = ini, False, False, 0
        self.running, self.reload_success, self.write_error = True, True, None
        self.calls = []
    def version(self): return "1.18.8"
    def services_running(self): return self.running
    def validate_home(self): pass
    def wfp_enabled(self): return self.enabled
    def wfp_configured(self): return self.configured
    def active_process_count(self): return self.active
    def ini_path(self): return self.ini
    def enable_setting(self):
        self.calls.append("write")
        if self.write_error: raise self.write_error
        # A stand-in for the official targeted update, retaining all original bytes.
        with self.ini.open("ab") as stream: stream.write(b"\r\nNetworkEnableWFP=y\r\n")
        self.configured = True
    def reconfigure(self):
        self.calls.append("reload")
        self.enabled = self.reload_success


class SetupTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="cage-setup-owned-")
        self.root = Path(self.temp.name)
        self.directory = self.root/"installed"
        self.directory.mkdir()
        for name in setup.REQUIRED_FILES: (self.directory/name).write_bytes(b"fixture")
        self.ini = self.root/"Sandboxie.ini"
        self.original = "# 合成配置\r\n[ExistingBox]\r\nFileRootPath=X:\\Persist\\MyBox\r\n".encode("utf-16")
        self.ini.write_bytes(self.original)
        self.backend = FakeBackend(self.ini)
        self.backups = self.root/"backups"
    def tearDown(self): self.temp.cleanup()
    def enable(self): return setup.enable_wfp(self.directory,self.backend,self.backups)
    def test_check_is_read_only_and_uses_runtime(self):
        self.backend.configured = True
        result = setup.inspect(self.directory,self.backend)
        self.assertTrue(result["installed"])
        self.assertTrue(result["servicesRunning"])
        self.assertFalse(result["wfpEnabled"])
        self.assertEqual(self.ini.read_bytes(),self.original)
        self.assertEqual(self.backend.calls,[])
        self.assertFalse(self.backups.exists())
    def test_enable_preserves_full_backup_before_update(self):
        result = self.enable()
        self.assertTrue(result["wfpEnabled"],result)
        folder = Path(result["backupDirectory"])
        self.assertEqual((folder/"Sandboxie.ini.before").read_bytes(),self.original)
        self.assertTrue(self.ini.read_bytes().startswith(self.original))
        self.assertTrue(json.loads((folder/"manifest.json").read_text())["existed"])
        self.assertEqual(self.backend.calls,["write","reload"])
    def test_already_enabled_is_idempotent_even_with_running_boxes(self):
        self.backend.configured = self.backend.enabled = True
        self.backend.active = 3
        result = self.enable()
        self.assertTrue(result["wfpEnabled"])
        self.assertFalse(result["changed"])
        self.assertEqual(self.backend.calls,[])
        self.assertEqual(self.ini.read_bytes(),self.original)
        self.assertFalse(self.backups.exists())
    def test_active_boxes_prevent_global_mode_switch(self):
        self.backend.active = 1
        result = self.enable()
        self.assertEqual(result["errorCode"],"spaces-running")
        self.assertEqual(self.backend.calls,[])
        self.assertEqual(self.ini.read_bytes(),self.original)
    def test_existing_setting_still_requires_runtime_reconfigure(self):
        self.backend.configured = True
        result = self.enable()
        self.assertTrue(result["wfpEnabled"])
        self.assertEqual(self.backend.calls,["reload"])
        self.assertEqual(self.ini.read_bytes(),self.original)
    def test_runtime_failure_keeps_backup_and_does_not_claim_ready(self):
        self.backend.reload_success = False
        result = self.enable()
        self.assertFalse(result["wfpEnabled"])
        self.assertEqual(result["errorCode"],"wfp-not-active")
        self.assertEqual((Path(result["backupDirectory"])/"Sandboxie.ini.before").read_bytes(),self.original)
        self.assertEqual(self.backend.calls,["write","reload"])
    def test_locked_configuration_is_not_bypassed(self):
        self.backend.write_error = setup.SetupError("configuration-password-required","fixture")
        result = self.enable()
        self.assertEqual(result["errorCode"],"configuration-password-required")
        self.assertEqual(self.backend.calls,["write"])
        self.assertEqual(self.ini.read_bytes(),self.original)
        self.assertTrue(Path(result["backupDirectory"]).is_dir())
    def test_new_install_records_absent_original(self):
        self.ini.unlink()
        result = self.enable()
        folder = Path(result["backupDirectory"])
        self.assertFalse(json.loads((folder/"manifest.json").read_text())["existed"])
        self.assertFalse((folder/"Sandboxie.ini.before").exists())
        self.assertTrue(result["wfpEnabled"])
    def test_missing_install_and_stopped_services_do_not_mutate(self):
        (self.directory/setup.REQUIRED_FILES[0]).unlink()
        self.assertFalse(self.enable()["installed"])
        (self.directory/setup.REQUIRED_FILES[0]).write_bytes(b"fixture")
        self.backend.running=False
        self.assertFalse(self.enable()["servicesRunning"])
        self.assertEqual(self.backend.calls,[])
    def test_backup_is_required(self):
        result=setup.enable_wfp(self.directory,self.backend,None)
        self.assertEqual(result["errorCode"],"backup-directory-required")
        self.assertEqual(self.backend.calls,[])
    def test_non_windows_is_explicitly_unsupported(self):
        result=setup.enable_wfp(self.directory,None,self.backups,supported=False)
        self.assertFalse(result["supported"])
        self.assertEqual(result["errorCode"],"unsupported")
        self.assertFalse(self.backups.exists())
    def test_official_ini_locations(self):
        self.assertEqual(setup.resolve_ini_location("H",self.directory,self.root),self.directory/"Sandboxie.ini")
        self.assertEqual(setup.resolve_ini_location("W",self.directory,self.root),self.root/"Sandboxie.ini")
        self.assertEqual(str(setup.resolve_ini_location(r"\??\D:\Settings\Sandboxie.ini",self.directory,self.root)),r"D:\Settings\Sandboxie.ini")
        with self.assertRaises(setup.SetupError): setup.resolve_ini_location("unknown",self.directory,self.root)


if __name__=="__main__": unittest.main()
