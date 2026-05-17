# Monitoring Pattern for Federation Nodes

**Applies to:** All 2cld federation sites (cf, sl, wf) and infrastructure services

## Overview

Each federation node maintains health check scripts that verify local services and cross-site connectivity. A coordination layer (status scripts) aggregates results across all nodes.

## Architecture

```
Per-node scripts (run locally on each site):
  ops/monitor/check-services.sh    ← are local services running?
  ops/monitor/check-connectivity.sh ← can I reach other nodes?
  ops/monitor/check-backup-state.sh ← are backups fresh?

Coordination layer (runs from any node with network access):
  status-script.js --compact        ← aggregates all nodes
```

## Per-Node Health Checks

### check-services.sh
Verifies local services are running:
```bash
#!/bin/bash
# Check local services
echo "=== $(hostname) SERVICE CHECK ==="

# Ping gateway
ping -c 1 -W 2 GATEWAY_IP > /dev/null 2>&1 && echo "✅ Gateway" || echo "❌ Gateway"

# Check key services (customize per site)
curl -s -o /dev/null -w "%{http_code}" http://localhost:PORT | grep -q 200 && echo "✅ Service" || echo "❌ Service"

# Check disk space
df -h / | awk 'NR==2 {if ($5+0 > 90) print "⚠️ Disk " $5; else print "✅ Disk " $5}'
```

### check-connectivity.sh
Verifies cross-site reachability via overlay network:
```bash
#!/bin/bash
# Check federation connectivity
echo "=== FEDERATION CONNECTIVITY ==="

# Other nodes (by overlay IP alias)
for node in site-a site-b site-c; do
  ping -c 1 -W 3 $node > /dev/null 2>&1 && echo "✅ $node" || echo "❌ $node"
done
```

### check-backup-state.sh
Reads the `.backup-state` file and reports freshness:
```bash
#!/bin/bash
# Check backup freshness
STATE_FILE="ops/backup/.backup-state"
if [ ! -f "$STATE_FILE" ]; then
  echo "❌ No backup state file"
  exit 1
fi

LAST_RUN=$(cat $STATE_FILE | python3 -c "import json,sys; print(json.load(sys.stdin).get('last_run','unknown'))")
STATUS=$(cat $STATE_FILE | python3 -c "import json,sys; print(json.load(sys.stdin).get('status','unknown'))")

echo "Last backup: $LAST_RUN | Status: $STATUS"
```

## Coordination Layer (Status Scripts)

A status script runs from a central location and checks all nodes remotely:

### Pattern: read → report → flag

```javascript
// status-script.js
// 1. READ: Check each site (HTTP, API, ping)
// 2. REPORT: Show what's up, what's down, what's stale
// 3. FLAG: Highlight anything that needs attention

// Output modes:
//   (default)  → full report with details
//   --compact  → one-liner for morning check-in integration
```

### Output Format

**Full mode:**
```
=== FEDERATION STATUS ===
--- SITES ---
  ✅ site-a (Location) — 200 293ms
  ✅ site-b (Location) — 200 210ms
  ❌ site-c (Location) — DOWN: timeout

--- REPOS ---
  ✅ repo-a: 5 days ago | 2 open issues
  ⚠️ repo-b: 45 days ago | stale

--- FLAGS ---
  ❌ Sites down: site-c
  ⚠️ Stale repos: repo-b
=== END ===
```

**Compact mode (for morning check-in):**
```
--- FEDERATION: 2/3 sites up | ⚠️ site-c down | ⚠️ repo-b stale ---
```

## Stale Detection

| Resource | Stale Threshold | Action |
|----------|:-:|--------|
| Site (HTTP check) | Unreachable | Flag immediately |
| Repo (last push) | 30+ days | Flag as stale |
| Backup state | 48+ hours | Flag as stale |
| Overlay node | 7+ days offline | Flag for investigation |

## Integration with Morning Check-in

The status script can be called from a daily check-in routine:
```javascript
// In morning check-in:
const output = execSync('node federation-status.js --compact');
console.log(output);
```

This surfaces federation health automatically without manual checking.

## Epic Status Scripts

For project coordination, each major work stream (Epic) can have its own status script:
- Checks relevant repos, sites, and services
- Runs in `--compact` mode for daily roll-up
- Runs standalone for deep-dive investigation
- Stubs announce "needs implementation" until built (squeaky wheel)

## Research Links
- [Grafana Alloy](https://grafana.com/docs/alloy/latest/) — log/metric collection
- [Grafana Loki](https://grafana.com/docs/loki/latest/) — log aggregation
- [Gatus](https://github.com/TwiN/gatus) — lightweight health dashboard
- [Jim's Garage Homelab Monitoring](https://www.youtube.com/watch?v=LShvy9l3tzs)

## Related
- [Federation Backup Plan](../backup/federation-backup-plan.md) — what to monitor for backup health
- [Federation Node Topology](../deployments/federation-node-topology.md) — what nodes exist
- [Sensitive Data Pattern](../security/sensitive-data-pattern.md) — .backup-state format
- [Session Logging](../tools/session-logging.md) — documenting monitoring changes
