[edit](https://github.com/2cld/netstack/edit/master/docs/ops/tools/email-triage-automation-pattern.md)

# Pattern: Scriptable Email Triage + Maintenance

**Category:** `docs/ops/tools/`  
**Purpose:** Classify incoming email by contract routing rules, label, archive noise, surface actions — all via script.  
**Audience:** Any netstack admin managing one or more email accounts who wants automated triage without depending on UI-only tools.  
**Reference implementation:** [wip `.local/scripts/email-triage.js`](https://github.com/2cld/wip)  
**Tracking:** [netstack#14](https://github.com/2cld/netstack/issues/14)

---

## The Problem

Email accumulates. Without automation:
- Important messages get buried
- Dev notifications clog the inbox
- Nobody knows which project owns an email
- Calendar responses pile up unread
- "I'll deal with it later" becomes "I'll never deal with it"

UI-based solutions (Workspace Studio, Gmail filters) can't be:
- Version controlled
- Tied to project contracts
- Run across multiple providers
- Tested or debugged programmatically

---

## The Solution: Contract-Driven Classification

```
email-config.json (accounts + connection method)
       │
       ▼
email-triage.js (daily — classify new messages)
       │
       ├─ Read unread/unclassified messages
       ├─ Match sender/subject against routing rules
       ├─ Rules derived from contract-map (who → which project)
       ├─ Apply label/folder
       ├─ Archive noise + notifications
       └─ Report: X action, Y dev, Z capture (unsure)
```

---

## Classification Buckets

| Bucket | What goes here | Action | Human review? |
|--------|---------------|--------|:-------------:|
| `action` | Direct requests, approvals, tasks from contract contacts | Keep in inbox | Yes — route to issue |
| `dev` | GitHub, Gitea, CI/CD notifications | Label, skip inbox | No |
| `financial` | Invoices, payments, bank alerts | Keep in inbox | Yes — track |
| `notification` | Calendar responses, confirmations, FYI | Archive | No |
| `noise` | Marketing, newsletters, automated junk | Archive | No |
| `capture` | **Everything else** (unsure) | Keep in inbox | Yes — add rule or dismiss |

**Key design:** `capture` is the safe default. Unknown senders go here for human review. Over time, you add rules for recurring senders → the capture bucket shrinks.

---

## Routing Rules Format

Rules are ordered — first match wins:

```javascript
const RULES = [
  // Dev notifications
  { match: { from: '@github.com' }, label: 'PREFIX/dev', action: 'skip-inbox' },
  { match: { from: 'gitea.example.com' }, label: 'PREFIX/dev', action: 'skip-inbox' },

  // Calendar noise
  { match: { from: 'calendar-notification@google.com' }, label: 'PREFIX/notification', action: 'archive' },
  { match: { subject: 'accepted' }, label: 'PREFIX/notification', action: 'archive' },

  // Project contacts (from your contract-map)
  { match: { from: '@client-domain.com' }, label: 'PREFIX/action', action: 'inbox', project: 'project-code' },

  // Financial
  { match: { subject: 'invoice' }, label: 'PREFIX/financial', action: 'inbox' },

  // Known noise
  { match: { from: 'noreply@' }, label: 'PREFIX/noise', action: 'archive' },
];

// Default: unsure → capture (human reviews)
const DEFAULT = { label: 'PREFIX/capture', action: 'inbox' };
```

---

## CLI Interface

```bash
email-triage.js              # preview (show classifications, don't touch anything)
email-triage.js --apply      # classify + label + archive
email-triage.js --status     # show label counts (quick health check)
```

---

## Setup (Gmail API)

### Prerequisites
- Google Workspace or personal Gmail account
- OAuth2 credentials with Gmail scope (`gmail.modify`)
- Labels created in Gmail (must exist before script can apply them)

### Labels to Create

In Gmail Settings → Labels → Create:
- `PREFIX/action`
- `PREFIX/dev`
- `PREFIX/financial`
- `PREFIX/notification`
- `PREFIX/noise`
- `PREFIX/capture`

Replace `PREFIX` with your namespace (e.g., `wip`, `ops`, `admin`).

---

## Provider Abstraction (future)

The classification logic is provider-independent. Only the connection layer changes:

| Provider | Connection | Labels | Archive |
|----------|-----------|--------|--------|
| Gmail (Workspace) | Gmail API | Gmail labels | Remove INBOX label |
| Gmail (personal) | Gmail API | Gmail labels | Remove INBOX label |
| Yahoo | IMAP | IMAP folders | Move to folder |
| Outlook | IMAP (or Graph API) | IMAP folders | Move to folder |

---

## Integration with Coordination Layer

### Daily cron
```bash
node email-triage.js --apply    # Classify new messages
node email-triage.js --status   # Report in daily summary
```

### Morning check-in output
```
📬 action: 2 | dev: 15 | capture: 1 (review) | notification: 0 | noise: 0
```

Only `action` and `capture` need human attention.

---

## Maintenance Script (periodic)

| Operation | What | When |
|-----------|------|------|
| Spam rescue | Scan spam, check against "never-spam" list | Weekly |
| Capture review | What's in capture? Should any become rules? | Weekly |
| Storage report | Size by age, large attachments | Monthly |
| Unsubscribe audit | Senders with >10 messages | Monthly |
| Archive by age | Messages >90 days, not critical | Monthly |

---

## Example: Minimal Setup (3 labels)

1. Create 3 labels: `ops/action`, `ops/dev`, `ops/noise`
2. Rules: GitHub → dev, known noise → noise, everything else → action
3. Run daily: `node email-triage.js --apply`
4. Review `ops/action` items manually

Scale up as volume justifies.

---

## Related

- [email-ai-triage-pattern](./email-ai-triage-pattern.md) — Workspace Studio AI approach (supplements this)
- [personal-gmail-maintenance-pattern](../users/personal-gmail-maintenance-pattern.md) — manual procedures
- [email-workspace-consolidation-pattern](./email-workspace-consolidation-pattern.md) — reduce accounts first
- [sensitive-data-pattern](../security/sensitive-data-pattern.md) — token storage
- [netstack#14](https://github.com/2cld/netstack/issues/14) — tracking issue
