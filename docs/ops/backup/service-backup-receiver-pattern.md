# Service backup receiver: synthetic reference prototype

**Status:** Proposed for review; the reference code is for synthetic fixtures
only, not a deployed service. Tracking: [netstack#43](https://github.com/2cld/netstack/issues/43).
It extends the [service-data backup pattern](service-data-backup-restore-pattern.md)
and uses the [storage request lifecycle](../storage-index/README.md#cross-site-request-lifecycle).

## Trust boundaries and lifecycle

The provider captures consistently and encrypts before transfer. A site may
choose restricted SFTP for untrusted incoming files, but transport selection,
account restrictions and enforcement require a site-owned reviewed procedure.
Uploader-owned staging is mutable: it is not sealed, and the uploader must not
be able to modify receiver-owned staging, accepted runs, receipts or keys.
The receiver copies a declared input into private staging, verifies actual size
and digest of its own copy, and publishes the bundle and its receipt as one
same-filesystem atomic directory rename. A receipt means matching bytes were
received, not that decryption, a database restore or application recovery passed.

The site must verify mount identity, physical backing and independent failure
domains, allocation and other commitments, current capacity and reserve, and
an accepted terms revision. Free space is not allocatable capacity. A soft
budget is not an enforced quota and cannot prevent other writers from exhausting
the filesystem. Sites must explicitly decide whether to accept that risk; no
such decision is encoded by a fixture. Each operation requiring access,
provisioning, actual transfer, restore, monitoring or deletion needs its own
owner authorization.

## Offline interfaces

The standard-library prototype lives at
[`tools/backup-receiver/receiver.py`](../../../tools/backup-receiver/receiver.py).
The command takes `--root`, `--manifest`, `--bundle`, `--policy`, and
`--evidence`, each supplied by an authorized test operator. It accepts only
`synthetic_only: true` and `budget_mode: "synthetic-soft-budget"`; this is a
test fence, **not an authorization or enforcement mechanism**.

All JSON inputs are bounded objects; identifiers use letters, digits, `_` and
`-` (1-64 characters, starting with a letter or digit). Byte counts are integers.
Input schema and fields:

| Record | Required fields |
|--------|-----------------|
| Manifest `netstack.receiver.manifest.v1` | `request_id`, `service_id`, `allocation_id`, `run_id`, `size_bytes`, lowercase `sha256` |
| Policy `netstack.receiver.policy.v1` | matching IDs, `terms_revision`, `accepted: true`, `synthetic_only: true`, `budget_mode: "synthetic-soft-budget"`, `allocation_bytes`, `max_input_bytes`, `reserve_bytes`, `max_evidence_age_seconds` |
| Evidence `netstack.receiver.evidence.v1` | matching IDs and revision, `observed_at` with timezone, `reservation_confirmed`, `mount_verified`, `commitments_complete` all true, `filesystem_total_bytes`, `filesystem_available_bytes`, `other_unconsumed_commitments_bytes` |
| Receipt `netstack.receiver.receipt.v1` | matched IDs, run, byte count and digest, terms revision, receiver timestamp and `synthetic-verified` result |

These booleans are **fixture assertions**, not authoritative approvals,
reservations or mount validation. Real use would require authenticated,
site-controlled sources, bound to actual owner decisions, filesystem identity,
quota/commitment ledger and accessible capacity. JSON from an uploader or an
untrusted caller is not sufficient. The prototype does not implement these
integrations and must not be used to admit production data.

With one allocation per receiver root, pre-create private `sealed/` and
`staging/` directories on the same filesystem. The prototype serializes
cooperating invocations with a local lock, checks source age and supplied
commitments, counts sealed bundle and receipt file bytes and checks local free space,
then verifies and publishes the run. Matching retries recheck both sealed and
submitted bytes and recheck current evidence freshness immediately before
acknowledgment; conflicting retries fail. A matching retry can use a newer
accepted terms revision, provided current policy and evidence still validate
the request, reservation and input limits. It returns the original receipt
unchanged, retaining the revision recorded when that run was sealed; it does
not make a new receipt or claim that the earlier run was accepted under the
new revision. An incomplete staging directory
blocks all further runs for operator investigation; nothing is automatically
pruned. Receipts and digests are protected evidence, not public status data.

For the fixture check against the dated available-space input, the prototype
subtracts all current sealed file bytes again. This deliberately conservative
bound can double-count bytes already reflected in that snapshot; it is not the
site allocation formula or an accurate allocatable-capacity calculation.
Actual filesystem free space is rechecked separately, but neither approach
accounts for filesystem metadata, directory blocks or unrelated writers.
Physical quota enforcement and complete accounting require site integration.

The prototype does not verify physical devices or quota, enforce role isolation,
control noncooperating writers, account for other applications' concurrent
reservations, authenticate policies, expire approvals, provide an upload daemon,
or run a restore. The lock protects only processes using the same local root
and filesystem locking semantics. A changed input is rejected when copied bytes
do not match the manifest; there is no trust in its post-copy state.

## Validation and adoption

Run isolated fixture tests from a Netstack checkout. They construct disposable
synthetic files, including one test at a 1 MiB limit and one above that limit;
no site accounts or services are used:

```bash
python3 -m unittest discover -s tools/backup-receiver -p 'test_*.py' -v
python3 tools/backup-receiver/demo.py
```

The demo prints an above-limit rejection and an at-limit synthetic receipt.
It uses a disposable temporary directory and creates no site report. It tests
receiver admission, not Wip's separate, unimplemented monitoring evaluator.

### Owner-reviewed site adoption plan (not deployment authority)

1. **Design and review:** the receiver site chooses and versions a transport,
   host/isolated instance, identities, durable storage and recovery configuration.
   Record the backing chain and compare physical failure domains with the
   provider. Confirm accepted terms and a serialized, site-owned reservation
   ledger; recheck source evidence freshness and mount identity at admission.
2. **Isolation and accounting:** the site specifies uploader-only staging,
   a separate receiver/sealer owner, protected accepted runs/receipts, and a
   verifier with independently controlled recovery-key access. Specify and
   test a hard quota, or obtain both owners' explicit acceptance of a soft-budget
   risk with mitigations. Account for all retained data, incoming objects,
   candidates, receipts, logs, filesystem overhead and other commitments.
3. **Provisioning gate:** after a site-specific runbook and owner approval,
   provision only the reviewed identities, service and storage. Preserve the
   current backup route and last-known-good data. Verify mount identity and
   effective access, including denial of shell, access to accepted runs, other
   allocations and keys. These are separately authorized synthetic tests.
4. **Rebuild and rollback:** rebuild disposable compute from the reviewed
   versioned configuration; verify the expected backing and attach the existing
   durable storage without formatting or overwriting it. Check existing run
   manifests and receipts, effective access, quota and reserve before admitting
   new work. If validation fails, stop admission and return to the previously
   approved configuration while retaining the existing durable data and receipt
   records. Do not remove incomplete staging or accepted runs automatically;
   investigate and obtain a separate approved disposition.
5. **Proof:** correlate a receiver-owned receipt with the provider's expected
   manifest and a separately authorized isolated restore/application check.
   Record the same run ID, timestamps, failures and limitations; do not promote
   receipt success to a restore or recovery claim.

Before any real run, obtain distinct approvals for provisioning, isolated
synthetic access/transfer tests, source capture and real-data transfer, restore,
and monitoring. Do not equate this prototype's successful fixture test with a
site deployment, an agreement, independent backup or tested recovery.
