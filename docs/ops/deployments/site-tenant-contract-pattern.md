# Pattern: Site-Tenant Contract (Federation Boundary Definition)

**Category:** `docs/ops/deployments/`  
**Purpose:** Define the boundary between a federation site (infrastructure provider) and its tenants (service operators), with AI-parseable contracts that determine monitoring scope and escalation paths.  
**Audience:** Any federated infrastructure where sites host tenant equipment, and a coordination layer (Wip or similar) needs to know what it's responsible for.

---

## The Problem

When infrastructure is federated across multiple physical sites, two roles emerge:
- **Site admin:** Responsible for power, place, bandwidth, LAN — the physical layer
- **Tenant:** Responsible for equipment, services, data, overlay network — the application layer

Without a formal boundary:
- The coordination layer alerts on everything (noise)
- Nobody knows who to escalate to ("is this MY problem or the site's?")
- A fresh AI context can't determine scope (monitors too much or too little)
- Multi-tenant sites become confusion factories

## The Solution: Site-Tenant Contract

A structured document that lives on the site repo. It defines:
1. What the site provides
2. What the tenant manages
3. Who monitors what
4. How to communicate between layers

---

## Contract Format

The contract uses YAML frontmatter (machine-parseable) + markdown body (human-readable). It lives at:

```
<site-repo>/.site-contract-<tenant>.yml
```

Example: `2cld/cf/.site-contract-cat9.yml`

### Schema

```yaml
# Site-Tenant Contract
# Pattern: https://netstack.org/docs/ops/deployments/site-tenant-contract-pattern/

contract:
  version: "1.0"
  site: cf
  site_admin: ghadmin@horseoff.com
  site_repo: "2cld/cf"
  tenant: cat9
  tenant_coordinator: wip@horseoff.com
  tenant_admin: nsadmin@horseoff.com
  effective_date: "2026-06-17"

# What the site provides (site admin's responsibility)
site_provides:
  power:
    description: "UPS-backed single circuit, residential"
    sla: "99% uptime (allows for outages, storms)"
    escalation: "power outage lasting > 5 min"
  place:
    description: "Indoor rack shelf, climate controlled (HVAC)"
    sla: "physical security, temperature 60-80°F"
    escalation: "unauthorized access, temperature alarm"
  bandwidth:
    description: "Residential ISP (Mediacom cable), shared"
    sla: "best effort, no guaranteed bandwidth"
    escalation: "total outage > 1 hour"
  lan:
    subnet: "192.168.6.0/24"
    gateway: "192.168.6.1"
    dhcp: true
    dns: "192.168.6.1"
    escalation: "LAN switch down, no local connectivity"

# What the tenant manages (tenant/coordinator's responsibility)
tenant_manages:
  equipment:
    - name: CyberTruck
      type: hypervisor
      ip: 192.168.6.30
      zt_ip: 10.147.17.219
    - name: nsdockerhv
      type: vm
      ip: 192.168.6.106
      zt_ip: 10.147.17.176
      role: "Docker services, Wip automation, dev"
    - name: cat9fin
      type: vm
      ip: 192.168.6.218
      zt_ip: 10.147.17.218
      role: "Accounting, hwpc-rp production"
  services:
    - name: gitea
      host: nsdockerhv
      port: 3000
      public_url: "https://gitea.cat9.me"
    - name: traefik
      host: nsdockerhv
      port: 443
      role: "reverse proxy, TLS termination"
    - name: nspwa
      host: nsdockerhv
      port: 3000
      public_url: "https://nspwa.cat9.me"
    - name: hwpc-rp
      host: cat9fin
      port: 5005
      access: "ZeroTier only (internal)"
    - name: backup-daily
      host: nsdockerhv
      schedule: "0 2 * * *"
      role: "Docker backup → sl off-site"
  overlay:
    network: "ZeroTier"
    network_id: "d5e5fb65371eb4a4"
    subnet: "10.147.17.0/24"
  data:
    owner: tenant
    backup_responsibility: tenant
    note: "All data on tenant equipment. Site has no access to tenant data."

# Monitoring scope — WHO checks WHAT
monitoring:
  tenant_monitors:
    - "Service health (HTTP checks, container status)"
    - "Backup freshness (.backup-state < 48h)"
    - "Overlay connectivity (ZeroTier peers reachable)"
    - "Certificate validity (TLS certs on public services)"
    - "Storage capacity on tenant equipment"
  site_monitors:
    - "Power status (UPS state)"
    - "ISP connectivity (WAN up/down)"
    - "LAN switch health"
    - "Physical environment (temperature, access)"
  not_monitored:
    - "cfDVR (decommissioned, not tenant equipment)"
    - "Plex on CyberTruck (personal media, not critical service)"

# Escalation paths
escalation:
  tenant_to_site:
    triggers:
      - "Cannot reach LAN gateway from tenant equipment"
      - "Power loss detected (UPS alarm or equipment offline without explanation)"
      - "ISP outage (no WAN from any tenant equipment)"
    channel: "email ghadmin@horseoff.com OR issue on 2cld/cf"
    response_sla: "acknowledge within 24h, resolve best-effort"
  site_to_tenant:
    triggers:
      - "Tenant equipment drawing excessive power"
      - "Tenant equipment noise/heat complaint"
      - "Physical maintenance requiring tenant downtime"
    channel: "email wip@horseoff.com OR issue on 2cld/cf"
    response_sla: "acknowledge within 24h"

# Communication
communication:
  issue_tracker: "2cld/cf"
  email_site: "ghadmin@horseoff.com"
  email_tenant: "wip@horseoff.com"
  format: "Per repo-communication-pattern: [MONITOR] prefix for automated, plain for human"
```

---

## How a Coordination Layer Uses This Contract

### During monitoring setup:
1. Read the contract YAML
2. Build monitoring checks ONLY for items in `tenant_manages.services` and `tenant_manages.equipment`
3. Ignore anything in `not_monitored`
4. For items NOT in tenant scope that appear unhealthy → escalate to site, don't alert tenant

### During a check failure:
```
Service down?
  ├── Is it in tenant_manages.services? → ALERT TENANT (your problem)
  ├── Is it in site_provides? → ESCALATE TO SITE (their problem)
  └── Is it in not_monitored? → IGNORE (known, accepted)
```

### During morning check-in:
```
For each check result:
  if check.target in contract.tenant_manages → show in report
  if check.target in contract.not_monitored → suppress
  if check.target seems like site issue → show as "escalate to site admin"
```

---

## Example: Applying to Current False Alerts

Using the cf-cat9 contract above, today's cron report items would be classified:

| Alert | Contract says | Correct action |
|-------|-------------|----------------|
| ✅ All federation nodes UP | tenant_manages.equipment | Report (correct) |
| ✅ Backup fresh | tenant_manages.services (backup-daily) | Report (correct) |
| ⚠️ ZeroTier "last: 0m ago" | tenant_manages.overlay — but ZT API reports "offline" for online nodes | Fix script (ZT API quirk), not a real alert |
| ❌ cfDVR offline 66d | not_monitored | **Suppress** — decommissioned |
| ⚠️ nscallbot 142d stale | tenant_manages? No — it's DEFERRED | **Suppress** — known deferred |
| sg DOWN from devwin10 | Is sg tenant equipment? If no → not_monitored | Clarify and suppress or monitor |
| wfMedia DOWN | Is wfMedia a tenant service? Personal media | **not_monitored** (or site responsibility at wf) |

**Result:** Applying the contract eliminates 4 of the current "false" alerts.

---

## Multi-Site Application

Each site-tenant pair gets its own contract:

| Site | Tenant | Contract Location | Site Admin |
|------|--------|-------------------|------------|
| cf | cat9 | `2cld/cf/.site-contract-cat9.yml` | ghadmin@horseoff.com |
| sl | cat9 | `2cld/sl/.site-contract-cat9.yml` | ghadmin@horseoff.com |
| wf | cat9 | `2cld/wf/.site-contract-cat9.yml` | ghadmin@horseoff.com |

Each contract specifies what cat9 equipment/services are at that site, what the site provides, and how to communicate. A tenant spanning all three sites has three contracts, one per site.

---

## Contract Lifecycle

| Event | Action |
|-------|--------|
| New equipment added to site | Update `tenant_manages.equipment` |
| New service deployed | Update `tenant_manages.services` |
| Service decommissioned | Move to `not_monitored` with note |
| Site upgrades (better ISP, UPS) | Update `site_provides` |
| Tenant leaves site | Archive contract, remove monitoring |
| New tenant arrives | Create new contract from template |

---

## Implementation for Wip

To use contracts in monitoring scripts:

```javascript
// Load site contract
const yaml = require('yaml');
const contract = yaml.parse(fs.readFileSync('.site-contract-cat9.yml'));

// Check if a service is in scope
function isInScope(serviceName) {
  return contract.tenant_manages.services.some(s => s.name === serviceName);
}

// Check if something should be suppressed
function isSuppressed(target) {
  return (contract.monitoring.not_monitored || []).some(item => 
    item.toLowerCase().includes(target.toLowerCase())
  );
}

// Determine escalation path
function getEscalation(issue) {
  if (isInScope(issue.target)) return { to: 'tenant', channel: contract.communication.email_tenant };
  return { to: 'site', channel: contract.communication.email_site };
}
```

---

## Related

- [pattern-workflow.md](../pattern-workflow.md) — netstack = WHY/HOW, site repos = WHAT
- [repo-communication-pattern](../monitor/repo-communication-pattern.md) — issue creation from monitoring
- [request-lifecycle](../monitor/request-lifecycle.md) — escalation + acknowledgment
- [monitoring-pattern](../monitor/monitoring-pattern.md) — what and how to check
- [status-freshness-cron-pattern](../monitor/status-freshness-cron-pattern.md) — automated state tracking
- [netstack#5](https://github.com/2cld/netstack/issues/5) — personal wip repo (separation of concerns)
- [Wip ops-red-alerts.md](https://github.com/2cld/wip/blob/main/docs/ops-red-alerts.md) — existing admin mapping (precursor)
