# site-config.yml Schema

**Purpose:** Document the canonical keys that site-config.yml files use across the federation.
**Consumers:** ns-site-template scripts (generate-site.sh, generate-docs.sh, collect-site.sh), BMR scripts (bootstrap.sh, deploy.sh, restore.sh, verify.sh)
**Related:** [LAN Overview / Standard IP Map](https://netstack.org/docs/lan/) (the gateway model this schema follows), [site-config-physical-schema.md](./site-config-physical-schema.md) (physical inventory extension), [netstack#18](https://github.com/2cld/netstack/issues/18), [netstack#28](https://github.com/2cld/netstack/issues/28) (this rewrite)

---

## Overview

`site-config.yml` is the machine-readable source of truth for each federation site. Every site repo (cf, sl, wf) has one at the repo root. Scripts read it to generate docs, deploy services, monitor health, and rebuild from scratch.

The config is organized around the **netstack gateway model** ([LAN Overview](https://netstack.org/docs/lan/)): a site's functions are expressed as **gateways** — network (ng), storage (sg), compute (cg), backups (bg), documents (dg). This is the primary organizing principle, matching how the operator reasons about any system.

> **Schema status (2026-09-25, netstack#28):** cf and sl use the gateway model documented here. **wf still uses the earlier flat schema** (see [Appendix: Flat Schema (transitional)](#appendix-flat-schema-transitional)) and is pending migration. Tools should accept both during the transition.

## The Gateway Model

A **gateway** is a **logical role**, not a specific piece of hardware or a fixed IP. A node or container *declares* which gateway function it fulfills; where it actually lives (IP, container, VM) is a separate, changeable fact.

| Gateway | Function |
|---------|----------|
| **ng** | network — routing, DNS, tunnels, VPN, the site's in/out |
| **sg** | storage — drives, NAS, file shares, backup target |
| **cg** | compute — hypervisors, containers, workstations, services |
| **bg** | backups — the BMR (bare-metal rebuild) config/control portal |
| **dg** | documents — document store/portal (optional) |

**Key principle — map the function, not the IP.** We usually do NOT control IP assignment (Docker IPAM assigns in start-order, ISP DHCP, etc.). So gateways are declared by role; the IP is whatever it happens to be. On a single-machine site, several gateways resolve to the **same node** — that's the normal "munged together" case, and the schema expresses it honestly.

### Standard IP Map (convention, NOT enforced)

When you DO control address assignment (a subnet you own, static Docker IPs), prefer this layout so the address self-documents the role. It is an **aspirational convention** — a hint, not a requirement. Source: [netstack.org/docs/lan/](https://netstack.org/docs/lan/).

| IP | name | role |
|----|------|------|
| `x.1` | ng | network gateway |
| `x.2` | sg | storage gateway |
| `x.3` | cg | compute gateway |
| `x.4` | bg2 | backups gateway (secondary) |
| `x.5` | ng2 | network gateway (secondary) |
| `x.6` | sg2 | storage gateway (secondary) |
| `x.7` | cg2 | compute gateway (secondary) |
| `x.8` | bg | backups gateway |
| `x.9` | dg | documents gateway |

Secondaries (`ng2/sg2/cg2` at `.5/.6/.7`) are HA partners. The address is a hint for a human/AI glancing at it — never a thing scripts require.

## Schema Sections

### site (required)

Identifies the site.

```yaml
site: sl                                # Short code — used in scripts, hostnames, paths
location: "St. Louis (O'Fallon)"        # Human-readable name / place
primary_node: slwin11ops                # The site's main node
repo: "https://github.com/2cld/sl"      # Canonical repo URL (optional but recommended)
timezone: "America/Chicago"             # System timezone (optional)
```

> The site code may appear as top-level `site:` (cf, sl) or as `site.code:` in a block (flat schema — see appendix). Tools accept either.

| Key | Required | Used by |
|-----|:--------:|--------|
| site (code) | YES | All scripts, hostname generation |
| location / name | YES | Docs generation |
| primary_node | YES | The declared entry node (see `access`) |
| repo | no | bootstrap.sh (clone source) |
| timezone | no | bootstrap.sh (timedatectl) |

### access (required) — the "one door"

Every site declares **one SSH-reachable node** — the entry point for ops, verify, and BMR. This is the "there's always a door to knock on" guarantee, and it should be **testable** (verify.sh / monitoring confirms it opens).

```yaml
access:
  ssh:
    host: 10.147.17.94        # ZeroTier or LAN IP of the door node
    port: 2020                # sl: WSL SSH on 2020 (NOT Windows :22)
    user: ghadmin
    note: "WSL Ubuntu on slwin11ops — the ops door"
```

### gateways (required)

Declares each gateway function and the node/container that fulfills it. On a single-box site, multiple gateways point at the same node.

```yaml
gateways:
  ng: { node: slwin11ops, function: network }   # routing, DNS, CF tunnel, ZeroTier
  sg: { node: slwin11ops, function: storage }   # F: backup target + media
  cg: { node: slwin11ops, function: compute }   # WSL Docker stack
  bg: { node: slwin11ops, function: backup }    # BMR rebuild portal
  # dg optional (documents gateway)
```

The detailed per-gateway config lives in the matching top-level section below (`ng:`, `sg:`, `cg:`). The `gateways:` block is the index; the sections are the detail.

### ng (network gateway detail)

Network config for the site — ISP, gateway IP, DNS, VPN/overlay, tunnels.

```yaml
ng:
  type: "residential"
  isp: "Spectrum"
  gateway: "192.168.1.1"
  vpn:
    zerotier:
      network_id: "d5e5fb65371eb4a4"
      ip: "10.147.17.94"
  tunnel: "sl-2cld (Cloudflare, via Docker in WSL)"
  dns: "192.168.1.1"
```

### sg (storage gateway detail)

Drives, pools, shares, backup targets. (See sl/cf for the drives-list form; `storage:` / `storage_index:` extend this for detailed manifests.)

```yaml
sg:
  drives:
    - letter: "F:"
      label: "slDriveF"
      size_gb: 1863
      purpose: "Media + Federation Backup"
```

### cg (compute gateway detail)

Compute host(s), platform, and the services running on them. **Services live under `cg.services`.**

```yaml
cg:
  pattern: "compute-wsl-docker-pattern"
  nodes:
    - name: slwin11ops
      type: "Windows 11"
      role: "Primary ops, backup receiver, Docker host (via WSL)"
  services:
    - { name: gitea, host: slwin11ops, port: 3000, critical: true, public: "gitea.2cld.com" }
    - { name: traefik, host: slwin11ops, port: 443, critical: true }
    - { name: cloudflared, host: slwin11ops, type: "cloudflare tunnel", critical: true }
```

### bg (backups gateway detail, optional)

The BMR rebuild config/control portal + backup flows. May reference `backup_and_recovery:`.

### federation (required)

Cross-site relationships. Used by restore.sh, backup scripts.

```yaml
federation:
  name: "2cld.net"
  role: "bu-0"             # primary, bu-0 (first backup), bu-1 (second backup)
  backup_from: cf          # Which site sends backups here
  backup_path: "F:/slMedia/catbu-sl/"
  reference: "https://netstack.org/docs/lan/"
```

### monitoring (optional)

Monitoring goals + checks. Used by verify.sh, generate-docs.sh. See `.wip-monitor.yml` for the contract-driven form.

### physical (optional)

Physical infrastructure (locations, switches, cables, power). See [site-config-physical-schema.md](./site-config-physical-schema.md).

## Validation Rules

1. **site code** must be unique across the federation (cf, sl, wf)
2. **access.ssh** must be present and reachable (the "one door" — testable)
3. Each declared **gateway** must name a node that exists at the site
4. On single-box sites, gateways sharing a node is valid (not an error)
5. **federation.role** must be one of: primary, bu-0, bu-1, bu-2, etc.
6. The **Standard IP Map is a convention, not a validation rule** — do not fail a config for using a different address

## Current State (measured 2026-09-25, netstack#28)

| Site | schema shape | services location | conforms to gateway model? |
|------|--------------|-------------------|:--------------------------:|
| **cf** | `ng`/`sg`/`cg` + `goals` | `cg.services` | ✅ yes |
| **sl** | `ng`/`sg`/`cg` + `goals` | `cg.services` | ✅ yes |
| **wf** | flat: `network`/`devices`/`compute`/`services` | top-level `services` | ⏳ transitional — migration pending |

> Corrects the prior table, which incorrectly claimed all three sites had `network:`/`devices:`/`services:`. Measured reality: cf/sl use the gateway shape; wf uses the flat shape.

**Open items (netstack#28):**
- Migrate wf from flat → gateway shape (pending; subnet confirmation needed first)
- Confirm real subnets (sl `.1` vs `.9`, wf `.9` vs `.254`) — needs operator/live-read, not docs
- Update `generate-docs.sh` to read `cg.services` (validator already handles the gateway shape as of ns-site-template#3)
- `dg` (documents gateway) — defined but not yet used by any site

## Appendix: Flat Schema (transitional)

wf currently uses an earlier **flat** schema with top-level `network:`, `devices:`, `compute:`, `storage:`, `services:`, `zerotier:`, `monitoring:`. It predates the gateway-model convergence (this doc, 2026-09-25). Tools accept it during the migration window. It will be removed once wf is migrated.

<details>
<summary>Flat schema sections (wf)</summary>

```yaml
site:
  code: wf
  name: "Winfield"
  repo: "https://github.com/2cld/wf"
network:
  subnet: 192.168.9.0/24
  gateway: 192.168.9.1
  netstack_assignments:      # ng/sg/cg as device-role labels (the seed of the gateway model)
    ng: { ipv4: 192.168.9.1, hostname: mikrotik }
devices:
  - hostname: mikrotik
    role: ng                 # gateway role as a device attribute
compute:
  host: cg2
  roles: { infra: {...}, glacial: [...] }   # compute-roles-pattern.md
services:
  - { name: "wfMedia", type: media, host: cg2, port: 32400 }
federation:
  name: "2cld.net"
  role: "bu-1"
```

Note: the flat schema already carried ng/sg/cg as **device role labels** (`devices[*].role`, `network.netstack_assignments`) — the gateway model is the promotion of that idea to a first-class organizing structure.
</details>

## Related

- [LAN Overview / Standard IP Map](https://netstack.org/docs/lan/) -- the gateway model + IP convention this schema follows
- [compute-roles-pattern.md](./compute-roles-pattern.md) -- compute role assignments (infra/glacial/recovery/sort)
- [bmr-pattern.md](./bmr-pattern.md) -- scripts that consume this schema (bg is their portal)
- [site-config-physical-schema.md](./site-config-physical-schema.md) -- physical inventory extension
- [site-docs-generator-pattern.md](./site-docs-generator-pattern.md) -- generating docs from config
- [ns-site-template](https://gitea.cat9.me/nsadmin/ns-site-template) -- scaffold scripts that read this schema
