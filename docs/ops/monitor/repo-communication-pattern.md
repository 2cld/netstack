# Pattern: Repo Communication (Automated Action Recommendations)

**Applies to:** Any coordination layer that monitors multiple repos and needs to communicate findings as issues on the appropriate target repo.

## Principle

> When monitoring detects a problem, communicate to the repo that owns the problem — not just to a local log. An issue on the right repo is worth more than a flag in a morning report.

## The Problem

Most monitoring-to-human communication looks like this:

```
Monitoring script runs → outputs flags → someone reads output → remembers to do something
```

This breaks at "someone reads output" and again at "remembers to do something." The gap:

- Monitoring knows something is wrong
- The responsible repo has no record of it
- No issue = no DoD = no accountability = drift

## The Solution: Automated Action Recommendations

When monitoring detects a threshold breach or state change, it creates (or updates) an issue on the target repo — not on the coordination repo.

```
Monitor detects problem
    ↓
Determine target repo (from project mapping)
    ↓
Check: issue already exists for this problem?
    ├── NO  → Create new issue (action recommendation)
    └── YES → Add comment with current state update
    ↓
Log the communication (who was told, when, what)
```

## What IS an Action Recommendation?

An action recommendation is an issue created by the coordination layer on a project repo. It says:

1. **What was detected** (the monitoring finding)
2. **Why it matters** (risk if not addressed)
3. **What to do** (suggested fix, linked to netstack pattern)
4. **How to verify** (how the coordinator will confirm resolution)

It is NOT:
- A command (the coordination layer requests, doesn't demand)
- A full solution (link to the pattern, don't re-explain it)
- Permanent (close it when resolved)

## Issue Template

```markdown
## [MONITOR] <brief description of finding>

**Detected:** <timestamp>
**Severity:** Critical / Warning / Info
**Pattern:** [link to relevant netstack pattern doc]

### What was detected
<one-paragraph description of what monitoring found>

### Risk
<what happens if this isn't addressed>

### Suggested action
<what the admin should do, with link to the pattern that explains how>

### Verification
Wip will auto-verify using: `<verification check description>`
When this check passes, this issue will be closed automatically.

---
*This issue was created automatically by monitoring. See [status-freshness-cron-pattern](https://netstack.org/docs/ops/monitor/status-freshness-cron-pattern/) for how this works.*
```

## Target Repo Determination

The coordination layer maintains a mapping: project code → repo → admin.

```javascript
// repo-communication-map (lives in coordination repo)
const REPO_MAP = {
  'cf-backup':    { repo: '2cld/cf', admin: 'ghadmin@horseoff.com' },
  'wf-backup':    { repo: '2cld/wf', admin: 'ghadmin@horseoff.com' },
  'sl-backup':    { repo: '2cld/sl', admin: 'ghadmin@horseoff.com' },
  'hwpc-rp':      { repo: 'ns-account', platform: 'gitea', admin: 'nsadmin@horseoff.com' },
  'netstack-doc': { repo: '2cld/netstack', admin: 'ho-wip' },
  'wip-process':  { repo: '2cld/wip', admin: 'ho-wip' },
};
```

**Rules for target selection:**
1. Issue goes on the repo that OWNS the problem (not the repo that detected it)
2. If the problem spans multiple repos → issue goes on the primary (closest to root cause)
3. If no repo owns it → issue goes on the coordination repo with a note to assign
4. Cross-reference with `.wip-contract.md` for admin contact per project

## Deduplication

Don't flood repos with duplicate issues. Before creating:

```
1. Search target repo for open issues with "[MONITOR]" prefix
2. If matching issue exists:
   - Add a comment: "Still detecting this. Current state: <data>. Days open: N."
   - If days open > escalation threshold → escalate (see below)
3. If no matching issue:
   - Create new issue using template
```

### Escalation Ladder

| Days Open | Action |
|:---------:|--------|
| 0 | Issue created, admin notified |
| 3 | Comment added: "still open, gentle reminder" |
| 7 | Comment added: "7 days, needs attention" + mention admin |
| 14 | Escalate: notify higher admin or flag in coordination repo as blocked |
| 30 | Stale: label as `stale-monitor`, surface in weekly review for decision |

## When NOT to Create an Issue

Not every monitoring flag warrants repo communication:

| Situation | Action Instead |
|-----------|---------------|
| Transient blip (check fails once, passes next run) | Log only, don't create issue |
| Known planned downtime | Skip (coordinator marks planned downtime in state file) |
| Problem is already in an active Epic | Comment on existing Epic issue instead |
| Informational (no action needed) | Include in morning report, no issue |

**The filter:** Only create an issue when the monitoring state has been in warning/critical for >= 2 consecutive checks AND no existing issue covers it.

## Connection to Existing Patterns

| Pattern | How this connects |
|---------|-------------------|
| `status-freshness-cron-pattern.md` | The cron triggers this pattern when state transitions to critical |
| `request-lifecycle.md` | A created issue IS a request. Verification + acknowledgment follow that lifecycle. |
| `pattern-workflow.md` | The issue links to the netstack pattern doc (action recommendation = "follow this pattern") |
| `site-status-page-pattern.md` | Status page shows current state; issue tracks the fix work |

## Implementation Skeleton

```javascript
// create-alert-issue.js — called by status-freshness-cron when threshold breaches

async function createOrUpdateIssue(finding) {
  const target = REPO_MAP[finding.checkId];
  if (!target) { console.log(`No repo mapping for ${finding.checkId}`); return; }

  // Search for existing monitor issue
  const existing = await searchIssues(target.repo, `[MONITOR] ${finding.title}`);

  if (existing) {
    // Add status comment
    await addComment(existing.number, [
      `**Update (${new Date().toISOString()}):** Still detecting this.`,
      `Current state: ${finding.status} (${finding.value})`,
      `Days open: ${daysSince(existing.created_at)}`,
    ].join('\n'));
  } else {
    // Create new issue from template
    await createIssue(target.repo, {
      title: `[MONITOR] ${finding.title}`,
      body: renderTemplate(finding, target),
      labels: ['monitor', finding.severity],
    });
  }

  // Log the communication
  logCommunication(finding, target, existing ? 'commented' : 'created');
}
```

## Closing the Loop

When the freshness cron detects recovery (critical → ok):

1. Find the open `[MONITOR]` issue on the target repo
2. Add a comment: "Resolved! Verification check now passing."
3. Close the issue
4. Send acknowledgment to admin (per request-lifecycle.md)
5. Log the resolution

This completes the cycle: **detect → communicate → verify → close → acknowledge.**

## Related

- [status-freshness-cron-pattern.md](./status-freshness-cron-pattern.md) — triggers this pattern
- [request-lifecycle.md](./request-lifecycle.md) — lifecycle after issue is created
- [monitoring-pattern.md](./monitoring-pattern.md) — what to monitor
- [pattern-workflow.md](../pattern-workflow.md) — action recommendations go through contracts
- [Wip ops-red-alerts.md](https://github.com/2cld/wip/blob/main/docs/ops-red-alerts.md) — implementation example
