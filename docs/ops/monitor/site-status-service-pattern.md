# Pattern: Site Status Service (Docker)

**Applies to:** Every federation site that wants automated, API-accessible health monitoring without requiring SSH from the coordinator.

**Working implementation:** [wf/ops/templates/services/site-server/](https://github.com/2cld/wf/tree/main/ops/templates/services/site-server)
**Live endpoint:** https://wf.klopfenstein.org/status.json
**Coordinator integration:** [wip/ops/scripts/netstack-status.js](https://github.com/2cld/wip/blob/main/ops/scripts/netstack-status.js)
**Federation dashboard:** [wip.2cld.net/docs/status/](https://wip.2cld.net/docs/status/) (reads all site endpoints)
**Related issue:** [wip#16](https://github.com/2cld/wip/issues/16) — reactive alerting

---

## Principle

> A site should report its own health. The coordinator (wip) reads the report via HTTPS — no SSH, no VPN dependency, no key management.

The site-status service runs locally on the site, checks local infrastructure, and publishes a JSON status document via the site's existing Cloudflare tunnel. The coordinator reads it with a single `curl`.

---

## Architecture

```
┌─── Site (e.g., wf) ────────────────────────────────────────┐
│                                                             │
│  checks.yml ──→ checker (Python, Docker)                    │
│                    │                                        │
│                    ├──→ /srv/output/status.json (API)        │
│                    └──→ /srv/output/health.json (self-check) │
│                                                             │
│               nginx (Docker, :8600)                         │
│                    │                                        │
│                    ▼                                        │
│           Cloudflare tunnel route                           │
│  (site.domain.org/status.json, site.domain.org/health)      │
│                                                             │
└─────────────────────────────────────────────────────────────┘
         │
         │  HTTPS (public internet)
         ▼
┌─── Coordinator (wip/nsdockerhv) ───────────────────────────┐
│                                                             │
│  curl -s https://site.domain.org/status.json                │
│    → parse JSON → compare with previous state → alert       │
│                                                             │
│  netstack-status.js --write-state --alert                   │
│    → .local/.monitor-state.json (state tracking)            │
│    → .local/.alerts (on critical transition)                │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Components

### 1. `checks.yml` — What to check

Declarative config listing all health checks for the site:

```yaml
site: wf
site_name: "Winfield"

checks:
  - name: "cg2 (Proxmox + ZFS)"
    type: ping
    target: "192.168.9.3"
    tier: operational
    goal: "Media distribution"

  - name: "Plex (wfMedia)"
    type: http
    url: "http://192.168.9.3:32400/identity"
    expect_status: 200
    tier: operational
    goal: "Media distribution"

  - name: "sg Synology (known DOWN)"
    type: ping
    target: "192.168.9.2"
    tier: cold
    known_down: true
    issue: "https://github.com/2cld/wf/issues/2"

  - name: "wf-cg boot disk"
    type: disk
    path: "/"
    alert_below_gb: 5
    tier: operational
    goal: "Compute health"
```

**Check types:**

| Type | What it does | Required fields |
|------|-------------|-----------------|
| `ping` | ICMP ping to target IP | `target` |
| `http` | HTTP GET, verify status code | `url`, `expect_status` |
| `command` | Run shell command, check output | `command`, `expect_contains` |
| `disk` | Check free space on path | `path`, `alert_below_gb` |

**Special fields:**
- `known_down: true` — suppresses alerts for intentionally-offline nodes
- `issue` — links to the tracking issue for the known-down state
- `tier` — `operational` (alert if down), `cold` (informational only)
- `goal` — maps to site goals per [site-status-page-pattern](./site-status-page-pattern.md)

### 2. `checker.py` — Status check loop

Python service that:
1. Loads `checks.yml`
2. Executes each check (ping, HTTP, command, disk)
3. Computes overall status (`ok` / `warning` / `degraded`)
4. Writes `status.json` atomically (tmp + rename)
5. Writes `health.json` (self-check)
6. Sleeps `CHECK_INTERVAL` seconds (default: 300 = 5 min)
7. Loops forever

**Environment variables:**

| Var | Default | Purpose |
|-----|---------|---------|
| `SITE_CODE` | `wf` | Site identifier in output |
| `CONFIG_FILE` | `/config/checks.yml` | Path to check definitions |
| `OUTPUT_DIR` | `/data` | Where to write results |
| `CHECK_INTERVAL` | `300` | Seconds between check runs |

### 3. Endpoints (nginx serves from output volume)

| Endpoint | Purpose | Update frequency |
|----------|---------|-----------------|
| `/status.json` | Machine-readable health checks | Every 5 min |
| `/health` or `/health.json` | Container self-check (is the service alive?) | Every 5 min |

### 4. `docker-compose.yml` — Deploy together

```yaml
services:
  checker:
    build: ./checker
    container_name: site-status-checker
    restart: unless-stopped
    network_mode: host
    volumes:
      - status_data:/data
      - ./checks.yml:/config/checks.yml:ro
    environment:
      - CHECK_INTERVAL=300
      - SITE_CODE=wf
      - OUTPUT_DIR=/data
      - CONFIG_FILE=/config/checks.yml

  web:
    image: nginx:alpine
    container_name: site-status-web
    restart: unless-stopped
    ports:
      - "8600:80"
    volumes:
      - status_data:/usr/share/nginx/html:ro
      - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro

volumes:
  status_data:
```

---

## Output Format (`status.json`)

```json
{
  "site": "wf",
  "site_name": "Winfield",
  "timestamp": "2026-08-06T22:37:42.131000+00:00",
  "status": "ok",
  "check_interval_seconds": 300,
  "checks": [
    {
      "name": "cg2 (Proxmox + ZFS)",
      "type": "ping",
      "status": "ok",
      "message": "0.301ms",
      "tier": "operational",
      "goal": "Media distribution"
    }
  ],
  "check_count": 6,
  "ok_count": 4,
  "error_count": 0,
  "warning_count": 0,
  "known_down_count": 2
}
```

**Status values:**

| Value | Meaning | Coordinator action |
|-------|---------|-------------------|
| `ok` | All operational checks passing | None |
| `warning` | Non-critical degradation | Log, surface in review |
| `degraded` | Operational check failing | Alert (per escalation levels) |
| `error` | Checker itself failed | Alert — checker container down |
| `known_down` | Intentionally offline | Ignore |

---

## Coordinator Integration

### Direct API read (preferred — no SSH)

```bash
STATUS_JSON=$(curl -s --max-time 10 https://site.domain.org/status.json)
OVERALL=$(echo "$STATUS_JSON" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['status'])")
```

### Freshness check

Compare `timestamp` to now. If > 10 minutes old (`CHECK_INTERVAL` × 2), the checker may be down:

```python
from datetime import datetime, timezone
age_min = (datetime.now(timezone.utc) - dt).total_seconds() / 60
stale = age_min > 10
```

### Reactive alerting (wip#16)

The coordinator (`netstack-status.js`) runs every 30 min and:
1. Reads each site's status API
2. Compares current state to previous (`.local/.monitor-state.json`)
3. On critical transition → writes to `.local/.alerts`
4. On recovery → clears the alert
5. Morning cron surfaces unresolved alerts

### Advantages over SSH-based monitoring

- No SSH keys to manage per site
- No VPN/ZeroTier dependency for monitoring reads
- Works even if the workstation node is powered off (checker runs on always-on compute)
- Faster (HTTPS vs SSH connection setup + PowerShell invoke)
- Same Cloudflare tunnel already serving the site docs
- Decoupled: site reports own health, coordinator just reads

---

## Deployment Steps (new site)

1. Copy template from `wf/ops/templates/services/site-status/`
2. Edit `checks.yml` for site infrastructure (nodes, services, disks)
3. Build + start: `docker compose up -d --build`
4. Add Cloudflare tunnel route: `site.domain.org → http://localhost:8600`
5. Add URL to coordinator (wip `wip-daily-cron.sh` federation section)
6. Verify: `curl -s https://site.domain.org/status.json | python3 -m json.tool`

---

## Federation Dashboard

A static HTML/JS page at [wip.2cld.net/docs/status/](https://wip.2cld.net/docs/status/) consumes the status.json endpoints from all sites and renders a unified view:

- Per-site status cards with individual check results
- Staleness detection (> 10 min = stale warning)
- Auto-refresh every 60 seconds
- Mobile-friendly responsive layout
- No server-side code — pure client-side fetch from public endpoints
- CORS headers on nginx (`Access-Control-Allow-Origin: *`) enable browser fetch

Source: [wip/docs/status/index.html](https://github.com/2cld/wip/blob/main/docs/status/index.html)
Issue: [netstack#16](https://github.com/2cld/netstack/issues/16)

---

## Implementations

| Site | Status | Endpoint | Repo | Deploy Runbook |
|------|--------|----------|------|----------------|
| wf | ✅ Live | https://wf.klopfenstein.org/status.json | [2cld/wf](https://github.com/2cld/wf/tree/main/ops/templates/services/site-status) | — |
| cf | 🔄 PR#5 | https://cf.2cld.net/status.json (pending) | [2cld/cf PR#5](https://github.com/2cld/cf/pull/5) | [ops-cf-status-deploy.md](https://github.com/2cld/wip/blob/main/docs/ops-cf-status-deploy.md) |
| sl | Planned | https://sl.2cld.net/status.json | [2cld/sl](https://github.com/2cld/sl) | TBD |

---

## Related Patterns

- [public-status-endpoint-pattern](./public-status-endpoint-pattern.md) — why public > SSH for monitoring
- [site-status-page-pattern](./site-status-page-pattern.md) — rendered markdown status format (human-readable)
- [status-freshness-cron-pattern](./status-freshness-cron-pattern.md) — check → compare → write → alert loop
- [contract-driven-monitoring-pattern](./contract-driven-monitoring-pattern.md) — what to monitor per contract scope
- [cross-platform-monitoring-pattern](./cross-platform-monitoring-pattern.md) — Linux/Windows/Proxmox check methods
- [resilient-cron-pattern](./resilient-cron-pattern.md) — cron job reliability patterns
