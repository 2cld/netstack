[edit](https://github.com/2cld/netstack/edit/master/docs/ops/monitor/ng-sg-cg-monitoring-pattern.md)

# Pattern: ng/sg/cg Monitoring — Unified Site Status from Config

**Category:** `docs/ops/monitor/`  
**Purpose:** Define a standard monitoring approach for federation sites based on the ng (network), sg (storage), cg (compute) model. Each site produces a `site-status.json` driven by its `site-config.yml`.  
**Audience:** All federation sites (cf, sl, wf)  
**Tracking:** [netstack#11](https://github.com/2cld/netstack/issues/11)

---

## Architecture

```
site-config.yml (source of truth)
       │
       │ defines: services, checks, thresholds, goals
       ▼
site-status.sh (runs locally on site node)
       │
       │ checks: ng (network), sg (storage), cg (compute)
       ▼
site-status.json (runtime output, gitignored)
       │
       │ read via SSH by coordination layer
       ▼
wip-daily-cron.sh (morning report)
       │
       │ parses JSON, reports per-site health
       ▼
README.md Federation Status table (auto-updated by wip up --apply)
```

---

## The Three Gateways

Every federation site has three monitoring layers:

| Layer | What | Checks |
|-------|------|--------|
| **ng** (Network Gateway) | Internet, VPN, DNS, tunnel | ping gateway, ZeroTier online, Cloudflare tunnel healthy |
| **sg** (Storage Gateway) | Drives, backup state, free space | drive free %, .backup-state freshness, NAS reachable |
| **cg** (Compute Gateway) | Services, containers, resources | Docker containers running, HTTP checks, process counts |

---

## site-status.json Output Format

```json
{
  "site": "sl",
  "timestamp": "2026-06-27T06:00:00Z",
  "status": "ok",
  "checks": [
    { "name": "internet", "layer": "ng", "status": "ok", "value": "12ms" },
    { "name": "zerotier", "layer": "ng", "status": "ok", "value": "online" },
    { "name": "tunnel-sl-2cld", "layer": "ng", "status": "ok", "value": "healthy" },
    { "name": "drive-F", "layer": "sg", "status": "ok", "value": "886 GB free (48%)" },
    { "name": "backup-state", "layer": "sg", "status": "ok", "value": "< 24h" },
    { "name": "docker-traefik", "layer": "cg", "status": "ok", "value": "Up 2d" },
    { "name": "docker-plex", "layer": "cg", "status": "ok", "value": "Up 2d" },
    { "name": "docker-gitea", "layer": "cg", "status": "ok", "value": "Up 2d" },
    { "name": "docker-cloudflared", "layer": "cg", "status": "ok", "value": "Up 2d" }
  ]
}
```

Overall `status` is derived: if any check is `critical` → site status is `critical`. If any is `warning` → `warning`. Otherwise `ok`.

---

## site-config.yml Drives Monitoring

The `cg.services` section in site-config.yml defines what to check:

```yaml
cg:
  services:
    - name: traefik
      critical: true
      layer: docker
      check: "docker ps --filter name=traefik --format '{{.Status}}'"
    - name: plex
      critical: true
      layer: docker
      check: "docker ps --filter name=plex --format '{{.Status}}'"
    - name: sshd
      critical: true
      layer: host
      check: "ssh -o ConnectTimeout=5 ghadmin@10.147.17.94"

sg:
  drives:
    - letter: "F:"
      size_gb: 1863
      alert_below_pct: 10
  backup:
    verified_by: "wip reads .backup-state sl=OK"

ng:
  vpn:
    zerotier:
      ip: "10.147.17.94"
  tunnel: "sl-2cld (Cloudflare)"
```

A future `site-ops monitor` command reads this config and generates the `site-status.sh` script automatically.

---

## How Wip Reads Site Status

From `wip-daily-cron.sh`:

```bash
# sl (via SSH to WSL on port 2020)
SL_JSON=$(ssh -o ConnectTimeout=10 -o BatchMode=yes -p 2020 ghadmin@10.147.17.94 \
  "cat ~/ops/site-status.json" 2>/dev/null)

if [ -n "$SL_JSON" ]; then
  SL_STATUS=$(echo "$SL_JSON" | python3 -c "
    import json,sys
    d=json.load(sys.stdin)
    ok=sum(1 for c in d['checks'] if c['status']=='ok')
    print(f\"{d['status']} ({ok}/{len(d['checks'])} passing)\")
  ")
  echo "  sl: ${SL_STATUS}"
fi
```

This produces the per-site line in the daily report:
```
  cf: ok (6/6 checks passing)
  sl: ok (5/5 passing)
  wf: no status file (deploy site-status.sh)
```

---

## Coordination Layer Integration

`netstack-status.js` provides the federation-wide view:
- **ZeroTier API** → node online/offline per site
- **Cloudflare API** → tunnel health per site
- **SSH to site** → site-status.json (ng/sg/cg details)

`wip up --apply` writes the Federation Status table to README.md:
```
| Site | Nodes | Tunnels | Backup | Last Check |
|------|-------|---------|--------|------------|
| cf | 4/4 UP | ✅ healthy | ✅ OK | 2026-06-27 |
| sl | 1/1 UP | ✅ healthy | ✅ receiving | 2026-06-27 |
| wf | 0/1 DOWN | — | ❌ offline | 2026-06-27 |
```

---

## Monitoring Sources (per API)

| Source | What it checks | Token/Access |
|--------|---------------|-------------|
| ZeroTier API | Node membership, online status | `ZEROTIER_API_TOKEN` |
| Cloudflare API | Tunnel health, connections | `CLOUDFLARE_API_TOKEN` |
| SSH to site | site-status.json, drive space, service checks | SSH key (port 22 or 2020) |
| GitHub/Gitea API | Repo activity, milestones, issue staleness | `GITHUB_HOWIP_API` / `GITEA_CAT9_WIP_API` |

---

## Implementation Status

| Site | site-status.sh | site-status.json | Wip reads it | Config-driven |
|------|:-:|:-:|:-:|:-:|
| cf | ✅ (cf-status.sh) | ✅ | ✅ | Manual |
| sl | ✅ (sl-status.sh) | ✅ | ✅ (SSH port 2020) | Manual |
| wf | ✅ (wf-status.sh) | ❌ (devwin10 DOWN) | ❌ | Manual |

**Current state:** All status scripts are hand-written per site. The config schema exists (sl-site-config.yml) but generation is not yet automated.

**Next step:** `site-ops monitor <config>` generates site-status.sh from the config's service definitions.

---

## Evolution

| Stage | What | Status |
|:-----:|------|:------:|
| 1 | Hand-written site-status.sh per site | ✅ DONE (cf, sl, wf) |
| 2 | site-config.yml schema with services + checks | ✅ DONE (sl) |
| 3 | Wip reads site-status.json via SSH in daily cron | ✅ DONE |
| 4 | netstack-status.js checks ZeroTier + Cloudflare APIs | ✅ DONE |
| 5 | Federation Status table auto-updated in README | ✅ DONE |
| 6 | `site-ops monitor` generates site-status.sh from config | NEXT |
| 7 | All sites have config-driven monitoring | FUTURE |

---

## Related

- [monitoring-pattern](./monitoring-pattern.md) — per-node health checks
- [wsl-monitoring-node-pattern](./wsl-monitoring-node-pattern.md) — WSL as Unix monitor on Windows
- [cross-platform-monitoring-pattern](./cross-platform-monitoring-pattern.md) — Windows + Linux approaches
- [status-freshness-cron-pattern](./status-freshness-cron-pattern.md) — staleness detection
- [site-status-page-pattern](./site-status-page-pattern.md) — public status pages
- [site-tenant-contract-pattern](../deployments/site-tenant-contract-pattern.md) — monitoring scope per contract
- [netstack#11](https://github.com/2cld/netstack/issues/11) — tracking issue
- sl-site-config.yml (wip draft) — reference implementation of config schema
