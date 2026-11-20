[edit](https://github.com/2cld/netstack/edit/master/docs/ops/work-recording-pattern.md) or [../ops](./)
# Work Recording Pattern: How Work Is Recorded in a Wip-Managed Repo

**Status:** Draft (2026-11-20)
**Companions:** [pattern-workflow.md](./pattern-workflow.md) (how patterns are created), [federation-consulting-pattern.md](./federation-consulting-pattern.md) (how patterns spread)

This doc answers one question: when a Wip (an AI coordinator paired with a human) works inside a repo, how is the work recorded so that planning, scheduling and review can all see it?

It holds the **how**. A repo's contract holds the **values** (which calendar code, what the Wip may touch). The coordinator holds the **when and who**.

---

## Why a shared pattern

A Wip session inside a project repo sees only that repo. If the recording rules live only in the coordinator's repo, the session does not know them, and issues get filed without a done-definition, an estimate, or a place in the plan. Copying the rules into every contract means the copies drift. One public doc that each contract links to avoids both.

A private repo can link to a public doc safely. A public repo cannot link to a private doc without exposing it or leaving a dead link.

---

## The seven rules

1. **Issue before work.** Open the issue first, or as the first action of a session. Never after the work is done.
2. **Issue format.** Four parts:
   - `## Problem`
   - `## Suggested Solution`
   - `## Definition of Done` (a checklist; do not substitute another heading)
   - an `Effort:` line, for example `Effort: 2h`. Mark estimates you are unsure of as `(guess)`.
3. **Planning metadata.** The issue belongs to a milestone (an epic) or carries the `ready` label, so scheduling and triage can see it. If milestones are not used in the repo, link the epic issue instead.
4. **Authorship.** The Wip account files what the Wip observed or proposes. The human files what they have committed to. When someone with no repo account does the work, tag the issue (for example `@partner: <name>`) so a status bridge can mirror it.
5. **Routing.** The repo has a calendar code in the coordinator's repo map before work starts. A private repo is marked private, so published pages show a count and no titles.
6. **Reporting back.** Close an issue on its original Definition of Done. A new idea becomes a separate issue; do not expand the one in front of you. Priority is set at the weekly review, not between reviews.
7. **Commit path.** Changes go by pull request. The human merges. (Where the Wip and the human share one account, the merge is not distinguishable in history; note this in the contract.)

---

## Public and private repos

Some work has a public face and a private implementation.

| Repo | Holds | Written in |
|------|-------|------------|
| Public | Outcomes: what the owner can do or see when it is done | The owner's words |
| Private | Implementation: code, infrastructure, deployment detail | Technical words |

The bridge is a **release version**. A public item is closed with "covered by `<project> vX.Y.Z`", not by linking private issue titles. The owner can confirm the version in the running application, so no repo access is needed.

Never put terms, rates, contact details or secrets in a public repo, not even encrypted. Keep them in an access-controlled private location and publish at most a signed hash and a pointer.

---

## One-line reminder for a contract

A contract should link here and keep a short reminder, in case a session does not follow links:

```markdown
## How work is recorded
Follow [the work recording pattern](https://netstack.org/docs/ops/work-recording-pattern).
In short: issue before work; Problem / Suggested Solution / Definition of Done / `Effort:`;
milestone or `ready`; changes by pull request.
```

The link has no trailing slash: this site serves `/docs/ops/<name>` and returns 404 for `/docs/ops/<name>/`.

---

## What a contract adds

The contract states only what is specific to the repo:

- project name, owner, access level, repo visibility
- the calendar code
- what the Wip may and may not do
- who to contact and how
- anything the pattern leaves open (for example how releases are approved)

---

## Related

- [pattern-workflow.md](./pattern-workflow.md): netstack holds the how, the repo holds the values, the coordinator holds when and who
- [federation-consulting-pattern.md](./federation-consulting-pattern.md): how a pattern is adopted across sites
