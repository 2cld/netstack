# Issue Tracking Pattern: Single-Repo Project Tracking

**Applies to:** Multi-entity projects where work is shared across LLCs, people, or repos

## Principle

One repo owns all issues for a project. Other repos reference by public URL. This prevents split-brain - you never wonder "where is this tracked?"

## When to Use

- Multiple entities collaborate on one project (e.g., TreesAES + TH Twig + CAT9 on a renovation)
- Work involves both digital and physical tasks
- Non-technical people need visibility (public GitHub issues are readable by anyone)

## Structure

Pick one repo as the **issue home**. All other repos link to it.

```
th-twig (issue home)     <-- all issues live here
  |
  |-- trees-aes          <-- references th-twig issues by URL
  |-- wip EPIC           <-- NEXT items link to th-twig issues
  |-- calendar events    <-- description contains th-twig issue URL
```

## Issue Format

```markdown
## Title: [area/phase] one-line description

**Assigned:** name(s)
**Target:** date or milestone

## Definition of Done
- [ ] Concrete measurable outcome
- [ ] Concrete measurable outcome

## Notes
Context, photos, links, materials needed

## Log
- YYYY-MM-DD: status update
```

## Rules

1. **One repo = one project's issues.** Don't split issues across repos for the same project.
2. **Public repos for shared work.** If non-technical people need to see status, use a public GitHub repo.
3. **Issue URL is the reference.** Calendar events, EPICs, emails - all link to the same issue URL.
4. **DoD in every issue.** No issue without a Definition of Done (anti-squirrel rule).
5. **Log section for updates.** Append dated notes rather than editing the description. This creates a timeline.
6. **Labels for filtering.** Use labels for phase, person, status (blocked/materials/waiting).
7. **Close when DoD is met.** Not before.

## Labels (suggested)

| Label | Purpose |
|-------|---------|
| `phase-1`, `phase-2`, etc. | Group by project phase |
| `brian`, `chris` | Who does the work |
| `blocked` | Waiting on something |
| `materials` | Needs a purchase |
| `scheduled` | Has a calendar block |

## Communication Flow

```
Issue created (GitHub)
  --> Wip reads issue, creates calendar event with issue link
  --> Calendar invite sent to contacts per .wip-contract.md
  --> Person works the task, updates issue log
  --> Wip verifies DoD during morning check-in
  --> Issue closed when DoD met
```

For people without GitHub access:
- They receive calendar invites (email) with the issue link in the description
- They can view the public issue in a browser
- Updates come through meetings or email - Chris/Wip updates the issue log

## Related

- [Pattern Workflow](../pattern-workflow.md) - how netstack drives ops
- [Automation Pattern](./automation-pattern.md) - read/propose/apply for scripts
- [CLI Helper Pattern](./cli-helper-pattern.md) - command shortcuts
