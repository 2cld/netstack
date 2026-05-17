# Federation Node Topology Pattern

**Applies to:** All 2cld federation sites (cf, sl, wf)

## Overview

The 2cld federation is a set of geographically distributed nodes connected via encrypted overlay network (ZeroTier). Each node runs a standard set of services and replicates data to the others.

## Node Types

| Type | Purpose | Examples |
|------|---------|----------|
| **Compute** | VMs, containers, services | Proxmox hosts, Hyper-V hosts |
| **Storage** | File storage, backup targets | NAS devices, ZFS pools |
| **Gateway** | Routing, DNS, VPN | MikroTik, pfSense |
| **Dev/CAVE** | Frozen dev environment | Dedicated dev machines |

## Site Structure

Each federation site follows the same pattern:

```
site/
├── docs/           ← site-specific documentation
│   ├── devices.md  ← device inventory
│   ├── services.md ← running services
│   ├── network.md  ← network topology
│   └── log/        ← session logs (may be gitignored)
├── ops/            ← operational procedures
│   ├── backup/     ← backup scripts + state
│   ├── monitor/    ← health check scripts
│   └── sensitive/  ← credentials (gitignored)
├── .mkdocs/        ← site documentation build
└── README.md       ← site overview
```

## Cross-Site Connectivity

Nodes connect via encrypted overlay network:
- Each node has a stable overlay IP
- File shares are mapped between sites for backup replication
- Status scripts verify cross-site reachability

### Backup Triangle Pattern

```
     Site A
    /      \
   /        \
  v          v
Site B <---> Site C
```

Each site can push backups to both other sites. Each site can pull from both others. No single point of failure for backup data.

## Share Mapping Convention

| Field | Description |
|-------|-------------|
| Source | Machine providing the share |
| Target | Machine mounting the share |
| Drive letter / mount | How it appears on the target |
| Purpose | What data flows through this share |
| Transport | Overlay network (encrypted) |

## Monitoring Pattern

Each site maintains health check scripts in `ops/monitor/`:
- `check-services.sh` — verify local services running
- `check-connectivity.sh` — verify reachability of other sites
- `check-backup-state.sh` — verify backup freshness

Output follows the `.backup-state` format (see [sensitive-data-pattern](../security/sensitive-data-pattern.md)).

## Adding a New Node

1. Provision hardware/VM at the site
2. Install base OS (follow CAVE principles for stability)
3. Join overlay network
4. Clone site repo from template
5. Configure site-specific values in `ops/sensitive/` (gitignored)
6. Run monitoring scripts to verify connectivity
7. Set up backup replication to other sites
8. Document device in `docs/devices.md`
9. Add to federation inventory

## Related
- [Federation Backup Plan](../backup/federation-backup-plan.md) — cross-site backup strategy
- [CAVE Principles](../security/cave-principles.md) — environment stability
- [Storage Indexing](../storage-index/) — data inventory method
- [Sensitive Data Pattern](../security/sensitive-data-pattern.md) — protecting node configs
- [Session Logging](../tools/session-logging.md) — documenting work on nodes
