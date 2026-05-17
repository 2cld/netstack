[edit](https://github.com/2cld/netstack/edit/master/docs/ops/deployments/README.md) or [../ops](../) or [../../docs](../../)

# Deployments

Site-specific configurations and network diagrams. Each site has its own private repo with full details — netstack holds the summary and cross-site patterns.

New site? Start from the [site template](./site-template/).

## Sites

| site | docs | repo |
|------|------|------|
| [cf](./cf/) (Cedar Falls) | [cf.2cld.net](https://cf.2cld.net) | [github (private)](https://github.com/2cld/cf) |
| [sl](./sl/) (St. Louis) | [sl.2cld.net](https://sl.2cld.net) | [github (private)](https://github.com/2cld/sl) |
| [wf](./wf/) (Winfield) | [wf.2cld.net](https://wf.2cld.net) | [github (private)](https://github.com/2cld/wf) |

- [CyberTruck](./CyberTruck/) - CyberTruck workstation (at cf site)

## Federation Architecture

```
                    ┌─────────────────┐
                    │    netstack     │
                    │  (architecture) │
                    │ netstack.org    │
                    └────────┬────────┘
                             │ references
              ┌──────────────┼──────────────┐
              │              │              │
     ┌────────▼───┐  ┌──────▼─────┐  ┌────▼────────┐
     │  sl node   │  │  cf node   │  │  wf node    │
     │ sl.2cld.net│  │cf.2cld.net │  │ wf.2cld.net │
     └────────────┘  └────────────┘  └─────────────┘
```

Each site node:
- Has its own private GitHub repo and MkDocs Material site
- Documents local devices, services, storage, and operations
- Connects to other sites via encrypted overlay VPN
- Exposes services externally via Cloudflare tunnels

## Site Build System

All site repos use the same build pattern:
- MkDocs Material theme (dark slate, blue-grey primary)
- GitHub Actions workflow triggers on push to `main`
- Deploys to `gh-pages` branch → GitHub Pages with custom CNAME
- Config at `.mkdocs/mkdocs.yml`, CSS at `.mkdocs/overrides/extra.css`

## Maintenance Pattern

| What to edit | Where |
|---|---|
| Site-specific data (devices, services, IPs) | Site repo (cf, sl, wf) — private |
| Architecture, install guides, portal docs | netstack — public |
| Cross-site deployment summary | Site repos (private) |
| MkDocs theme, build workflow, CSS | ns-site-template |
| Node-local monitoring scripts | Site repo `ops/monitor/` |

## Related

- [Federation Node Topology](./federation-node-topology.md) — standard node structure
- [Federation Backup Plan](../backup/federation-backup-plan.md) — cross-site backup strategy
- [Sensitive Data Pattern](../security/sensitive-data-pattern.md) — what stays private
