# Pattern: Cloudflare Tunnel Monitoring

**Pattern type:** Federation infrastructure monitoring
**Applies to:** Sites using Cloudflare Tunnels (cloudflared) for public service access
**Related:** [plex-lan-only-pattern](../portals/plex/plex-lan-only-pattern.md), [site-tenant-contract-pattern](../ops/deployments/site-tenant-contract-pattern.md)

## Overview

Federation sites use Cloudflare Tunnels to expose Docker services publicly without opening ports on the router. The tunnel runs as a Docker container (`cloudflared`) connecting to Cloudflare's edge, and Traefik handles per-hostname routing to backend containers.

```
Browser → Cloudflare Edge → Tunnel → cloudflared container → http://traefik:80
  → Traefik routes by Host header → backend container
```

## What to Monitor

### 1. Tunnel Health (Cloudflare API)

```bash
# Check tunnel status
curl -s "https://api.cloudflare.com/client/v4/accounts/<account_id>/cfd_tunnel/<tunnel_id>" \
  -H "Authorization: Bearer <CF_API_TOKEN>" | jq '.result.status, (.result.connections | length)'
```

**Expected:** status = "healthy", connections >= 2

**Alert if:**
- status != "healthy"
- connections = 0 (tunnel completely down)
- connections < 2 (degraded, may lose availability on edge failover)

### 2. Ingress Rules (Cloudflare API)

```bash
# Check tunnel configuration
curl -s "https://api.cloudflare.com/client/v4/accounts/<account_id>/cfd_tunnel/<tunnel_id>/configurations" \
  -H "Authorization: Bearer <CF_API_TOKEN>" | jq '.result.config.ingress'
```

**Expected:** Rules match what's defined in site-config.yml. Typically:
- `*.domain.com` → `http://traefik:80` (wildcard, traefik handles routing)
- catch-all → `http_status:404`

**Alert if:**
- Unexpected rules appear (security concern)
- Expected wildcard rule missing
- Rules point to wrong target (e.g., localhost instead of traefik)

### 3. Service Reachability (HTTP check from external)

```bash
# Check each expected subdomain from outside the network
curl -s -o /dev/null -w '%{http_code}' https://gitea.2cld.com
curl -s -o /dev/null -w '%{http_code}' https://portainer.2cld.com
curl -s -o /dev/null -w '%{http_code}' https://sl.2cld.com
```

**Expected:** 200 or 302 for active services

**Alert if:** 502 (traefik can't reach backend), 522 (tunnel down), 404 (no route)

### 4. Container Health (Docker, from monitoring node)

```bash
# Check cloudflared container running
docker ps --filter name=<tunnel-container-name> --format '{{.Status}}'
```

**Alert if:** Container not running or restarting

## site-config.yml Schema

```yaml
cloudflare:
  enabled: true
  account_id: "<cloudflare-account-id>"
  tunnels:
    - name: "<tunnel-name>"
      tunnel_id: "<uuid>"
      domain: "<domain>"
      container_name: "<docker-container-name>"
      token_location: "<path-to-.env-with-token>"
      
      # Expected ingress (for validation)
      expected_ingress:
        - hostname: "*.<domain>"
          service: "http://traefik:80"
        - service: "http_status:404"
      
      # Services routed through this tunnel (for HTTP checks)
      services:
        - hostname: "gitea.<domain>"
          expected_code: [200, 302]
          critical: true
        - hostname: "portainer.<domain>"
          expected_code: [200, 302]
          critical: false
        - hostname: "sl.<domain>"
          expected_code: [200]
          critical: false

  api_monitoring:
    token_env_var: "CLOUDFLARE_API_TOKEN"
    permissions_needed: "Account > Cloudflare Tunnel > Read"
    check_frequency: "daily (in wip-daily-cron)"
```

## Monitoring Script Integration

### In netstack-status.js (federation-level)

Already implemented — checks tunnel health via API, writes to `.monitor-state.json`.

### In site-status.sh (per-site)

```bash
# Check cloudflared container is running
if docker ps --filter name=sl-2cld --format '{{.Status}}' | grep -q "Up"; then
  echo "✅ Cloudflare tunnel container running"
else
  echo "❌ Cloudflare tunnel container down"
fi
```

### In site-ops verify (config validation)

```bash
# Verify tunnel ingress matches expected
ACTUAL=$(curl -s "$CF_API/cfd_tunnel/$TUNNEL_ID/configurations" -H "Authorization: Bearer $TOKEN")
# Compare against site-config.yml expected_ingress
# Flag any unexpected routes
```

## Human vs Automation Boundary

| Action | Who | Why |
|--------|-----|-----|
| Create/delete tunnel | Human (dashboard) | Security — tunnel tokens are sensitive |
| Add/remove public hostnames | Human (dashboard) | DNS/routing changes affect public access |
| Add DNS CNAME records | Human (dashboard) | Domain configuration |
| Monitor tunnel health | Wip (API) | Automated, read-only |
| Validate ingress rules | Wip (API) | Compare against config, alert on drift |
| Check service HTTP codes | Wip (curl) | Automated health checks |
| Restart cloudflared container | Human (per contract) | Wip may NOT restart services |
| Alert on issues | Wip (issue + email) | Per escalation pattern |

## Alerting

| Condition | Severity | Action |
|-----------|----------|--------|
| Tunnel unhealthy / 0 connections | Critical | Issue on site repo + email admin |
| Service returning 502 | Warning | Issue on site repo (traefik → backend broken) |
| Unexpected ingress rule | Security | Issue on site repo immediately |
| Container not running | Critical | Issue on site repo (check Docker + WSL auto-start) |
| Tunnel degraded (< 2 connections) | Warning | Monitor, may self-recover |

## Related

- [Cloudflare Zero Trust Dashboard](https://one.dash.cloudflare.com/)
- [cloudflared Docker docs](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/install-and-setup/tunnel-guide/local/as-a-service/)
- [netstack#16](https://github.com/2cld/netstack/issues/16) — federation dashboard
- [sl-site-config.yml](https://github.com/2cld/sl) — sl cloudflare section
- [cf-site-config.yml](https://github.com/2cld/cf) — cf cloudflare section (cf-cat9me tunnel)
