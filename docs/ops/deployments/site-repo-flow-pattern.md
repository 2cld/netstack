# Site Repo Flow + Reproducible Build Pattern

**Applies to:** Every federation site (cf, sl, wf). Generic pattern — site-specific
values (IPs, names, hardware) live in each site's private repo as overlays, never here.
**Related:** [site-config-schema.md](./site-config-schema.md), [bmr-pattern.md](./bmr-pattern.md),
[federation-backup-plan.md](../backup/federation-backup-plan.md), [dr-node-topology](./federation-node-topology.md)
**Host path:** the layers below assume the standard Proxmox host path ([netstack#37](https://github.com/2cld/netstack/issues/37)); on a non-Proxmox host (e.g. a Hyper-V VM running Docker directly) the same four layers apply, with the build clone on that host.
**Service layout:** where service compose files, `.env` and data live on the Docker host is defined in [docker-service-subdomain-pattern](../../wan/cloudflare/docker-service-subdomain-pattern.md) (`/opt/appdata/<name>/`). The build clone deploys into it.
**Origin:** wf BMR test-flight (2cld/wip#48, netstack#32) — validated by walking the docs as a human would.

---

## Core Philosophy

**Reproducible, air-gap-capable, version-pinned. Updates are a deliberate human act, never implicit.**

A rebuild (BMR) must reproduce *the system that was working* — not "whatever is newest today."
Newest-today is how you rebuild mid-disaster and discover a new package broke your stack.

Three tenets:
1. **Air-gap first** — a node can be rebuilt with ZERO network, everything from a DR USB.
   Online rebuild is the *fallback*, not the primary path.
2. **Pin everything** — Debian point-release, LXC template versions, container image tags,
   service versions. No `:latest`. The repo + USB are the source of truth for *versions*, not just config.
3. **Updates are deliberate** — "update node X" is its own reviewed task. It is NEVER a
   side-effect of a rebuild. `apt dist-upgrade` is gated, not automatic.

> **The USB is a golden image. Keeping it current is intentionally a slow, deliberate, manual
> human process** — that friction IS the deliberate-update gate. You cannot accidentally drift
> the golden image because refreshing it requires sitting down and doing it on purpose.

---

## The Four Repo Layers

Every site's repo exists in up to four places. **Change always flows DOWN from GitHub.
Never edit layers 2-4 directly — they are cattle, regenerated from the source of truth.**

```
┌──────────────────────────────────────────────────────────────────────┐
│ 1. GITHUB (source of truth)         github.com/2cld/<site>            │
│    The canonical repo. All edits land here (via PR).                   │
└───────────────┬────────────────────────────────────────────────────────┘
                │ clone / pull
                ▼
┌──────────────────────────────────────────────────────────────────────┐
│ 2. WORKING CLONE (edit here)        ops controller / dev machine       │
│    Humans + Wip edit, commit, push. The only place you EDIT.           │
└───────────────┬────────────────────────────────────────────────────────┘
                │ (a) baked onto DR USB    (b) git pull on host
                ▼
┌──────────────────────────────────────────────────────────────────────┐
│ 3. BUILD CLONE (run scripts from)   Proxmox host  /root/<site>         │
│    Persistent clone on the host, used to run BMR/deploy scripts.       │
│    Refreshed via `git pull` before a build (online) OR copied whole    │
│    from the DR USB (air-gap). Never edited by hand.                    │
└───────────────┬────────────────────────────────────────────────────────┘
                │ auto-pull (hourly)
                ▼
┌──────────────────────────────────────────────────────────────────────┐
│ 4. CONTAINER CLONE (serves docs)    site-docs container  /srv/repo     │
│    Auto-pulls from GitHub, builds MkDocs + status.json, nginx serves   │
│    the published site + health/status endpoints. Fully automated.      │
│    Reaching it is 3 hops: host → pct exec <lxc> → docker exec site-docs │
└──────────────────────────────────────────────────────────────────────┘
```

**Why whole-repo copy (not partial):** the repo is a few MB of markdown/bash/yaml. Copying
all of it to the build host is free and guarantees completeness — no "the script references a
file that wasn't copied." Aligns with "the site repo contains ALL configs; pull nothing unknown."

**Each layer can independently drift from GitHub.** A rebuild reconciles them. If the published
site (layer 4) looks stale, check what commit `/srv/repo` is on — the auto-pull may be stuck.

---

## Base Scripts + Env Overlay (generic pattern, unique data)

The build scripts are **generic**; the site's values are a **thin overlay**:

| Layer | What | Generic or site-specific |
|-------|------|--------------------------|
| `ops/templates/base/dr-usb-bootstrap.sh` | Air-gap bootstrap (site-select, repo-copy, post-install, keys, ZT, templates) | **Generic** (reads the env) |
| `ops/templates/base/proxmox-post-install.sh` | Vanilla PVE cleanup + federation extras (repos, nag, HA-disable, IOMMU, keys, service dirs) | **Generic** (reads the env) |
| `ops/templates/lxc/docker-host.sh` | Build the Docker LXC + breadcrumb | **Generic** (reads the env) |
| `ops/templates/site/<site>.env` | IPs, names, hardware, pinned versions, keys | **SITE OVERLAY** — the unique data |

So: run a generic script, it `source`s the site `.env`, it does the right thing for that site.
The pattern lives in netstack (how); the `.env` lives in the site repo (what).

---

## BMR Entry Paths

### PRIMARY: Air-gap USB (reproducible, offline, reviewed)

Everything from the DR USB — no internet, nothing mystery-fetched. The USB carries:
`repo/<site>/` (whole repo) · `secrets/` (keys, PAT, ZT identity) · `iso/` (LXC templates) ·
`site-env/<site>.env` · `dr-bootstrap.sh`.

```
1. Boot fresh Proxmox from USB partition 1 (pinned PVE ISO)
2. mount LABEL=DR-DATA /mnt/dr-usb
3. bash /mnt/dr-usb/dr-bootstrap.sh   → site-select, copies repo, runs post-install,
                                         deploys keys, restores ZT identity, loads templates
4. (reboot for IOMMU) → create LXC(s) → deploy services → import data → validate
```
No `dist-upgrade` reaching out. No `curl|bash` of unknown remotes. Reproducible.

### FALLBACK: Online (convenience, still pinned)

When you have network + no current USB. Allowed to pull, but **still installs pinned versions
from the env** — not `latest`. Two-step bootstrap:
```
1. Vanilla PVE cleanup (public, no auth):
   bash -c "$(wget -qLO - https://github.com/community-scripts/ProxmoxVE/raw/main/misc/post-pve-install.sh)"
2. Get our (private) repo + run our scripts:
   apt-get install -y git
   git clone https://<PAT>@github.com/2cld/<site>.git /root/<site>
   cd /root/<site>/ops/templates && source site/<site>.env
   bash base/proxmox-post-install.sh   # our extras, pinned
```
Online is a convenience, not the standard. Prefer the USB.

---

## Keeping the USB Current (the deliberate PITA)

By design, refreshing the golden USB is a manual, periodic, human ritual — NOT automated.
This friction is the deliberate-update gate.

Checklist (run periodically / after a validated change):
- [ ] `git pull` the site repo onto the USB `repo/<site>/`
- [ ] Refresh pinned LXC templates in `iso/` (only when deliberately bumping)
- [ ] Refresh the PVE ISO on partition 1 (only on deliberate PVE version bump)
- [ ] Verify `secrets/` current (PAT not expired, ZT identity, buadmin key)
- [ ] Update `site-env/<site>.env` pinned versions if deliberately bumping
- [ ] Record "USB refreshed <date>, repo @ <commit>" in the DR log
See the site's `dr-usb-build.md` + `dr-kit.md`.

---

## Version Pinning Rules

| Thing | Pin where | Rule |
|-------|-----------|------|
| PVE ISO | DR USB partition 1 | Bump only on deliberate PVE upgrade |
| Debian / apt packages | (gated) | `dist-upgrade` is NOT automatic in rebuild; deliberate task |
| LXC templates | `iso/` on USB + `<site>.env` | Pinned filename, no "latest template" |
| Container images | service `docker-compose.yml` + `<site>.env` | Pinned tags. **NO `:latest`.** |
| Service versions | `<site>.env` (`GITEA_VERSION`, etc.) | Explicit |

> **Audit:** any `:latest` tag or ungated `dist-upgrade` in a build path is a bug against this pattern.

---

## Related

- [bmr-pattern.md](./bmr-pattern.md) — the rebuild runbook structure
- [site-config-schema.md](./site-config-schema.md) — the config this reads
- [federation-backup-plan.md](../backup/federation-backup-plan.md) — what gets backed up for restore
- [service-recovery-pattern.md](../backup/service-recovery-pattern.md) — per-service restore
- [docker-service-subdomain-pattern](../../wan/cloudflare/docker-service-subdomain-pattern.md) — service routing, appdata layout, backup rules
- Site instance: each repo documents its actual layer paths (e.g. wf: working=`~/code/wf` on nsdockerhv, build=`/root/wf` on wf-cg, container=`/srv/repo` in site-docs LXC 109)
