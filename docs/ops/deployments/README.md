[edit](https://github.com/2cld/netstack/edit/master/docs/ops/deployments/README.md) or [../ops](../) or [../../docs](../../)

# Deployments

Site-specific configurations and network diagrams. Each site has its own repo with full details — netstack holds the summary and cross-site view.

New site? Start from the [site template](./site-template/).

## Sites

| site | subnet | PIP | docs | repo |
|------|--------|-----|------|------|
| [cf](./cf/) (Cedar Falls) | 192.168.6.0/24 | 192.111.21.62 | [cf.2cld.net](https://cf.2cld.net) | [github](https://github.com/2cld/cf) |
| [sl](./sl/) (St. Louis) | 192.168.0.0/24 | 24.216.208.251 | [sl.2cld.net](https://sl.2cld.net) | [github](https://github.com/2cld/sl) |
| [wf](./wf/) (Winfield) | 192.168.9.0/24 | 98.97.4.249 | [wf.2cld.net](https://wf.2cld.net) | [github](https://github.com/2cld/wf) |

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
     │ 192.168.0.x│  │192.168.6.x │  │192.168.9.x  │
     └────────────┘  └────────────┘  └─────────────┘
```

Each site node:
- Has its own GitHub repo and MkDocs Material site
- Documents local devices, services, storage, and operations
- Connects to other sites via ZeroTier VPN (network d5e5fb65371eb4a4)
- Exposes services externally via Cloudflare tunnels

## Network Diagram

![img](./mermaid-diagram-2025-04-22-130702.png)

[Edit diagram on mermaid.live](https://mermaid.live/edit#pako:eNqtlFFvmzAQx78K8lMiJQwDgQRNe8mk7WXTpE57aLIHxxgX1djINmnTqt99ZwNJO9GtmvbE-Xz3v_PPhx8RVSVDBWpqWTak3csg0ErZeS0t05LZmfMURU2VnFUkqMiSCtWVc-cOAm9Xgmi2hNj5ZTnr9ycSnbvftLqWtz5P8gDnUYjfH_S7D8fWhH4rpKqZ0oGMO6Vvl3e1ZmMjg5rhOycUeyFeW0YuUj_HyBdih47_JmFuvAaOvIirZFpC2XQ6QAJyRLzUaAW731mtTs6YTqxq0YwQK8kdgmwA8LU_X_CJWHZHTt5HqzCmogzHG3kTEloBD-OEeyBXVmnCXzlJSSw5EMPO2UEgicEvVvG42p4OTH_XHb2dXcyeVy1xBBWTAZ8RwYOFTr4BCe_5fGqZ_nGJcIjsMVBCkIZA7HyyO7i_tgPYz7pzlfCxmQ1fLwaq-FnI3yRo1R3iOEpB5WK61tI3i9CK8h11jBPfwbYPGC9vmjVnRJtnJdrKMAnoJY-DzR-nID6PQQ-vT_T27JWWp2bDiH7k8FDMiH8YLyNgvP7fTBkBJAd8b8NmhL_7i4N3Zsk1aV4hIUhrVQsCaIEa-HFJXcLL9-ii98jesIbtUQFmySrSCbtHe_kEoaSz6uokKSqs7tgCadXxG1RURBhYdS2ckn2siSt89rZEXivVjCmsrIHTl_6p9S_uAnHtyg-STJZMb1UnLSqyNPUCqHhE96hI1iFepTjeRHmUxMkGNk-owPEqzFab9WqN02wVZ-vsaYEefMkozJJNnuUYR0ma52m-fvoFJVXP-Q)

## ZeroTier Cross-Site Connectivity

All sites share ZeroTier network `d5e5fb65371eb4a4`:

| node | site | ZeroTier IP | role |
|------|------|-------------|------|
| slwin11ops | sl | 10.147.17.94 | ops workstation |
| mg2 | sl | 10.147.17.135 | Hyper-V Ubuntu VM (Docker) |
| CyberTruck | cf | 10.147.17.219 | workstation / ct-hv |
| nsdockerhb | cf | 10.147.17.176 | Docker host |
| cats-mac-mini | cf | 10.147.17.59 | Mac Mini |
| sg (Synology) | wf | 10.147.17.209 | NAS / CF tunnel endpoint |
| devwin10 | wf | 10.147.17.165 | workstation |

## External Services (Cloudflare Tunnels)

Cross-site view of all public endpoints. Full tunnel configs live in each site repo.

| public hostname | site | service |
|-----------------|------|---------|
| traefik.2cld.com | sl | traefik via mg2 |
| portainer.2cld.com | sl | portainer via mg2 |
| gitea.2cld.com | sl | gitea via mg2 |
| traefik.cat9.me | cf | traefik via nsdockerhb |
| portainer.cat9.me | cf | portainer via nsdockerhb |
| gitea.cat9.me | cf | gitea via nsdockerhb |
| nginx.cat9.me | cf | nginx via nsdockerhb |
| netbox.cat9.me | cf | netbox via nsdockerhb |
| chat.bradnordyke.com | cf | Open WebUI (Ollama) |
| ssh.bradnordyke.com | cf | SSH to WSL |
| rt.bradnordyke.com | cf | Rust test |
| sg.klopfenstein.org | wf | Synology admin portal |
| gitea.klopfenstein.org | wf | Gitea on Synology |
| metube.klopfenstein.org | wf | MeTube on Synology |
| jp.klopfenstein.org | wf | WebDAV |

## Maintenance Pattern

| What to edit | Where |
|---|---|
| Site-specific data (devices, services, IPs) | Site repo ([sl](https://github.com/2cld/sl), [cf](https://github.com/2cld/cf), [wf](https://github.com/2cld/wf)) |
| Architecture, install guides, portal docs | [netstack](https://github.com/2cld/netstack) |
| Cross-site deployment summary | This file (netstack/docs/ops/deployments) |
| MkDocs theme, build workflow, CSS | [ns-site-template](https://gitea.cat9.me/nsadmin/ns-site-template) |
| Node-local monitoring scripts | Site repo `ops/monitor/` |

## Site Build System

All site repos use the same build pattern:
- MkDocs Material theme (dark slate, blue-grey primary)
- GitHub Actions workflow triggers on push to `main`
- Deploys to `gh-pages` branch → GitHub Pages with custom CNAME
- Config at `.mkdocs/mkdocs.yml`, CSS at `.mkdocs/overrides/extra.css`
