# Compute Roles Pattern

**Purpose:** Define standard compute-role taxonomy for federation sites.
**Exemplar:** [wf compute architecture](https://github.com/2cld/wf/blob/main/ops/compute/wf-compute-architecture.md)
**Related:** [netstack#17](https://github.com/2cld/netstack/issues/17) (BMR), [netstack#18](https://github.com/2cld/netstack/issues/18)

---

## The Problem

Federation sites tend to collapse all workloads onto one machine: always-on infrastructure, cold storage, and ad-hoc workbench tasks all share hardware. This creates conflicts:

- A tunnel server forces a 200W storage box to run 24/7
- Sort/triage work risks the archival pool
- Power profiles (always-on vs. cold vs. ad-hoc) fight each other

## The Pattern: Role-Based Compute Assignment

Every site assigns hardware to one of four standard roles based on power profile and uptime requirements:

| Role | Power Profile | Uptime | BMR Target? | Purpose |
|------|--------------|--------|:-----------:|---------|
| **infra** | Always-on, low power (5-15W) | 24/7 | YES | Tunnels, monitoring, WoL triggers, coordination |
| **glacial** | Mostly OFF, WoL-scheduled | Scheduled windows | No | Cold storage, backup receive, archival media |
| **recovery** | Manual, powered during active recovery | As-needed | No | Data recovery from old/damaged media |
| **sort** | Manual, powered when physically present | As-needed | No | Drive triage, indexing, data migration workbench |

Not every site needs all four roles. A minimal site (like sl) might only have **infra** (WSL Docker on the one machine). A site with heavy storage (like wf) uses all four.

## Role Definitions

### infra (always-on gateway)

**What it does:**
- Runs Cloudflare tunnel (remote visibility)
- Runs Traefik (reverse proxy for local services)
- Runs monitoring (site-status.sh, produces site-status.json)
- Sends WoL packets to wake glacial/recovery units on schedule
- Hosts coordination services (Portainer, optional web dashboard)

**Hardware requirements:**
- Low power draw (target: under 15W idle)
- SSD only (no spinning drives)
- Network connectivity (wired ethernet + ZeroTier)
- Reliable (this is the DR-critical piece - if infra dies, remote visibility goes dark)

**Candidate platforms:**
- Raspberry Pi 5 (8GB) - 5W, ARM64, proven Docker support
- Mini-PC (Intel N100 class) - 10W, x86_64, full compat
- MikroTik (container-capable models: hAP ax3, RB5009) - RouterOS 7.4+, requires ARM64/x86 + 1GB+ RAM
- Proxmox LXC on existing hardware - 0W extra (but forces host to stay on)
- Old laptop with SSD - 15W, built-in UPS (battery)

**MikroTik note:** Only higher-end models support containers. Requirements: RouterOS v7.4+, ARM64 or x86 CPU, 1GB+ RAM. Models like RB951G (128MB RAM) CANNOT run containers - they remain network gateway (ng) role only.

**BMR:** This is the primary BMR target. `bootstrap.sh` from netstack#17 rebuilds this role from `site-config.yml`.

### glacial (cold storage)

**What it does:**
- Holds large storage pools (ZFS, btrfs, or raw partitions)
- Accepts backup writes on schedule (rsync from other sites)
- Runs health checks (pool scrub, SMART) when awake
- Shuts down after completing scheduled work

**Hardware requirements:**
- Multiple drive bays (4+ SATA for meaningful ZFS pools)
- WoL-capable NIC (wakes on schedule from infra)
- Does NOT need to be low-power (it's mostly off)
- Reliable storage controller

**Candidate platforms:**
- 1U rackmount servers (SR1580SFHS, Dell R610, etc.) - good drive density
- Tower servers with multiple bays
- NAS appliances (Synology, TrueNAS) if available

**Multi-unit pattern:** Sites with multiple clients or isolation requirements can run multiple glacial units - one per client. Each unit has independent WoL schedule, independent failure domain.

**Operational pattern:**
```
infra sends WoL -> glacial boots -> mounts pool -> backup job runs
-> health check -> reports status -> shuts down -> infra logs result
```

### recovery (temporary data extraction)

**What it does:**
- Mounts drives from decommissioned/damaged hardware (NAS, old servers)
- Runs indexing scripts to discover what's on the drives
- Stages recovered data for triage (what to keep vs. discard)
- Temporary role - once recovery is complete, hardware gets repurposed

**Hardware requirements:**
- Compatible drive interface (SATA backplane, SAS card, or USB)
- Enough RAM/CPU to run indexing scripts
- LAN connectivity (to transfer recovered data to glacial units)
- Does NOT need ZeroTier, tunnels, or remote access

**Lifecycle:** Recovery is a temporary role. Once data is extracted and migrated to glacial storage, the hardware either becomes another glacial unit or gets decommissioned.

### sort (workbench)

**What it does:**
- Connects bulk drives (USB shelves, SAS arrays) for indexing and triage
- Runs index-device scripts, generates manifests
- Stages data on local storage during sort operations
- Physically present work - requires hands on hardware

**Hardware requirements:**
- Many I/O ports (SAS card, USB 3.0 ports, multiple SATA)
- Large local staging area (SSD or fast HDD for temporary data)
- Physical access (not remote-operated)
- Does NOT need network services, tunnels, or WoL

**What happens to sorted data:**
- Irreplaceable (home video, personal docs) -> glacial units
- Reproducible but costly (DVD rips, CD rips) -> glacial units (lower priority)
- Reproducible and easy (DVR recordings) -> delete
- Disposable (temp files, caches) -> wipe drive

## site-config.yml Integration

Sites declare compute roles in their `site-config.yml`:

```yaml
compute:
  roles:
    infra:
      host: rpi5
      platform: docker
      always_on: true
      bmr_target: true
    glacial:
      - host: 1u-srv-01
        platform: linux
        wol_mac: "AA:BB:CC:DD:EE:01"
        schedule: "0 2 * * 0"
        client: "federation"
    recovery:
      host: 1u-srv-sg
      purpose: "Synology sg drive extraction"
      temporary: true
    sort:
      host: cg2
      purpose: "USB shelf + SAS drive triage"
```

## Mapping Your Site

To apply this pattern:

1. **Inventory your hardware** - what machines exist at the site?
2. **Identify the power profiles** - what MUST be always-on? What can sleep?
3. **Assign roles** - match hardware to roles based on power profile + capabilities
4. **Document in site-config.yml** - add `compute.roles` section
5. **Plan migration** - if everything is on one box today, plan phased separation

## Examples

| Site | infra | glacial | recovery | sort |
|------|-------|---------|----------|------|
| wf | LXC 100 (Phase 1) -> RPi 5 (Phase 2) | 1U fleet (per-client) | 1U with sg drives | cg2 (SAS card) |
| sl | slwin11ops (WSL Docker) | slwin11ops (same machine, backup-receive only) | -- | -- |
| cf | nsdockerhv (Docker VM on CyberTruck) | CyberTruck local storage | -- | -- |

## Related Patterns

- [BMR Pattern](./bmr-pattern.md) - how to rebuild the infra role from scratch
- [Federation Node Topology](./federation-node-topology.md) - standard node structure
- [Federation User Model](./federation-user-model-pattern.md) - user roles per node
- [site-config-physical-schema.md](./site-config-physical-schema.md) - physical inventory format
