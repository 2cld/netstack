# Pattern: Repo Health Check

**Category:** `docs/ops/feedback/`  
**Purpose:** A repeatable process for auditing a coordination or documentation repo to catch drift, staleness, and broken references.  
**Audience:** Any admin managing infrastructure repos where documentation doubles as the source of truth.

---

## The Problem

Coordination repos (task trackers, wikis, ops docs) decay silently. Unlike code repos where CI fails when things break, documentation repos have no compiler. Stale dates, dead links, orphaned references, and forgotten blockers accumulate until the repo actively misleads instead of helping.

## The Pattern

Run a structured health check at a regular interval. The check is mechanical — it doesn't require domain expertise, just discipline. A new admin (or AI assistant) can execute it cold.

---

## Health Check Steps

### 1. Freshness Scan

Identify all date-stamped content. Flag anything older than expected:

| Content Type | Stale Threshold | Example |
|-------------|-----------------|---------|
| Daily status | > 1 day | "Last check-in: Jun 10" on Jun 16 |
| Weekly summary | > 7 days | "This Week" showing last month |
| Service status | > 7 days | "Last Check: May 28" |
| "Current State" sections | > 30 days | "Current State (March 2026)" |

**Why this matters:** Stale dates destroy trust. If a reader sees old dates, they assume the whole document is unreliable — even the parts that are current.

### 2. Reference Integrity

Check that all internal links resolve:

```bash
# Find markdown links to local files
grep -oP '\]\(\./[^\)]+\)' README.md | grep -oP '\./[^\)]+' | while read f; do
  [ ! -f "$f" ] && echo "BROKEN: $f"
done
```

Also check:
- External links to issues (do they still exist? are they closed?)
- Links to other repos (has the repo been renamed/archived?)
- Links to services (is the URL still valid?)

**Why this matters:** Broken links are the #1 sign of a repo that's been copy-pasted or reorganized without follow-through.

### 3. Vocabulary Consistency

Every repo has canonical identifiers — project codes, hostnames, service names. Scan for:

- Identifiers used that aren't in the canonical list
- Identifiers in the list that are never referenced (dead entries)
- Inconsistent naming (abbreviations, typos, old names)

**Why this matters:** Inconsistent vocabulary splits institutional memory. When the same thing has two names, knowledge fragments.

### 4. Status vs. Reality

For each "in progress" or "blocked" item, ask:
- When was this last updated?
- Is the blocker still real?
- Has this been "in progress" for > 30 days without movement?

Items that haven't moved in 30+ days are either:
- Actually blocked (document the blocker explicitly)
- Abandoned (close them with a reason)
- Done but not marked done (mark them)

**Why this matters:** Zombie tasks pollute priority decisions. If your list has 20 items and 12 haven't moved in a month, your real list is 8 items — but you're carrying the cognitive load of 20.

### 5. Structural Promises

Check that the repo structure matches what documentation claims:

- Does the README reference a file that doesn't exist?
- Does a process doc mention a workflow that's no longer followed?
- Are there files in the repo with no inbound links (orphans)?

**Why this matters:** Structural drift happens when process evolves faster than documentation. The fix is mechanical: update the doc or create the missing file.

---

## When to Run

| Trigger | Scope |
|---------|-------|
| Weekly review | Quick scan (steps 1, 4) |
| Monthly audit | Full check (all steps) |
| Before major planning | Full check (ensures you're planning from reality) |
| After extended absence | Full check (catches drift during downtime) |
| New team member onboarding | Full check (validates docs work for fresh eyes) |

---

## Output Format

Produce a findings table:

| # | Type | Finding | Severity | Action |
|---|------|---------|----------|--------|
| 1 | Stale | Federation status 11 days old | Medium | Update from last backup run |
| 2 | Broken | `tasks.md` referenced but doesn't exist | Low | Create or remove reference |
| 3 | Zombie | "CyberTruck SSH" blocked 30+ days | Medium | Confirm blocker or close |

Severity guide:
- **High** — actively misleading (wrong info that could cause bad decisions)
- **Medium** — stale or confusing (creates uncertainty)
- **Low** — cosmetic or minor (doesn't affect operations)

---

## Implementation Notes

### For AI-Assisted Repos (Human + AI pair)

If your repo uses an AI assistant (like Wip), the health check is a natural task to delegate:
1. AI reads the key files (README, status pages, notes)
2. AI cross-references dates, links, and identifiers against known-good sources
3. AI produces the findings table
4. Human reviews findings and decides actions
5. Both execute the fixes

This works because the check is mechanical — it doesn't require judgment about *what to work on*, only observation of *what's drifted*.

### For Solo Admins

Set a calendar reminder. The check takes 15–20 minutes once you know the pattern. The ROI is high: 20 minutes prevents hours of confusion when you return to the repo after a break.

### For Teams

Include the health check in your PR/review process for documentation repos. If someone updates a doc, they scan adjacent docs for staleness. This distributes the maintenance cost.

---

## The Principle

> **Documentation that isn't maintained is worse than no documentation.** It actively misleads. A health check turns maintenance from "when I get around to it" into a scheduled, repeatable operation — the same way you'd schedule backups or monitoring checks.

This is the feedback loop for documentation: write → use → check → fix → use → check → fix.

---

## Related

- [Pattern Workflow](../pattern-workflow.md) — How netstack patterns drive federation operations
- [Automation Pattern](../tools/automation-pattern.md) — Read → Propose → Apply for scripts
- [Wip PROCESS.md](https://github.com/2cld/wip/blob/main/PROCESS.md) — Implementation of this pattern in a live coordination repo
