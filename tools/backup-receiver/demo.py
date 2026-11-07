#!/usr/bin/env python3
"""Demonstrate the receiver with disposable synthetic data only."""

import hashlib
import json
import subprocess
import sys
import tempfile
from datetime import datetime, timezone
from pathlib import Path


def main():
    script = Path(__file__).with_name("receiver.py")
    with tempfile.TemporaryDirectory(prefix="receiver-fixture-") as temp:
        base = Path(temp)
        root = base / "root"
        root.mkdir(mode=0o700)
        (root / "sealed").mkdir(mode=0o700)
        (root / "staging").mkdir(mode=0o700)
        ids = {"request_id": "synthetic-request", "service_id": "synthetic-service",
               "allocation_id": "synthetic-allocation"}
        policy = {
            "schema": "netstack.receiver.policy.v1", **ids, "terms_revision": "fixture",
            "accepted": True, "synthetic_only": True, "budget_mode": "synthetic-soft-budget",
            "max_evidence_age_seconds": 300, "reserve_bytes": 1,
            "allocation_bytes": 5 * 1024 * 1024, "max_input_bytes": 1024 * 1024,
        }
        evidence = {
            "schema": "netstack.receiver.evidence.v1", **ids, "terms_revision": "fixture",
            "reservation_confirmed": True, "mount_verified": True, "commitments_complete": True,
            "observed_at": datetime.now(timezone.utc).isoformat(),
            "filesystem_total_bytes": 100 * 1024 * 1024,
            "filesystem_available_bytes": 50 * 1024 * 1024,
            "other_unconsumed_commitments_bytes": 0,
        }
        for name, value in (("policy.json", policy), ("evidence.json", evidence)):
            (base / name).write_text(json.dumps(value), encoding="utf-8")

        def run(size, run_id):
            payload = b"X" * size
            bundle = base / "bundle"
            bundle.write_bytes(payload)
            manifest = {
                "schema": "netstack.receiver.manifest.v1", **ids, "run_id": run_id,
                "size_bytes": size, "sha256": hashlib.sha256(payload).hexdigest(),
            }
            manifest_path = base / "manifest.json"
            manifest_path.write_text(json.dumps(manifest), encoding="utf-8")
            return subprocess.run(
                [sys.executable, str(script), "--root", str(root),
                 "--manifest", str(manifest_path), "--bundle", str(bundle),
                 "--policy", str(base / "policy.json"), "--evidence", str(base / "evidence.json")],
                capture_output=True, text=True, check=False,
            )

        rejected = run(1_258_291, "above-limit")
        if rejected.returncode == 0 or "input exceeds limit" not in rejected.stderr:
            raise RuntimeError(f"above-limit fixture did not fail as expected: {rejected.stderr}")
        accepted = run(1_048_576, "at-limit")
        if accepted.returncode != 0:
            raise RuntimeError(f"at-limit fixture failed: {accepted.stderr}")
        receipt = json.loads(accepted.stdout)
        if receipt.get("size_bytes") != 1_048_576 or receipt.get("result") != "synthetic-verified":
            raise RuntimeError("unexpected synthetic receipt")
        print("1,258,291-byte fixture: rejected by 1,048,576-byte input limit")
        print("1,048,576-byte fixture: accepted with synthetic-verified receipt")
        print("Disposable fixtures only; no monitoring, agreement or real backup was performed.")


if __name__ == "__main__":
    main()
