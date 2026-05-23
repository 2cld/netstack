# Repo Private Data Pattern

How netstack repos separate tracked tools from untracked sensitive data.

## Principle

> Track the tools. Gitignore the data. Document the boundary.

Every repo that handles sensitive or client-specific data follows this structure:
- **Tools and code** are git-tracked (shareable, versionable, reviewable)
- **Client data, credentials, and runtime state** are NOT tracked
- **The boundary is documented** so any new contributor (human or AI) can set up correctly

## Two Mechanisms

### 1. `.local/` — Private Runtime Data

For credentials, auth tokens, symlinks to external sources, caches, and generated data.

```
repo/
├── .local/                    ← GITIGNORED (entire dir)
│   ├── README.md              ← REQUIRED: documents what goes here
│   ├── .env                   ← credentials (never tracked)
│   ├── auth/ → ../other-repo  ← symlink to auth source
│   ├── data/ → /mnt/share     ← symlink to external mount
│   └── cache/                 ← generated/exported data
├── .gitignore                 ← includes .local/ (except README.md)
└── tools/                     ← TRACKED
```

**Rules for `.local/`:**
1. `.local/README.md` is ALWAYS present and describes what should exist
2. `.local/README.md` MAY be tracked (so new clones get setup instructions)
3. Everything else in `.local/` is gitignored
4. Symlinks point to auth repos, mounted shares, or sibling repos
5. Tools reference `.local/{name}` — never hardcode external paths

**`.local/README.md` template:**

```markdown
# .local/ — Private Runtime Data

## Required Setup
After cloning, create these:

| Entry | Type | Source | Purpose |
|-------|------|--------|---------|
| .env | file | password manager | API tokens |
| auth/ | symlink | ../nsgctime | OAuth2 tokens |
| data/ | symlink | /mnt/share | Client data mount |

## Refresh
- .env: update from password manager when tokens rotate
- auth/: symlink to wherever OAuth tokens live on this machine
- data/: mount the share first, then symlink
```

### 2. Gitignored Tenant Directories — Sub-Projects at Repo Root

For client working directories that have their own identity, docs, and internal structure.

```
repo/
├── .gitignore                 ← lists tenant dirs
├── .wip-consulting.md         ← contract for the REPO
├── _tools/                    ← TRACKED (shared across tenants)
│
├── client-a/                  ← GITIGNORED tenant
│   ├── .wip-consulting.md     ← contract for THIS tenant
│   ├── docs/                  ← tenant's own documentation
│   └── data/                  ← tenant's working data
│
├── client-b/                  ← GITIGNORED tenant
│   ├── .wip-consulting.md     ← contract for THIS tenant
│   └── ...
└── ...
```

**Rules for tenant directories:**
1. Each tenant dir is listed in `.gitignore`
2. Each tenant MAY have its own `.wip-consulting.md` (opt-in to automation)
3. Tools in `_tools/` reference tenants via relative path (`../{tenant}/`)
4. Tenant dirs are never committed — they contain real client/business data
5. Backup of tenant dirs is handled separately (not via git)

## When to Use Which

| Situation | Use | Why |
|-----------|-----|-----|
| OAuth tokens, API keys | `.local/.env` | Pure credentials, no structure |
| Symlink to auth repo | `.local/auth/` | Runtime dependency |
| Symlink to mounted share | `.local/data/` | External data source |
| Generated exports (CSVs, caches) | `.local/cache/` | Ephemeral, regenerable |
| LLC working directory | Tenant dir at root | Has own identity + docs |
| Client project with task lists | Tenant dir at root | Sub-project, not just data |
| Service production data | Tenant dir at root | Critical, needs own backup plan |

## Discovery (for automation / AI agents)

An automation agent discovers what's available by:

```
1. Read .wip-consulting.md at repo root
   → Understand repo-level scope and permissions

2. Read .local/README.md
   → Understand private runtime dependencies
   → Verify symlinks resolve (health check)

3. Parse .gitignore for directory entries
   → These are potential tenant dirs

4. For each gitignored dir that exists on disk:
   → Check for .wip-consulting.md inside
   → If present: agent has scoped access (read contract)
   → If absent: agent does not access this dir
```

## `.wip-consulting.md` Format

Placed in repo root OR tenant dir root:

```markdown
# Wip Consulting Agreement

**Project:** {name}
**Owner:** {persona/email}
**Date:** {YYYY-MM-DD}
**Access granted:** read-only

## Scope
Wip may observe:
- {what's visible}

Wip may NOT:
- {restrictions}

## Task Integration
tasks:
  primary: "{path to task list}"
  issues:
    platform: "{gitea|github}"
    url: "{issue tracker URL}"

## Verification
This file's presence confirms consulting access.
```

## .gitignore Template

Standard `.gitignore` for repos using this pattern:

```gitignore
# Private runtime data
.local/
!.local/README.md

# Tenant directories (add one line per tenant)
# client-a/
# client-b/

# Standard ignores
*.env
*.env.*
node_modules/
```

## Security Notes

- **Public repos:** Never reference tenant dir names in tracked files (reveals business structure)
- **Private repos:** Tenant names in `.gitignore` are acceptable (repo is already access-controlled)
- **Symlinks:** Document the pattern, not the target path (targets are machine-specific)
- **Backup:** Gitignored data needs its own backup strategy — git won't save it

## Examples in Practice

### Accounting repo (tools + LLC tenants)
```
account-repo/
├── _tools/tax-prep/           ← tracked
├── _tools/migration/          ← tracked
├── llc-alpha/                 ← gitignored tenant
│   └── .wip-consulting.md
├── llc-beta/                  ← gitignored tenant
│   └── .wip-consulting.md
└── .local/
    └── README.md
```

### Coordination repo (scripts + external data via symlinks)
```
coordination-repo/
├── .local/
│   ├── README.md
│   ├── auth/ → ../auth-repo
│   ├── data/ → /mnt/share
│   ├── scripts/               ← tracked (tools)
│   └── clients/               ← gitignored (generated)
└── docs/                      ← tracked
```

## Related

- [automation-pattern.md](./automation-pattern.md) — read → propose → apply
- [repo-lifecycle.md](./repo-lifecycle.md) — repo creation and management
- [session-logging.md](./session-logging.md) — work logging convention
