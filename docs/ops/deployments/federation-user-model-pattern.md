# Pattern: Federation User Model (Admin / Ops Agent / Coordination Agent)

**Category:** `docs/ops/deployments/`  
**Purpose:** Define the three user roles on federation compute nodes, their access boundaries, and how sites grant cross-site visibility to coordination agents.  
**Audience:** Any federated infrastructure where multiple admins manage separate sites, and an AI coordination layer (Wip or similar) needs to observe without interfering.

---

## The Problem

When one person (or one AI) has access to everything, you get:
- **Split-brain:** Changes happen through multiple identities and nobody can trace who did what
- **Scope creep:** The monitoring tool starts "fixing" things, creating undocumented state
- **Trust confusion:** A new federation member doesn't know what they're granting access to
- **Blast radius:** If one credential is compromised, everything is exposed

## The Solution: Three Roles, Strict Boundaries

Every federation compute node has up to three user roles. Each role has a clear boundary: what it owns, what it reads, what it writes.

```
┌─────────────────────────────────────────────────────────────────┐
│  Federation Compute Node                                         │
│                                                                   │
│  ┌─────────────────┐  ┌──────────────────┐  ┌────────────────┐  │
│  │  Human Admin     │  │  Ops Agent        │  │  Coord Agent   │  │
│  │  (nsadmin)       │  │  (buadmin)        │  │  (wip)         │  │
│  │                  │  │                   │  │                │  │
│  │  Interactive     │  │  Automated work   │  │  Observe +     │  │
│  │  dev, decisions  │  │  backup, deploy   │  │  communicate   │  │
│  │  full access     │  │  limited scope    │  │  read-only     │  │
│  └─────────────────┘  └──────────────────┘  └────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Role Definitions

### 1. Human Admin (`nsadmin`, `ghadmin`, or site-specific)

**Who:** The person responsible for the site. Makes decisions.

| Attribute | Value |
|-----------|-------|
| Access | Full (sudo, Docker, SSH to all nodes) |
| Shell | Interactive (bash) |
| Purpose | Development, troubleshooting, decision-making |
| Auth | Personal SSH key, interactive login |
| Cron | None (manual work only) |
| Repos | Personal dev repos, experiments |

**Rule:** The human admin DOES things. They approve, deploy, fix. They don't run on cron — they respond to findings from the other two roles.

### 2. Ops Agent (`buadmin`)

**Who:** The automated "hands" of the site. Does operational work on schedule.

| Attribute | Value |
|-----------|-------|
| Access | Limited: Docker (for volume dumps), SSH to remote nodes (SCP only), r/w to backup/deploy targets |
| Shell | Non-interactive (scripts only) |
| Purpose | Backup, deployment, data movement, service restart |
| Auth | Dedicated SSH key (named `id_backup` or `id_ops`) |
| Cron | backup-daily.sh, deploy scripts, retention cleanup |
| Repos | None (doesn't push to git, only moves files) |

**Rule:** buadmin is the "hands." It moves data, creates backups, deploys configs. It has WRITE access to infrastructure but NO access to communication channels (GitHub, email, calendar). It can't create issues or send notifications — that's wip's job.

**On remote nodes:** buadmin is the SSH target that RECEIVES files. Minimal permissions — can write to designated backup directories only.

### 3. Coordination Agent (`wip`)

**Who:** The AI coordination layer. Observes state, communicates findings, manages documentation.

| Attribute | Value |
|-----------|-------|
| Access | Read-only to: `.backup-state`, logs, `site-status.json`, cron output. Read-write to: repos (docs, issues, contracts) |
| Shell | Non-interactive (scripts only) |
| Purpose | Monitoring, reporting, issue creation, contract management, split-brain detection |
| Auth | SSH key registered to repo account (ho-wip). API tokens for GitHub, Gitea, Google Calendar/Email |
| Cron | wip-daily-cron.sh (status report), monitoring checks |
| Repos | All contracted repos (push docs, create issues) |

**Rule:** wip is the "eyes and mouth." It READS state produced by buadmin's work, REPORTS findings via issues/email/calendar, and WRITES documentation. It NEVER modifies infrastructure, restarts services, or moves data. If something needs fixing, wip creates an issue for the human admin.

---

## Access Matrix

| Resource | nsadmin | buadmin | wip |
|----------|:-------:|:-------:|:---:|
| Docker engine | ✅ full | ✅ (for backups) | ❌ |
| SSH to remote nodes | ✅ (manual) | ✅ (cron, SCP) | ❌ |
| `.backup-state` file | ✅ r/w | ✅ write | 📖 read |
| `site-status.json` | ✅ r/w | ❌ | 📖 read |
| Backup directories | ✅ r/w | ✅ r/w | 📖 read |
| Log files | ✅ r/w | ✅ write | 📖 read |
| GitHub repos (push) | ✅ (personal) | ❌ | ✅ (ho-wip) |
| GitHub issues | ✅ | ❌ | ✅ create/edit |
| Google Calendar | ✅ (personal) | ❌ | ✅ (wip@horseoff) |
| Email sending | ✅ (personal) | ❌ | ✅ (wip@horseoff) |
| sudo | ✅ | ❌ | ❌ |
| Service restart | ✅ | ✅ (limited) | ❌ |

---

## Cross-Site Federation

The power of this model: sites can grant access to EACH OTHER's coordination agents without granting infrastructure access.

### How site A grants visibility to site B's Wip:

1. Site A's admin creates a `.wip-contract.md` in their repo
2. Contract specifies: "wip may READ these state files via SSH"
3. Site A's buadmin grants wip's SSH key READ-ONLY access (or wip reads via API/shared file)
4. Site B's wip instance reads Site A's state and reports

```
Site A (cf)                    Site B (sl)
  buadmin writes state           buadmin writes state
  ├── .backup-state              ├── site-status.json
  └── logs/                      └── logs/

       │ (read-only)                  │ (read-only)
       ▼                              ▼
  ┌──────────────────────────────────────────┐
  │  wip (on cf/nsdockerhv)                   │
  │  Reads both sites' state                  │
  │  Creates issues on both repos             │
  │  Reports unified morning status           │
  └──────────────────────────────────────────┘
```

### Future: Multiple Wip instances

When federation grows to multiple admins:

```
Admin A's Wip ←── reads ──→ Site A (.wip-contract grants RO)
Admin A's Wip ←── reads ──→ Site B (.wip-contract grants RO)

Admin B's Wip ←── reads ──→ Site B (.wip-contract grants RO)
Admin B's Wip ←── reads ──→ Site C (.wip-contract grants RO)
```

Each admin's Wip only sees what contracts grant. No admin's Wip can modify another admin's infrastructure. Communication happens through repo issues.

---

## Implementation on nsdockerhv (cf site)

### Current state:
```
nsadmin  — does everything (split-brain risk)
buadmin  — exists, unused
wip      — exists, repos cloned, SSH key to ho-wip
```

### Target state:
```
nsadmin  — interactive only, no cron
buadmin  — owns: backup-daily.sh cron, id_backup SSH key, Docker group
wip      — owns: wip-daily-cron.sh cron, ho-wip SSH key, API tokens, .env
```

### Migration steps:

1. Move backup-daily.sh cron from nsadmin to buadmin
2. Give buadmin: Docker group membership, ownership of /home/nsadmin/backups/ (or new /home/buadmin/backups/)
3. Move wip-daily-cron.sh cron from nsadmin to wip
4. Give wip: read access to .backup-state, API tokens (.env), Google OAuth tokens
5. Ensure wip CANNOT: sudo, access Docker, SSH to remote nodes
6. Test: backup still runs at 2 AM (buadmin), report still runs at 5:30 AM (wip)

---

## Remote Node User Model

On Windows/WSL federation nodes (sl, wf):

| Role | User | Access | Purpose |
|------|------|--------|---------|
| Site admin | ghadmin | Full (Windows admin + WSL sudo) | Physical maintenance, decisions |
| Ops target | buadmin (future) | SCP write to backup dirs only | Receives backups from cf buadmin |
| Monitoring | ghadmin (WSL) | Runs site-status.sh locally on cron | Produces site-status.json for wip to read |

For now, `ghadmin` fills both admin and monitoring roles on remote sites. When the model matures:
- `buadmin` on remote nodes has a restricted shell (rssh or forced command) that only allows SCP to designated paths
- Site-status cron runs as a dedicated user (or ghadmin with limited scope)

---

## Contract-Driven Access

The `.wip-contract.md` on each repo IS the access control document:

```markdown
## What Wip May Read (monitoring scope)
- .backup-state (via buadmin output)
- site-status.json (via WSL SSH port 2020)
- Cron logs at ~/ops/site-status.log

## What Wip May Write
- This repo (docs, issues, .wip-monitor.yml updates)
- Calendar events (tagged with project code)
- Email notifications (per contact method)

## What Wip May NOT Do
- SSH to site nodes directly
- Modify running services
- Execute commands on infrastructure
- Access data outside monitoring scope
```

If a site admin wants to revoke Wip's access: remove the SSH key, update the contract to "access: none." Wip stops seeing that site's state.

---

## Naming Convention

| Role | OS Username | SSH Key Name | GitHub Account |
|------|-------------|-------------|----------------|
| Human admin (cf) | nsadmin | id_rsa (personal) | christrees or horseoffcom |
| Human admin (sl/wf) | ghadmin | (Windows local) | — |
| Ops agent | buadmin | id_backup / id_ops | — (no GitHub needed) |
| Coordination agent | wip | id_ed25519 (wip) | ho-wip |

---

## Security Properties

| Property | How it's achieved |
|----------|-------------------|
| Least privilege | Each role has only what it needs |
| Auditability | Separate users = separate auth.log entries |
| Blast radius | Compromised wip can't modify infra; compromised buadmin can't push to repos |
| Revocability | Remove one key = revoke one role |
| Traceability | Git commits show which identity pushed (ho-wip vs christrees) |
| Federation-safe | Cross-site access is contract-driven and read-only |

---

## Related

- [site-tenant-contract-pattern](./site-tenant-contract-pattern.md) — site vs tenant boundary
- [contract-driven-monitoring-pattern](../monitor/contract-driven-monitoring-pattern.md) — .wip-monitor.yml
- [wsl-monitoring-node-pattern](../monitor/wsl-monitoring-node-pattern.md) — WSL as monitoring layer
- [access-monitoring-pattern](../security/access-monitoring-pattern.md) — who SHOULD have access where
- [netstack#12](https://github.com/2cld/netstack/issues/12) — Unix monitoring node requirement
