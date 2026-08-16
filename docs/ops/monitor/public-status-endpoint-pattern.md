# Public Status Endpoint Pattern

**Status:** Adopted (wf validated 2026-08-13, cf PR open 2026-08-16) | **Goal:** All sites by Q4 2026

## Problem

SSH-based monitoring from the coordinator (nsdockerhv/wip) to site nodes is unreliable:
- Windows OpenSSH key auth fails intermittently from cron context
- SSH timeouts add 10-45s to every cron run per check
- ZeroTier dependency means monitoring fails when the network overlay fails
- Each new check requires SSH plumbing (user, key, port, shell differences)

Result: "Permission denied" errors in daily cron logs for weeks/months with no fix.

## Solution

Each site generates its own `status.json` locally, then publishes it via a Cloudflare tunnel at a public HTTPS endpoint. The coordinator reads it with a simple `curl` or `fetch()`.

```
┌─────────────────────────────────────────────────────┐
│ SITE (local)                                        │
│                                                     │
│  checks.yml → site-status-checker → status.json     │
│                                        │            │
│  nginx (site-web) ← serves status.json + /health   │
│         │                                           │
│  cloudflared tunnel ← exposes to internet           │
└─────────┼───────────────────────────────────────────┘
          │ HTTPS (public, CF Access bypass on /status.json)
          ▼
┌─────────────────────────────────────────────────────┐
│ COORDINATOR (wip on nsdockerhv)                     │
│                                                     │
│  curl https://site.domain/status.json               │
│         │                                           │
│  netstack-status.js / storage-status.js             │
│         │                                           │
│  .monitor-state.json → morning-update → README      │
└─────────────────────────────────────────────────────┘
          │
          │  HTTPS (public)
          ▼
┌─────────────────────────────────────────────────────┐
│ FEDERATION DASHBOARD (wip.2cld.net/docs/status/)    │
│                                                     │
│  Static HTML + JS (GitHub Pages)                    │
│  Fetches status.json from each site                 │
│  Renders unified status view                        │
│  Auto-refreshes every 60s                           │
│                                                     │
└─────────────────────────────────────────────────────┘
```

## Architecture Principles

1. **Status is public, data is private.** The status endpoint reports health (ok/error/warning) and capacity (GB free). It does NOT expose file contents, credentials, or user data.

2. **No SSH for monitoring.** SSH is for administration and backup. Monitoring reads a published artifact.

3. **No ZeroTier dependency for monitoring.** Cloudflare tunnels provide the transport. ZT is only needed for backup transfers and SSH admin.

4. **Staleness is the alert.** If `status.json` is older than 10 minutes, the checker is down. The coordinator doesn't need to know why — stale = problem.

5. **Site autonomy.** Each site owns its `checks.yml`. Adding a new check is a git push, not a coordinator config change.

6. **Federation dashboard reads the same endpoints.** The web UI at wip.2cld.net/docs/status/ fetches each site's status.json directly — no server-side aggregation needed.

## Implementation Per Site

### What runs locally (on the site's always-on node)

| Component | Container | Purpose |
|-----------|-----------|---------|
| site-status-checker | `site-status-checker` or `cf-status-checker` | Reads `checks.yml`, runs checks every 5 min, writes `status.json` |
| site-web | nginx | Serves `status.json` at `/status.json` and `/health` |
| cloudflared | `cloudflared` | Tunnels site-web to public internet |

### What the coordinator reads

| Endpoint | Auth | Purpose |
|----------|------|---------|
| `https://{site}.domain/status.json` | None (CF Access bypass) | Machine-readable health checks |
| `https://{site}.domain/health` | None (CF Access bypass) | Simple container alive check |

### `status.json` schema

```json
{
  "site": "wf",
  "site_name": "Winfield",
  "timestamp": "2026-08-13T15:47:20.123Z",
  "status": "ok|warning|degraded|error",
  "check_interval_seconds": 300,
  "check_count": 12,
  "ok_count": 10,
  "error_count": 1,
  "warning_count": 0,
  "known_down_count": 1,
  "checks": [
    {
      "name": "descriptive name",
      "type": "ping|http|command|disk",
      "status": "ok|error|warning|known_down",
      "message": "human-readable result",
      "tier": "operational|cold|glacial",
      "goal": "which contract goal this serves"
    }
  ]
}
```

## Adoption Status

| Site | Local Checker | Public Endpoint | Coordinator Reads | Dashboard | Status |
|------|:---:|:---:|:---:|:---:|--------|
| wf | ✅ | ✅ `wf.klopfenstein.org/status.json` | ✅ | ✅ | **Done** (2026-08-13) |
| cf | ✅ [PR#5](https://github.com/2cld/cf/pull/5) | Pending deploy | ❌ (runs locally) | Pending | **In Progress** (2026-08-16) |
| sl | ❌ | ❌ | ❌ (SSH to WSL) | Pending | Needs site-server deploy |

### Next steps

1. **cf:** Merge PR#5, deploy Docker stack, add CF tunnel route to `cf.2cld.net`. Deploy runbook: [wip/docs/ops-cf-status-deploy.md](https://github.com/2cld/wip/blob/main/docs/ops-cf-status-deploy.md)

2. **sl:** Deploy site-server container on slwin11ops WSL (or dedicated LXC). Configure `checks.yml` for F: drive, docker services, tunnel health. Expose via sl's Cloudflare tunnel at `sl.2cld.net/status.json`.

3. **Federation dashboard:** Live at [wip.2cld.net/docs/status/](https://wip.2cld.net/docs/status/) — fetches all site endpoints, renders unified view. Code in [wip/docs/status/index.html](https://github.com/2cld/wip/blob/main/docs/status/index.html).

4. **Coordinator migration:** Once all sites publish, remove SSH-based checks from `wip-daily-cron.sh`, `storage-status.js`, and `netstack-status.js`. The public endpoint becomes the single source of truth.

## Related Patterns

- [site-status-service-pattern](./site-status-service-pattern.md) — how to build the local checker
- [site-status-page-pattern](./site-status-page-pattern.md) — rendering status for humans
- [contract-driven-monitoring-pattern](./contract-driven-monitoring-pattern.md) — what to check per site contract
- [status-freshness-cron-pattern](./status-freshness-cron-pattern.md) — coordinator reads status + detects staleness
- [resilient-cron-pattern](./resilient-cron-pattern.md) — cron structure that doesn't fail on one check

## Validation (wf proof)

Before (SSH proxy, daily failures):
```
ghadmin@10.147.17.165: Permission denied (publickey,password,keyboard-interactive).
❌ site-server: Command failed: ssh -o BatchMode=yes ...
```

After (public endpoint, instant):
```
--- WF (Winfield) ---
  ✅ devwin10 (10.147.17.165) — online
  --- site-server (https://wf.klopfenstein.org/status.json) ---
    ✅ site-server: ok
    📊 status.json: error (10/12 ok) @ 2026-08-13T15:47:20
    ✅ Mikrotik router: 0.345ms
    ✅ cg2 (Proxmox + ZFS): 0.302ms
    ...
```

No SSH. No ZT dependency. No Permission denied. Sub-second response.
