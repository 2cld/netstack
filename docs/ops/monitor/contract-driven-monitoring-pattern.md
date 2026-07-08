# Pattern: Contract-Driven Monitoring (`.wip-monitor.yml`)

**Status:** Active  
**First implementation:** [2cld/wf/.wip-monitor.yml](https://github.com/2cld/wf/blob/main/.wip-monitor.yml)  
**Related:** [cross-platform-monitoring-pattern](./cross-platform-monitoring-pattern.md), [site-status-page-pattern](./site-status-page-pattern.md)

---

## Problem

Monitoring scripts accumulate hardcoded assumptions (drive letters, tar vs rsync, SSH users, port numbers). When infrastructure changes, the scripts break silently — producing false alerts or missing real problems.

The admin who changes the infrastructure is rarely the same context as the automation that monitors it. This creates drift.

## Solution

Each project repo that Wip monitors publishes a `.wip-monitor.yml` file alongside its `.wip-contract.md`. This file is:

- **Machine-readable** — monitoring scripts consume it directly
- **Admin-owned** — the person who changes infrastructure updates the monitor config in the same commit
- **Version-controlled** — changes are auditable, diffable, revertable
- **Template-driven** — a generator script builds site-specific status checks from all `.wip-monitor.yml` files

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│  Project Repos (admin-owned)                                     │
│                                                                   │
│  repo/.wip-contract.md       (human: goals, scope, contacts)     │
│  repo/.wip-monitor.yml       (machine: what to check)            │
│  repo/site-config.yml        (full infrastructure truth)         │
└──────────────────────────────┬──────────────────────────────────┘
                               │ (coordinator reads at cron time)
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│  Coordination Node (e.g. nsdockerhv)                              │
│                                                                   │
│  monitor-runner.js                                                │
│    - Fetches .wip-monitor.yml from each contracted repo           │
│    - Validates schema                                             │
│    - Executes checks per type/tier                                │
│    - Reports results (cron report, calendar event)                │
└─────────────────────────────────────────────────────────────────┘
```

## Flow

1. **Admin changes infra** (e.g., switches backup from tar to rsync, plugs USB drive)
2. **Admin updates `.wip-monitor.yml`** in same PR/commit (changes check method, adds drive)
3. **Next cron run** picks up the new config → correct check runs
4. **No manual script editing** needed on the coordinator

If admin forgets to update `.wip-monitor.yml`, coordinator detects drift:
- Contract says "monitor X" but check fails with method error → create issue asking admin to update config

## File Relationships

| File | Audience | Purpose |
|------|----------|---------|
| `.wip-contract.md` | Humans + AI | Goals, scope, permissions, contacts |
| `.wip-monitor.yml` | Scripts + AI | Actionable check definitions |
| `site-config.yml` | Infrastructure docs | Full site truth (network, devices, services) |

The contract references the monitor file:
```markdown
## Monitoring Scope
See [.wip-monitor.yml](./.wip-monitor.yml) for machine-readable check definitions.
```

## Schema (v1.0)

```yaml
schema: "1.0"
project: "<site-code>"
repo: "<org>/<repo>"

contact:
  action: "<email>"
  cc: "<email>"

access:
  <hostname>:
    zt_ip: "<zerotier IP>"
    ssh_user: "<user>"
    ssh_port: <port>
    methods:
      - name: "<method name>"
        reliable: true/false
        notes: "<context>"

checks:
  - name: "<human label>"
    type: <check_type>
    tier: <operational|cold|glacial|scratch>
    enabled: true/false
    goal: "<which contract goal this serves>"
    # ... type-specific fields
```

## Check Types

| Type | Purpose | Key Fields |
|------|---------|-----------|
| `ping` | Node reachable | `target` (IP) |
| `http` | Service responding | `target` (URL), `expect_status` |
| `ssh_command` | Run command, check output | `host`, `command`, `expect` |
| `disk_space` | Volume capacity | `host`, `volume_label`, `alert_below_gb`, `alert_below_pct` |
| `file_age` | File freshness | `host`, `path`, `max_age_hours` |
| `backup_state` | Read .backup-state | `path`, `key`, `expect` |
| `api` | External API check | `url`, `headers`, `expect` |
| `process` | Service running | `host`, `command` (pgrep pattern) |

## Tier Behavior

| Tier | Alert on low space? | Alert on unreachable? | Show in report? |
|------|:---:|:---:|:---:|
| `operational` | ⚠️ YES | ❌ YES | Always |
| `cold` | ℹ️ info only | ⚠️ if expected UP | Always |
| `glacial` | No | No | On request |
| `scratch` | No | No | Never |

## Special Fields

| Field | Purpose |
|-------|---------|
| `known_down: true` | Suppress alerts — tracked by issue |
| `issue: "<url>"` | Link to tracking issue (suppresses alerts until closed) |
| `volume_label` | Authoritative identifier (stable across drive letter changes) |
| `drive_letter` | Hint only (may change for USB/removable media) |

## Design Decisions

- **`volume_label` over `drive_letter`**: USB drives get reassigned letters when re-plugged. Label is stable.
- **`tier` controls alerting**: Consistent vocabulary instead of per-check `alert: true/false`
- **`known_down` + `issue`**: Don't nag about things already tracked. Alert resumes when issue is closed.
- **`access` section**: Scripts read connection info from YAML instead of hardcoding SSH users/ports.
- **`goal` field**: Ties each check back to `.wip-contract.md` goals without duplicating them.

## Implementation Approaches

**A. Runtime (recommended to start)**
- Status script reads `.wip-monitor.yml` at execution time
- Interprets checks from YAML each run
- Pro: no build step, always current
- Con: slightly slower, needs YAML parser at runtime

**B. Generated (future, for scale)**
- Build script reads all YAML files → generates status check scripts
- Run after any `.wip-monitor.yml` change
- Pro: fast execution, lint/validate at build time
- Con: extra build step

## Migration Path

1. ✅ Create `.wip-monitor.yml` for wf (proof of concept)
2. Update status scripts to optionally read from YAML
3. Create for cf, hwpc
4. Eventually: all status scripts driven by YAML, hardcoded checks removed

## Related

- [cross-platform-monitoring-pattern](./cross-platform-monitoring-pattern.md) — goal-based monitoring philosophy
- [site-status-page-pattern](./site-status-page-pattern.md) — status page format
- [resilient-cron-pattern](./resilient-cron-pattern.md) — cron reliability
- [status-freshness-cron-pattern](./status-freshness-cron-pattern.md) — freshness checks
