# Pattern: Federation User Model (Roles, Boundaries, Site Mapping)

**Category:** `docs/ops/deployments/`  
**Purpose:** Define abstract roles for federation compute nodes, their access boundaries, and how each site maps roles to actual usernames and hostnames.  
**Audience:** Any federated infrastructure where multiple admins manage separate sites, and an AI coordination layer needs to observe without interfering.

---

## The Problem

When one person (or one AI) has access to everything, you get:
- **Split-brain:** Changes happen through multiple identities and nobody can trace who did what
- **Scope creep:** The monitoring tool starts "fixing" things, creating undocumented state
- **Trust confusion:** A new federation member doesn't know what they're granting access to
- **Blast radius:** If one credential is compromised, everything is exposed
- **Name confusion:** "buadmin" means different things on different sites, or the same person uses different names

## The Solution: Roles (abstract) + Site Mapping (concrete)

The pattern defines **abstract roles** with strict boundaries. Each site's `site-config.yml` maps those roles to **actual usernames and hostnames** for that site.

---

## Part 1: Abstract Roles

These are the PATTERN names. They describe WHAT a role does, not WHO it is.

### Role: `site-admin`

The human who makes decisions and performs interactive work.

| Attribute | Definition |
|-----------|------------|
| Type | Human, interactive |
| Access | Full (sudo, Docker, SSH, all nodes at this site) |
| Purpose | Deploy services, troubleshoot, approve changes |
| Cron | None (responds to findings, doesn't run on schedule) |
| Repos | May push as personal identity |
| Communication | Receives action recommendations from coordination-agent |

**Rule:** site-admin DOES things. Deploys, configures, fixes. All infrastructure changes flow through this role.

### Role: `backup-agent`

Automated process that moves data on schedule. Very restrictive.

| Attribute | Definition |
|-----------|------------|
| Type | Automated, non-interactive |
| Access | ONLY: read source data, write to backup targets, read/write .backup-state |
| Purpose | Backup execution ONLY (tar, scp, rsync, rotation) |
| Cron | Backup scripts only |
| Repos | None (no git access, no communication channels) |
| Cannot | sudo, restart services, install packages, push to git, send email |

**Rule:** backup-agent has the narrowest possible scope. It reads data from one place, writes it to another, and records that it did so. Nothing else.

**On remote nodes:** backup-agent is the SSH target that RECEIVES files. Restricted shell or forced-command that only allows SCP to designated paths.

### Role: `coordination-agent`

AI or automation that observes and communicates. Never modifies infrastructure.

| Attribute | Definition |
|-----------|------------|
| Type | Automated, non-interactive |
| Access | Read-only to: state files, logs, status output. Read-write to: repos (docs, issues) |
| Purpose | Monitoring, reporting, issue creation, contract management, split-brain detection |
| Cron | Status checks, morning reports |
| Repos | Push docs/issues to contracted repos |
| Cannot | sudo, Docker, SSH to remote infra nodes, modify running services |

**Rule:** coordination-agent is "eyes and mouth." It READS state, REPORTS findings, WRITES documentation. If something needs fixing, it creates an issue for site-admin. It NEVER touches infrastructure.

---

## Part 2: Node Roles (abstract)

Netstack defines abstract node roles. Each site maps these to actual hostnames.

| Role Code | Full Name | Purpose |
|-----------|-----------|---------|
| `ng` | Network Gateway | Router, firewall, DHCP, DNS |
| `sg` | Storage Gateway | NAS, file server, ZFS pool host |
| `cg` | Compute Gateway | Primary compute (Docker, VMs, services) |
| `cg2` | Secondary Compute | Additional compute capacity |
| `bu-0` | Backup Target Primary | Off-site backup receiver #1 |
| `bu-1` | Backup Target Secondary | Off-site backup receiver #2 |

---

## Part 3: Site Mapping (in site-config.yml)

Each site's `site-config.yml` includes a `roles:` section that maps abstract roles to concrete names:

```yaml
# site-config.yml — Role Mapping section
roles:
  users:
    site-admin:
      username: "nsadmin"           # cf uses nsadmin
      auth: "SSH key (personal)"
      email: "christrees@gmail.com"
      notes: "Chris Trees — interactive admin"

    backup-agent:
      username: "buadmin"           # could be any name
      auth: "SSH key (id_backup)"
      scope: "backup-daily.sh cron ONLY"
      notes: "Restricted to backup operations"

    coordination-agent:
      username: "wip"
      auth: "SSH key (ho-wip ed25519)"
      github: "ho-wip"
      email: "wip@horseoff.com"
      scope: "read state, write repos"

  # On REMOTE nodes (where this site receives connections FROM)
  inbound:
    backup-agent:
      username: "buadmin"           # receives SCP from federation controller
      auth: "authorized_keys (nsdockerhv id_backup)"
      scope: "write to ~/backups/ only"

    coordination-agent:
      username: "wip"
      auth: "authorized_keys (nsdockerhv wip key)"
      scope: "read ~/ops/site-status.json only"

  nodes:
    ng: "mikrotik"                  # wf uses MikroTik router
    sg: "MediaVolume (ZFS on cg2)"  # wf storage is ZFS pool
    cg: "devwin10"                  # wf primary compute
    cg2: "cg2 (Proxmox)"           # wf secondary compute
    bu-0: "slwin11ops"             # primary backup target (sl)
    bu-1: "devwin10 D:"            # secondary backup target (wf local)
```

### Example: Same roles, different names across sites

| Role | cf site | sl site | wf site |
|------|---------|---------|---------|
| site-admin | nsadmin | ghadmin | ghadmin |
| backup-agent | buadmin | ghadmin (shared) | buadmin |
| coordination-agent | wip | wip (remote, on cf) | wip (remote, on cf) |
| ng | router (192.168.6.1) | Spectrum router | mikrotik |
| sg | CyberTruck D: | slwin11ops F: | MediaVolume (ZFS) |
| cg | nsdockerhv | slwin11ops WSL | LXC 100 on cg2 |

**Note:** sl uses `ghadmin` for both site-admin AND backup-agent because it's a smaller site. The ROLE separation still applies (cron jobs run backup scripts, interactive work is separate) even when the same username fills both.

---

## Part 4: Access Matrix (by role, not by name)

| Resource | site-admin | backup-agent | coordination-agent |
|----------|:----------:|:------------:|:------------------:|
| sudo | ✅ | ❌ | ❌ |
| Docker | ✅ | ❌ | ❌ |
| Service start/stop | ✅ | ❌ | ❌ |
| SSH to other nodes | ✅ (manual) | ✅ (SCP only, cron) | ❌ |
| Read .backup-state | ✅ | ✅ write | 📖 read |
| Read site-status.json | ✅ | ❌ | 📖 read |
| Read/write backup dirs | ✅ | ✅ | ❌ |
| Push to git repos | ✅ (personal) | ❌ | ✅ (coordination identity) |
| Create issues | ✅ | ❌ | ✅ |
| Send email/calendar | ✅ (personal) | ❌ | ✅ (coordination identity) |
| Install packages | ✅ | ❌ | ❌ |
| Modify firewall/network | ✅ | ❌ | ❌ |

---

## Part 5: Cross-Site Federation

Sites grant access to each other's coordination-agents via `.wip-contract.md`:

```
Site A admin grants → Site B's coordination-agent → read-only to state files
```

The contract specifies exactly what's visible. No infrastructure access crosses site boundaries for coordination-agents.

```
Site A (cf)                    Site B (sl)
  backup-agent writes state      backup-agent writes state
  ├── .backup-state              ├── site-status.json
  └── logs/                      └── logs/

       │ (read-only)                  │ (read-only)
       ▼                              ▼
  ┌──────────────────────────────────────────┐
  │  coordination-agent (on cf)               │
  │  Reads both sites' state                  │
  │  Creates issues on both repos             │
  │  Reports unified morning status           │
  └──────────────────────────────────────────┘
```

---

## Part 6: Communication Flow

When the coordination-agent detects a problem:

```
Problem detected
  ├── Which site? → check site-config.yml roles.nodes mapping
  ├── Which role should fix it? → site-admin (infra change) or backup-agent (cron fix)
  ├── Where to communicate? → .wip-contract.md contact method
  ├── How? → Create issue on site repo with specific action recommendation
  └── Who verifies? → coordination-agent reads state after fix
```

The coordination-agent NEVER fixes things directly. It:
1. Detects the problem
2. Identifies the responsible role
3. Creates an issue with the exact commands/steps needed
4. Waits for site-admin to execute
5. Verifies the fix via state files

---

## Part 7: ns-site-template Generation

The `roles:` section in site-config.yml enables ns-site-template to generate:

- `bootstrap.sh` — creates the correct usernames for each role
- `ops/scripts/` — cron scripts run as the backup-agent username
- Status scripts — write to paths the coordination-agent can read
- Documentation — maps abstract roles to actual names for human reference
- SSH key deployment — knows which key goes to which user

---

## Security Properties

| Property | How it's achieved |
|----------|-------------------|
| Least privilege | Roles define maximum access — sites can restrict further |
| Auditability | Separate users = separate auth.log entries |
| Blast radius | Compromised coordination-agent can't modify infra; compromised backup-agent can't communicate |
| Revocability | Remove one key = revoke one role |
| Traceability | Git commits show which identity pushed |
| Federation-safe | Cross-site access is contract-driven and read-only |
| Site autonomy | Each site maps roles to names independently |

---

## Related

- [site-tenant-contract-pattern](./site-tenant-contract-pattern.md) — site vs tenant boundary
- [contract-driven-monitoring-pattern](../monitor/contract-driven-monitoring-pattern.md) — .wip-monitor.yml
- [wsl-monitoring-node-pattern](../monitor/wsl-monitoring-node-pattern.md) — WSL as monitoring layer
- [access-monitoring-pattern](../security/access-monitoring-pattern.md) — who SHOULD have access where
- [netstack#12](https://github.com/2cld/netstack/issues/12) — Unix monitoring node requirement
- [netstack#17](https://github.com/2cld/netstack/issues/17) — site-ops bootstrap (uses role mapping)
