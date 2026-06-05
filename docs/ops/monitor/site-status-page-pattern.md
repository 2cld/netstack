# Site Status Page Pattern

**Applies to:** Every federation site (cf, sl, wf). Provides a quick-scan goal-based status visible from the site's docs.

## Principle

The status page answers: **"Are this site's goals being met right now?"** Not a list of every service - just goal outcomes, green or red.

## Where It Lives

```
<site>/docs/status.md        <- the rendered status page (site.2cld.net/docs/status/)
<site>/site-config.yml       <- source of truth (goals, monitoring config, enabled state)
<site>/ops/scripts/*-status.sh <- the check script that produces the data
```

## Status Page Format

```markdown
# XX Status

**Site:** xx.2cld.net | **Updated:** YYYY-MM-DD HH:MM

## Goals

| Goal | Check | Status | Last Verified |
|------|-------|--------|--------------|
| Goal 1 description | What's checked | OK/Alert/Down | timestamp |
| Goal 2 description | What's checked | OK/Alert/Down | timestamp |

## Nodes

| Node | IP | Enabled | Status |
|------|-----|---------|--------|
| node1 | x.x.x.x | true | UP |
| node2 | x.x.x.x | false | DOWN (known, function served by node1) |

## Services

| Service | Host | Port | Status |
|---------|------|------|--------|
| service1 | node1 | 8080 | UP |

## Alerts
- RED ALERT: <anything requiring immediate action>
- Warning: <degraded but functional>

## Links
- [site-config.yml](../site-config.yml) - source of truth
- [monitoring script](../ops/scripts/xx-status.sh)
- [.wip-contract.md](../.wip-contract.md) - monitoring scope
- [netstack status pattern](https://netstack.org/docs/ops/monitor/site-status-page-pattern/)
```

## Generation

**Manual (current):** Admin or Wip updates `docs/status.md` from monitoring output.

**Auto (future):** A generator script reads `site-config.yml` + status script output and produces `docs/status.md`. This is the ns-site-template generator target.

## site-config.yml Status Section

```yaml
status:
  page: "docs/status.md"
  generated_from: "site-config.yml + ops/scripts/xx-status.sh"
  goals:
    - name: "Goal description"
      check: "What monitoring verifies"
      enabled: true
```

The `enabled` field on devices/services controls whether they appear in status checks:
- `enabled: true` = monitor, alert if down
- `enabled: false` = known state, skip (function served elsewhere)

## Integration

- **wip README** shows federation rollup (one line per site: OK/Alert)
- **site docs/status.md** shows site detail (one line per goal)
- **morning-update.js** reads site status to update wip README federation table
- **wip-daily-cron.sh** runs the site status scripts

## Related

- [cross-platform-monitoring-pattern](./cross-platform-monitoring-pattern.md) - how checks run
- [service-lifecycle-pattern](../tools/service-lifecycle-pattern.md) - when to add/remove from status
- [pattern-workflow](../pattern-workflow.md) - netstack drives all ops
