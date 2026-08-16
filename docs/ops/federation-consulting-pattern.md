# Federation Consulting Pattern: How Patterns Propagate Across Sites

**Status:** Active (formalized 2026-08-16)
**Companion:** [pattern-workflow.md](./pattern-workflow.md) — how patterns get created
**This doc:** how patterns get adopted across federation sites

---

## Core Premise

> Maintainability IS disaster recovery. If you can maintain it, you can recover it. Patterns are the vehicle for both.

The federation consulting model treats every operational pattern as both a maintenance procedure AND a recovery instruction. If the pattern is clear enough to maintain, it's clear enough to rebuild from bare metal.

---

## The Propagation Cycle

```
1. WANT   → Consultant (Wip) identifies something useful for the federation
2. BUILD  → Develop on ONE site (proof-of-concept, working code)
3. EXTRACT → Pattern works? Extract to netstack + ns-site-template
4. WAIT   → Don't push to other sites. Wait for a natural trigger.
5. ADOPT  → During maintenance window, introduce alongside requested work
6. REINFORCE → Repetition across sites builds muscle memory in humans
```

### The Triggers (when to adopt at a new site)

| Trigger | Example |
|---------|---------|
| User requests a new service | "I want Plex at wf" → deploy with monitoring pattern |
| Maintenance cycle touches the site | Quarterly review → add status endpoint |
| Learning moment (human is in context) | Fixing a backup → introduce backup-state pattern |
| Disaster recovery event | Site rebuild → full pattern stack from scratch |

### What is NOT a trigger

- "We built it for cf, let's push to sl too" (no user context)
- "The pattern is ready, every site should have it" (tech push, not user pull)
- "It's been 3 months since we updated sl" (calendar, not need)

---

## Why Three Sites Minimum (Quorum)

| Count | What it means | Pattern status |
|-------|--------------|----------------|
| 1 site | Experiment | Draft — might not generalize |
| 2 sites | Coincidence | Validated — probably works elsewhere |
| 3 sites | Pattern | Proven — document in netstack, add to template |

Three sites also provides:
- **Backup resilience:** N+1 minimum for DR (data exists in 2+ places)
- **Pattern variation:** exercises the pattern under different constraints (Linux/Windows, residential/commercial, different ISPs)
- **Human diversity:** multiple operators validates the docs are followable by someone who didn't write them

---

## The BMDR Principle (Bare Metal Disaster Recovery)

> If you can't push-button rebuild, you haven't documented the pattern well enough.

Backups must contain:
1. **Data** (the obvious part)
2. **Scripts** (how to restore and configure)
3. **Config** (`.site-config.yml`, `checks.yml`, `docker-compose.yml`)
4. **Docs** (which patterns to follow, in what order)

The recovery sequence is:
```
1. Hardware + OS (manual or PXE — documented in site ops/)
2. Network (ZeroTier join — scripted)
3. Docker services (docker compose up — scripted)
4. Data restore (pull from backup site — scripted)
5. Monitoring (site-status comes up automatically with Docker)
6. Verification (status.json reports ok from outside)
```

If any step requires undocumented knowledge, the pattern is incomplete.

---

## Human Learning Constraints

Patterns propagate at human speed, not at deployment speed.

### Rules for introducing patterns to site users

1. **One pattern per maintenance window.** Don't stack changes.
2. **Attach to something they asked for.** The pattern rides alongside a feature request.
3. **Show, don't document.** Walk through it once, then leave the docs as reference.
4. **Expect forgetting.** The pattern must survive 6 months of non-use. That's what the scripts + config are for.
5. **Reinforce through repetition.** Same structure at every site → muscle memory → "oh, it's the same as cf."

### Anti-patterns (don't do these)

- ❌ Push a new monitoring stack to a site nobody is actively using
- ❌ Rewrite a working setup to match a pattern (if it works, wait for the next change)
- ❌ Document a pattern but never implement it (patterns come from working code, not theory)
- ❌ Assume a user read the docs (they didn't — show them during the work)

---

## The Consulting Relationship

```
Wip (consultant) ←→ Site (client)
     │                    │
     │ Proposes patterns  │ Requests services
     │ Tracks readiness   │ Reports problems
     │ Schedules work     │ Approves changes
     │ Documents results  │ Uses the system
     │                    │
     └────────────────────┘
           .wip-contract.md defines the boundary
```

Wip does NOT unilaterally change sites. Every site has a `.wip-contract.md` that defines:
- What Wip is responsible for
- What requires user approval
- Communication method for recommendations
- Escalation path for problems

---

## Pattern Lifecycle (full example)

### Example: Public Status Endpoint

| Phase | Date | What happened |
|-------|------|--------------|
| WANT | 2026-07 | SSH monitoring failing at wf (Permission denied daily) |
| BUILD | 2026-08-06 | Built site-status Docker service on wf (LXC 109) |
| VALIDATE | 2026-08-13 | wf.klopfenstein.org/status.json live, cron reads it |
| EXTRACT | 2026-08-13 | Documented in netstack (public-status-endpoint-pattern, site-status-service-pattern) |
| WAIT | 2026-08-14 | cf#4 issue created, but not pushed — waited for active work |
| ADOPT (cf) | 2026-08-16 | During active cf session, deployed cf.cat9.me/status.json |
| WAIT | now | sl adoption waits for sl maintenance window |
| Template | pending | Add to ns-site-template as standard site service |

### What makes this a good propagation

- ✅ Started from a real problem (SSH failures)
- ✅ Solved at one site first (wf)
- ✅ Pattern extracted before pushing to second site
- ✅ Second site adopted during active work session (not cold-pushed)
- ✅ Third site (sl) explicitly waiting for trigger
- ✅ Recovery is built-in (Docker compose + checks.yml = rebuild in 5 min)

---

## Where This Pattern Gets Used

| Context | How |
|---------|-----|
| netstack | This document — the WHY behind pattern propagation |
| Wip process | `docs/ops-federation-consulting.md` — operational guide for Wip |
| Site repos | `.wip-contract.md` — defines the consulting boundary per site |
| ns-site-template | Template structure that embodies all patterns (the WHAT) |
| Weekly review | Wip checks: which sites have pending patterns? Any triggers? |

---

## Related

- [pattern-workflow.md](./pattern-workflow.md) — how patterns get created and followed
- [site-status-service-pattern](./monitor/site-status-service-pattern.md) — example of a propagated pattern
- [public-status-endpoint-pattern](./monitor/public-status-endpoint-pattern.md) — adoption status across sites
- [site-tenant-contract-pattern](./deployments/site-tenant-contract-pattern.md) — .wip-contract.md structure
- [ns-site-template](https://gitea.cat9.me/netstack/ns-site-template) — the template that embodies all patterns
