[edit](https://github.com/2cld/netstack/edit/master/docs/ops/feedback/2025-01-22-ns-site-template-feedback.md)

> **GitHub Issue:** [#2 — ns-site-template feedback and netstack.org improvements](https://github.com/2cld/netstack/issues/2)
> **Working Branch:** `feedback/ns-site-template-improvements` (when created)
> **Contributing:** See [CONTRIBUTING.md](../../../CONTRIBUTING.md) for the feedback workflow

# Netstack.org Documentation Feedback

This document tracks feedback, questions, and suggestions for the [netstack.org](https://netstack.org/docs/) documentation project as we implement their patterns in our home network.

## Document Purpose

As we restructure our network documentation following netstack.org patterns, we're documenting:
- Areas where netstack.org docs were helpful
- Sections that need clarification
- Missing information we needed
- Suggested improvements
- Questions for the netstack.org team

## Implementation Status

| Component | Netstack Pattern | Our Implementation | Status | Notes |
|-----------|------------------|-------------------|--------|-------|
| 0.1 ng (Network Gateway) | [docs](https://netstack.org/docs/lan/network/) | templates/network-template.md | In Progress | - |
| 0.2 sg (Storage Gateway) | [docs](https://netstack.org/docs/lan/storage/) | templates/storage-template.md | In Progress | - |
| 0.3 cg (Compute Gateway) | [docs](https://netstack.org/docs/lan/compute/) | templates/compute-template.md | In Progress | - |
| Portals | [docs](https://netstack.org/docs/portals/) | templates/service-template.md | In Progress | - |
| Operations | [docs](https://netstack.org/docs/ops/) | ops/ | In Progress | - |

## Positive Feedback

### What Works Well
- Clear separation of concerns (ng, sg, cg pattern)
- Logical numbering system (0.1, 0.2, 0.3, etc.)
- Focus on home lab / small network scale
- Practical examples with real hardware

## Questions & Clarifications Needed

### Network Gateway (ng)
- [ ] **Q**: How to handle multiple subnets in a single location?
  - Our case: ISP router (192.168.1.x) + our router (192.168.0.x)
  - Should we document both or just our managed network?

- [ ] **Q**: VPN integration patterns?
  - We use ZeroTier mesh VPN - where does this fit in the ng documentation?
  - Should VPN be part of ng or separate WAN documentation?

- [ ] **Q**: Cloudflare tunnel documentation?
  - We use CF tunnels for external access instead of traditional port forwarding
  - Is this considered part of ng or WAN?

### Storage Gateway (sg)
- [ ] **Q**: How to document network shares vs local storage?
  - We have NAS (sg) + local drives on compute nodes
  - Should local drives be documented under cg or sg?

- [ ] **Q**: Backup storage (sg2) patterns?
  - When is sg2 a separate device vs just a backup pool on sg?
  - Our QNAP is offline - should we keep sg2 designation?

### Compute Gateway (cg)
- [ ] **Q**: Windows workstation as cg?
  - Netstack examples show Proxmox/Linux
  - We use Windows 11 + Hyper-V + WSL2 + Docker
  - Does this still qualify as cg or is it a "workstation"?

- [ ] **Q**: Container platform documentation?
  - Where do Docker Compose stacks fit in the cg pattern?
  - Should each container be documented separately or as a stack?

### Portals
- [ ] **Q**: Deprecated service documentation?
  - How to handle services we've removed (CasaOS, Guacamole)?
  - Keep in docs with strikethrough or move to archive?

- [ ] **Q**: Service access methods?
  - We have multiple access paths (LAN, ZT, CF tunnel)
  - Should all be documented or just primary method?

## Missing Information

### Topics Not Covered (or hard to find)
1. **Multi-site networking**
   - We have 3 locations (sl, cf, wf) connected via ZeroTier
   - How to document cross-site dependencies?
   - Naming conventions for multi-site?

2. **Windows-centric deployments**
   - Most examples are Linux/Proxmox
   - Need patterns for Windows + Hyper-V + WSL2

3. **Media server specific patterns**
   - Plex is common in home labs
   - Storage mapping patterns for media libraries
   - DVR/tuner integration

4. **Device inventory tracking**
   - MAC address tracking
   - Physical port mapping
   - Cable management (coax, ethernet)

5. **Remote access patterns**
   - Google Remote Desktop
   - Microsoft RDP
   - SSH to WSL (non-standard port)

6. **Monitoring and health checks**
   - What should be monitored?
   - How to document health check procedures?
   - Alerting patterns for home labs?

## Suggested Improvements

### Documentation Structure
1. **Add a "Quick Start" guide**
   - Single location, simple setup
   - Minimal viable documentation
   - Then expand to full pattern

2. **Windows deployment guide**
   - Windows as hypervisor (Hyper-V)
   - WSL2 for Linux services
   - Docker Desktop vs Docker in WSL2

3. **Template files**
   - Provide downloadable markdown templates
   - Include placeholder text
   - Show example filled-in templates

4. **Multi-site patterns**
   - How to scale from one location to multiple
   - Cross-site service dependencies
   - Naming conventions

### Specific Sections

#### Network Gateway
- Add section on VPN mesh networks (ZeroTier, Tailscale)
- Document Cloudflare tunnel setup
- ISP router + managed router scenarios

#### Storage Gateway
- Network share mounting examples (Windows, Linux, macOS)
- Media library organization patterns
- Backup strategies for home labs

#### Compute Gateway
- Windows + Hyper-V + WSL2 pattern
- Docker Compose stack organization
- Container networking with Traefik

#### Portals
- Service deprecation/migration patterns
- Multi-access method documentation
- Authentication/SSO patterns

#### Operations
- Backup automation scripts
- Health check scripts
- Update procedures

## Implementation Differences

### Where We Deviate from Netstack Pattern

| Component | Netstack Pattern | Our Implementation | Reason |
|-----------|------------------|-------------------|--------|
| Primary Router | pfSense/Mikrotik | TP-Link consumer router | Cost, simplicity |
| Compute Platform | Proxmox | Windows + Hyper-V + WSL2 | Existing hardware, familiarity |
| Storage | FreeNAS/TrueNAS | QNAP (offline) + local drives | Legacy hardware |
| VPN | OpenVPN | ZeroTier mesh | Easier setup, NAT traversal |
| External Access | Port forwarding | Cloudflare tunnels | Security, no port forwarding |

## Questions for Netstack.org Team

1. Is there a GitHub repo for netstack.org where we can contribute?
2. Are you interested in Windows-based deployment examples?
3. Would you like contributions for multi-site patterns?
4. Can we submit template files for others to use?
5. Is there a community forum or Discord for discussions?

## How to Contribute Back

Once we have our documentation cleaned up and templates validated:
1. Share our templates with netstack.org
2. Document Windows + Hyper-V + WSL2 pattern
3. Create multi-site networking guide
4. Contribute media server patterns
5. Share automation scripts

## Contact

- **Our Project**: [github.com/2cld/sl](https://github.com/2cld/sl)
- **Netstack.org**: [netstack.org/docs](https://netstack.org/docs/)
- **Feedback Method**: TBD (GitHub issues, email, forum?)

## Updates

| Date | Update | By |
|------|--------|-----|
| 2025-01-22 | Initial feedback document created | ghadmin |
| 2026-03-17 | Added alignment analysis and ns-site-template suggestions | ghadmin |
| 2026-03-19 | Added federation deployment reference architecture for netstack presentation | ghadmin |

## Alignment Analysis: ns-site-template vs netstack site-template

### Netstack Site Template Structure (from netstack.org/docs/ops/deployments/site-template/)

```
docs/
  README.md          # site overview
  devices.md         # device inventory
  services.md        # running services
  tunnels.md         # cloudflare tunnels
  storage.md         # NAS and plex mappings
  ops/
    backup.md        # site-specific backup
    notes.md         # maintenance log
```

### Our ns-site-template Structure (superset)

```
xx/
  README.md            # site intro
  site-overview.md     # comprehensive single-page reference
  services.md          # running services (netstack-compatible)
  tunnels.md           # cloudflare tunnels (netstack-compatible)
  .site-config.yml     # machine-readable config (source of truth)
  network/
    README.md          # network gateway (ng)
    devices.md         # device inventory (netstack-compatible)
  storage/
    README.md          # NAS and storage (netstack-compatible)
  compute/
    README.md          # compute gateway (cg)
  portals/
    README.md          # per-service detailed docs
  ops/
    README.md          # operations overview
    notes.md           # maintenance log (netstack-compatible)
    backup/README.md   # backup procedures (netstack-compatible)
    install/README.md  # installation notes
    access/README.md   # remote access methods
    scripts/           # operational automation
    logs/              # operation logs
```

### Compatibility Mapping

| Netstack File | Our File | Notes |
|---------------|----------|-------|
| `docs/README.md` | `site-overview.md` | Ours is more comprehensive |
| `docs/devices.md` | `network/devices.md` | Same content, organized under network/ |
| `docs/services.md` | `services.md` | Direct match |
| `docs/tunnels.md` | `tunnels.md` | Direct match |
| `docs/storage.md` | `storage/README.md` | Same content, organized under storage/ |
| `docs/ops/backup.md` | `ops/backup/README.md` | Same content |
| `docs/ops/notes.md` | `ops/notes.md` | Direct match |

## Suggestions to Push Back to Netstack.org

### 1. Add `.site-config.yml` to the Site Template

**Problem:** The netstack site template has no machine-readable configuration file. All data lives only in markdown, making automation difficult.

**Suggestion:** Add a `.site-config.yml` (or similar) as the source of truth for site data. This enables:
- Automated validation of documentation
- Script-driven site generation
- Consistency checking between config and docs
- Monitoring and health checks driven by config

```yaml
site:
  code: xx
  name: "Site Name"
network:
  subnet: 192.168.X.0/24
  gateway: 192.168.X.1
  netstack_assignments:
    ng: { ipv4: 192.168.X.1 }
    sg: { ipv4: 192.168.X.2 }
    cg: { ipv4: 192.168.X.3 }
```

### 2. Add `site-overview.md` as Single-Page Reference

**Problem:** The current `README.md` serves as both landing page and overview. For GitHub Pages sites (like sl.2cld.net), a comprehensive single-page reference is valuable.

**Suggestion:** Add a `site-overview.md` template that consolidates:
- Network configuration and netstack assignments
- Device inventory summary
- Service listing
- Tunnel configuration
- Remote access methods
- Quick reference commands

### 3. Add Operational Scripts Directory

**Problem:** No automation tooling in the site template. Each site admin reinvents validation and monitoring.

**Suggestion:** Include an `ops/scripts/` directory with:
- `validate-config.sh` - Validate site configuration
- `validate-docs.sh` - Check for unreplaced placeholders
- `check-connectivity.sh` - Ping documented devices
- `generate-report.sh` - Create status reports

### 4. Add IPv6 Support to Templates

**Problem:** Current templates only reference IPv4 addresses. Many home networks are moving to dual-stack.

**Suggestion:** Add IPv6 fields alongside IPv4 in device and network templates. Even if not used immediately, the structure is ready.

### 5. Add Service Port Tracking to Netstack Assignments

**Problem:** ng, sg, cg are documented as IP addresses, but they're really service endpoints. A router runs admin UI on port 80, SSH on 22, etc.

**Suggestion:** Expand netstack assignments to include services:
```
ng: 192.168.X.1
  - Admin UI: http://192.168.X.1:80
  - SSH: port 22
sg: 192.168.X.2
  - Admin UI: http://192.168.X.2:8080
  - SMB: port 445
```

### 6. Add `install/` and `access/` to ops/

**Problem:** The current ops/ only has `backup.md` and `notes.md`. Installation procedures and remote access methods are common needs.

**Suggestion:** Add:
- `ops/install.md` - Node installation notes and checklists
- `ops/access.md` - Remote access methods (ZeroTier, SSH, RDP, etc.)

### 7. Standardize Placeholder Naming

**Problem:** No standard placeholder convention in the template. Makes it hard to validate completeness.

**Suggestion:** Use consistent UPPER_CASE placeholders:
- `LOCATION_CODE` - Site code (xx)
- `LOCATION_NAME` - Full site name
- `SUBNET_CIDR` - Network subnet
- `NG_IP`, `SG_IP`, `CG_IP` - Netstack gateway IPs
- `NG_HOSTNAME`, `SG_HOSTNAME`, `CG_HOSTNAME` - Device hostnames

### 8. Add Cross-Site Reference Pattern

**Problem:** The deployments page shows cross-site data but there's no template for how sites should reference each other.

**Suggestion:** Add a `related_sites` section to the site template:
```yaml
related_sites:
  - code: cf
    name: "Cedar Falls"
    subnet: 192.168.6.0/24
    connection: "zerotier"
  - code: sl
    name: "St. Louis"
    subnet: 192.168.0.0/24
    connection: "zerotier"
```

### 9. Add GitHub Pages Setup to Template

**Problem:** The "After creating the site repo" section mentions GitHub Pages but doesn't include the CNAME file or Jekyll config in the template.

**Suggestion:** Include in the site template:
- `CNAME` file template
- `_config.yml` for Jekyll/GitHub Pages
- `.nojekyll` option for plain markdown

## Federation Deployment: 2cld.net Reference Architecture

This section documents our multi-site federation as a concrete reference deployment for the netstack.org pattern. We present this as a working example of what netstack's deployment documentation could look like at scale.

### What is 2cld.net?

2cld.net is a federation of three residential site nodes, each running the netstack ng/sg/cg pattern on its own private LAN. Sites are interconnected via ZeroTier mesh VPN and expose selected services publicly through Cloudflare tunnels.

```
                        ┌──────────────────────────────────┐
                        │         2cld.net Federation       │
                        │   netstack.org pattern deployed   │
                        └──────────────┬───────────────────┘
                                       │
              ┌────────────────────────┼────────────────────────┐
              │                        │                        │
     ┌────────▼────────┐     ┌────────▼────────┐     ┌────────▼────────┐
     │   cf (Cedar Falls)│     │  sl (St. Louis)    │     │  wf (Winfield)   │
     │  192.168.6.0/24  │     │  192.168.0.0/24  │     │ 192.168.254.0/24 │
     │  cf.2cld.net     │     │  sl.2cld.net     │     │                  │
     └────────┬─────────┘     └────────┬─────────┘     └────────┬─────────┘
              │                        │                        │
     ┌────────▼─────────┐    ┌────────▼─────────┐    ┌────────▼─────────┐
     │ ng: 192.168.6.1  │    │ ng: 192.168.0.1  │    │ ng: 192.168.254.1│
     │ sg: 192.168.6.2  │    │ sg: 192.168.0.2  │    │ sg: (tbd)        │
     │ cg: 192.168.6.3  │    │ cg: 192.168.0.3  │    │ cg: (tbd)        │
     │ sg2: 192.168.6.6 │    │                   │    │                  │
     └──────────────────┘    └───────────────────┘    └──────────────────┘
              │                        │                        │
              └────────────────────────┼────────────────────────┘
                                       │
                              ┌────────▼────────┐
                              │    ZeroTier VPN   │
                              │  10.147.17.0/24  │
                              │  Cross-site mesh │
                              └──────────────────┘
```

### Federation Site Summary

| Site | Location | Subnet | Public IP | Docs | Tunnel Domains |
|------|----------|--------|-----------|------|----------------|
| cf | Cedar Falls, IA | 192.168.6.0/24 | 192.111.21.62 | [cf.2cld.net](https://cf.2cld.net) | *.bradnordyke.com, *.klopfenstein.org, *.cat9.me |
| sl | St. Louis, MO | 192.168.0.0/24 | 24.216.208.251 | [sl.2cld.net](https://sl.2cld.net) | *.2cld.com |
| wf | Winfield, IN | 192.168.254.0/24 | — | — | *.klopfenstein.org |

### Per-Site Netstack Assignments (cf example)

| Role | IP | Device | Description |
|------|----|--------|-------------|
| 0.1 ng | 192.168.6.1 | 854G-1 | CFU ISP router |
| 0.2 sg | 192.168.6.2 | TrueNAS i3 | Storage gateway (TrueNAS apps: Homer, Gitea, Jellyfin) |
| 0.3 cg | 192.168.6.3 | win11 i7 | Compute gateway (Hyper-V host, Plex) |
| 0.6 sg2 | 192.168.6.6 | Synology DS411 | Backup storage (cfDVR: Plex, Gitea, MeTube) |

### Connectivity Layers

| Layer | Technology | Scope | Visibility |
|-------|-----------|-------|------------|
| LAN | Ethernet / WiFi | Single site | Private (on-site only) |
| VPN | ZeroTier mesh | Cross-site | Private (VPN members only) |
| Tunnels | Cloudflare tunnels | Internet | Public (selected services) |
| Port forwards | ISP router NAT | Internet | Public (Plex, SSH) |

### Cloudflare Tunnel Summary (all sites)

| Tunnel | Site | Services | Domains |
|--------|------|----------|---------|
| cf-cat9me | cf | Traefik, Portainer, Gitea, Nginx, Netbox | *.cat9.me |
| cf-2cld | cf | Open WebUI, RT, SSH, MeTube, SG2, Homepage, Guacamole, Homer | *.bradnordyke.com, *.klopfenstein.org |
| sl-2cld | sl | Traefik, Portainer, Gitea | *.2cld.com |
| wf-2cld | wf | MeTube, Gitea, SG Portal, DAV | *.klopfenstein.org |

### What We Learned Building This

1. Each site needs a machine-readable config (`.site-config.yml`) as the source of truth — markdown alone doesn't scale
2. The federation view should live in every site's config so docs can be generated from a single file
3. ZeroTier mesh VPN is the simplest cross-site connectivity for residential deployments (NAT traversal built in)
4. Cloudflare tunnels replace port forwarding for most services — more secure, no ISP dependency
5. The ng/sg/cg pattern maps cleanly to residential networks, but you often need sg2/cg2 for backup devices
6. Windows + Hyper-V + WSL2 + Docker is a viable cg platform (not just Proxmox/Linux)

### What Netstack Could Add for Federation

These are the gaps we hit when trying to document our multi-site deployment using netstack patterns:

1. **Federation config schema** — a standard way to describe site-to-site relationships in a config file (we built `federation:` in `.site-config.yml`)
2. **Cross-site VPN patterns** — ZeroTier and Tailscale are common in home labs but not documented
3. **Tunnel-first architecture** — Cloudflare tunnels as the primary external access method (vs traditional port forwarding)
4. **Multi-site naming conventions** — how to namespace devices and services across sites (we use `{site}-{role}` like `cf-sg`, `sl-cg`)
5. **Federation doc generation** — tooling to produce a federation overview from per-site configs
6. **Reference deployments** — real-world examples like 2cld.net showing the pattern in production

### Our Tooling for Federation

We built [ns-site-template](https://github.com/2cld/ns-site-template) to automate federation documentation:

- `generate-site.sh` — scaffold a new site from templates following netstack pattern
- `generate-docs.sh` — generate `federation.md`, `services.md`, `tunnels.md` from `.site-config.yml`
- `collect-site.sh` — validate all documented resources are reachable
- `publish-site.sh` — sanitize private data and publish to GitHub Pages

We'd be happy to contribute these patterns and tools back to netstack.org.

## Reference
- Netstack.org main docs: https://netstack.org/docs/
- Netstack site template: https://netstack.org/docs/ops/deployments/site-template/
- Netstack deployments: https://netstack.org/docs/ops/deployments/
- Our templates: [../templates/](../templates/)
- Our implementation: [./](../)
- CF federation doc: [../sites/cf/federation.md](../sites/cf/federation.md)
- CF site config: [../sites/cf/.site-config.yml](../sites/cf/.site-config.yml)
