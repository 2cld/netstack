# site-config.yml Schema

**Purpose:** Document the canonical keys that site-config.yml files use across the federation.
**Consumers:** ns-site-template scripts (generate-site.sh, generate-docs.sh, collect-site.sh), BMR scripts (bootstrap.sh, deploy.sh, restore.sh, verify.sh)
**Related:** [site-config-physical-schema.md](./site-config-physical-schema.md) (physical inventory extension), [netstack#18](https://github.com/2cld/netstack/issues/18)

---

## Overview

`site-config.yml` is the machine-readable source of truth for each federation site. Every site repo (cf, sl, wf) has one at the repo root. Scripts read it to generate docs, deploy services, monitor health, and rebuild from scratch.

## Schema Sections

### site (required)

Identifies the site. Used by all scripts.

```yaml
site:
  code: wf                              # Short identifier (used in scripts, hostnames, paths)
  name: "Winfield"                      # Human-readable name
  repo: "https://github.com/2cld/wf"   # Canonical repo URL
  created: 2024-01-01                   # When site was first documented
  timezone: "America/Chicago"           # System timezone for cron/logs
  location: "Physical address"          # Physical address
  owner: "TreesAES LLC"                 # Legal owner of hardware/location
  email: "treesaes@gmail.com"           # Owner contact
  admin: "christrees@gmail.com"         # Technical admin contact
```

| Key | Required | Used by |
|-----|:--------:|--------|
| code | YES | All scripts, hostname generation |
| name | YES | Docs generation |
| repo | YES | bootstrap.sh (clone source) |
| timezone | YES | bootstrap.sh (timedatectl) |
| location | no | Docs, physical inventory |
| owner | no | Contract/legal reference |
| email | no | .wip-contract.md generation |
| admin | no | Escalation contact |

### network (required)

LAN configuration. Used by bootstrap.sh, generate-docs.sh.

```yaml
network:
  subnet: 192.168.9.0/24
  gateway: 192.168.9.1
  dns_primary: 1.1.1.1
  dns_secondary: 8.8.8.8
  isp: "Starlink"
  dhcp:
    enabled: true
    range_start: 192.168.9.100
    range_end: 192.168.9.199
    server: 192.168.9.1
  netstack_assignments:    # Named roles (ng, sg, cg, etc.)
    ng:
      ipv4: 192.168.9.1
      hostname: mikrotik
      model: "MikroTik RB951G-2HnD"
      mac: "00:0C:42:B7:CA:E9"
      enabled: true
```

### devices (required)

All network-attached hardware. Used by generate-docs.sh, collect-site.sh.

```yaml
devices:
  - hostname: mikrotik
    type: router          # router, server, workstation, nas, isp, switch
    role: ng              # netstack role assignment
    ipv4: 192.168.9.1
    mac: "00:0C:42:B7:CA:E9"
    model: "MikroTik RB951G-2HnD"
    location: wf-ops-rm1  # Physical location tag
    services:
      - name: "DHCP"
        port: 67
      - name: "Admin"
        port: 80
        url: "http://192.168.9.1"
    notes: "RouterOS 7.5"
```

### compute (optional -- extends base for BMR)

Virtualization and compute roles. Used by bootstrap.sh, deploy.sh.

```yaml
compute:
  host: cg2                # Primary compute host
  platform: proxmox        # proxmox, docker, wsl, bare-metal
  access: "https://192.168.9.3:8006"

  # Compute role assignments (per compute-roles-pattern.md)
  roles:
    infra:
      host: lxc-100
      platform: docker
      always_on: true
      bmr_target: true
    glacial:
      - host: 1u-srv-01
        wol_mac: "AA:BB:CC:DD:EE:01"
        schedule: "0 2 * * 0"
        client: "federation"
    recovery:
      host: 1u-srv-sg
      purpose: "Synology drive extraction"
      temporary: true
    sort:
      host: cg2
      purpose: "USB shelf + SAS triage"

  # VMs/containers on the compute host
  vms:
    - id: 100
      name: docker
      type: lxc            # lxc, vm
      hostname: docker
      ip: 192.168.9.11
      cores: 2
      memory: 2048
      disk: "local-lvm:4G"
      onboot: false
      status: stopped
      services:
        - name: Portainer
          port: 9443
```

### storage (optional)

Storage pools and datasets. Used by generate-docs.sh, verify.sh.

```yaml
storage:
  pools:
    - name: MediaVolume
      type: zfs             # zfs, btrfs, lvm, raw
      layout: raidz1        # raidz1, mirror, stripe, single
      host: cg2
      size_tb: 21.8
      used_tb: 12.4
      free_tb: 9.37
      drives:
        - serial: Z4D0830X
          model: ST6000DX000-1H217Z
      datasets:
        - name: Media
          size: "8.86 TB"
          tier: media        # media, scratch, warm, cold, archive
```

### services (optional)

Running services. Used by deploy.sh, verify.sh, generate-docs.sh.

```yaml
services:
  - name: "wfMedia"
    type: "media"           # media, infra, backup, web, database
    application: "Plex"
    host: cg2
    vm_id: 101
    port: 32400
    status: running
    access:
      local: "http://192.168.9.x:32400"
      remote: "none"
```

### zerotier (optional)

Overlay network membership. Used by bootstrap.sh.

```yaml
zerotier:
  enabled: true
  networks:
    - id: d5e5fb65371eb4a4
      name: cat-ghadmin-grid
      purpose: federation
  members:
    - hostname: devwin10
      zt_ip: 10.147.17.165
      networks: [d5e5fb65371eb4a4]
```

### monitoring (optional)

Monitoring goals and checks. Used by verify.sh, generate-docs.sh.

```yaml
monitoring:
  enabled: true
  script: "ops/scripts/wf-status.sh"
  goals:
    - name: "Federation backup target"
      enabled: true
      depends:
        - service: ssh
          host: devwin10
          user: buadmin
          port: 22
      validated_by: ".backup-state file fresh < 24h"
      current_status: "OPERATIONAL"
  checks:
    - name: devwin10
      method: ping
      target: 10.147.17.165
```

### federation (required)

Cross-site relationships. Used by restore.sh, backup scripts.

```yaml
federation:
  name: "2cld.net"
  role: "bu-1"             # primary, bu-0 (first backup), bu-1 (second backup)
  backup_from: cf          # Which site sends backups here
  backup_path: "D:\\cat9bu-wf\\"
  reference: "https://netstack.org/docs/ops/deployments/"
```

### physical (optional)

Physical infrastructure (locations, switches, cables, power). See [site-config-physical-schema.md](./site-config-physical-schema.md) for full specification.

## Validation Rules

1. **site.code** must be unique across the federation (cf, sl, wf)
2. **site.repo** must be a valid git clone URL
3. **devices[*].hostname** must be unique within the site
4. **devices[*].ipv4** must be within `network.subnet`
5. **compute.vms[*].id** must be unique within the compute host
6. **zerotier.networks[*].id** must be a valid 16-character hex string
7. **federation.role** must be one of: primary, bu-0, bu-1, bu-2, etc.

## Cross-Site Validation

When validating across all federation sites:
- No two sites should have the same `site.code`
- `federation.backup_from` must reference a valid site code
- ZeroTier network IDs should be consistent across sites that need connectivity

## Current State (validated against actual configs)

| Site | site | network | devices | compute | storage | services | zerotier | monitoring | federation |
|------|:----:|:-------:|:-------:|:-------:|:-------:|:--------:|:--------:|:----------:|:----------:|
| cf | YES | YES | YES | YES | YES | YES | YES | YES | YES |
| sl | YES | YES | YES | YES | YES | YES | YES | YES | YES |
| wf | YES | YES | YES | YES | YES | YES | YES | YES | YES |

**Gaps identified:**
- `compute.roles` section (from compute-roles-pattern.md) not yet present in any site config -- proposed addition
- wf has the most complete config; sl has the most detailed physical inventory
- cf compute section documents Proxmox VMs but not role assignments

## Related

- [compute-roles-pattern.md](./compute-roles-pattern.md) -- defines the `compute.roles` extension
- [bmr-pattern.md](./bmr-pattern.md) -- scripts that consume this schema
- [site-config-physical-schema.md](./site-config-physical-schema.md) -- physical inventory extension
- [site-docs-generator-pattern.md](./site-docs-generator-pattern.md) -- generating docs from config
- [ns-site-template](https://gitea.cat9.me/nsadmin/ns-site-template) -- scaffold scripts that read this schema
