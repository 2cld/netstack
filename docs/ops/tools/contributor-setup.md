# Contributor Setup — Working with 2cld Repos

**Applies to:** Anyone contributing to 2cld federation repos

## Prerequisites

- Git installed
- GitHub account with access to 2cld org repos
- Text editor or IDE
- (Optional) Gitea account on gitea.cat9.me for infrastructure repos

## Repo Types

| Type | Platform | Examples | Access |
|------|----------|----------|--------|
| Public docs/sites | GitHub | netstack, sl, cf, wf, hwpc | Anyone can read, contributors can push |
| Private coordination | GitHub | wip | Collaborators only |
| Infrastructure | Gitea (cat9.me) | ns-account, nspwa, nscallbot, ns-site-template | Org members |

## Cloning and Working

```bash
# GitHub repos
git clone https://github.com/2cld/REPO_NAME.git

# Gitea repos
git clone https://gitea.cat9.me/nsadmin/REPO_NAME.git
```

## Commit Convention

```bash
# Standard commit
git commit -m "Brief description of change"

# Daily review (wip repo)
git commit -m "Daily review YYYY-MM-DD @daily-review-YYYY-MM-DD"

# Weekly review (wip repo)
git commit -m "Sunday Review YYYY-MM-DD @weekly-review-YYYY-MM-DD"
```

## Branch Strategy

- **Default branch:** `main` (preferred) or `master` (legacy)
- **Feature work:** Create a branch (`cleanup/description`, `feature/description`)
- **Direct push to default:** OK for docs, small fixes, daily reviews
- **Branch + PR:** For significant code changes or multi-step restructuring

## Session Logging

When working on a project, maintain session logs:

```bash
mkdir -p docs/log
# Write a log entry for each work session
```

See [Session Logging Convention](session-logging.md) for format.

## Sensitive Data

Never commit:
- IP addresses, network IDs
- Passwords, tokens, API keys
- Machine names + paths together

Use `.gitignore` patterns. See [Sensitive Data Pattern](../security/sensitive-data-pattern.md).

## Adding a New Repo to the Federation

1. Create repo on GitHub or Gitea
2. Clone to working machine
3. Add standard structure (docs/, ops/, .gitignore)
4. Add session logging (`docs/log/`)
5. Add to coordination repo's inventory (repo map)
6. Document the machine + local path where you work on it

## Related
- [Sensitive Data Pattern](../security/sensitive-data-pattern.md)
- [Session Logging](session-logging.md)
- [CAVE Principles](../security/cave-principles.md)
- [Federation Node Topology](../deployments/federation-node-topology.md)
