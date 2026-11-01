# Pattern: Docker Service on `<name>.<domain>` (Cloudflare Tunnel → Traefik)

**Pattern type:** Service deployment
**Applies to:** Any federation site that runs Docker + Traefik + a `cloudflared` tunnel (reference site: cf, domain `cat9.me`)
**Related:** [site-repo-flow-pattern](../../ops/deployments/site-repo-flow-pattern.md) (rebuild/BMR, version pinning), [cloudflare-tunnel-monitoring-pattern](./cloudflare-tunnel-monitoring-pattern.md), [site-docs-generator-pattern](../../ops/deployments/site-docs-generator-pattern.md)

## Overview

One tunnel, one reverse proxy, one wildcard cert. Adding a service is: a compose file with Traefik labels, a DNS CNAME, and a tunnel ingress entry. Nothing else.

```
Browser → Cloudflare edge (proxied CNAME) → tunnel → cloudflared container
  → https://traefik:443 (Host header preserved) → Traefik router by Host(`<name>.<domain>`)
  → backend container on the `proxy` docker network
```

## Fixed components (set up once per site)

| Component | Rule |
|-----------|------|
| Docker network | External network `proxy`. Traefik, cloudflared and every routed service join it. |
| Traefik | Docker provider, `exposedByDefault: false`. Entrypoints `http` (→ https redirect) and `https`. |
| TLS | Wildcard `*.<domain>` from the `cloudflare` ACME DNS-challenge resolver (token in a Docker secret/`.env`, never in compose). |
| cloudflared | `tunnel run`, token from `.env` (`TUNNEL_TOKEN=${CLOUDFLARE_TUNNEL_TOKEN}`), on the `proxy` network. |
| Tunnel ingress | Remotely managed (Zero Trust dashboard / API). |

## ZeroTier clients: local name override (split horizon)

Cloudflare's filters flag/challenge traffic coming from ZeroTier-network clients. To avoid that, ZeroTier clients resolve `<name>.<domain>` locally (hosts file or local DNS) to the Docker host's ZeroTier IP (cf: `10.147.17.176`) and hit Traefik directly on 443, using the same wildcard cert. Public clients use the Cloudflare tunnel path above.

```
ZeroTier client → local override → 10.147.17.176:443 → Traefik → container
Public client   → Cloudflare DNS → tunnel → https://traefik:443 → Traefik → container
```

Consequences:
- Local DNS answers (private IP, `pile.cat9.me` alias) differ from Cloudflare's; audit Cloudflare via the API, not `dig` from a ZeroTier host.
- A service can work for ZeroTier clients while its tunnel ingress is broken (and vice versa). Test both paths: `curl --resolve <name>.<domain>:443:<zt-ip> https://<name>.<domain>` and the public path from a non-ZeroTier network.
- Each new service needs the override added wherever it is maintained (record that location in the site's services doc).

## Host layout (LinuxServer.io appdata convention)

Every service lives in one folder under a single appdata root. Default root: `/opt/appdata` (override per host with `DATA_ROOT`).

```
/opt/appdata/<name>/
    compose.yml      # copied from the owning repo (see "Where compose files live")
    .env             # secrets, chmod 600, never in git
    config/          # app configuration (bind mount)
    data/            # app state: databases, uploads (bind mount)
```

Rules:
- `~/code` holds git repos only. No service data, no secrets, no live compose files.
- Persistent data uses **bind mounts** under `${DATA_ROOT:-/opt/appdata}/<name>/`. Named volumes are only for rebuildable output (generated sites, caches).
- Containers run with `PUID`/`PGID` (the service owner, e.g. 1000:1000) where the image supports it, so files in appdata are owned by a normal user.
- Large media/shares (NAS) are mounted from `/media/<share>` and are not part of appdata.
- Traefik is a service like any other: `/opt/appdata/traefik/` holds `config/traefik.yaml`, `config/dynamic/`, `acme.json` (600) and `logs/`.

### Where compose files live

| What | Source of truth | Deployed to |
|------|-----------------|-------------|
| App with its own repo (e.g. tte) | `deploy/docker-compose.yml` + `deploy/example.env` in that repo | `/opt/appdata/<name>/compose.yml` |
| Site service (site-status, wip-site) | `ops/services/<name>/` in the site repo (cf, wip) | `/opt/appdata/<name>/compose.yml` |
| Infrastructure (traefik, cloudflared, gitea, portainer) | `ops/services/<name>/` in the site repo | `/opt/appdata/<name>/compose.yml` |

A separate catch-all `docker-compose` repo is not used: compose files are versioned with the thing they deploy. Use one compose file per service; the repo-root `docker-compose.yml` (if any) is for **offline/local use** (e.g. a meet with no internet: published port, no Traefik, no tunnel) and `deploy/docker-compose.yml` is for the tunnel/Traefik deployment.

### Backup

- Back up `/opt/appdata` (not `~/code`). Exclude `*/logs/`, caches and rebuildable named volumes.
- Never copy a live database. Dump first: `pg_dump` for Postgres, `sqlite3 <db> ".backup <file>"` for SQLite, or `docker compose stop` for the copy window.
- Use a snapshotting tool (restic or borg) with retention, and push a copy to the other federation sites.
- `.env` files and `acme.json` are secrets: include them in the encrypted backup only.
- A backup is not done until a restore of one service has been tested.

## Per-service recipe

### 1. Compose file (source in the owning repo, deployed to `/opt/appdata/<name>/compose.yml`)

No `ports:` publishing. Traefik is the only entry point.

```yaml
services:
  <name>:
    image: <image>
    container_name: <name>
    restart: unless-stopped
    networks: [proxy]
    volumes:
      - ${DATA_ROOT:-/opt/appdata}/<name>/data:/app/data
    labels:
      - traefik.enable=true
      - traefik.docker.network=proxy
      - traefik.http.routers.<name>.rule=Host(`<name>.<domain>`)
      - traefik.http.routers.<name>.entrypoints=https
      - traefik.http.routers.<name>.tls=true
      - traefik.http.routers.<name>.tls.certresolver=cloudflare
      - traefik.http.services.<name>.loadbalancer.server.port=<container port>

networks:
  proxy:
    external: true
```

Pin the image tag (`image: <image>:<version>`, version from `.env`). No `:latest`; see [site-repo-flow-pattern](../../ops/deployments/site-repo-flow-pattern.md#version-pinning-rules). Updates are a deliberate act.

Two compose files per app when it must also run offline: the repo-root `docker-compose.yml` is for **local/offline events** (published port, no Traefik, no tunnel); `deploy/docker-compose.yml` is the tunnel/Traefik deployment (this recipe) and is the one copied to `/opt/appdata/<name>/compose.yml`.

Multi-container projects: only the web-facing container gets labels. Name routers/services `<name>` (no `-secure` suffixes, no duplicate http router; the entrypoint redirect handles port 80).

### 2. DNS (Cloudflare zone)

`CNAME <name>` → `<tunnel-id>.cfargotunnel.com`, **proxied**. (Or `cloudflared tunnel route dns`.)

### 3. Tunnel ingress (Zero Trust → Networks → Tunnels → Public hostnames)

| Hostname | Service | Origin request |
|----------|---------|----------------|
| `<name>.<domain>` | `https://traefik:443` | No TLS Verify = on |

**Origin request settings (required):** set **Origin Server Name** = `<name>.<domain>` (preferred: cloudflared connects to `traefik` but the cert is `*.<domain>`, so without this the TLS name check fails and Cloudflare returns 502). Fallback: **No TLS Verify** = on. Leave HTTP Host Header unset so Traefik sees the original `Host`. Do **not** turn TLS off; the origin is `https://traefik:443`.

**Rule order matters:** ingress rules are matched **top to bottom, first match wins**. A wildcard rule (`*.<domain>`) matches every hostname listed below it, so those rules never run. Keep no wildcard rule (preferred), or put it last, just above the final `http_status:404`. New hostnames go anywhere above it.

Always target the container name `traefik` on the `proxy` network. **Never** use a host IP such as `https://192.168.x.x`; it breaks when the host's LAN address changes.

### 4. Deploy and verify (both paths)

```bash
mkdir -p /opt/appdata/<name>/data
cd /opt/appdata/<name> && docker compose up -d
docker logs traefik 2>&1 | grep <name>
# Public path (Cloudflare tunnel) - run from a host WITHOUT a local override for <name>:
curl -sI https://<name>.<domain>     # expect 200/302, server: cloudflare
# ZeroTier path (direct to Traefik):
curl -sI --resolve <name>.<domain>:443:<zt-ip> https://<name>.<domain>
# Tunnel errors:
docker logs --tail 20 cf-cat9me      # check ingressRule=N and originService for the failing request
```

### 5. Document

1. Add a row to the site repo's `docs/services.md` (published at `<site>.<domain>`).
2. Add a check to the site's `checks.yml` if the service is operational-tier.

## Cleanup / audit checklist

- Every proxied DNS CNAME has a matching tunnel ingress entry, and every ingress hostname has a DNS record.
- No wildcard ingress rule above a specific hostname (first match wins); every Traefik origin has Origin Server Name set (or No TLS Verify).
- Every ingress service is `https://traefik:443` (or `http://traefik:80`), except deliberate non-Traefik origins, which must be listed in the site's services doc with a reason.
- Every running container with `traefik.enable=true` has a DNS record and ingress entry.
- No `:latest` image tags; versions pinned.
- Compose files contain no secrets (tunnel token, API tokens); use `.env` (git-ignored, 600).
- One Traefik config directory (`/opt/appdata/traefik/config`), one source of truth.
- Persistent data is under `/opt/appdata/<name>/`, not `~/code` and not a hidden named volume.
- Compose source is in the owning repo, not a catch-all `docker-compose` repo.
- Services publishing host ports are internal-only (ZeroTier/LAN) and documented as such.

## Audit commands

```bash
# Router rules of running containers
docker ps -q | xargs -I{} docker inspect {} --format '{{.Name}} {{range $k,$v := .Config.Labels}}{{if eq $k "traefik.enable"}}enabled{{end}}{{end}}'

# Tunnel ingress (account token with Cloudflare Tunnel:Read)
curl -s -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
  https://api.cloudflare.com/client/v4/accounts/$CLOUDFLARE_ACCOUNT_ID/cfd_tunnel/$TUNNEL_ID/configurations \
  | jq -r '.result.config.ingress[] | "\(.hostname) -> \(.service)"'

# DNS records (zone token with DNS:Read)
curl -s -H "Authorization: Bearer $CF_ZONE_READ_TOKEN" \
  "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?per_page=200" \
  | jq -r '.result[] | "\(.type) \(.name) -> \(.content)"'
```
