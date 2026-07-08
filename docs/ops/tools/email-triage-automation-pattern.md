# Pattern: Scriptable Email Triage + Maintenance

**Category:** `docs/ops/tools/`  
**Purpose:** Classify incoming email by contract routing rules, label, archive noise, surface actions — all via script.  
**Audience:** Any netstack admin managing one or more email accounts who wants automated triage without depending on UI-only tools.  
**Reference implementation:** wip `.local/scripts/email-triage.js`

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
  { match: { subject: 'declined' }, label: 'PREFIX/notification', action: 'archive' },

  // Project contacts (from your contract-map)
  { match: { from: '@client-domain.com' }, label: 'PREFIX/action', action: 'inbox', project: 'project-code' },

  // Financial
  { match: { subject: 'invoice' }, label: 'PREFIX/financial', action: 'inbox' },
  { match: { subject: 'payment' }, label: 'PREFIX/financial', action: 'inbox' },

  // Known noise
  { match: { from: 'noreply@' }, label: 'PREFIX/noise', action: 'archive' },
  { match: { from: 'marketing@' }, label: 'PREFIX/noise', action: 'archive' },
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

**Modes:**
- **Preview** (default): Shows what would happen. Safe to run anytime.
- **Apply**: Actually labels messages and archives noise/notification.
- **Status**: One-liner per label — how many unread in each bucket.

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

### Configuration

```json
{
  "account": "your-email@example.com",
  "provider": "gmail",
  "connection": "api",
  "label_prefix": "wip",
  "rules_source": "inline"
}
```

---

## Provider Abstraction (future)

The classification logic is provider-independent. Only the connection layer changes:

| Provider | Connection | Labels | Archive |
|----------|-----------|--------|---------|
| Gmail (Workspace) | Gmail API | Gmail labels | Remove INBOX label |
| Gmail (personal) | Gmail API | Gmail labels | Remove INBOX label |
| Yahoo | IMAP | IMAP folders | Move to folder |
| Outlook | IMAP (or Graph API) | IMAP folders | Move to folder |

```javascript
const providers = {
  gmail: { listUnread, getHeaders, applyLabel, archive },
  imap:  { listUnread, getHeaders, moveToFolder, archive }
};
```

---

## Integration with Coordination Layer

### Daily cron integration

```bash
# In wip-daily-cron.sh (or equivalent):
node email-triage.js --apply    # Classify new messages
node email-triage.js --status   # Report label counts in daily report
```

### Morning check-in integration

The status output feeds into the daily report:
```
📬 action: 2 unread | dev: 15 | capture: 1 (review) | notification: 0 | noise: 0
```

Only `action` and `capture` need human attention. Everything else is auto-handled.

---

## Maintenance Script (periodic)

Separate from daily triage — runs weekly or monthly:

| Operation | What | When |
|-----------|------|------|
| Spam rescue | Scan spam, check against "never-spam" list | Weekly |
| Capture review | What's in capture? Should any become rules? | Weekly |
| Storage report | Size by age, large attachments | Monthly |
| Unsubscribe audit | Senders with >10 messages, no engagement | Monthly |
| Archive by age | Messages >90 days, not starred/critical | Monthly |

```bash
email-maintenance.js --report       # show what would happen
email-maintenance.js --apply        # execute cleanup
email-maintenance.js --spam-rescue  # just the spam check
```

---

## Security Considerations

- OAuth tokens stored in gitignored files (per sensitive-data-pattern)
- Script only reads headers for classification (not full body by default)
- Labels are applied, messages are never deleted (archive ≠ delete)
- Preview mode (default) makes no changes — safe to test

---

## Example: Minimal Setup (3 labels)

For admins who want the simplest possible version:

1. Create 3 labels: `ops/action`, `ops/dev`, `ops/noise`
2. Rules: GitHub → dev, known noise → noise, everything else → action
3. Run daily: `node email-triage.js --apply`
4. Review `ops/action` inbox items manually

Scale up by adding `financial`, `notification`, `capture` as your volume justifies.

---

## Related

- [email-ai-triage-pattern](./email-ai-triage-pattern.md) — Workspace Studio approach (AI classification, supplements this)
- [personal-gmail-maintenance-pattern](../users/personal-gmail-maintenance-pattern.md) — manual maintenance procedures
- [email-workspace-consolidation-pattern](./email-workspace-consolidation-pattern.md) — reduce accounts first
- [contract-map](https://github.com/2cld/wip/blob/main/docs/contract-map.md) — source of routing rules
- [netstack#14](https://github.com/2cld/netstack/issues/14) — tracking issue
