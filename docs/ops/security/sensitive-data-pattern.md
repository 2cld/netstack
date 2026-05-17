# Sensitive Data Pattern for Federation Sites

**Applies to:** All 2cld site repos (sl, cf, wf) and infrastructure repos

## Principle

> Document the pattern, not the instance.
> Publish methodology. Keep specifics private.

Public documentation should explain **what** we do and **why**, without revealing **where** things are or **how** to access them. This prevents published docs from becoming attack paths.

## The Two-Layer Approach

### Public layer (committed to git, anyone can see)
- Architecture diagrams (without IPs)
- Procedure steps (without credentials)
- Tool names and patterns (without configs)
- Template files with placeholder values
- Status formats and conventions

### Private layer (gitignored, local only)
- IP addresses, network IDs
- Passwords, tokens, API keys
- Machine names + paths (maps infrastructure)
- Backup targets with connection details
- Session logs with internal troubleshooting details

## Standard .gitignore for Site Repos

Every public site repo should include:

```gitignore
# Sensitive operational data (never push to public)
ops/sensitive/
ops/backup/logs/
ops/backup/.backup-state
docs/log/
*.env
*.env.*
```

## Backup State Monitoring

Sensitive data that's gitignored still needs monitoring. Use the `.backup-state` pattern:

### Format (gitignored, local only):
```json
{
  "last_run": "2026-05-17T06:30:00Z",
  "status": "success",
  "items_backed_up": 3,
  "target": "offsite-1",
  "next_scheduled": "2026-05-18T06:30:00Z"
}
```

No paths, no IPs, no credentials. Just: when, pass/fail, how many items, which target (by alias).

### Status script output:
```
--- BACKUP: last run 12h ago, success, 3 items to offsite-1 ---
```
or
```
--- BACKUP: ⚠️ STALE — last run 3 days ago ---
```

## Backup of Gitignored Data

Gitignored data is safe from public exposure but vulnerable to machine loss.

### Backup targets (in priority order):
1. **Private git repo** — for small state files, configs (no credentials)
2. **Federation storage** (encrypted) — for larger data, backup archives
3. **Cloud storage** (encrypted) — for redundancy
4. **Password manager** — for credentials specifically

## Publishing Guidelines

### ✅ Safe to publish:
- Architecture patterns (without IPs)
- Procedure steps (without credentials)
- Tool names and usage patterns
- "We use X for Y" statements
- Template files with placeholder values
- Status formats and conventions
- .gitignore patterns

### ❌ Never publish:
- IP addresses (internal or VPN)
- Network IDs (ZeroTier, WireGuard)
- Passwords, tokens, API keys
- Machine names + paths together
- Email addresses (social engineering vector)
- Account numbers, financial details
- Specific share paths

### ⚠️ Judgment call:
- Machine names alone (without IPs) — probably OK
- Service URLs (if publicly accessible anyway) — OK
- Port numbers (without IP) — usually OK
- "We use ZeroTier" (without network ID) — OK

## Related
- [netstack.org/docs/ops/backup/](../backup/) — backup procedures
- [netstack.org/docs/ops/monitor/](../monitor/) — monitoring patterns
- [Session Logging Convention](../tools/session-logging.md) — how to log work without leaking
