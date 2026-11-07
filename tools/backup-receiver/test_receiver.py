import hashlib
import importlib.util
import json
import os
import subprocess
import sys
import tempfile
import unittest
from datetime import datetime, timedelta, timezone
from pathlib import Path
from unittest.mock import patch

SCRIPT = Path(__file__).with_name("receiver.py")
spec = importlib.util.spec_from_file_location("receiver", SCRIPT)
receiver = importlib.util.module_from_spec(spec)
spec.loader.exec_module(receiver)


class ReceiverTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)
        self.root = self.base / "root"
        self.root.mkdir(mode=0o700)
        (self.root / "sealed").mkdir(mode=0o700)
        (self.root / "staging").mkdir(mode=0o700)
        self.bundle = self.base / "incoming"
        self.bundle.write_bytes(b"synthetic bundle")
        self.manifest = {
            "schema": receiver.SCHEMA, "request_id": "request", "service_id": "service",
            "allocation_id": "allocation", "run_id": "run1",
            "size_bytes": len(self.bundle.read_bytes()),
            "sha256": hashlib.sha256(self.bundle.read_bytes()).hexdigest(),
        }
        self.policy = {
            "schema": "netstack.receiver.policy.v1", "request_id": "request",
            "service_id": "service", "allocation_id": "allocation", "terms_revision": "rev1",
            "accepted": True, "synthetic_only": True, "budget_mode": "synthetic-soft-budget",
            "max_evidence_age_seconds": 300, "reserve_bytes": 1, "allocation_bytes": 1000,
            "max_input_bytes": 100,
        }
        self.evidence = {
            "schema": "netstack.receiver.evidence.v1", "request_id": "request",
            "service_id": "service", "allocation_id": "allocation", "terms_revision": "rev1",
            "reservation_confirmed": True, "mount_verified": True, "commitments_complete": True,
            "observed_at": datetime.now(timezone.utc).isoformat(),
            "filesystem_total_bytes": 10000, "filesystem_available_bytes": 9000,
            "other_unconsumed_commitments_bytes": 0,
        }

    def inputs(self):
        paths = []
        for name, value in (("manifest", self.manifest), ("policy", self.policy), ("evidence", self.evidence)):
            path = self.base / name
            path.write_text(json.dumps(value))
            paths.append(path)
        return paths

    def receive(self):
        manifest, policy, evidence = self.inputs()
        return receiver.receive(self.root, manifest, self.bundle, policy, evidence)

    def test_receipt_idempotent_and_conflict_preserves_sealed(self):
        first = self.receive()
        self.assertEqual(first["result"], "synthetic-verified")
        self.assertEqual(first, self.receive())
        sealed = (self.root / "sealed/run1/bundle").read_bytes()
        self.manifest["sha256"] = "0" * 64
        with self.assertRaisesRegex(receiver.Rejected, "conflicting"):
            self.receive()
        self.assertEqual((self.root / "sealed/run1/bundle").read_bytes(), sealed)

    def test_retry_after_terms_change_preserves_original_receipt(self):
        first = self.receive()
        receipt_path = self.root / "sealed/run1/receipt.json"
        original_bytes = receipt_path.read_bytes()
        self.policy["terms_revision"] = "rev2"
        self.evidence["terms_revision"] = "rev2"
        self.assertEqual(self.receive(), first)
        self.assertEqual(receipt_path.read_bytes(), original_bytes)
        self.assertEqual(first["terms_revision"], "rev1")

    def test_retry_rejects_missing_or_invalid_original_revision(self):
        self.receive()
        receipt_path = self.root / "sealed/run1/receipt.json"
        receipt = json.loads(receipt_path.read_text())
        for revision in (None, "", "invalid/revision"):
            with self.subTest(revision=revision):
                receipt["terms_revision"] = revision
                receipt_path.write_text(json.dumps(receipt))
                with self.assertRaisesRegex(receiver.Rejected, "terms revision"):
                    self.receive()

    def test_retry_requires_current_terms(self):
        self.receive()
        self.policy["terms_revision"] = "rev2"
        self.evidence["terms_revision"] = "rev2"
        self.policy["accepted"] = False
        with self.assertRaisesRegex(receiver.Rejected, "accepted terms"):
            self.receive()

    def test_retry_rechecks_evidence_freshness_after_verification(self):
        first = self.receive()
        observed = datetime.now(timezone.utc)
        self.evidence["observed_at"] = observed.isoformat()
        self.policy["max_evidence_age_seconds"] = 1
        with patch.object(receiver, "datetime", wraps=datetime) as clock:
            clock.now.side_effect = [observed, observed + timedelta(seconds=2)]
            with self.assertRaisesRegex(receiver.Rejected, "stale"):
                self.receive()
        self.assertEqual(json.loads((self.root / "sealed/run1/receipt.json").read_text()), first)

    def test_existing_tampering_is_not_acknowledged(self):
        self.receive()
        (self.root / "sealed/run1/bundle").write_bytes(b"X" * self.manifest["size_bytes"])
        with self.assertRaisesRegex(receiver.Rejected, "corrupt"):
            self.receive()

    def test_retry_does_not_acknowledge_mismatched_upload(self):
        self.receive()
        self.bundle.write_bytes(b"X" * self.manifest["size_bytes"])
        with self.assertRaisesRegex(receiver.Rejected, "retry input"):
            self.receive()

    def test_retry_refuses_oversized_input(self):
        self.receive()
        self.bundle.write_bytes(b"X" * (self.manifest["size_bytes"] + 1))
        with self.assertRaisesRegex(receiver.Rejected, "file exceeds expected size"):
            self.receive()

    def test_limit_with_12_mib_fixture(self):
        self.bundle.write_bytes(b"X" * 1258291)
        self.manifest["size_bytes"] = self.bundle.stat().st_size
        self.manifest["sha256"] = hashlib.sha256(self.bundle.read_bytes()).hexdigest()
        self.policy["max_input_bytes"] = 1024 * 1024
        self.policy["allocation_bytes"] = 5 * 1024 * 1024
        self.evidence["filesystem_total_bytes"] = 100 * 1024 * 1024
        self.evidence["filesystem_available_bytes"] = 50 * 1024 * 1024
        with self.assertRaisesRegex(receiver.Rejected, "input exceeds limit"):
            self.receive()
        self.assertFalse((self.root / "sealed/run1").exists())

    def test_exact_input_limit_is_accepted(self):
        size = 1024 * 1024
        self.bundle.write_bytes(b"X" * size)
        self.manifest["size_bytes"] = size
        self.manifest["sha256"] = hashlib.sha256(self.bundle.read_bytes()).hexdigest()
        self.policy["max_input_bytes"] = size
        self.policy["allocation_bytes"] = 2 * size
        self.evidence["filesystem_total_bytes"] = 100 * size
        self.evidence["filesystem_available_bytes"] = 50 * size
        self.assertEqual(self.receive()["size_bytes"], size)

    def test_staged_copy_change_is_rejected(self):
        with patch.object(receiver, "file_digest", return_value=(self.manifest["size_bytes"], "0" * 64)):
            with self.assertRaisesRegex(receiver.Rejected, "staged copy verification failed"):
                self.receive()
        self.assertFalse((self.root / "sealed/run1").exists())

    def test_admission_failures(self):
        cases = [
            ("acceptance", self.policy, "accepted", False),
            ("reservation", self.evidence, "reservation_confirmed", False),
            ("commitments", self.evidence, "commitments_complete", False),
            ("mount", self.evidence, "mount_verified", False),
            ("future", self.evidence, "observed_at", (datetime.now(timezone.utc) + timedelta(seconds=3)).isoformat()),
            ("stale", self.evidence, "observed_at", (datetime.now(timezone.utc) - timedelta(seconds=301)).isoformat()),
            ("revision", self.evidence, "terms_revision", "other"),
            ("budget", self.policy, "allocation_bytes", 1),
            ("limit", self.policy, "max_input_bytes", 1),
            ("reserve", self.policy, "reserve_bytes", 10000),
            ("false-hard-quota", self.policy, "budget_mode", "hard"),
            ("non-synthetic", self.policy, "synthetic_only", False),
            ("allocation-mismatch", self.evidence, "allocation_id", "other"),
        ]
        for label, obj, key, value in cases:
            with self.subTest(label=label):
                old = obj[key]
                obj[key] = value
                with self.assertRaises(receiver.Rejected):
                    self.receive()
                obj[key] = old
                self.assertEqual(list((self.root / "sealed").iterdir()), [])

    def test_missing_and_invalid_records(self):
        for obj, key in ((self.evidence, "other_unconsumed_commitments_bytes"),
                         (self.policy, "accepted"), (self.manifest, "sha256")):
            value = obj.pop(key)
            with self.assertRaises(receiver.Rejected):
                self.receive()
            obj[key] = value
        manifest, policy, evidence = self.inputs()
        evidence.write_text('{"schema":"x","schema":"y"}')
        with self.assertRaisesRegex(receiver.Rejected, "duplicate JSON"):
            receiver.receive(self.root, manifest, self.bundle, policy, evidence)

    def test_invalid_bundle_preserves_incomplete_staging_and_prior_run(self):
        self.receive()
        self.manifest["run_id"] = "run2"
        self.bundle.write_bytes(b"changed content!")
        with self.assertRaises(receiver.Rejected):
            self.receive()
        self.assertTrue((self.root / "sealed/run1/receipt.json").exists())
        self.assertFalse((self.root / "sealed/run2").exists())
        self.assertEqual(len(list((self.root / "staging").iterdir())), 1)
        with self.assertRaisesRegex(receiver.Rejected, "incomplete staging"):
            self.receive()

    def test_interrupted_publish_fails_closed_on_restart(self):
        with patch.object(receiver.os, "rename", side_effect=OSError("interrupted")):
            with self.assertRaises(OSError):
                self.receive()
        self.assertFalse((self.root / "sealed/run1").exists())
        with self.assertRaisesRegex(receiver.Rejected, "incomplete staging"):
            self.receive()

    def test_expired_evidence_before_publication_blocks_run(self):
        original = receiver.validate
        calls = 0

        def expire_after_copy(manifest, policy, evidence, now):
            nonlocal calls
            calls += 1
            if calls == 2:
                now += timedelta(seconds=policy["max_evidence_age_seconds"] + 1)
            return original(manifest, policy, evidence, now)

        with patch.object(receiver, "validate", side_effect=expire_after_copy):
            with self.assertRaisesRegex(receiver.Rejected, "stale"):
                self.receive()
        self.assertFalse((self.root / "sealed/run1").exists())
        self.assertTrue(list((self.root / "staging").iterdir()))

    def test_interruption_after_rename_revalidates_and_syncs_retry(self):
        original = receiver.sync_dir
        failed = False

        def interrupt_after_publish(path):
            nonlocal failed
            if path == self.root / "sealed" and not failed:
                failed = True
                raise OSError("interrupted after rename")
            return original(path)

        with patch.object(receiver, "sync_dir", side_effect=interrupt_after_publish):
            with self.assertRaisesRegex(OSError, "interrupted after rename"):
                self.receive()
        self.assertTrue((self.root / "sealed/run1/receipt.json").exists())
        with patch.object(receiver, "sync_dir", wraps=original) as sync:
            receipt = self.receive()
        self.assertEqual(receipt["result"], "synthetic-verified")
        self.assertIn(self.root / "sealed", [call.args[0] for call in sync.call_args_list])

    def test_uploader_changes_input_while_copying(self):
        content = b"A" * (2 * 1024 * 1024)
        self.bundle.write_bytes(content)
        self.manifest["size_bytes"] = len(content)
        self.manifest["sha256"] = hashlib.sha256(content).hexdigest()
        self.policy["max_input_bytes"] = len(content)
        self.policy["allocation_bytes"] = 4 * len(content)
        self.evidence["filesystem_total_bytes"] = 20 * len(content)
        self.evidence["filesystem_available_bytes"] = 10 * len(content)
        source_inode = self.bundle.stat().st_ino
        fdopen = receiver.os.fdopen
        bundle = self.bundle

        class ChangingReader:
            def __init__(self, stream):
                self.stream = stream
                self.changed = False

            def __enter__(self):
                return self

            def __exit__(self, *args):
                return self.stream.__exit__(*args)

            def fileno(self):
                return self.stream.fileno()

            def read(self, length):
                data = self.stream.read(length)
                if data and not self.changed:
                    self.changed = True
                    with open(bundle, "r+b", buffering=0) as writer:
                        writer.seek(1024 * 1024 + 4096)
                        writer.write(b"changed")
                return data

        def wrap_source(fd, mode, *args, **kwargs):
            info = os.fstat(fd)
            stream = fdopen(fd, mode, *args, **kwargs)
            if mode == "rb" and info.st_ino == source_inode:
                return ChangingReader(stream)
            return stream

        with patch.object(receiver.os, "fdopen", side_effect=wrap_source):
            with self.assertRaisesRegex(receiver.Rejected, "digest mismatch"):
                self.receive()
        self.assertFalse((self.root / "sealed/run1").exists())
        self.assertTrue(list((self.root / "staging").iterdir()))

    def test_budget_includes_receipts_and_prior_runs(self):
        self.policy["allocation_bytes"] = 1200
        self.receive()
        receipt_size = (self.root / "sealed/run1/receipt.json").stat().st_size
        self.manifest["run_id"] = "run2"
        self.policy["allocation_bytes"] = 2 * self.manifest["size_bytes"] + receipt_size
        with self.assertRaisesRegex(receiver.Rejected, "allocation budget exceeded"):
            self.receive()
        self.assertFalse((self.root / "sealed/run2").exists())
        self.assertTrue((self.root / "sealed/run1/receipt.json").exists())

    def test_concurrent_runs_cannot_exceed_budget(self):
        self.policy["allocation_bytes"] = 500
        manifest1, policy, evidence = self.inputs()
        self.manifest["run_id"] = "run2"
        manifest2 = self.base / "manifest2"
        manifest2.write_text(json.dumps(self.manifest))
        common = ["--root", str(self.root), "--bundle", str(self.bundle),
                  "--policy", str(policy), "--evidence", str(evidence)]
        commands = [[sys.executable, str(SCRIPT), "--manifest", str(item), *common]
                    for item in (manifest1, manifest2)]
        processes = [subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
                     for command in commands]
        results = [process.communicate(timeout=10) for process in processes]
        self.assertEqual(sorted(process.returncode for process in processes), [0, 1], results)
        self.assertEqual(len(list((self.root / "sealed").iterdir())), 1)

    def test_cli_and_invalid_symlink(self):
        manifest, policy, evidence = self.inputs()
        command = [sys.executable, str(SCRIPT), "--root", str(self.root),
                   "--manifest", str(manifest), "--bundle", str(self.bundle),
                   "--policy", str(policy), "--evidence", str(evidence)]
        result = subprocess.run(command, capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout)["result"], "synthetic-verified")
        self.manifest["run_id"] = "run2"
        manifest, _, _ = self.inputs()
        self.bundle.unlink()
        self.bundle.symlink_to(manifest)
        result = subprocess.run(command, capture_output=True, text=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse((self.root / "sealed/run2").exists())

    def test_self_contained_synthetic_demo(self):
        result = subprocess.run([sys.executable, str(SCRIPT.with_name("demo.py"))],
                                capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("1,258,291-byte fixture: rejected", result.stdout)
        self.assertIn("1,048,576-byte fixture: accepted", result.stdout)


if __name__ == "__main__":
    unittest.main()
