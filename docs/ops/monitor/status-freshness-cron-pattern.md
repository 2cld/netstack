# Pattern: Status Freshness Cron

**Applies to:** Any automated monitoring that needs to write results back (update a status page, trigger an alert, or update a coordination repo).

## Principle

> A monitoring check that doesn't write its results somewhere is just a log line nobody reads. The cron pattern closes the loop: **check → compare → write → alert.**

## The Problem

Most monitoring setups stop at "run a check, print output." The output goes to stdout or a log file. Someone has to manually read it and take action. Status pages go stale because updating them is a manual step nobody remembers.

The gap:

```
✅ Existing patterns cover:
   - What to check (monitoring-pattern.md)
   - How to check across platforms (cross-platform-monitoring-pattern.md)
   - What the status page looks like (site-status-page-pattern.md)

❌ Missing:
   - HOW the check results get written back automatically
   - WHEN to escalate from "stale" to "alert"
   - WHERE the write-back goes (file, API, issue)
```

## The Pattern: Check → Compare → Write → Alert

```
┌─────────────────────────────────────────────────────────────┐
│ CRON RUNS (e.g., every 6 hours, daily, on deploy)           │
└───────────────────────────┬─────────────────────────────────┘
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ 1. CHECK — Run monitoring scripts                           │
│    - Per-node checks (SSH, HTTP, ping)                      │
│    - Backup freshness (.backup-state file dates)            │
│    - Repo activity (API: last push, open issues)            │
│    - Service status (HTTP codes, port checks)               │
└───────────────────────────┬─────────────────────────────────┘
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. COMPARE — Apply thresholds                               │
│    - Is this value within acceptable range?                  │
│    - Has this timestamp exceeded the stale threshold?        │
│    - Did a previously-OK check just fail?                    │
│    - Did a previously-failed check just recover?            │
└───────────┬───────────────────────────────────┬─────────────┘
            │ ALL OK                            │ THRESHOLD BREACHED
            ▼                                   ▼
┌───────────────────────┐         ┌───────────────────────────┐
│ 3a. WRITE (routine)   │         │ 3b. WRITE + ALERT         │
│ - Update status file  │         │ - Update status file      │
│ - Update timestamp    │         │ - Update timestamp        │
│ - Log "all clear"     │         │ - CREATE ISSUE or ALERT   │
└───────────────────────┘         │ - Notify responsible admin│
                                  └───────────────────────────┘
```

## Threshold Table

Define thresholds once per resource type. These drive the compare step:

| Resource | Check Method | OK | Warning | Critical |
|----------|-------------|:--:|:-------:|:--------:|
| Site (HTTP) | HTTP GET status code | 200 in < 5s | 200 in > 5s | non-200 or timeout |
| Node (SSH) | SSH connect + echo | connects < 3s | connects 3-10s | timeout or refused |
| Backup (.backup-state) | File date comparison | < 24h old | 24–48h old | > 48h old |
| Repo (last push) | GitHub/Gitea API | < 14 days | 14–30 days | > 30 days |
| Service (TCP port) | TCP connect | responds | slow (> 2s) | refused or timeout |
| Status page (last updated) | File mtime or timestamp in file | < 12h | 12–24h | > 24h |

## Write-Back Targets

Where does the cron write results? Multiple targets, layered:

| Target | Format | Purpose | Updated |
|--------|--------|---------|:-------:|
| Status file (`docs/status.md`) | Markdown table | Human-readable, per-site status page | Every run |
| State file (`.monitor-state.json`) | JSON | Machine-readable, for comparison on next run | Every run |
| Coordination repo (wip README) | Markdown table row | Federation rollup (one line per site) | Daily |
| Issue tracker | Issue body or comment | When threshold breaches (alert action) | On breach only |
| Log file | Append-only text | Historical record | Every run |

### State File Format (`.monitor-state.json`)

```json
{
  "last_run": "2026-06-16T09:00:00Z",
  "checks": {
    "cf-http": { "status": "ok", "value": "200 142ms", "since": "2026-06-10T06:00:00Z" },
    "cf-backup": { "status": "warning", "value": "36h old", "since": "2026-06-15T06:00:00Z" },
    "wf-ssh": { "status": "critical", "value": "timeout", "since": "2026-06-12T06:00:00Z" }
  }
}
```

**Why a state file?** It enables transition detection. If `cf-backup` was "ok" last run and is "warning" this run, that's a state change worth flagging. If it was already "warning" last run, don't re-alert — just note the duration.

## Transition Detection

The compare step uses the previous state to detect meaningful changes:

| Previous | Current | Action |
|:--------:|:-------:|--------|
| ok | ok | Write routine update, no alert |
| ok | warning | Write update + flag in morning check-in |
| ok | critical | Write update + **create issue/alert immediately** |
| warning | critical | Write update + **escalate** (issue if not already open) |
| critical | ok | Write update + **send recovery acknowledgment** |
| warning | ok | Write update + note recovery in log |

## Cron Frequency

| Check Type | Recommended Frequency | Rationale |
|------------|:---------------------:|-----------|
| Site HTTP checks | Every 6 hours | Catch outages within business day |
| Backup freshness | Daily (morning) | Backups run overnight, check in AM |
| Repo activity | Daily (morning) | Surface stale repos in check-in |
| Federation rollup | Daily (morning) | Update wip README before standup |
| Full audit | Weekly (Sunday) | Comprehensive check for weekly review |

## Implementation Skeleton

```bash
#!/bin/bash
# status-freshness-cron.sh — the write-back layer
# Called by: wip-daily-cron.sh (daily) or standalone (ad-hoc)

STATE_FILE=".monitor-state.json"
STATUS_FILE="docs/status.md"

# 1. CHECK: Run all monitoring scripts, capture output
RESULTS=$(node federation-status.js --json)

# 2. COMPARE: Load previous state, detect transitions
PREVIOUS=$(cat "$STATE_FILE" 2>/dev/null || echo '{}')
TRANSITIONS=$(node compare-states.js "$PREVIOUS" "$RESULTS")

# 3. WRITE: Update status file + state file
node render-status.js "$RESULTS" > "$STATUS_FILE"
echo "$RESULTS" > "$STATE_FILE"

# 4. ALERT: If transitions include critical, create issue
if echo "$TRANSITIONS" | grep -q "critical"; then
  node create-alert-issue.js "$TRANSITIONS"
fi

# 5. RECOVER: If transitions include recovery, acknowledge
if echo "$TRANSITIONS" | grep -q "recovered"; then
  node send-recovery.js "$TRANSITIONS"
fi
```

## Connection to Existing Patterns

| Pattern | How this extends it |
|---------|-------------------|
| `monitoring-pattern.md` | Adds the write-back layer (step 3+4) after read/report |
| `site-status-page-pattern.md` | Automates the "generation" step (currently manual) |
| `cross-platform-monitoring-pattern.md` | The CHECK step uses these SSH patterns |
| `request-lifecycle.md` | The ALERT step creates a request; recovery triggers acknowledgment |

## Related

- [monitoring-pattern.md](./monitoring-pattern.md) — what and how to check
- [site-status-page-pattern.md](./site-status-page-pattern.md) — status page format
- [request-lifecycle.md](./request-lifecycle.md) — request → verify → acknowledge
- [repo-communication-pattern.md](./repo-communication-pattern.md) — how to create issues from monitoring output
- [pattern-workflow.md](../pattern-workflow.md) — netstack drives all ops
