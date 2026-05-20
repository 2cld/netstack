# Federation Production Deployment — Phased Plan

A guide for taking small business clients (LLCs, trusts, custom applications) from ad-hoc local setups into production state on federation infrastructure.

## Who This Is For

- A consultant managing multiple small business clients (LLCs, trusts)
- Each client has sensitive data (financial, customer PII, tax records)
- Custom applications serve the business (e.g., route planning, invoicing)
- Infrastructure is self-hosted across multiple geographic sites
- Goal: production reliability without enterprise cost/complexity

## The Problem

Small business IT typically evolves like this:
1. Start on one machine (laptop, desktop, single server)
2. Data accumulates (customer DB, accounting, documents)
3. Backups are manual and inconsistent
4. Multiple clients share the same machine
5. No disaster recovery plan
6. One person holds all the knowledge

This works until it doesn't. A drive failure, a stolen laptop, or the one person being unavailable creates a crisis.

## The Solution: Federation

Distribute data and services across multiple sites connected by encrypted overlay network. Each site can recover from the others. No single point of failure.

```
Site A (primary)          Site B (off-site)         Site C (off-site)
├── Client apps           ├── Backup target         ├── Backup target
├── Client data           ├── Failover capable      ├── Archive storage
├── Development           ├── Monitoring            └── Cold storage
└── Daily operations      └── Recovery point
```

---

## Phase 1: Inventory and Classify (Week 1-2)

**Goal:** Know what you have, where it lives, and what's at risk.

### 1.1 Data Classification

Classify all data into tiers:

| Tier | Description | Examples | Backup Frequency |
|------|-------------|----------|:----------------:|
| **Critical** | Irreplaceable, active, business-stopping if lost | Production databases, customer data | Daily |
| **Important** | Replaceable with effort, needed for operations | Tax returns, invoices, configs | Weekly |
| **Reproducible** | Can be rebuilt from source | Code (in git), built artifacts, VMs | On change (git push) |
| **Archive** | Rarely accessed, historical value | Old tax years, completed projects | Monthly/quarterly |

### 1.2 Sensitivity Classification

| Level | Description | Storage Rules |
|-------|-------------|---------------|
| **PII/Financial** | SSNs, account numbers, customer data | Never in git, encrypted at rest, encrypted in transit |
| **Credentials** | Passwords, API tokens, keys | Vault only (age-encrypted), never in any repo |
| **Internal** | IPs, architecture, procedures | Private repos OK, never public |
| **Public** | Patterns, templates, documentation | Public repos, shareable |

### 1.3 Map Current State

For each client/project, document:
- Where data lives (which machine, which directory)
- Who accesses it (which persona/identity)
- How it's currently backed up (if at all)
- What would happen if that machine died tomorrow

---

## Phase 2: Establish Backup (Week 2-4)

**Goal:** Every critical file has at least one copy on separate physical storage.

### 2.1 Immediate (Day 1)

For each critical-tier item with no backup:
```bash
# Tar the critical data
tar -cf /path/to/backup/client-data-$(date +%Y%m%d).tar /path/to/critical/data

# Copy to separate physical disk (same site)
cp backup.tar /separate-disk/

# Copy to off-site (via encrypted overlay)
cp backup.tar /offsite-mount/
```

### 2.2 Automate (Week 2)

Create a backup script per client that:
1. Tars critical data
2. Copies to local separate disk
3. Copies to off-site via overlay network
4. Writes a `.backup-state` file (timestamp + success/fail)
5. Runs on a schedule (cron/Task Scheduler)

### 2.3 Verify (Week 3-4)

- Test restore from each backup target
- Verify `.backup-state` files are being written
- Set up monitoring that alerts if backup is stale

---

## Phase 3: Separate Concerns (Month 2)

**Goal:** Each client's data is isolated. Code is in git. Secrets are in vault.

### 3.1 Git for Code and Docs

Everything that's NOT sensitive goes into git repos:
- Application code
- Configuration templates (with placeholders)
- Documentation and procedures
- Infrastructure-as-code (deployment scripts)

Git repos on multiple remotes = automatic backup. See [git-as-backup pattern](ops-git-as-backup.md).

### 3.2 Vault for Secrets

Credentials and encryption keys go into an age-encrypted vault:
- Private git repo on self-hosted infrastructure
- One age key to protect (stored in password manager + physical backup)
- Everything else encrypted in the vault repo

### 3.3 Client Isolation

Each client gets:
- Own directory structure (no mixing of client data)
- Own git repo (for their code/docs)
- Own backup schedule (based on their data tier)
- Own monitoring (status script)
- Clear ownership (who's the admin, who's the developer)

### 3.4 Gitignore Pattern

For repos that mix code and client data:
```gitignore
# Client PII data (never in git)
client-data/
*.db
*.env
backup/logs/
```

The code is backed up via git. The data is backed up via federation tar/rsync.

---

## Phase 4: Federation Infrastructure (Month 3-4)

**Goal:** Multiple sites connected, automated replication, failover capability.

### 4.1 Overlay Network

Connect all sites via encrypted overlay (ZeroTier, WireGuard, Tailscale):
- Each site gets a stable overlay IP
- File shares mapped between sites
- Monitoring scripts verify cross-site connectivity

### 4.2 Site Standardization

Each site follows the same structure (see [federation-node-topology](deployments/federation-node-topology.md)):
```
site/
├── docs/           ← site-specific documentation
├── ops/
│   ├── backup/     ← backup scripts + state
│   ├── monitor/    ← health checks
│   └── sensitive/  ← credentials (gitignored)
└── README.md
```

### 4.3 Automated Replication

Replace manual tar-and-copy with scheduled replication:
- Critical data: daily to 2 off-site targets
- Important data: weekly to 1 off-site target
- Reproducible: git push to multiple remotes (automatic)

### 4.4 Failover Planning

For each critical application:
- Document: "If Site A dies, how does Site B take over?"
- Test: Actually fail over and verify it works
- Automate: Where possible, make failover automatic

---

## Phase 5: Production Operations (Ongoing)

**Goal:** Sustainable, monitored, documented operations.

### 5.1 Monitoring

- Daily status checks (automated scripts)
- Backup freshness alerts (red alert if stale)
- Service health checks (is the app responding?)
- Cross-site connectivity verification

### 5.2 Documentation

- Every procedure has a runbook
- Session logs track what was done and why
- Consulting agreements define access and responsibilities
- Sensitive data patterns prevent accidental exposure

### 5.3 Coordination

- A coordination layer (like Wip) tracks all projects
- Morning check-ins surface issues across all clients
- Weekly reviews assess progress and priorities
- Red alerts squeak daily until resolved

### 5.4 Maintenance Cadence

| Frequency | Action |
|-----------|--------|
| Daily | Automated backups run, status checks, morning review |
| Weekly | Verify backup freshness, review alerts, check stale repos |
| Monthly | Full backup test (restore), security review, storage audit |
| Quarterly | Client review, infrastructure assessment, capacity planning |

---

## Phase 6: Continuous Improvement

### 6.1 CAVE Principles

Apply [CAVE principles](security/cave-principles.md) to production services:
- Pin versions, don't auto-update production
- Validate changes in staging before production
- Keep environments reproducible from scripts

### 6.2 Ephemeral Infrastructure

Move toward rebuildable systems:
- OS and services defined in provisioning scripts
- If a machine dies, rebuild from scripts + restore data from backup
- Only backup dynamic data (vault + client data), not the OS

### 6.3 Collaborator Backup

Active collaborators who pull repos regularly are distributed backups. Encourage frequent check-ins — collaboration IS backup.

---

## Success Criteria

- [ ] Every critical file has 3 copies on 2 different media, 1 off-site
- [ ] Backup freshness is monitored and alerts fire if stale
- [ ] Each client's data is isolated and clearly owned
- [ ] Credentials are in vault, never in repos
- [ ] At least one application can fail over to another site
- [ ] A new person can onboard by reading the documentation
- [ ] Recovery from total site loss takes hours, not days

## Related

- [Federation Backup Plan](ops/backup/federation-backup-plan.md) — 3-2-1 rule details
- [Git as Backup](ops-git-as-backup.md) — using git remotes as backup
- [CAVE Principles](ops/security/cave-principles.md) — environment stability
- [Sensitive Data Pattern](ops/security/sensitive-data-pattern.md) — protecting PII
- [Session Logging](ops/tools/session-logging.md) — documenting work
- [Monitoring Pattern](ops/monitor/monitoring-pattern.md) — automated health checks
- [Federation Node Topology](ops/deployments/federation-node-topology.md) — site structure
