# Pattern: Email Workspace Consolidation + Alias Routing

**Category:** `docs/ops/tools/`  
**Purpose:** Reduce Google Workspace costs by consolidating role-based accounts into aliases on primary accounts, with routing rules that preserve functionality.  
**Audience:** Any admin managing a Google Workspace domain with more accounts than needed.

---

## The Problem

Google Workspace charges per user. Over time, domains accumulate accounts created for specific functions (info@, admin@, accounting@, support@) that don't represent real users — they're role addresses that receive mail and maybe store some Drive files.

Typical scenario:
- 6 accounts × $4.35/mo = $26.10/mo ($313/yr)
- Only 2 accounts are actual humans
- The other 4 could be free aliases

**The fix:** Convert role addresses to aliases on primary accounts. Mail still arrives, nothing breaks externally, cost drops to minimum.

---

## The Pattern: Audit → Plan → Migrate → Convert → Verify

```
┌────────────────────────────────────────────────────────────┐
│ 1. AUDIT — What accounts exist? What do they do?           │
└───────────────────────────┬────────────────────────────────┘
                            ▼
┌────────────────────────────────────────────────────────────┐
│ 2. PLAN — Which are real users? Which are roles?           │
│    Real users = keep as accounts                           │
│    Role addresses = convert to aliases                     │
└───────────────────────────┬────────────────────────────────┘
                            ▼
┌────────────────────────────────────────────────────────────┐
│ 3. MIGRATE — Move data from role accounts before removal   │
│    (Drive files, email history, contacts)                  │
└───────────────────────────┬────────────────────────────────┘
                            ▼
┌────────────────────────────────────────────────────────────┐
│ 4. CONVERT — Add aliases, set up routing/filters           │
└───────────────────────────┬────────────────────────────────┘
                            ▼
┌────────────────────────────────────────────────────────────┐
│ 5. VERIFY — Confirm mail delivery, no broken dependencies  │
└────────────────────────────────────────────────────────────┘
```

---

## Step 1: Account Audit

Create an inventory using this template:

| Account | Type | Cost/mo | Last Login | Drive Used | Mail Volume | Forwards To | Keep? |
|---------|------|:-------:|:----------:|:----------:|:-----------:|-------------|:-----:|
| cat@ | Real user | $4.35 | Today | 12 GB | High | — | ✅ |
| candy@ | Real user (bot) | $4.35 | Never (API) | 2 GB | Low | — | ✅ |
| admin@ | Role | $4.35 | 90+ days | 0.1 GB | Low | cat@ | → alias |
| info@ | Role | $1.26 | Archived | 0 GB | None | candy@ | → alias |

**How to gather this data:**
- Google Admin console → Directory → Users (shows last login, status)
- Google Admin console → Reports → User reports → Accounts (shows storage)
- Gmail → Settings → Forwarding (shows existing forwards)

### Decision Framework

| If the account... | Then... |
|---|---|
| Has a human logging in regularly | Keep as real user |
| Only receives mail (no login) | Convert to alias |
| Only used for API access (bot) | Keep if API needs auth, else alias |
| Is archived with no forwards | Delete (add alias if address might still receive mail) |
| Has significant Drive data | Migrate data first, then convert |
| Has active forwarding rules | Alias replaces the forward (same result, no account cost) |

---

## Step 2: Cost Analysis

| Scenario | Accounts | Cost/mo | Cost/yr |
|----------|:--------:|:-------:|:-------:|
| Current (all accounts) | 6 | $19.92 | $239.04 |
| Target (real users only) | 2 | $8.70 | $104.40 |
| **Savings** | -4 | **$11.22/mo** | **$134.64/yr** |

Adjust numbers for your domain. The template is:
```
Current: [N accounts] × [per-user cost] = [total]
Target:  [M accounts] × [per-user cost] = [total]
Savings: [N-M] × [per-user cost] × 12 = [annual savings]
```

---

## Step 3: Data Migration (before removing accounts)

For each account being converted to an alias:

### Email History
- **Option A:** Google Admin → Data migration tool (imports mail into target account)
- **Option B:** Let it go (old mail isn't needed — verify with owner)
- **Option C:** Google Takeout → export mbox → archive offline

### Drive Files
- **Option A:** Transfer ownership (Admin console → Users → [user] → Transfer data)
- **Option B:** Share to target account, then delete original
- **Option C:** Download + re-upload (last resort)

### Contacts
- Admin console → Users → [user] → Transfer data (includes contacts)

### Other Services
- Check: Calendar events owned by this account?
- Check: Groups this account is a member of? (update group membership)
- Check: Any third-party apps authenticated as this account?

---

## Step 4: Convert to Aliases + Set Up Routing

### Add Alias (Google Admin Console)
1. Admin console → Directory → Users → select primary account (e.g., cat@)
2. Click user → "User information" → "Alternate email (alias)"
3. Add the role address (e.g., info@, admin@)
4. Save — mail to info@ now delivers to cat@'s inbox

### Set Up Filters (Gmail)
For each alias, create a filter to auto-label/route:

```
Filter: deliveredto:info@yourdomain.com
Action: Apply label "info-inquiries", Skip inbox (optional), Forward to wip@coordination.com (optional)
```

**Filter patterns per alias:**

| Alias | Label | Skip Inbox? | Forward to Coordination? |
|-------|-------|:-----------:|:------------------------:|
| info@ | `info-inquiries` | Yes (low priority) | ✅ (triage externally) |
| admin@ | `admin-alerts` | No (see immediately) | ✅ |
| accounting@ | `accounting` | No | ✅ |
| support@ | `support-tickets` | Yes | ✅ |

### "Send As" Configuration
If you need to reply FROM the alias address:
1. Gmail → Settings → Accounts → "Send mail as"
2. Add the alias address
3. Select "Treat as an alias" (no verification needed for same-domain aliases)

---

## Step 5: Coordination Layer Integration

If using a coordination layer (like Wip) to process email:

```
External sender → info@hwpc (alias on cat@)
                      ↓
              Gmail filter: deliveredto:info@ → label + forward
                      ↓
              Forward → wip@coordination.com
                      ↓
              Coordination layer triages:
                - Action needed? → create issue on project repo
                - FYI only? → archive
                - Financial? → route to accounting Epic
```

### Forwarding Rule Setup
In Gmail settings on the primary account:
1. Settings → Forwarding → Add forwarding address (coordination inbox)
2. Verify the forwarding address
3. Create filter: `deliveredto:alias@domain` → Forward to coordination inbox

### Coordination Layer Processing
The coordination layer (Wip, or similar) handles triage per its own email processing docs:
- Categorize by alias (which "hat" is the sender reaching?)
- Route to correct project Epic/issue
- Flag for human response if needed

---

## Step 6: Verification

After conversion, verify each alias works:

| Check | How | Expected |
|-------|-----|----------|
| Mail delivery | Send test email to alias | Arrives in primary inbox with correct label |
| Filter/label | Check label applied | Alias-specific label present |
| Forward to coordination | Check coordination inbox | Message forwarded with headers intact |
| Send-as reply | Reply from alias | Recipient sees alias address as sender |
| External sender experience | No bounce, no error | Transparent — sender doesn't know it's an alias |
| Old account removed | Try to log in | Login fails (account no longer exists) |

### Verification Script (optional automation)
```bash
# Send test to each alias and verify delivery
for alias in info admin accounting; do
  echo "Test from verification script $(date)" | mail -s "Alias test: ${alias}" ${alias}@yourdomain.com
  echo "Sent to ${alias}@yourdomain.com — check primary inbox"
done
```

---

## Multi-Domain Application

This pattern applies identically across multiple Workspace domains. Each domain gets its own audit + consolidation:

| Domain | Primary Account | Aliases Added | Coordination Forward |
|--------|----------------|---------------|---------------------|
| hwpc.com | cat@hwpc | info@, admin@, elic@, accthwpc@ | wip@horseoff.com |
| horseoff.com | cat@horseoff | (TBD — audit needed) | wip@horseoff.com |
| gmail.com (personal) | christrees@ | N/A (no aliases on Gmail) | Forwarding rules only |

**Cross-domain consolidation:**
- Each domain's primary account forwards actionable items to the SAME coordination inbox
- Coordination layer labels by source domain (filter: `to:*@hwpc.com` vs `to:*@horseoff.com`)
- One triage workflow handles all domains

---

## Anti-Patterns

- ❌ **Don't delete accounts before adding aliases** — mail will bounce in the gap
- ❌ **Don't skip the Drive migration** — files owned by deleted accounts become orphaned
- ❌ **Don't forget "Send As"** — if you reply from the primary, the sender sees the wrong address
- ❌ **Don't assume archived = safe to delete** — archived accounts may still receive mail
- ❌ **Don't consolidate bot accounts** — if an account authenticates to an API (OAuth), it needs to remain a real account

---

## Related

- [pattern-workflow.md](../pattern-workflow.md) — netstack drives all ops (pattern first, then implement)
- [time-code-taxonomy-pattern](./time-code-taxonomy-pattern.md) — how time tracking integrates with project routing
- [repo-communication-pattern](../monitor/repo-communication-pattern.md) — how monitoring communicates findings via issues
- [Wip ops-email-processing.md](https://github.com/2cld/wip/blob/main/docs/ops-email-processing.md) — implementation reference for coordination layer email triage
- [Google Workspace Admin Help: Add email aliases](https://support.google.com/a/answer/33327)
