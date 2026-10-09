> **GitHub Issue:** [#34 — Cloudflare Access model for federation sites](https://github.com/2cld/netstack/issues/34)
> **Working Branch:** `feedback/issue-34-cloudflare-access-pattern`
> **Contributing:** See [CONTRIBUTING.md](../../../CONTRIBUTING.md)

# Feedback: Cloudflare Access model for federation sites

**Author:** ho-wip (with christrees)
**Date:** 2026-10-09
**Relates to:** [monitor/public-status-endpoint-pattern.md](../monitor/public-status-endpoint-pattern.md), [security/access-monitoring-pattern.md](../security/access-monitoring-pattern.md)
**Site context:** 3-site residential federation (cf Cedar Falls, wf Winfield, sl St. Louis), single Cloudflare account

## Summary

The `public-status-endpoint-pattern` tells each site to serve `status.json` publicly "with a CF Access bypass." That one line hides the actual mechanism — and the mechanism the downstream runbooks *assumed* was wrong. This feedback captures the real-world incident that exposed it and the verified configuration, so the new pattern doc is grounded in what actually worked rather than what the docs guessed.

## The incident (why this exists)

**2026-10-08:** The federation dashboard showed **cf "unreachable."** The operator was literally on the box running cf. Direct probes showed every cf service healthy (gitea 200, hwpc-rp 200, tunnel healthy). So "unreachable" was a false alarm.

**Root cause:** the browser `fetch('https://cf.cat9.me/status.json')` was **302-redirecting to the Cloudflare Access login page**, which fails CORS and throws — rendering as "unreachable." cf's status endpoint was **auth-gated**, not down. It had been that way silently for weeks.

**Why:** pulling the live Access config (all apps + policies via the CF API) showed cf had **no dedicated status app**. `cf.cat9.me` was only covered by a broad domain app (`tunnellockdown`, covering `cat9.me` + several subdomains) whose policies were all allow-email / service-token — **no status/health bypass**. So `/status.json` fell through to "require login."

**The contrast that revealed the fix:** wf and the coordinator (wip) both worked — and both had **dedicated, path-scoped Access apps** (`wf-status` → `wf.klopfenstein.org/status.json`, Bypass/Everyone). Notably, `wip.cat9.me` is *also* inside the broad `tunnellockdown` app, yet its status works — because its path-scoped app overrides the broad one.

## The key finding (the undocumented mechanism)

> **A path-scoped Access application takes precedence over a broad domain application.**

You do **not** fix an auth-gated `/status.json` by adding a Bypass *policy* to the broad app (that would widen the broad app, or not match the path cleanly). You create a **separate Access application scoped to the exact path** (`site.domain/status.json`) with one Bypass/Everyone policy. Cloudflare evaluates the most-specific app, so the broad app no longer gates that path — while `/` and everything else stay protected by the broad app.

This is the whole trick, and it was absent from every existing doc. The prior wip runbooks said "add a bypass policy to the existing app," which is why the gap persisted.

## Verified fix (cf, 2026-10-09)

Created two path-scoped apps mirroring wf:

| App | Scope | Policy |
|-----|-------|--------|
| `cf-status` | `cf.cat9.me/status.json` | Bypass / Everyone |
| `cf-health` | `cf.cat9.me/health` | Bypass / Everyone |

Result (probed):
- `cf.cat9.me/status.json` → **200 · application/json · access-control-allow-origin: \*** ✅
- `cf.cat9.me/health` → **200** ✅
- `cf.cat9.me/` → **302 → CF Access login** (still protected) ✅

## GUI nav notes (real, 2026-10-09 — the UI had moved)

The operator's observations while applying the fix (these corrected stale assumptions):

1. **It is NOT under Networking/Tunnels.** That path (`dash → <acct> → tunnels → <tunnel> → overview`) is **DNS/routing**, not access. A dead end for this task.
2. **The right place:** `dash → Zero Trust → Access controls → Applications` (`.../one/access-controls/apps`).
3. Create new application → **"Continue with Self-hosted and private."**
4. **Subdomain:** `cf` · **Domain:** `cat9.me` · **Path:** `status.json`.
5. **Access policies:** attach a reusable **"Public status endpoints"** Bypass/Everyone policy (create once, reuse per app).
6. **Name:** `cf-status` → Create. Repeat for `cf-health` (path `health`).

## Verification invariant (use on any site)

```bash
# public path — want: 200 + application/json + access-control-allow-origin: *
curl -s -D - -o /dev/null -L https://<site.domain>/status.json \
  | grep -iE "^HTTP/|access-control-allow-origin|content-type"

# protected root — want: STILL 302 to *.cloudflareaccess.com login
curl -sI https://<site.domain>/ | grep -i location
```

## Feedback Items

### Item 1: document the path-scoped-app precedence mechanism
- **Section:** new `security/cloudflare-federation-access-pattern.md`
- **Type:** new-content
- **Detail:** the precedence rule above is the core; without it operators add policies to the broad app and stay broken.

### Item 2: correct the "add a bypass policy" guidance
- **Section:** cross-refs from `monitor/public-status-endpoint-pattern.md` (and downstream wip runbooks `ops-cloudflare-access-setup.md`, `ops-cf-status-deploy.md`)
- **Type:** correction
- **Detail:** those say "bypass policy on the existing app." Replace with "create a path-scoped app."

### Item 3: capture the GUI nav correction
- **Type:** new-content
- **Detail:** Zero Trust → Access controls, NOT Networking/Tunnels. The UI moved; the nav trips people up.

## Proposed Documentation Changes

- NEW: `docs/ops/security/cloudflare-federation-access-pattern.md` (this PR)
- CROSS-LINK: add a reference from `docs/ops/monitor/public-status-endpoint-pattern.md` → the new access pattern (follow-up, kept out of this PR to stay single-topic)

## Discussion

- Naming: is `cloudflare-federation-access-pattern` the right file name, or prefer `access-bypass-pattern` / fold into `access-monitoring-pattern.md`? Kept standalone since it's a distinct mechanism.
- Severity-model aside (out of scope here, noted for the monitor side): a dashboard `fetch()` throw should distinguish *auth-gated* and *not-deployed* from *genuinely down* — all three currently render identically. Tracked downstream (2cld/wip#73).
