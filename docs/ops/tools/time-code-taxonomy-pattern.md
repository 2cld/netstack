# Pattern: Time-Code Taxonomy for Calendar-Based Effort Tracking

**Category:** `docs/ops/tools/`  
**Purpose:** A naming convention for calendar event codes that signals how time should be classified, routed, and reported — optimized for mobile entry.  
**Audience:** Any admin or solo operator tracking billable vs. personal time through calendar events.

---

## The Problem

When you use calendar events as your time-tracking mechanism, you need a way to distinguish:
- Work that needs deliverables and accountability (billable)
- Personal time you want visibility into (tracked but not billable)
- Scheduling blocks that shouldn't count at all (just holds on the calendar)

Most people solve this with complex category dropdowns or separate apps. This pattern solves it with a **naming convention** — three tiers encoded in how you type the event code.

---

## The Pattern: Three Tiers

| Pattern | Tier | Meaning | System Behavior |
|---------|------|---------|-----------------|
| `<org>-<project>` | Official | Billable work | Full routing: needs deliverable + tracking |
| `<name>` | Personal tracked | Time you want to see in reports | Log hours, no deliverable required |
| `<name>-` | Personal untracked | Schedule-only placeholder | Ignore entirely — don't count |

### How to read the signal

1. **`<org>-<project>`** (e.g., `acme-website`, `cat9-hwpc`)  
   This is work. It has a client, a project, a deliverable. Your system should enforce accountability: does this time block have a goal? Is the goal done?

2. **`<name>`** bare (e.g., `chris`, `gus`, `family`)  
   This is personal time you choose to track. Shows up in weekly summaries so you can see where hours go. No questions asked, no deliverables. Useful for: time with people, recurring commitments, personal projects you want visibility on.

3. **`<name>-`** trailing dash (e.g., `chris-`, `andi-`)  
   This is a calendar hold — nothing more. You put it there so you don't double-book. Your system should skip it completely: no logging, no summaries, no questions. Useful for: haircuts, errands, buffer time, blocks you don't want counted.

---

## Why a Trailing Dash?

The `-` acts as a **mute signal**. Design rationale:

- **One character** — minimal effort on mobile keyboards
- **Visually distinct** — the trailing dash reads as "trailing off" or "dismissed"
- **Backward-compatible** — existing bare-name entries (without dash) keep working as tracked
- **Easy regex** — detection is trivial: `if code.endsWith('-') → skip`
- **No new UI** — works in any calendar app that supports free-text event titles

---

## Detection Logic (for automation)

```
INPUT: calendar event title, first word before space = code

if code matches "<org>-<project>" pattern  → TIER 1: OFFICIAL
  - enforce: repo + issue + definition-of-done
  - report: include in billable time summary
  - flag if missing: "⚠️ unmapped — needs routing"

else if code ends with "-"                 → TIER 3: UNTRACKED
  - skip entirely
  - do not include in any time report
  - no questions, no flags

else (bare name, no prefix, no dash)       → TIER 2: PERSONAL TRACKED
  - log hours to person/category
  - include in personal time summary
  - no routing, no deliverable check
```

### Distinguishing Tier 1 from Tier 2

The key differentiator is the `<org>-` prefix. Define your org prefix once (e.g., `cat9-`, `acme-`, `ops-`) and anything starting with it is Tier 1. Everything else without a trailing dash is Tier 2.

---

## Phone Optimization

This pattern is designed for people who create calendar events from their phone:

| What you type | Characters | Tier |
|---------------|-----------|------|
| `cat9-hwpc review status` | 22 | Official |
| `gus lunch` | 9 | Personal tracked |
| `chris- haircut` | 15 | Untracked |

The shortest entries are personal (bare names). Official work is longer because it carries the org prefix — but that's appropriate since official work needs the precision.

---

## Promotion Path

Time can change tiers as situations evolve:

- **Tier 2 → Tier 1:** A friend becomes a client. `gus` (hanging out) → `cat9-gus` (consulting project). Now needs issue + DoD.
- **Tier 3 → Tier 2:** You realize you want to track a category. `chris-` (errands) → `chris` (personal errands you want visibility on).
- **Tier 1 → Tier 2:** A project wraps up but you still spend time with the person. `cat9-cole` (house build consulting) → `cole` (personal time).

---

## Implementation Examples

### For a solo consultant
- `acme-redesign` — client project (billable)
- `family` — family time (tracked for work-life balance visibility)
- `self-` — personal maintenance (untracked holds)

### For a small ops team
- `ops-infra` — infrastructure work (tracked, assigned)
- `ops-oncall` — on-call time (tracked, reportable)
- `lunch` — break time (tracked for scheduling awareness)
- `break-` — quick breaks (untracked)

### For a federated infrastructure admin
- `cat9-hwpc` — hardware business ops
- `cat9-dev` — development (holding code, needs routing)
- `gus` — personal time with a friend
- `chris-` — errands, not counted

---

## Related

- [Pattern Workflow](../pattern-workflow.md) — How patterns drive federation operations
- [Wip Project Codes](https://github.com/2cld/wip/blob/main/docs/cat9-project-codes.md) — Implementation of this pattern
- [Repo Health Check](../feedback/repo-health-check-pattern.md) — Auditing repos that use this pattern
