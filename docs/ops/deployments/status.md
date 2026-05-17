[edit](https://github.com/2cld/netstack/edit/master/docs/ops/deployments/status.md)
# Federation Status

Public health summary for the 2cld federation. Updated periodically from node monitoring scripts.

---

**[PASS] OPERATIONAL** — 3/3 sites online | Last updated: 2026-05-17

---

## Sites

| Site | URL | Status | Last Checked |
|------|-----|--------|--------------|
| sl (St. Louis) | [sl.2cld.net](https://sl.2cld.net) | UP | 2026-05-17 |
| cf (Cedar Falls) | [cf.2cld.net](https://cf.2cld.net) | UP | 2026-05-17 |
| wf (Winfield) | [wf.2cld.net](https://wf.2cld.net) | UP | 2026-05-17 |

## Public Services

| Service | Domain | Status | Site |
|---------|--------|--------|------|
| Traefik | traefik.cat9.me | UP (auth) | cf |
| Gitea | gitea.cat9.me | UP | cf |
| Portainer | portainer.cat9.me | DOWN (502) | cf |
| Nginx | nginx.cat9.me | UP | cf |
| Netbox | netbox.cat9.me | UP | cf |
| Traefik | traefik.2cld.com | DOWN | sl |
| Portainer | portainer.2cld.com | DOWN | sl |
| Gitea | gitea.2cld.com | DOWN | sl |
| Synology | sg.klopfenstein.org | DOWN | wf |
| Gitea | gitea.klopfenstein.org | DOWN | wf |
| MeTube | metube.klopfenstein.org | DOWN | wf |

## Cross-Site VPN

| Path | Status | Notes |
|------|--------|-------|
| cf ↔ sl | Partial | sl ops node online, compute VM offline |
| cf ↔ wf | DOWN | wf storage node offline |
| sl ↔ wf | DOWN | wf storage node offline |

## Known Issues

| Issue | Since | Impact |
|-------|-------|--------|
| sl compute VM offline | ~3 months | sl tunnel services (*.2cld.com) down |
| wf storage node offline | ~1 month | wf tunnel services (*.klopfenstein.org) down |
| cf portainer backend | current | Container down on Docker host, tunnel returns 502 |

## How This Page Is Updated

This page is generated from the monitoring scripts running on each node's admin workstation. The detailed status (with internal IPs and diagnostics) lives in each site's private repo under `docs/status.md`.

To regenerate from cf node:
```
powershell -ExecutionPolicy Bypass -File ops\monitor\generate-status.ps1
```

Then manually update this public summary with scrubbed results.
