# Pattern: Personal Gmail Account Maintenance

**Category:** `docs/ops/users/`  
**Purpose:** Routine maintenance procedure for personal Gmail accounts — filter auditing, spam rescue, cleanup, and forwarding to coordination layer.  
**Audience:** Anyone managing one or more personal Gmail accounts who wants to prevent important mail from being lost and keep storage manageable.

---

## The Problem

Personal Gmail accounts accumulate cruft over time:
- Filters created years ago that conflict with newer ones
- Important senders landing in spam (false positives)
- Storage creeping toward the 15GB free limit
- No visibility into what's being auto-archived or filtered
- Multiple accounts with no clear routing between them

Unlike Workspace accounts, personal Gmail has no admin console, no Workspace Studio, and limited automation. Maintenance must be manual but can be systematic.

---

## Monthly Maintenance Checklist

Run this monthly (set a calendar reminder, or add to Sunday Evening Review):

- [ ] **Spam rescue** — check spam folder for false positives (important senders caught)
- [ ] **Filter audit** — review all filters, look for conflicts or stale rules
- [ ] **Storage check** — are you approaching 15GB? Clean if > 80%
- [ ] **Forwarding verify** — confirm forwarding rules are still active and delivering
- [ ] **Security check** — review connected apps, recovery email/phone, 2FA status
- [ ] **Unsubscribe pass** — search `unsubscribe newer_than:30d`, kill top noise sources

---

## Procedure: Spam Rescue

When important mail lands in spam:

### Immediate Fix
1. Open Spam folder
2. Find the wrongly-flagged message(s)
3. Select → click **"Not spam"** (trains Gmail's classifier)
4. Create a filter to prevent recurrence:

### Create "Never Spam" Filter
1. Gmail → Settings → Filters and Blocked Addresses → Create new filter
2. From: `sender@important.com` (or the domain: `@insurancecompany.com`)
3. Click "Create filter"
4. Check: **"Never send it to Spam"**
5. Optionally: Apply label, Star it, or Forward to coordination inbox
6. Check: "Also apply filter to matching conversations" (rescues existing messages)
7. Click "Create filter"

### Critical Senders List

Maintain a list of senders that should NEVER go to spam. Review quarterly:

| Category | Senders to protect |
|----------|-------------------|
| Insurance | `@statefarm.com`, `@progressive.com`, etc. |
| Banking | `@chase.com`, `@ally.com`, etc. |
| Tax/Legal | `@intuit.com`, `@irs.gov`, etc. |
| Medical | `@mychart.com`, provider domains |
| Utilities | `@alliantenergy.com`, `@windstream.com` |
| Family | specific family member addresses |

---

## Procedure: Filter Audit

### Export Current Filters
1. Gmail → Settings → Filters and Blocked Addresses
2. Scroll to bottom → "Export all filters" (downloads XML)
3. Save to a known location (or commit to a private repo for version control)

### Review Each Filter

For each filter ask:

| Question | If Yes |
|----------|--------|
| Is this still relevant? | Keep |
| Does it conflict with another filter? | Fix — later filters override earlier ones |
| Is it catching things it shouldn't? | Narrow the criteria |
| Does it forward to an address that still exists? | Verify delivery |
| Was this created for a one-time thing? | Delete |

### Common Conflicts

| Conflict | Symptom | Fix |
|----------|---------|-----|
| Filter A skips inbox + Filter B stars | Message starred but never seen | Remove "skip inbox" or merge filters |
| Old forward to dead address | Bounces you never see | Remove or update forward address |
| Overly broad "from:" match | Catches legitimate senders | Narrow to specific address, not domain |
| "Delete it" filter still active | Missing messages you expect | Convert to "archive" instead of "delete" |

### Filter Naming Convention

Gmail doesn't name filters, but you can identify them by their criteria. Document your filters:

```markdown
## Active Filters (christrees@gmail.com)

| # | Criteria | Action | Purpose | Added |
|---|----------|--------|---------|-------|
| 1 | from:@github.com | label:dev, skip inbox | Dev notifications | 2024-01 |
| 2 | from:@statefarm.com | never spam, label:insurance | Insurance | 2026-06 |
| 3 | to:wip@horseoff.com | forward, archive | Coordination capture | 2026-05 |
```

---

## Procedure: Storage Management

Gmail personal accounts share 15GB across Gmail, Drive, and Photos.

### Check Current Usage
- Go to [one.google.com/storage](https://one.google.com/storage)
- See breakdown: Gmail vs Drive vs Photos

### Cleanup by Size (biggest wins first)
```
Gmail search: has:attachment larger:10M
→ Review, download what you need, delete the rest

Gmail search: has:attachment larger:5M
→ Same process

Gmail search: larger:2M older_than:2y
→ Bulk archive or delete old large messages
```

### Cleanup by Age
```
Gmail search: before:2023/01/01
→ Select all → Archive (or delete if you're comfortable)

Gmail search: before:2022/01/01 in:anywhere
→ Nuclear option for very old mail
```

### Cleanup by Category
```
Gmail search: category:promotions older_than:6m
→ Select all → Delete (promotions older than 6 months are noise)

Gmail search: category:social older_than:1y
→ Select all → Delete

Gmail search: category:updates older_than:1y
→ Review, then archive or delete
```

### Unsubscribe Campaign
```
Gmail search: unsubscribe newer_than:30d
→ Group by sender (use "from:" search for top offenders)
→ Open one from each sender → scroll to bottom → Unsubscribe
→ Then: from:sender@noise.com → select all → delete
```

---

## Procedure: Forwarding to Coordination Layer

Personal Gmail can't run Workspace Studio, but it CAN forward to a Workspace account that does.

### Setup Forwarding
1. Gmail → Settings → Forwarding and POP/IMAP
2. Click "Add a forwarding address" → enter `wip@horseoff.com`
3. Google sends verification to wip@ → confirm it
4. DO NOT enable "Forward all" — use filters instead

### Selective Forwarding via Filters
Create filters that forward specific mail to wip@:

```
Criteria: from:@github.com OR from:@gitea.cat9.me
Action: Forward to wip@horseoff.com, Apply label: "forwarded-to-wip"

Criteria: subject:invoice OR subject:payment OR subject:due
Action: Forward to wip@horseoff.com, Apply label: "forwarded-to-wip"

Criteria: from:@statefarm.com OR from:@alliantenergy.com
Action: Forward to wip@horseoff.com, Apply label: "forwarded-to-wip"
```

### What Happens Next
- wip@horseoff.com receives the forwarded messages
- Workspace Studio flow classifies them (`wip/action`, `wip/financial`, etc.)
- Morning check-in surfaces classified items
- Personal Gmail stays clean — you see it, wip processes it

---

## Procedure: Security Audit

### Quarterly Security Check
1. Go to [myaccount.google.com/security](https://myaccount.google.com/security)
2. Review:
   - [ ] 2FA enabled? (should be: security key or authenticator app)
   - [ ] Recovery email current? (not a dead address)
   - [ ] Recovery phone current?
   - [ ] Recent security events — anything unexpected?
3. Go to [myaccount.google.com/permissions](https://myaccount.google.com/permissions)
   - Review third-party app access
   - Remove anything you don't recognize or no longer use
4. Go to [myaccount.google.com/device-activity](https://myaccount.google.com/device-activity)
   - Review devices with access
   - Remove old/unknown devices

---

## AI Features on Personal Gmail (2026)

What's available WITHOUT Workspace:

| Feature | Status | How to Enable |
|---------|--------|---------------|
| AI Inbox (to-dos + topics) | ✅ Rolling out globally | Settings → Smart features → enable |
| AI summaries on threads | ✅ Available | Automatic (shows at top of long threads) |
| AI Overviews in search | ✅ Available | Just search — AI summary appears |
| Smart compose | ✅ Available | Settings → Smart Compose → on |
| Smart reply | ✅ Available | Settings → Smart Reply → on |
| Workspace Studio | ❌ Not available | Workspace only |
| Custom AI agents | ❌ Not available | Workspace only |
| Google One AI Premium | 💰 $20/mo | Enhanced Gemini, 2TB storage, more AI features |

### Strategy for Personal Accounts
- Enable all free AI features (they help with manual triage)
- Forward actionable items to Workspace account (where Studio runs)
- Use personal Gmail for reading/replying, Workspace for processing/routing

---

## Multi-Account Inventory

If managing multiple personal Gmail accounts:

| Account | Owner | Purpose | Forwards To | Last Audit |
|---------|-------|---------|-------------|:----------:|
| christrees@gmail.com | Chris | Primary personal + business | wip@ (selective) | 2026-06-16 |
| [family]@gmail.com | Family | Family member support | — | TBD |
| [other]@gmail.com | Chris | Legacy/specific purpose | — | TBD |

**Audit cadence:** Monthly for primary, quarterly for secondary accounts.

---

## Related

- [email-ai-triage-pattern](../tools/email-ai-triage-pattern.md) — Workspace AI automation (what personal Gmail forwards to)
- [email-workspace-consolidation-pattern](../tools/email-workspace-consolidation-pattern.md) — Workspace account reduction
- [Wip ops-email-processing.md](https://github.com/2cld/wip/blob/main/docs/ops-email-processing.md) — coordination layer pipeline
- [Google: Create rules to filter emails](https://support.google.com/mail/answer/6579)
- [Google: Check storage usage](https://one.google.com/storage)
- [Google: Security checkup](https://myaccount.google.com/security)
