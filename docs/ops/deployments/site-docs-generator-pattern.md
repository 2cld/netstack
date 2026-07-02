# Pattern: Site Documentation Generator (Config-Driven)

**Pattern type:** Documentation automation
**Applies to:** All federation sites with a `site-config.yml`
**Implementation:** `ns-site-template/scripts/generate-site-docs.js`
**Related:** [netstack#16](https://github.com/2cld/netstack/issues/16), [site-tenant-contract-pattern](../deployments/site-tenant-contract-pattern.md)

## Problem

Site documentation gets stale because it's maintained separately from the infrastructure it describes. When a service changes, the docs lag behind. Manual HTML editing doesn't scale across 3+ sites.

## Solution: Generate Docs from Config

One source of truth (`site-config.yml`) drives both the infrastructure deployment AND the documentation. Change the config → regenerate the docs → they match reality by definition.

```
site-config.yml (source of truth)
    │
    ├── site-ops deploy  → provisions infrastructure
    ├── site-ops monitor → generates health check scripts
    ├── site-ops verify  → validates everything works
    └── site-ops docs    → generates documentation site
                              │
                              ├── index.html (core: status, services, network, storage, backup, power, federation)
                              ├── media/    (module: media-detail, if enabled)
                              ├── pool/     (module: pool ops, if enabled)
                              └── site-status.json (live, from monitoring cron)
```

## Architecture: Core + Modules

### Core Generator (`generate-site-docs.js`)

Produces the main page for every site. Thin, infrastructure-focused.

**Sections generated (from config blocks):**

| Section | Config Source | Content |
|---------|-------------|---------|
| Status | `site_ops.monitor` + `site_ops.verify` | Live status + how to run checks + verify checklist |
| Services | `cg.services` | Host-level + Docker services tables |
| Equipment | `physical.equipment` | Tagged devices with location, MAC, IP, status |
| Network | `physical.switches` + `physical.cable_runs` | Switch port maps + cable run table |
| Storage | `sg.drives` + `storage_index` | Physical disks + tier classification + content manifest |
| Backup | `backup_and_recovery` | Data classification + federation flows + recovery procedures |
| Power | `physical.power` | Circuits + recovery order |
| Federation | `cloudflare` + `contract` | Tunnel config + contract link |
| Modules | `modules` | Links to bolt-on sub-pages |

### Bolt-On Modules

Specialized generators for site-specific complexity. Declared in config, only loaded if enabled.

```yaml
modules:
  - name: "media-detail"
    description: "Home media stations, receivers, HSCs, remote guides"
    config_section: "physical.media"     # data lives in main site-config.yml
    generator: "generate-media-detail.js"
    output: "media/"
    enabled: true

  - name: "pool"
    description: "Pool operations — equipment, valves, plumbing, procedures"
    config_file: "sl-pool-config.yml"    # data lives in separate config (too specialized)
    generator: "generate-pool.js"
    output: "pool/"
    enabled: true
```

**Module types:**
- `config_section` — data lives inside the main site-config.yml (e.g., `physical.media`)
- `config_file` — data lives in a separate YAML file (for large specialized configs)

**When to make a module vs core section:**
- Core = every site needs it (network, storage, power, services)
- Module = only some sites need it (home media, pool, shop equipment, farm ops)

### Currently Available Modules

| Module | Config | Generates | Sites |
|--------|--------|-----------|-------|
| `media-detail` | `physical.media` in site-config | Receiver maps, HSCs, cable tags per room, remote guides | sl |
| `pool` | separate `pool-config.yml` | Equipment, valves, plumbing, procedures, chemicals | sl |
| *(future)* `shop-inventory` | `physical.shop` | Tool inventory, workbench layout | wf |
| *(future)* `farm-ops` | separate config | Seasonal ops, equipment, field maps | wf (FHKlopFarms) |

## Usage

```bash
# Generate core site docs
node generate-site-docs.js site-config.yml --output ./html/

# With live status data merged in
node generate-site-docs.js site-config.yml --output ./html/ --live ~/ops/site-status.json

# Deploy to site docs container
scp html/index.html <target>:~/docker/data/sl-docs/html/
```

## site-config.yml — Required Sections (for core generator)

Minimum viable config for docs generation:

```yaml
site: <code>
location: "<city>"
primary_node: <hostname>
primary_zt_ip: <ip>
subnet: "<cidr>"

cg:
  services: [...]

sg:
  drives: [...]

physical:
  switches: [...]
  equipment: [...]
  power:
    circuits: [...]

site_ops:
  monitor:
    output: "..."
    cron: "..."
  verify:
    script: "..."
    checks: [...]
```

Everything else (backup_and_recovery, storage_index, cloudflare, modules) is optional — sections only appear if the data exists in the config.

## Hosting

The generated docs are served by a Docker container at each site:

```yaml
# In docker-compose (sl-docs service):
services:
  sl-docs:
    image: nginx:alpine
    container_name: sl-docs
    volumes:
      - ./html:/usr/share/nginx/html:ro
    labels:
      - "traefik.http.routers.sl-docs.rule=Host(`sl.2cld.com`)"
```

Routed through: Cloudflare tunnel → traefik → sl-docs container.

The site-status.json is copied into the HTML directory by cron (5 min after each status check).

## Regeneration Workflow

```
1. Edit site-config.yml (add/update equipment, services, storage, etc.)
2. Run: node generate-site-docs.js site-config.yml --output ./html/
3. Deploy: copy html/ to the docs container volume
4. Verify: browse https://<site>.2cld.com — content reflects changes
```

Future: `site-ops docs` wraps steps 2-3 into one command.

## Design Decisions

1. **HTML, not markdown** — served directly by nginx, no build tooling needed at the site
2. **Single page (core)** — everything on one scrollable page with nav anchors. No multi-page complexity for the core.
3. **Sub-pages (modules)** — bolt-ons get their own directory (`/media/`, `/pool/`)
4. **JS-yaml for parsing** — proper YAML parser, not regex (configs are complex)
5. **No framework** — plain HTML + inline CSS. Zero dependencies at render time.
6. **Live status via JS fetch** — page loads static, then fetches site-status.json for live data

## Related

- [netstack#16](https://github.com/2cld/netstack/issues/16) — federation dashboard (parent issue)
- [site-tenant-contract-pattern](../deployments/site-tenant-contract-pattern.md) — defines monitoring scope
- [storage-index](../storage-index/README.md) — storage classification system
- [media-equipment-pattern](../../lan/media/media-equipment-pattern.md) — media module schema
- [cloudflare-tunnel-monitoring](../../wan/cloudflare/cloudflare-tunnel-monitoring-pattern.md) — tunnel section
- [plex-lan-only-pattern](../../portals/plex/plex-lan-only-pattern.md) — Plex service config
- [service-recovery-pattern](../backup/service-recovery-pattern.md) — backup section
- [ns-site-template](https://gitea.cat9.me/nsadmin/ns-site-template) — template repo (generator lives here)
