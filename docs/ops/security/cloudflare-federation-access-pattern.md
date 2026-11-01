# Cloudflare Federation Access Pattern

**Status:** Adopted (wf + coordinator since 2026-08; cf 2026-10-09; sl pending). Default-deny lockdown + verification added 2026-11-01 ([netstack#38](https://github.com/2cld/netstack/issues/38)) | **Scope:** every federation site + the coordinator

> **Companion:** this is the *access* half of the [public-status-endpoint-pattern](../monitor/public-status-endpoint-pattern.md). That pattern says "serve `status.json` publicly with a CF Access bypass"; this one documents **how** to configure that bypass correctly in Cloudflare Access without exposing the rest of the site.

## Principle

> **Machine-readable health is public. Everything human-or-sensitive is protected.**

| Path | Access | Why |
|------|--------|-----|
| `/status.json` | 🔓 Bypass (Everyone) + CORS `*` | dashboard `fetch()`, cron, bots, AI/MCP read it without auth |
| `/health` | 🔓 Bypass (Everyone) | infra liveness checks |
| `/` and everything else | 🔒 Protected (owner + named users) | docs/portals expose IPs, schedules, control surfaces |

## Default deny: every hostname is locked unless listed

> **No hostname is public by accident.** A new tunnel hostname is born locked; opening a path is a deliberate, listed exception.

**Design**

1. **One wildcard lockdown app per zone** (e.g. `cat9-lockdown`: `*.cat9.me` + the apex `cat9.me`) with the `owners` policy. A new `<name>.cat9.me` is protected the moment its DNS record exists, with no Access change needed. (A hostname-by-hostname list only protects hostnames someone remembered to add; that is how most of a site ends up exposed.)
2. **Per-hostname apps only when the audience or session differs** (e.g. admin tools with an 8h session). More specific apps win over the wildcard.
3. **Path-scoped Bypass apps** (below) for `/status.json`, `/health` and nothing else, except documented exceptions such as the Gitea registry `/v2/` (container clients cannot do an interactive login; the registry still enforces its own token).
4. **Naming:** `<site>-lockdown`, `<site>-<service>` (per-host), `<site>-<service>-<path>` (bypass, e.g. `cf-status`, `cf-health`).

**Policies (create once as reusable policies, attach by reference):**

| Policy | Decision | Include | Attach to |
|--------|----------|---------|-----------|
| `owners` | Allow | named owner emails (`email`) + domains we control (`email_domain`, e.g. `horseoff.com`) | the lockdown app and per-host apps |
| `public-readonly` | Bypass | Everyone | **only** the path-scoped bypass apps |
| `svc-<consumer>` | Service Auth (non_identity) | one named service token | **one** app/host that consumer needs |

Rules:
- Allowed identities are people and domains we control. Do not carry over third-party domains (e.g. a client's domain) that were approved for a different site; grant named individuals instead.
- Use the **`email_domain`** selector for a domain. An **`email`** rule with the value `@example.com` matches only that literal string, i.e. nobody (a real mistake found in the cf audit).
- A service token's policy is attached to the single app it needs, **not** to the wildcard lockdown app, or the token opens every hostname. Rotate tokens per [netstack#22](https://github.com/2cld/netstack/issues/22).
- Restrict **Allowed identity providers** to the ones in use; enable auto-redirect when there is exactly one.

**Sessions:** admin and control surfaces (Traefik, Portainer, Cockpit, Gitea admin) **8-24h**; everything else **24h**; avoid 730h. Longer means a stolen browser stays logged in for a month.

**What stays outside Access:** direct ZeroTier access to Traefik (split-horizon hosts overrides) never passes through Cloudflare, so Access does not apply to it. Those services keep their own authentication (Traefik basic auth, app login) and ZeroTier membership is the network boundary. Do not rely on Access alone for an admin tool.

**Exposed data:** public `/status.json` and `/health` are read-only and must contain no internal IPs, credentials or action endpoints (wf lesson, [netstack#21](https://github.com/2cld/netstack/issues/21)).

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

## Verify (the invariant) and monitor it

Use the verification script, `verify-access.sh` (reference copy: `ops/services/site-status/` in the cf repo), driven by a per-site `access-policy.conf` that lists every hostname and its only allowed unauthenticated paths:

```
cf.cat9.me      /status.json /health     # intentional bypass
gitea.cat9.me   /v2/=401                 # registry; expected status after '='
tte.cat9.me                              # fully locked
```

For each hostname it asserts, **as the public sees it** (names resolved over DNS-over-HTTPS via `curl --doh-url`, so a local `/etc/hosts` split-horizon override cannot hide a hole):

| Check | Expected |
|-------|----------|
| `GET /` | 302 to `*.cloudflareaccess.com` |
| `GET /__access_probe__` (arbitrary path) | 302 to Access (catches path-scoped apps that leave the rest open) |
| each listed bypass path | NOT an Access redirect, expected status (default 200) |

Output ends with `ACCESS OK n/n` or `ACCESS FAIL k/n: <hosts>` (exit 0/1). It is read-only, needs no credentials and takes about 1 s for 13 hosts.

**Monitoring:** run it from the site-status checker as a `command` check (`expect_contains: "ACCESS OK"`) so a newly exposed hostname turns the site status red. Add the hostname to `access-policy.conf` in the same change that adds its tunnel route. See the cf repo's `checks.yml` for the entry.

Manual equivalents:

```bash
# PUBLIC path - want: HTTP 200 + content-type application/json + access-control-allow-origin: *
curl -s -D - -o /dev/null -L https://<site.domain>/status.json \
  | grep -iE "^HTTP/|access-control-allow-origin|content-type"

# PROTECTED root - want: STILL a 302 redirect to a *.cloudflareaccess.com login URL
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
| New hostname answers 200/401 to anyone | no Access app covers it (hostname-list apps do not cover new names) | wildcard lockdown app; `verify-access.sh` catches it |
| Added a Bypass policy to the broad app, still gated | Policy on the broad app doesn't beat the broad app's own protect policies for the path | Create a separate path-scoped **app**, not a policy |
| `curl` works but browser fetch fails | missing CORS on the response | ensure the status service sends `access-control-allow-origin: *` (see the status service's nginx/`checker` config) |
| Can't find Access in the dashboard | looking under Networking/Tunnels (DNS) | go to **Zero Trust → Access controls → Applications** |

## Related Patterns

- [monitor/public-status-endpoint-pattern.md](../monitor/public-status-endpoint-pattern.md) — the status endpoint this makes public (the other half)
- [security/access-monitoring-pattern.md](./access-monitoring-pattern.md) — detecting unauthorized access attempts
- [security/sensitive-data-pattern.md](./sensitive-data-pattern.md) — what counts as protected

## Provenance

Grounded in a real 3-site federation and a 2026-10-08/09 incident (cf dashboard false-"unreachable" → auth-gated status endpoint). Feedback doc with the full incident trace: [docs/ops/feedback/2026-10-09-cloudflare-access-pattern.md](../feedback/2026-10-09-cloudflare-access-pattern.md).
