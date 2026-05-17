# Session Logging Convention

**Applies to:** All project repos in the federation

## Purpose

Session logs capture decisions, context, and "why" that git commits alone don't preserve. They build institutional memory — when someone (human or AI) picks up a project cold, the logs explain what was tried, what worked, and what was abandoned.

## Where Logs Live

Each project repo maintains its own session logs:

```
project-repo/
├── docs/
│   └── log/
│       ├── README.md          ← convention reference
│       ├── session-2026-05-17.md
│       └── session-2026-05-18.md
└── .gitignore                 ← docs/log/ may be gitignored in public repos
```

**Public repos:** Gitignore `docs/log/` if logs contain sensitive details (IPs, credentials, internal architecture). See [sensitive-data-pattern.md](../security/sensitive-data-pattern.md).

**Private repos:** Logs can be committed safely.

## Log Format

```markdown
# Session Log — YYYY-MM-DD

## Project: [project-name]
## Location: [machine:path]

### What was done
- Brief factual list of work performed

### Key decisions (and why)
- Decision made → reasoning

### What changed
- Files/configs modified
- Commits made (link if possible)

### Blockers / open questions
- What's stuck or unclear

### Next steps
- What to do next time this project is touched
```

## Optional: Focus Tracking

For personal productivity analysis, add:

```markdown
### Focus tracking
- 🐿️ Squirrel thoughts (captured, returned to task)
- ⚡ Priority interrupts (what broke, how long)
- 🧠 Brain dead drift (time of day, trigger)
```

This data helps identify patterns: when you drift, what triggers it, and how to structure your day better.

## Cross-Referencing

When working across multiple projects, reference other logs:

```markdown
### What was done
- Fixed share mapping (see also: [cf session 2026-05-17])
```

A coordination repo (like a private "wip" repo) can maintain daily summaries that pull from all project logs.

## Setting Up in a New Repo

```bash
mkdir -p docs/log
cat > docs/log/README.md << 'EOF'
# Session Logs

Work logs for this project. See [netstack session logging convention](https://netstack.org/docs/ops/tools/session-logging/) for format.
EOF
```

For public repos, add to `.gitignore`:
```gitignore
# Session logs may contain sensitive details
docs/log/*.md
!docs/log/README.md
```

## Benefits

- **Onboarding:** New contributors (human or AI) can read logs to understand context
- **Debugging:** "Why did we do X?" → search the logs
- **Accountability:** Track what was worked on and when
- **Pattern recognition:** Focus tracking reveals productivity patterns
- **Institutional memory:** Survives personnel changes and context resets

## Related
- [Sensitive Data Pattern](../security/sensitive-data-pattern.md) — what to gitignore
- [netstack.org/docs/ops/monitor/](../monitor/) — automated monitoring
- [netstack.org/docs/ops/backup/](../backup/) — backup procedures
