# Cloudflare Federation Access Pattern

**Status:** Adopted (wf + coordinator since 2026-08; cf 2026-10-09; sl pending) | **Scope:** every federation site + the coordinator

> **Companion:** this is the *access* half of the [public-status-endpoint-pattern](../monitor/public-status-endpoint-pattern.md). That pattern says "serve `status.json` publicly with a CF Access bypass"; this one documents **how** to configure that bypass correctly in Cloudflare Access without exposing the rest of the site.

## Principle

> **Machine-readable health is public. Everything human-or-sensitive is protected.**

| Path | Access | Why |
|------|--------|-----|
| `/status.json` | 🔓 Bypass (Everyone) + CORS `*` | dashboard `fetch()`, cron, bots, AI/MCP read it without auth |
| `/health` | 🔓 Bypass (Everyone) | infra liveness checks |
| `/` and everything else | 🔒 Protected (owner + named users) | docs/portals expose IPs, schedules, control surfaces |

## The mechanism that actually matters

> **A path-scoped Access application takes precedence over a broad domain application.**

Most federations end up with a **broad domain app** protecting a whole zone (e.g. an app whose domains include `example.com`, `gitea.example.com`, `site.example.com`). That broad app will also gate `site.example.com/status.json` — redirecting it to the Access login.

You do **NOT** fix this by editing the broad app's policies. You create a **separate Access application scoped to the exact path**:

```
Broad app:   site.example.com            → protected (login required)
Scoped app:  site.example.com/status.json → Bypass / Everyone   ← wins for this path
Scoped app:  site.example.com/health      → Bypass / Everyone   ← wins for this path
```

Cloudflare evaluates the **most specific** application for a request, so the path-scoped Bypass app overrides the broad app for `/status.json` and `/health`, while `/` stays protected by the broad app. This is the entire trick — and the common failure mode is trying to add a Bypass *policy* to the broad app instead of creating a scoped *app*.

## Configure it (Cloudflare Zero Trust GUI)

> ⚠️ **Not** under Networking → Tunnels. That is DNS/routing. Access lives under **Zero Trust**.

1. `dash.cloudflare.com` → **Zero Trust** → **Access controls → Applications**
2. **Create new application** → **"Self-hosted and private"**
3. **Subdomain:** `<site>` · **Domain:** `<zone>` · **Path:** `status.json`
   (e.g. subdomain `cf`, domain `cat9.me`, path `status.json` → `cf.cat9.me/status.json`)
4. **Access policies:** attach a **Bypass / Everyone** policy. Create it once as a reusable policy (e.g. named "Public status endpoints") and reuse it for every site's status + health apps.
5. **Name** the app `<site>-status` → **Create**.
6. **Repeat** for `/health` → name `<site>-health`.
7. Leave the broad domain app untouched.

## Verify (the invariant)

```bash
# PUBLIC path — want: HTTP 200 + content-type application/json + access-control-allow-origin: *
curl -s -D - -o /dev/null -L https://<site.domain>/status.json \
  | grep -iE "^HTTP/|access-control-allow-origin|content-type"

# PROTECTED root — want: STILL a 302 redirect to a *.cloudflareaccess.com login URL
curl -sI https://<site.domain>/ | grep -i location
```

A browser `fetch()` of the public path must succeed (no redirect to the Access login). If it 302s to `*.cloudflareaccess.com`, the path-scoped app is missing or mis-scoped.

## Per-site adoption

| Site | Service domain | `<site>-status` / `<site>-health` apps | Status |
|------|----------------|-----------------------------------------|--------|
| coordinator (wip) | `wip.cat9.me` | ✅ `wip-status`, `wip-health` | reference |
| wf | `wf.klopfenstein.org` | ✅ `wf-status`, `wf-health` | reference |
| cf | `cf.cat9.me` | ✅ `cf-status`, `cf-health` | done 2026-10-09 |
| sl | `2cld.com` | ❌ not yet | pending ([2cld/sl#5](https://github.com/2cld/sl/issues/5)) |

## Automation that needs protected paths

Scripts read only the public endpoints. If automation must reach a *protected* path, use a **Cloudflare Access Service Token** (`CF-Access-Client-Id` / `CF-Access-Client-Secret` headers) — never widen a path bypass. A service token authenticates *through* a policy; it is not an API admin credential.

## Common failure modes

| Symptom | Cause | Fix |
|---------|-------|-----|
| Dashboard shows site "unreachable" but services are up | `/status.json` 302s to Access login (browser fetch throws on the cross-origin redirect) | Add the path-scoped `-status` app |
| Added a Bypass policy to the broad app, still gated | Policy on the broad app doesn't beat the broad app's own protect policies for the path | Create a separate path-scoped **app**, not a policy |
| `curl` works but browser fetch fails | missing CORS on the response | ensure the status service sends `access-control-allow-origin: *` (see the status service's nginx/`checker` config) |
| Can't find Access in the dashboard | looking under Networking/Tunnels (DNS) | go to **Zero Trust → Access controls → Applications** |

## Related Patterns

- [monitor/public-status-endpoint-pattern.md](../monitor/public-status-endpoint-pattern.md) — the status endpoint this makes public (the other half)
- [security/access-monitoring-pattern.md](./access-monitoring-pattern.md) — detecting unauthorized access attempts
- [security/sensitive-data-pattern.md](./sensitive-data-pattern.md) — what counts as protected

## Provenance

Grounded in a real 3-site federation and a 2026-10-08/09 incident (cf dashboard false-"unreachable" → auth-gated status endpoint). Feedback doc with the full incident trace: [docs/ops/feedback/2026-10-09-cloudflare-access-pattern.md](../feedback/2026-10-09-cloudflare-access-pattern.md).
