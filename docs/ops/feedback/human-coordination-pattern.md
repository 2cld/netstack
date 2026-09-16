# Pattern: Low-Friction Human Coordination

**Status:** pattern (generalized from the wip coordinator; see 2cld/wip docs/design-human-coordination.md)
**Applies to:** any coordinator (a "Wip") that directs a human's attention across a federation of
projects and sites.
**Related:** contract-driven-monitoring-pattern · status-freshness-cron-pattern · repo-health-check-pattern

---

## Principle

> A coordinator should direct a human through the channels the human **already lives in** —
> calendar, email, chat, and repo issues — not by making the human feed a bespoke tool.
> Every signal that can ride an existing channel must.

Coordination is bidirectional and only works if **both** directions are low-friction. If telling the
coordinator something is high-friction, the human stops doing it, and the coordinator plans from stale
or missing input.

---

## The channels

| Channel | Human's use | Coordinator's use |
|---------|-------------|-------------------|
| Calendar | living the day; recording what happened | proposing the day; alerting; the human's *time* priority surface |
| Repo issues | project work + priority (traditional home) | source of truth for *project* priority, blocked-state, effort |
| Email | inbox; external capture | triage → route to issue/calendar |
| Chat | ad-hoc capture; thinking out loud | capture → route; conversational planning |

**Two priority surfaces, one translation job:** the calendar is the *human's-day* priority surface;
the repo issue is the *project's* priority surface. The coordinator's core function is translating
between them — issues → a proposed day, and what-actually-happened → project state.

---

## The two feedback loops

- **Coordinator → Human:** proposed schedule, alerts, confirmations. The human reads the
  coordinator's view of priority by looking at their own calendar.
- **Human → Coordinator:** what matters, what's blocked, what's next. Traditionally the repo issue —
  but raw issue-editing is high-friction. **Fix:** let the human feed priority/blocked/effort through
  a frictionless surface (a tagged calendar note, an accept/decline/move) and have the coordinator
  **write it back to the issue.** The issue stays the system of record; the low-friction surface is
  the input path.

---

## Lanes (with latency tolerance)

Coordination signals fall into lanes with different urgency, interrupt-rights, and **latency
tolerance.** Confusing lanes is a top friction source. Remind the human which lane they're in.

| Lane | Interrupt rights | Latency tolerance |
|------|------------------|-------------------|
| Personal | none (human owns it) | n/a |
| Project (from issues) | proposed in the periodic fill | predictable — done before the human looks |
| Alert (something broke) | may interrupt the day | minutes |
| Log-back (record past work) | none | hours — recording, not acting |
| Blocked (can't proceed) | none — must NOT be scheduled | until unblocked |

**Lane-dependency (ordering):** log-back runs before the fill (logged work occupies its slot first);
alerts override the proposed day; blocked items are removed from the proposal pool, not scheduled.

---

## HELL — Human Envolvement Loop Latency

The latency in the loop between human and coordinator. Batching trades immediacy for the human's
peace: too fast churns the human's calendar (can't tell "settled" from "in-flight"); too slow leaves
signals stale and erodes trust.

**Do not use a single global frequency knob — tune per lane** (see table). And note the real driver
of HELL-pain is **trust, not raw delay**: a signal the human trusts will be processed creates no
anxiety; an unacknowledged one makes them watch the pot, and the watching is the cost. Levers:
(1) match cadence to the lane, (2) give cheap acknowledgment so the human can stop watching.

---

## What an issue must carry (so the coordinator can translate)

The periodic fill is only as good as its input. An issue should carry:

1. **Priority** — MUST (hard deadline) / SHOULD / WANT — drives scheduling + stickiness.
2. **Blocked-state + blocker** — blocked work must not be scheduled.
3. **Effort** — rough size for sane slotting.

Corollaries:
- **Sticky MUST:** hard-deadline items re-surface until the issue closes, even if declined once.
- **Frictionless blocked-signal:** a tagged note (calendar/chat) marks an issue blocked; the
  coordinator records the blocker and stops scheduling until unblocked.

---

## Why this matters for the federation

A backup human at any site interacts with their own coordinator through the *same* channels and
lanes. Standardizing the interaction model means the coordination substrate (repos/issues,
 contract-driven monitoring) is legible to any human-and-coordinator pair — which is what lets the
federation scale past a single operator. See 2cld/wip ops-federated-coordination.md for the
substrate side.
