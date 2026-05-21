# Request Lifecycle Pattern — Proactive Monitoring and Feedback

**Applies to:** Any coordination layer managing requests across multiple admins/nodes

## Principle

> Every request should have a corresponding monitor that detects when it's been fulfilled. Proactive acknowledgment builds trust and improves future response time.

## The Problem

Traditional request flow:
1. Detect issue
2. Send request to responsible person
3. Wait...
4. Eventually ask "did you do it?"
5. Person says "oh yeah, I did that last week"
6. No feedback loop, no reinforcement

## The Solution: Request + Verification Monitor

```
1. DETECT    — Monitor flags an issue (automated)
2. REQUEST   — Send to responsible admin (email, issue)
3. QUEUE     — Add to request queue with verification check
4. MONITOR   — Automated check runs daily/weekly
5. RESOLVE   — When check passes, send proactive "thank you"
6. CLOSE     — Move to resolved, log the resolution
```

## Request Queue Format

| Request | Sent To | Date | Verification Check | Frequency | Status |
|---------|---------|:----:|-------------------|:---------:|:------:|
| Enable SSH on Node X | admin@example | 2026-05-21 | `ssh -o ConnectTimeout=3 user@node "echo ok"` | Daily | Pending |
| Backup critical DB | dev@example | 2026-05-20 | Check file date newer than request date | Weekly | Pending |
| Set up monitoring | admin@example | 2026-05-21 | Status output file exists | Daily | Pending |

## Verification Check Types

| What to Verify | How | Example |
|---------------|-----|---------|
| Service is running | TCP connect or HTTP check | `curl -s -o /dev/null -w "%{http_code}" http://host:port` |
| SSH is enabled | SSH connection test | `ssh -o ConnectTimeout=3 -o BatchMode=yes user@host "echo ok"` |
| File was created | Check file existence + date | `ls -la /path/to/expected/file` |
| Backup is fresh | Compare file date to threshold | `find /backup -name "*.tar" -newer /reference` |
| Config was applied | Read config and verify value | `ssh host "cat /etc/config \| grep expected"` |

## Proactive Acknowledgment

When a verification check transitions from "pending" to "resolved":

```
Subject: Thanks - [request description] is working

[Admin],

I can confirm [specific thing] is now working:
  - Verified: [what the check detected]
  - Time: [when it was detected]

This resolves the request from [date].
[Any follow-up actions enabled by this resolution]

-- Coordination Layer
```

### Why This Matters

- **Positive reinforcement:** Admin feels acknowledged for their work
- **Builds trust:** Admin knows the coordination layer is paying attention
- **Improves response time:** Next request gets faster action (proven feedback loop)
- **Reduces nagging:** No need to ask "did you do it?" — the monitor knows
- **Creates accountability:** Both sides have a record of request → resolution

## Integration with Morning Check-in

The daily check-in runs all verification checks and reports:

```
--- OPEN REQUESTS ---
  SSH on Node X: still pending (3 days)
  Backup to off-site: still pending (1 day)
  Perf monitoring: RESOLVED (send thanks!)
```

Stale requests (pending > threshold) get escalated:
- 3+ days: mention in daily check-in
- 7+ days: re-send request with "gentle reminder"
- 14+ days: escalate to higher admin or flag as blocked

## Connection to Red Alerts

Red alerts are a special case of requests:
- Red alert = urgent request (daily squeak until resolved)
- Yellow alert = important request (weekly check)
- Request = normal ask (weekly check, escalate if stale)

The verification pattern is the same for all three — only the urgency and squeak frequency differ.

## Anti-Patterns

- **Don't nag without checking:** Always verify before re-sending. Maybe it's done and you just can't see it yet.
- **Don't skip the thank-you:** The acknowledgment IS the feedback loop. Without it, you're just a nagging bot.
- **Don't automate the fix:** The coordination layer requests and verifies. It doesn't implement (stay in your lane).
- **Don't forget to close:** Resolved requests that stay "open" erode trust in the system.

## Related
- [Monitoring Pattern](monitor/monitoring-pattern.md) — how to build verification checks
- [Session Logging](tools/session-logging.md) — documenting request/resolution history
- [Federation Production Plan](../ops-federation-production-plan.md) — Phase 5 (operations)
- [Sensitive Data Pattern](security/sensitive-data-pattern.md) — what not to include in request emails
