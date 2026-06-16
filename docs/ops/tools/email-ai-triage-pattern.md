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
| **Google Workspace Studio** | No-code AI agent builder — automate labeling, archiving, data extraction | [studio.google.com](https://studio.google.com) | Included in Workspace |
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
  - New email arrives → Gemini classifies → applies label
  - Categories: action-required, fyi, financial, dev-notification, noise
  - Optionally: extract data to Sheets, draft reply, notify

Layer 3: Gemini in Gmail (human-assist)
  - AI Inbox surfaces suggested to-dos
  - Smart reply for quick responses
  - Search with AI Overviews for finding past context
```

---

## Setup: Workspace Studio Auto-Label Agent

### Prerequisites
- Google Workspace account with Workspace Studio enabled
- Gmail API access (should already be active on Workspace accounts)
- Visit [studio.google.com](https://studio.google.com) to confirm access

### Step 1: Create New Automation

1. Go to **Workspace Studio** → "Create new"
2. Describe in natural language:

```
When a new email arrives in my inbox:
1. Use Gemini to classify it into one of these categories:
   - "action-required" (needs a response or task from me)
   - "financial" (invoices, bills, payment confirmations)
   - "dev-notification" (GitHub, Gitea, CI/CD alerts)
   - "fyi" (informational, no action needed)
   - "noise" (marketing, promotions, automated junk)
2. Apply a Gmail label matching the category name
3. If category is "noise", archive it (remove from inbox)
4. If category is "action-required", also forward to wip@horseoff.com
```

3. Review the automation Gemini builds → test with sample emails → activate

### Step 2: Configure Categories

Customize categories for your workflow:

| Category | Label | Auto-Action | Forward to Coordination? |
|----------|-------|-------------|:------------------------:|
| action-required | `ai/action` | Keep in inbox | ✅ Yes |
| financial | `ai/financial` | Keep in inbox | ✅ Yes |
| dev-notification | `ai/dev` | Skip inbox (but keep) | Only if issue-related |
| fyi | `ai/fyi` | Skip inbox | ❌ No |
| noise | `ai/noise` | Archive | ❌ No |

### Step 3: Test and Tune

1. Run for 1 week in "label only" mode (no auto-archive yet)
2. Review: did it classify correctly? Adjust natural language prompt if not
3. Once accurate: enable auto-archive for noise, auto-forward for action-required
4. Check weekly: any mis-classifications? Add to prompt as examples

---

## Setup: Gemini in Gmail (AI Inbox)

### Enable Smart Features
1. Gmail → Settings → "See all settings" → General tab
2. Check: "Smart features and personalization"
3. Check: "Smart features and personalization in other Google products"
4. Save

### Using AI Inbox
Once enabled, Gmail shows:
- **Suggested to-dos** — high-priority items extracted from email content
- **Topics to catch up on** — grouped summaries of related messages
- **AI summaries** — one-line summary at top of long email threads

### Integration with Coordination Layer
During morning check-in, Wip can reference AI Inbox to-dos:
- Read via Gmail API: messages with `ai/action` label = pre-classified action items
- Reduces triage from "read every email" to "review AI-flagged items only"

---

## Bulk Cleanup Procedure

For accounts with years of accumulated mail:

### Phase 1: Archive by Age
```
Gmail search: before:2025/01/01
Select all → Archive

Gmail search: before:2024/01/01 (already archived from above, but catches stragglers)
```

### Phase 2: Unsubscribe Campaign
```
Gmail search: unsubscribe newer_than:30d
Sort by sender → unsubscribe from top noise sources
Then: from:sender@noise.com → select all → delete
```

### Phase 3: Large Attachments
```
Gmail search: has:attachment larger:5M
Review → download what you need → delete the rest
```

### Phase 4: Workspace Studio Cleanup Agent
Create automation:
```
Find all emails older than 2 years that are:
- Not starred
- Not labeled "important" or "action-required"
- Not in a conversation I replied to
Archive them all.
```

---

## Cross-Provider Strategy

For non-Gmail accounts that don't have native AI:

| Provider | Best Strategy | Steps |
|----------|--------------|-------|
| **Yahoo** | IMAP migration to Gmail → then apply AI | Gmail Settings → Check mail from other accounts → Add Yahoo IMAP |
| **Outlook/Live** | Forward all to Gmail OR migrate | Outlook → Settings → Forwarding → forward to Gmail |
| **Apple (iCloud)** | Forward selectively (limited API) | iCloud Mail → Rules → forward matching |
| **Other** | Cold archive (Download My Data) → close | Download mbox → store offline → delete account |

**Principle:** Consolidate everything into Gmail where AI can work on it. Non-Gmail providers become either forwarding sources or archived history.

---

## Integration with Coordination Layer (Wip)

```
Email arrives at any account
    ↓
Forwarding rules send to Gmail primary (or directly to wip@)
    ↓
Workspace Studio classifies + labels
    ↓
Morning check-in reads labels via Gmail API:
  - ai/action → surface in morning report as "needs triage"
  - ai/financial → surface in LLC Epic section
  - ai/dev → cross-reference with active NEXT items
  - ai/fyi, ai/noise → skip (already handled)
    ↓
Human reviews flagged items → routes to issues
```

### API Integration (morning-checkin.js enhancement)
```javascript
// Read AI-classified action items
const actionMessages = await gmail.users.messages.list({
  userId: 'me',
  q: 'label:ai/action is:unread'
});
// Surface in morning report
console.log(`📬 ${actionMessages.length} action items (AI-classified)`);
```

---

## Privacy and Security Considerations

| Concern | Reality | Mitigation |
|---------|---------|------------|
| Gemini reads all email | Yes (since Oct 2025, on by default) | Accept for business accounts; disable for personal if desired |
| Data used for training | Workspace: NOT used for training (enterprise ToS). Personal: may be. | Use Workspace accounts for sensitive business email |
| Classification errors | AI will mis-classify some messages | Keep "label only" mode for first week; review before enabling auto-archive |
| Forwarding sensitive data | Forwarding to coordination layer moves data between accounts | Both accounts should be same Workspace domain or trusted |

---

## Reference Implementation: wip@horseoff.com

**Domain:** horseoff.com (Google Workspace)  
**Volume:** Low (system alerts, forwarded items only)  
**Goal:** Near-zero manual triage

Setup:
1. Workspace Studio agent classifies incoming → labels `ai/action`, `ai/dev`, `ai/noise`
2. `ai/noise` auto-archived
3. `ai/action` stays in inbox → `morning-checkin.js` reads via API
4. `ai/dev` skips inbox → checked during project monitoring

This is the simplest test case because:
- Low volume (easy to validate accuracy)
- Known senders (GitHub, Gitea, forwarding rules)
- Full API access already configured
- No legacy cleanup needed

Once proven here → apply to christrees@gmail.com (higher volume) → then HWPC domain accounts.

---

## Related

- [email-workspace-consolidation-pattern](./email-workspace-consolidation-pattern.md) — reduce accounts first, then apply AI
- [pattern-workflow](../pattern-workflow.md) — netstack drives all ops
- [Wip ops-email-processing.md](https://github.com/2cld/wip/blob/main/docs/ops-email-processing.md) — current manual pipeline
- [wip#5](https://github.com/2cld/wip/issues/5) — Wip email inbox processing
- [Google: Manage to-dos with AI Inbox](https://support.google.com/mail/answer/16845247)
- [Google: Workspace Studio Gmail automation](https://support.google.com/appsheet/answer/15725655)
- [Google: Gemini in Gmail](https://workspace.google.com/intl/en/products/gmail/ai/)
