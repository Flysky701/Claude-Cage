"""Runtime admission invalidation and public-only gateway tests; no system writes."""
from datetime import datetime, timezone
import ipaddress
from pathlib import Path
import sys
import tempfile
import threading
import time
import types
import unittest
from unittest.mock import patch

sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
import runtime

class RuntimeTests(unittest.TestCase):
    def test_proxy_rejects_private_or_mixed_dns_answers_before_dial(self):
        front=object.__new__(runtime.Frontend)
        front.cut=threading.Event()
        front.owner=types.SimpleNamespace(dns=object(),route=object())
        for addresses in (["127.0.0.1"],["169.254.169.254"],["::1"],["1.1.1.1","10.0.0.1"],["100.64.0.1"]):
            with patch.object(runtime,"target_addresses",return_value=map(ipaddress.ip_address,addresses)),patch.object(runtime,"session_tcp") as dial:
                with self.assertRaises(OSError):front.connect("synthetic.example",443)
                dial.assert_not_called()
    def test_proxy_uses_the_checked_literal_address(self):
        front=object.__new__(runtime.Frontend);front.cut=threading.Event();front.owner=types.SimpleNamespace(dns=object(),route=object())
        with patch.object(runtime,"target_addresses",return_value=[ipaddress.ip_address("1.1.1.1")]),patch.object(runtime,"session_tcp",return_value="stream") as dial:
            self.assertEqual(front.connect("synthetic.example",443),"stream")
            self.assertEqual(dial.call_args.args[1:],("1.1.1.1",443))
    def test_admission_expires_even_when_saved_phase_is_healthy(self):
        active=object.__new__(runtime.Runtime);active.failed="";active.finished=threading.Event();active.monitor={"phase":"healthy"}
        active.verified_at=active.last_tls=time.monotonic()
        self.assertTrue(active.healthy())
        active.last_tls-=46;self.assertFalse(active.healthy())
        active.last_tls=time.monotonic();active.verified_at-=46;self.assertFalse(active.healthy())
        active.verified_at=time.monotonic();active.finished.set();self.assertFalse(active.healthy())
    def test_network_policy_replacement_never_removes_all_rules_first(self):
        active=object.__new__(runtime.Runtime);active.box="SyntheticBox";active.policy={};calls=[]
        def settings(*args):
            calls.append(args)
            if args[0]=="query":return ["*,Block","*,Allow;Address=127.0.0.1;Port=4444;Protocol=TCP"]
        active.control=types.SimpleNamespace(settings=settings)
        active.setting("NetworkAccess",["*,Block","*,Allow;Address=127.0.0.1;Port=4444;Protocol=TCP"])
        self.assertEqual(calls[0],("set","SyntheticBox","NetworkAccess","*,Block"))
        self.assertNotIn("delete",[c[0] for c in calls])
    def test_privacy_partition_excludes_only_explicit_shared_subtree(self):
        with tempfile.TemporaryDirectory() as temp:
            home=Path(temp);(home/"private").mkdir();(home/".cage/profile/browser").mkdir(parents=True);(home/".cage/profile/runtime").mkdir();(home/".cage/config.json").write_text("synthetic")
            hidden,files=runtime.private_home_rules(home,[home/".cage/profile/browser"])
            self.assertIn(home/"private",hidden);self.assertIn(home/".cage/profile/runtime",hidden)
            self.assertIn(home/".cage/config.json",files)
            self.assertNotIn(home/".cage",hidden);self.assertNotIn(home/".cage/profile/browser",hidden)
    def test_stale_terminal_generation_cannot_attach(self):
        active=object.__new__(runtime.Runtime);active.lock=threading.RLock();active.ensure=lambda:None
        active.session="fresh";active.config_hash="fresh-hash";active.leases={"lease":{}}
        with self.assertRaises(RuntimeError):active.attach_terminal({"leaseId":"lease","sessionId":"old","configurationHash":"fresh-hash"})

if __name__=="__main__":unittest.main()
