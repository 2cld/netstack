# Bare Metal Rebuild (BMR) Pattern

**Purpose:** Define the scripted rebuild path for federation site infrastructure.
**Implementation:** [netstack#17](https://github.com/2cld/netstack/issues/17) (contains bootstrap.sh reference implementation)
**Exemplar:** [wf compute architecture](https://github.com/2cld/wf/blob/main/ops/compute/wf-compute-architecture.md)
**Related:** [netstack#18](https://github.com/2cld/netstack/issues/18), [compute-roles-pattern](./compute-roles-pattern.md)

---

## The Problem

If a site's infra node dies, recovery depends on tribal knowledge. The pieces exist (site-config.yml, Docker compose files, backup scripts) but there's no single documented path from "fresh hardware" to "site operational."

## The Pattern: Four-Script Rebuild

BMR targets the **infra role** (see [compute-roles-pattern](./compute-roles-pattern.md)). Four scripts, executed in order, take a fresh machine to full operation:

```bash
# On fresh Ubuntu (bare metal, VM, LXC, RPi, or WSL):
git clone git@github.com:2cld/<site>.git
cd <site>/ops
./bootstrap.sh site-config.yml    # OS config, users, deps, keys, cron
./deploy.sh site-config.yml       # Docker stack, tunnels, services
./restore.sh site-config.yml --from <backup-source>   # Pull data from off-site
./verify.sh site-config.yml       # Confirm everything matches expected state
```

Each script reads `site-config.yml` as its single source of truth.

## Script Responsibilities

### bootstrap.sh -- Provision the OS

| Step | What | Reads from config |
|------|------|------------------|
| 1 | Set timezone | `site.timezone` |
| 2 | Install packages (openssh, docker, yq, git, curl) | implicit |
| 3 | Create users (buadmin, wip) per federation-user-model | `compute.roles.infra.users` |
| 4 | Generate SSH keys per user | -- |
| 5 | Create directory structure | -- |
| 6 | Clone repos (site repo, netstack, wip) | `site.repo` |
| 7 | Set up cron (backup, monitoring) | `monitoring`, `federation` |
| 8 | Enable Docker | -- |
| 9 | Join ZeroTier network | `zerotier.networks[0].id` |

**Output:** A provisioned machine with users, Docker, ZeroTier, and cron -- but no services running yet.

**Reference implementation:** [netstack#17](https://github.com/2cld/netstack/issues/17) contains a full bootstrap.sh.

### deploy.sh -- Start Services

| Step | What | Reads from config |
|------|------|------------------|
| 1 | Pull Docker images | `services[*].image` |
| 2 | Generate docker-compose.yml from config | `services[*]` |
| 3 | Configure Cloudflare tunnel | `services[*].tunnel` |
| 4 | Configure Traefik routes | `services[*].url` |
| 5 | Start Docker stack | -- |
| 6 | Verify services responding | `services[*].port` |

**Output:** All services running, tunnel active, site reachable remotely.

### restore.sh -- Pull Backup Data

| Step | What | Reads from config |
|------|------|------------------|
| 1 | Identify backup source | `federation.backup_from` or `--from` flag |
| 2 | SSH to source, verify backup freshness | source's `.backup-state` |
| 3 | rsync data from source to local paths | `services[*].volumes` |
| 4 | Restore database dumps (if any) | `services[*].backup.restore_cmd` |
| 5 | Restart services with restored data | -- |

**Output:** Services running with real data (not empty). Site is fully operational.

### verify.sh -- Confirm Healthy State

| Step | What | Reads from config |
|------|------|------------------|
| 1 | Check each service is responding | `services[*].port` |
| 2 | Check ZeroTier connected | `zerotier.networks` |
| 3 | Check tunnel healthy | `services[*].tunnel` |
| 4 | Check backup script runs | `federation.role` |
| 5 | Check cron installed | -- |
| 6 | Run .wip-monitor.yml checks | `.wip-monitor.yml` |
| 7 | Produce site-status.json | -- |

**Output:** Pass/fail report. If all pass, site is confirmed operational.

## What Lives Where

| Component | Location | Why |
|-----------|----------|-----|
| Pattern docs (this file) | netstack `docs/ops/deployments/` | Shared knowledge -- HOW |
| Script templates | ns-site-template (gitea.cat9.me) | Generic scaffolding |
| site-config.yml | Site repo (cf, sl, wf) | Site-specific values -- WHAT |
| .wip-monitor.yml | Site repo | Monitoring contract |
| .wip-contract.md | Site repo | Communication contract |
| Docker compose | Site repo `ops/docker/` | Service definitions |
| Backup scripts | Site repo `ops/scripts/` | Site-specific backup logic |

**The contract between generic and specific:**
- Scripts read `site-config.yml` keys
- If a key exists, the script acts on it
- If a key is missing, the script skips that step (graceful degradation)
- Site repos can override/extend with site-specific scripts in `ops/scripts/`

## BMR Scope: What Gets Rebuilt vs. What Gets Restored

| Category | Rebuilt by scripts | Restored from backup |
|----------|:-:|:-:|
| OS + packages | bootstrap.sh | -- |
| Users + SSH keys | bootstrap.sh | -- (new keys, register on remotes) |
| Docker services | deploy.sh | -- |
| Tunnel config | deploy.sh | -- |
| Application data (DBs, repos) | -- | restore.sh |
| Media files | -- | restore.sh (or accept loss if reproducible) |
| Cron jobs | bootstrap.sh | -- |
| ZeroTier membership | bootstrap.sh | -- (re-authorize in Central) |

## Platform Support

| Platform | bootstrap.sh | deploy.sh | Notes |
|----------|:-:|:-:|-------|
| Ubuntu 22.04+ (bare metal) | YES | YES | Primary target |
| Proxmox LXC (Ubuntu) | YES | YES | wf Phase 1 |
| Raspberry Pi OS (arm64) | YES | YES | wf Phase 2 |
| WSL2 (Ubuntu on Windows) | PARTIAL | YES | sl pattern -- some steps differ (no systemd) |
| MikroTik RouterOS containers | NO | PARTIAL | Different runtime -- document separately |

## Testing BMR

### Smoke Test (non-destructive)
```bash
# On existing infra node:
./verify.sh site-config.yml
# Should pass -- confirms current state matches config
```

### Full DR Test (destructive, controlled)
1. Provision a fresh VM/LXC (NOT the production node)
2. Run all four scripts against it
3. Verify services come up with real data
4. Tear down test environment
5. Document results in issue comment

### Cross-Site DR Test (proves portability)
1. On a DIFFERENT site's hardware, provision a test VM
2. Clone the target site's repo
3. Run bootstrap + deploy + restore
4. Verify the site works from different physical hardware
5. This proves: if site X dies, it can be rebuilt at site Y

## Migration Path (for sites not yet BMR-ready)

1. **Write verify.sh first** -- confirms what you HAVE matches what config SAYS
2. **Write deploy.sh** -- automates what you do manually today to start services
3. **Write bootstrap.sh** -- automates the OS provisioning you did once and forgot
4. **Write restore.sh** -- automates pulling backup data
5. **Test on a disposable VM** -- don't test on production

## Related Patterns

- [Compute Roles Pattern](./compute-roles-pattern.md) -- defines which hardware role is the BMR target
- [Federation User Model](./federation-user-model-pattern.md) -- user roles created by bootstrap.sh
- [Compute WSL Docker Pattern](./compute-wsl-docker-pattern.md) -- WSL-specific deployment (sl)
- [Site Tenant Contract](./site-tenant-contract-pattern.md) -- .wip-contract.md defines scope
- [Contract-Driven Monitoring](../monitor/contract-driven-monitoring-pattern.md) -- .wip-monitor.yml drives verify.sh
