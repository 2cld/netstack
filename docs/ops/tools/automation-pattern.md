# Automation Script Pattern: Read → Propose → Apply

**Applies to:** All automation scripts in the federation

## Principle

Every automation script follows the same three-phase pattern:

1. **READ** — Gather state from APIs, files, services
2. **PROPOSE** — Show what would change (preview mode)
3. **APPLY** — Make the changes (only with explicit flag)

This ensures:
- No surprises — you always see what will happen before it happens
- Safe by default — running without flags is read-only
- Auditable — the preview output documents what changed and why
- Trustworthy — both human and AI can verify before applying

## Usage Convention

```bash
# Preview (safe, read-only)
node script.js

# Apply (makes changes)
node script.js --apply

# Compact output (for integration into other scripts)
node script.js --compact
```

## Script Template

```javascript
#!/usr/bin/env node
// Script Name — brief description
// Usage:
//   node script.js          → preview (shows what would change)
//   node script.js --apply  → make changes
//   node script.js --compact → one-liner for integration
//
// Pattern: read → propose → apply

const APPLY = process.argv.includes('--apply');
const COMPACT = process.argv.includes('--compact');

async function run() {
  // --- READ ---
  // Gather state from APIs, files, services
  const state = await gatherState();

  // --- PROPOSE ---
  // Generate proposed changes
  const changes = generateChanges(state);
  
  // Show preview
  if (COMPACT) {
    console.log(formatCompact(changes));
    return;
  }
  
  console.log(APPLY ? '=== APPLYING ===' : '=== PREVIEW ===');
  console.log(formatFull(changes));

  if (!APPLY) {
    console.log('\n=== PREVIEW ONLY — run with --apply to make changes ===');
    return;
  }

  // --- APPLY ---
  // Make the changes
  await applyChanges(changes);
  console.log('\n✅ Changes applied');
}

run().catch(e => console.error('Error:', e.message));
```

## Flag Handling

| Flag | Behavior | Safe? |
|------|----------|:-----:|
| (none) | Read + preview only | ✅ Always safe |
| `--apply` | Read + preview + make changes | ⚠️ Changes state |
| `--compact` | Read + one-liner output | ✅ Always safe |
| `--quiet` | Suppress verbose output | ✅ Always safe |

## Examples in Practice

| Script | READ | PROPOSE | APPLY |
|--------|------|---------|-------|
| morning-update | Calendar API, README | New Today/Yesterday sections | Write README, git commit+push |
| federation-status | HTTP checks, repo APIs | Status report + flags | (read-only, no apply) |
| email-triage | Gmail API | Labels to apply | Apply labels, archive noise |
| backup-verify | .backup-state files | Freshness report | (read-only, no apply) |
| issue-file | Inbox items | Proposed issues | Create issues via API |

## When to Use This Pattern

- Any script that modifies state (files, APIs, git)
- Any script that aggregates information for review
- Any script that will be called by other scripts (use --compact)
- Any script where you want human/AI verification before action

## When NOT to Use

- Simple one-off queries (just print the result)
- Interactive tools (use prompts instead of flags)
- Real-time services (use proper service architecture)

## Related
- [Monitoring Pattern](../monitor/monitoring-pattern.md) — status scripts follow this pattern
- [Session Logging](session-logging.md) — document what scripts do
- [CAVE Principles](../security/cave-principles.md) — validation gate aligns with propose/apply
