# Pattern: AI-Powered Email Triage + Bulk Cleanup

**Category:** `docs/ops/tools/`  
**Purpose:** Use Google's native AI tools (Gemini, Workspace Studio) to automate email classification, labeling, and routing — reducing manual triage to near-zero.  
**Audience:** Any admin with a Google Workspace account who wants AI-assisted email management.

---

## The Problem

Manual email triage doesn't scale. Even with forwarding rules and filters, a human still has to:
- Read each message to decide what it is
- Route it to the right project/issue
- Decide: action needed, FYI, or noise?
- Periodically clean up accumulated mail

Google now provides built-in AI that can do most of this classification automatically.

---

## Available Tools (2026)

| Tool | What it does | Access | Cost |
|------|-------------|--------|------|
| **Gemini in Gmail** | Summarizes, prioritizes, suggests to-dos, drafts replies | Built into Gmail (enable Smart Features) | Included in Workspace |
| **AI Inbox** | Shows "Suggested to-dos" and "Topics to catch up on" | Gmail web/mobile | Included |
| **Google Workspace Studio** | No-code AI agent builder — automate labeling, archiving, data extraction | [studio.workspace.google.com](https://studio.workspace.google.com) or Gmail side panel icon | Included in Workspace |
| **Gmail Filters** | Rule-based routing (from, to, subject, has:attachment) | Gmail Settings | Free |
| **AI Overviews in Search** | Contextual AI summary when searching mail | Gmail search bar | Included |

---

## The Pattern: Layer AI on Top of Filters

```
Layer 1: Gmail Filters (deterministic, fast)
  - Route known senders to labels (GitHub → dev, Intuit → financial)
  - Forward actionable items to coordination layer
  - Auto-archive known noise (unsubscribe candidates)

Layer 2: Workspace Studio (AI classification)
  - New email arrives → Gemini classifies → applies ONE label
  - Categories: action, capture, dev, financial, noise, notification
  - Optionally: extract data to Sheets, draft reply, notify

Layer 3: Gemini in Gmail (human-assist)
  - AI Inbox surfaces suggested to-dos
  - Smart reply for quick responses
  - Search with AI Overviews for finding past context
```

---

## Deployed Implementation: Workspace Studio Flow

### What We Deployed (wip@horseoff.com, June 2026)

**Labels created (in Gmail before activating flow):**

| Label | Purpose | Action |
|-------|---------|--------|
| `wip/action` | Needs a response or task from me | Keep in inbox |
| `wip/capture` | New item to route through Effort Validation | Keep in inbox |
| `wip/dev` | GitHub, Gitea, CI/CD, code-related notifications | Skip inbox |
| `wip/financial` | Invoices, bills, payment confirmations | Keep in inbox |
| `wip/noise` | Marketing, promotions, automated junk | Archive |
| `wip/notification` | FYI — informational, no action needed | Skip inbox |

### Setup Steps (exact procedure)

1. **Create labels first** — Gmail → Settings → Labels → Create each label above. Studio cannot apply labels that don't exist.

2. **Open Workspace Studio** — [studio.workspace.google.com](https://studio.workspace.google.com) OR click the Workspace Studio icon in Gmail's right side panel.

3. **Create new flow** — use this natural language prompt:

```
When a new email arrives in my inbox, classify it into exactly ONE of these categories
based on the content, sender, and subject:

- "wip/action" — requires a response, decision, or task from me (requests, approvals, questions directed at me)
- "wip/capture" — contains a new idea, link, or item that should be captured for later processing
- "wip/dev" — developer notifications (GitHub, Gitea, CI/CD, build alerts, code reviews)
- "wip/financial" — invoices, bills, payment confirmations, bank alerts, accounting
- "wip/noise" — marketing, promotions, newsletters I didn't subscribe to, automated junk
- "wip/notification" — informational updates that don't require action (calendar responses, confirmations, FYI)

Rules:
- Apply ONLY ONE label (the single best match)
- If the email is from GitHub or Gitea → always "wip/dev"
- If the email contains "invoice" or "payment" → always "wip/financial"  
- If unsure between categories → use "wip/capture" (safe default for human review)
- If the email is a calendar acceptance/decline → "wip/notification"

After classifying:
- Apply the matching Gmail label
- If label is "wip/noise" → also archive the message (remove from inbox)
```

4. **Test** — send yourself a test email, wait 1-2 minutes, check if correct label was applied. Adjust prompt if classification is wrong.

5. **Activate** — once classification is accurate, enable the flow permanently.

### Lessons Learned

| Issue | Cause | Fix |
|-------|-------|-----|
| All labels applied to every message | Prompt said "classify into categories" (plural) | Changed to "classify into exactly ONE" + "Apply ONLY ONE label" |
| Labels not applying | Labels didn't exist in Gmail before flow activation | Create labels FIRST, then activate flow |
| Sent messages not classified | Studio flows only trigger on received messages | Expected behavior — only incoming gets classified |
| Classification takes 1-2 minutes | Studio is asynchronous, not instant | Normal — don't expect real-time |

### Verification

Check classification is working:
```javascript
// In morning-checkin.js or ad-hoc:
const labels = await gmail.users.labels.list({ userId: 'me' });
const wipLabels = labels.data.labels.filter(l => l.name.startsWith('wip/'));
for (const label of wipLabels) {
  const detail = await gmail.users.labels.get({ userId: 'me', id: label.id });
  console.log(`${label.name}: ${detail.data.messagesUnread || 0} unread`);
}
```

---

## Integration with Wip Dashboard

The email classification feeds directly into the coordination layer's morning check-in:

```
Workspace Studio classifies incoming email
    ↓
Morning check-in reads label counts via Gmail API:
  wip/action: 3 unread → "📬 3 action items need triage"
  wip/financial: 1 unread → "💰 1 financial item"
  wip/dev: 5 unread → "(info only, skip)"
  wip/noise: 0 → "(already archived by flow)"
    ↓
Daily report shows actionable count → Chris reviews wip/action items
    ↓
Each item gets routed: issue on project repo, calendar block, or archive
```

### The Admin Experience (phone-friendly)

1. **Morning:** Check calendar event → see "📬 3 action items" in description
2. **If time:** Open wip@ inbox → only `wip/action` + `wip/capture` items visible (everything else auto-handled)
3. **Route:** Each action item → becomes an issue on the right repo (per contract-map)
4. **Done:** Inbox stays near-zero without manual sorting

---

## For Other Netstack Admins

Any admin with a Google Workspace account can replicate this:

1. **Choose your label prefix** — we used `wip/`. You might use `ops/`, `admin/`, or your name.
2. **Define your categories** — adapt from our 6 categories to match your workflow.
3. **Create the labels in Gmail** — must exist before the flow can apply them.
4. **Set up the Studio flow** — copy our prompt, adjust category names.
5. **Connect to your coordination layer** — whether that's a wip repo, a Trello board, or just your own review process, the labels tell you what needs attention.

**Minimum viable setup:** 3 labels (`action`, `dev`, `noise`) + Studio flow. You can add more categories later as you understand your email patterns.

---

## Bulk Cleanup Procedure

For accounts with years of accumulated mail:

### Phase 1: Archive by Age
```
Gmail search: before:2025/01/01
Select all → Archive
```

### Phase 2: Unsubscribe Campaign
```
Gmail search: unsubscribe newer_than:30d
Open top senders → Unsubscribe (link at top of message) → delete their history
```

### Phase 3: Large Attachments
```
Gmail search: has:attachment larger:5M
Review → download what you need → delete the rest
```

---

## Cross-Provider Strategy

For non-Gmail accounts that don't have native AI:

| Provider | Best Strategy |
|----------|--------------|
| **Yahoo** | IMAP migration to Gmail → then apply AI |
| **Outlook/Live** | Forward all to Gmail OR migrate |
| **Apple (iCloud)** | Forward selectively (limited API) |
| **Personal Gmail** | Can't use Studio — forward actionable items TO Workspace account where Studio runs |

**Principle:** Consolidate everything into a Workspace Gmail where AI can work on it.

---

## Privacy and Security

| Concern | Reality | Mitigation |
|---------|---------|------------|
| Gemini reads all email | Yes (since Oct 2025, on by default) | Accept for business accounts; disable for personal if desired |
| Data used for training | Workspace: NOT used for training (enterprise ToS) | Use Workspace for sensitive business email |
| Classification errors | AI will mis-classify some messages | Start with "label only" (no auto-archive) for first week |

---

## Related

- [email-workspace-consolidation-pattern](./email-workspace-consolidation-pattern.md) — reduce accounts first, then apply AI
- [personal-gmail-maintenance-pattern](../users/personal-gmail-maintenance-pattern.md) — personal Gmail cleanup + forwarding
- [pattern-workflow](../pattern-workflow.md) — netstack drives all ops
- [personal-wip-pattern](https://github.com/2cld/netstack/issues/5) — coordination layer for solo admins (planned)
- [Google: Workspace Studio admin setup](https://support.google.com/a/answer/16796372)
- [Google: Get started with Workspace Studio](https://support.google.com/workspace-studio/answer/16444479)
- [Google: Access Studio from Gmail side panel](https://support.google.com/workspace-studio/answer/16765741)
- [Google: Gemini in Gmail](https://workspace.google.com/intl/en/products/gmail/ai/)
