#!/usr/bin/env python3
"""Offline reference receiver for synthetic fixtures; not an installation tool."""

import argparse
import fcntl
import hashlib
import json
import os
import re
import stat
import sys
import tempfile
from datetime import datetime, timezone
from pathlib import Path

ID = re.compile(r"[A-Za-z0-9][A-Za-z0-9_-]{0,63}\Z")
DIGEST = re.compile(r"[a-f0-9]{64}\Z")
SCHEMA = "netstack.receiver.manifest.v1"


class Rejected(Exception):
    pass


def require(condition, message):
    if not condition:
        raise Rejected(message)


def number(obj, key, minimum=0):
    value = obj.get(key)
    require(type(value) is int and value >= minimum, f"invalid {key}")
    return value


def identifier(value, label):
    require(isinstance(value, str) and ID.fullmatch(value) is not None, f"invalid {label}")
    return value


def read_json(path, limit=65536):
    descriptor = os.open(path, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK)
    with os.fdopen(descriptor, "rb") as source:
        require(stat.S_ISREG(os.fstat(source.fileno()).st_mode), "input is not a regular file")
        raw = source.read(limit + 1)
    require(len(raw) <= limit, "JSON input is too large")
    def unique_pairs(pairs):
        result = {}
        for key, value in pairs:
            require(key not in result, "duplicate JSON key")
            result[key] = value
        return result
    try:
        value = json.loads(raw, object_pairs_hook=unique_pairs)
    except (UnicodeError, ValueError) as error:
        raise Rejected("invalid JSON input") from error
    require(isinstance(value, dict), "JSON input must be an object")
    return value


def timestamp(value, label):
    require(isinstance(value, str), f"missing {label}")
    try:
        parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError as error:
        raise Rejected(f"invalid {label}") from error
    require(parsed.utcoffset() is not None, f"{label} needs a timezone")
    return parsed.astimezone(timezone.utc)


def validate(manifest, policy, evidence, now):
    require(manifest.get("schema") == SCHEMA, "unsupported manifest schema")
    require(policy.get("schema") == "netstack.receiver.policy.v1", "unsupported policy schema")
    require(evidence.get("schema") == "netstack.receiver.evidence.v1", "unsupported evidence schema")
    for key in ("request_id", "service_id", "allocation_id"):
        identifier(manifest.get(key), key)
        require(manifest.get(key) == policy.get(key) == evidence.get(key), f"{key} mismatch")
    identifier(manifest.get("run_id"), "run_id")
    size = number(manifest, "size_bytes", 1)
    require(isinstance(manifest.get("sha256"), str) and DIGEST.fullmatch(manifest["sha256"]), "invalid sha256")
    require(policy.get("accepted") is True and evidence.get("reservation_confirmed") is True,
            "accepted terms and reservation required")
    require(policy.get("terms_revision") == evidence.get("terms_revision") and
            isinstance(policy.get("terms_revision"), str) and ID.fullmatch(policy["terms_revision"]),
            "terms revision mismatch")
    require(policy.get("budget_mode") == "synthetic-soft-budget" and
            policy.get("synthetic_only") is True, "prototype requires synthetic soft-budget inputs")
    max_age = number(policy, "max_evidence_age_seconds", 1)
    age = (now - timestamp(evidence.get("observed_at"), "observed_at")).total_seconds()
    require(0 <= age <= max_age, "evidence stale or future-dated")
    require(evidence.get("mount_verified") is True and evidence.get("commitments_complete") is True,
            "mount and commitments evidence required")
    total = number(evidence, "filesystem_total_bytes", 1)
    available = number(evidence, "filesystem_available_bytes")
    commitments = number(evidence, "other_unconsumed_commitments_bytes")
    reserve = number(policy, "reserve_bytes")
    budget = number(policy, "allocation_bytes", 1)
    require(available <= total, "filesystem availability exceeds total")
    require(size <= number(policy, "max_input_bytes", 1), "input exceeds limit")
    return size, available, commitments, reserve, budget


def sync_dir(path):
    fd = os.open(path, os.O_RDONLY | os.O_DIRECTORY)
    try:
        os.fsync(fd)
    finally:
        os.close(fd)


def file_digest(path, max_bytes=None):
    descriptor = os.open(path, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK)
    with os.fdopen(descriptor, "rb") as source:
        require(stat.S_ISREG(os.fstat(source.fileno()).st_mode), "sealed bundle is not a regular file")
        digest = hashlib.sha256()
        count = 0
        while chunk := source.read(1024 * 1024):
            count += len(chunk)
            if max_bytes is not None:
                require(count <= max_bytes, "file exceeds expected size")
            digest.update(chunk)
    return count, digest.hexdigest()


def protected_root(root):
    info = root.lstat()
    require(stat.S_ISDIR(info.st_mode) and info.st_uid == os.getuid() and not info.st_mode & 0o077,
            "receiver root must be private and operator-owned")
    for name in ("sealed", "staging"):
        target = root / name
        info = target.lstat()
        require(stat.S_ISDIR(info.st_mode) and info.st_uid == os.getuid() and not info.st_mode & 0o077,
                f"{name} must be a private operator-owned directory")
        require(info.st_dev == root.stat().st_dev, "receiver directories must share a filesystem")
    return root / "sealed", root / "staging"


def receiver_usage(sealed, policy):
    total = 0
    for entry in sealed.iterdir():
        require(entry.is_dir() and not entry.is_symlink() and ID.fullmatch(entry.name), "unrecognized sealed entry")
        receipt = read_json(entry / "receipt.json")
        require(receipt.get("run_id") == entry.name, "invalid sealed receipt")
        require(receipt.get("schema") == "netstack.receiver.receipt.v1" and
                receipt.get("result") == "synthetic-verified" and
                receipt.get("allocation_id") == policy["allocation_id"] and
                receipt.get("request_id") == policy["request_id"] and
                receipt.get("service_id") == policy["service_id"], "sealed receipt does not match allocation")
        require({item.name for item in entry.iterdir()} == {"bundle", "receipt.json"},
                "unexpected sealed content")
        expected = number(receipt, "size_bytes", 1)
        info = (entry / "bundle").lstat()
        require(stat.S_ISREG(info.st_mode) and info.st_size == expected, "sealed bundle size mismatch")
        receipt_info = (entry / "receipt.json").lstat()
        require(stat.S_ISREG(receipt_info.st_mode), "invalid sealed receipt file")
        total += expected + receipt_info.st_size
    return total


def receive(root, manifest_path, bundle_path, policy_path, evidence_path):
    sealed, staging = protected_root(root)
    lock_fd = os.open(root / "receiver.lock", os.O_CREAT | os.O_RDWR | os.O_NOFOLLOW, 0o600)
    with os.fdopen(lock_fd, "r+") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        manifest = read_json(manifest_path)
        policy = read_json(policy_path)
        evidence = read_json(evidence_path)
        now = datetime.now(timezone.utc)
        size, available, commitments, reserve, budget = validate(manifest, policy, evidence, now)
        require(not any(staging.iterdir()), "incomplete staging requires operator review")
        target = sealed / manifest["run_id"]
        if target.exists() or target.is_symlink():
            require(target.is_dir() and not target.is_symlink(), "invalid existing run")
            receipt = read_json(target / "receipt.json")
            fields = ("request_id", "service_id", "allocation_id", "run_id", "size_bytes", "sha256")
            require(all(receipt.get(k) == manifest.get(k) for k in fields), "conflicting duplicate run")
            require(receipt.get("schema") == "netstack.receiver.receipt.v1" and
                    receipt.get("result") == "synthetic-verified", "existing receipt is invalid")
            identifier(receipt.get("terms_revision"), "original terms revision")
            require(file_digest(target / "bundle", size) == (size, manifest["sha256"]), "existing run is corrupt")
            require(file_digest(bundle_path, size) == (size, manifest["sha256"]), "retry input does not match receipt")
            sync_dir(target)
            sync_dir(sealed)
            sync_dir(staging)
            validate(manifest, policy, evidence, datetime.now(timezone.utc))
            return receipt
        usage = receiver_usage(sealed, policy)
        require(usage + size <= budget, "allocation budget exceeded")
        require(available - commitments - reserve - usage >= size, "insufficient observed reserve")
        actual = os.statvfs(root)
        require(actual.f_bavail * actual.f_frsize - reserve - commitments >= size,
                "insufficient current filesystem reserve")

        source_fd = os.open(bundle_path, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK)
        with os.fdopen(source_fd, "rb") as source:
            require(stat.S_ISREG(os.fstat(source.fileno()).st_mode), "bundle is not a regular file")
            stage = Path(tempfile.mkdtemp(prefix="run-", dir=staging))
            sync_dir(staging)
            digest = hashlib.sha256()
            count = 0
            with open(stage / "bundle", "xb") as dest:
                while True:
                    chunk = source.read(min(1024 * 1024, size - count + 1))
                    if not chunk:
                        break
                    count += len(chunk)
                    require(count <= size, "bundle exceeds declared size")
                    dest.write(chunk)
                    digest.update(chunk)
                dest.flush()
                os.fsync(dest.fileno())
            require(count == size and digest.hexdigest() == manifest["sha256"], "bundle size or digest mismatch")
            require(file_digest(stage / "bundle") == (size, manifest["sha256"]), "staged copy verification failed")
            validate(manifest, policy, evidence, datetime.now(timezone.utc))
            actual_after = os.statvfs(root)
            require(actual_after.f_bavail * actual_after.f_frsize >= reserve + commitments,
                    "current filesystem reserve or commitments breached")
            receipt = {key: manifest[key] for key in
                       ("request_id", "service_id", "allocation_id", "run_id", "size_bytes", "sha256")}
            receipt.update({"schema": "netstack.receiver.receipt.v1",
                            "terms_revision": policy["terms_revision"],
                            "received_at": datetime.now(timezone.utc).isoformat(),
                            "result": "synthetic-verified"})
            with open(stage / "receipt.json", "x", encoding="utf-8") as file:
                json.dump(receipt, file, sort_keys=True)
                file.write("\n")
                file.flush()
                os.fsync(file.fileno())
            receipt_size = (stage / "receipt.json").stat().st_size
            require(usage + size + receipt_size <= budget, "allocation budget exceeded")
            require(available - commitments - reserve - usage >= size + receipt_size,
                    "insufficient observed reserve")
            current = os.statvfs(root)
            require(current.f_bavail * current.f_frsize >= reserve + commitments,
                    "current filesystem reserve or commitments breached")
            sync_dir(stage)
            os.rename(stage, target)
            sync_dir(sealed)
            sync_dir(staging)
            return receipt


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ("root", "manifest", "bundle", "policy", "evidence"):
        parser.add_argument(f"--{name}", type=Path, required=True)
    args = parser.parse_args()
    os.umask(0o077)
    try:
        receipt = receive(args.root, args.manifest, args.bundle, args.policy, args.evidence)
    except (OSError, Rejected) as error:
        print(f"REJECTED: {error}", file=sys.stderr)
        return 1
    print(json.dumps(receipt, sort_keys=True))
    return 0


if __name__ == "__main__":
    sys.exit(main())
