# Pattern Workflow: How Netstack Drives Federation Operations

**Netstack is the bible.** It holds the Why, How, and Where for all digital services in the federation. Site repos (cf, sl, wf) hold site-specific values. Wip handles coordination.

## The Principle

```
netstack  = WHY + HOW + WHERE  (patterns, guides, architecture)
cf/sl/wf  = WHAT               (site-specific config, devices, IPs, services)
wip       = WHEN + WHO         (coordination, scheduling, routing, contracts)
```

No site repo should contain explanations of *how* something works or *why* a decision was made. Those live in netstack. Site repos contain the values that make a pattern concrete at that location.

## The Workflow

When a problem arises during federation work:

```
┌─────────────────────────────────────────────────────────┐
│ 1. PROBLEM ARISES                                       │
│    (need to set up a node, fix a backup, wire a tool)   │
└────────────────────────┬────────────────────────────────┘
                         ▼
┌─────────────────────────────────────────────────────────┐
│ 2. CHECK NETSTACK                                       │
│    Does a pattern doc exist?                            │
│    Search: netstack.org/docs/ops/                       │
└──────────┬──────────────────────────────┬───────────────┘
           │ YES                          │ NO
           ▼                              ▼
┌──────────────────────┐    ┌─────────────────────────────┐
│ 3a. FOLLOW PATTERN   │    │ 3b. RESEARCH + DOCUMENT     │
│ Link it in the work  │    │  - Research the solution    │
│                      │    │  - Test it                  │
│                      │    │  - Write pattern in netstack│
│                      │    │  - Then proceed to 3a       │
└──────────┬───────────┘    └──────────────┬──────────────┘
           │                               │
           └───────────────┬───────────────┘
                           ▼
┌─────────────────────────────────────────────────────────┐
│ 4. ACTION RECOMMENDATION                                │
│    Write to site/service repo contact per               │
│    .wip-contract.md specified contact/method            │
│    Include: link to netstack pattern + site values      │
└─────────────────────────────────────────────────────────┘
```

## Rules

1. **Never solve a problem without documenting the pattern first.** If you can't point to a netstack doc, you haven't finished the work.
2. **Site repos link to netstack, never duplicate.** A site's `backup.md` says "follows [netstack backup-cron-pattern](https://netstack.org/docs/ops/backup/backup-cron-pattern/)" — it doesn't re-explain the pattern.
3. **Action recommendations go through contracts.** The `.wip-contract.md` defines who gets notified and how. Wip sends the recommendation with a netstack link + site-specific values.
4. **Research is not wasted.** Even if a solution doesn't get implemented immediately, the pattern doc in netstack preserves the knowledge for future use.

## Example: Setting Up a CLI Helper on a New Node

1. Problem: need `wip` command on wf node
2. Check netstack → `docs/ops/tools/cli-helper-pattern.md` exists ✓
3. Follow pattern: create dispatcher, symlink into `~/.local/bin/`
4. Action recommendation to wf repo: "CLI helper installed per [netstack cli-helper-pattern](https://netstack.org/docs/ops/tools/cli-helper-pattern/)"

## Example: NAS Won't Mount After Storm Damage

1. Problem: wf NAS not responding after power event
2. Check netstack → no "NAS recovery" pattern exists
3. Research: diagnose (CR1220 battery? drive failure? network?), find solution, test
4. Document: write `docs/ops/storage-index/nas-recovery-pattern.md` in netstack
5. Follow the new pattern to fix wf NAS
6. Action recommendation to wf repo contact: "NAS recovered per [netstack nas-recovery-pattern](https://netstack.org/docs/ops/storage-index/nas-recovery-pattern/) — replaced CR1220, ZFS scrub clean"

## Where Patterns Live in Netstack

| Category | Path | Covers |
|----------|------|--------|
| Tools | `docs/ops/tools/` | CLI helpers, automation scripts, session logging |
| Backup | `docs/ops/backup/` | Backup cron, Docker backup, restore procedures |
| Users | `docs/ops/users/` | Node setup, dev environments, SSH config |
| Deployments | `docs/ops/deployments/` | Site topology, federation guide, site template |
| Monitor | `docs/ops/monitor/` | Health checks, alerting, performance baselines |
| Security | `docs/ops/security/` | Access control, key management, firewall |
| Storage | `docs/ops/storage-index/` | NAS, ZFS, Plex, media management |
| Network | `docs/wan/` | ZeroTier, WireGuard, Cloudflare, DNS |
| Compute | `docs/lan/compute/` | Proxmox, Docker, VMs |

## Related

- [.wip-consulting.md](https://github.com/2cld/wip/blob/main/.wip-consulting.md) — Wip first principles
- [.cat9-contract.md](https://github.com/2cld/wip/blob/main/.cat9-contract.md) — CAT9 management contracts (defines contacts)
- [Federation Setup Guide](./deployments/federation-setup-guide.md) — standing up a new node
- [Automation Pattern](./tools/automation-pattern.md) — read→propose→apply for scripts
