# Pattern: Access Monitoring & Authentication Audit

**Category:** `docs/ops/security/`  
**Purpose:** Define expected access patterns, monitor for deviations, detect abuse.  
**Audience:** All federation nodes (cf, sl, wf) + coordination layer (nsdockerhv)  
**Principle:** Security is an onion — layers matter. Each layer validates what's expected and detects what isn't.

---

## Philosophy: Security as Layers, Not Walls

A single access control (SSH key, firewall, VPN) is a wall — one breach bypasses everything. Layered security means every access event is validated at multiple points, and anomalies are visible even if one layer fails.

```
Layer 0: Network boundary (ZeroTier membership — who CAN reach the node)
Layer 1: Authentication (SSH keys — who IS on the node)
Layer 2: Authorization (sudoers, file permissions — what they CAN do)
Layer 3: Audit trail (logs — what they DID do)
Layer 4: Behavioral baseline (patterns — was this EXPECTED)
Layer 5: Alerting (deviation — flag the UNEXPECTED)
```

**The key insight:** Layers 0-2 are preventive (stop bad actors). Layers 3-5 are detective (notice when something is wrong). Most homelab/small infra has layers 0-2 and nothing for 3-5. That's where breaches go unnoticed.

---

## The Four Questions

Every access event should be answerable against:

| Question | What it validates | Example |
|----------|-------------------|---------|
| **WHO** | Identity (key fingerprint, username, source IP) | `nsadmin from 10.147.17.176 (nsdockerhv)` |
| **WHEN** | Time (was this during expected hours? cron schedule?) | `02:00 AM daily` (cron) vs `3:47 AM Sunday` (unexpected) |
| **WHERE** | Target (which node, which service, which path) | `ghadmin@10.147.17.94 port 22` (Windows SSH) |
| **WHY** | Purpose (automation, interactive, maintenance) | Matches known cron job or documented procedure |

An event that answers all four against a known baseline is **expected process**.  
An event that fails any one of the four is a **deviation** — investigate.

---

## Layer 0: Network Boundary (ZeroTier)

**What it does:** Controls which devices can reach federation nodes at all.

**Expected state:**
- ZeroTier network `d5e5fb65371eb4a4` has authorized members only
- Membership requires approval at [my.zerotier.com](https://my.zerotier.com)
- `netstack-status.js` already monitors node membership (online/offline)

**Detection:** New member appears that isn't in the authorized list → flag.

**Audit check:**
```bash
# List all ZT members (via API) — compare against known inventory
curl -s -H "Authorization: token $ZT_TOKEN" \
  "https://api.zerotier.com/api/v1/network/d5e5fb65371eb4a4/member" | \
  jq '.[].config.ipAssignments'
```

---

## Layer 1: Authentication (SSH Keys)

**What it does:** Controls who can establish a session on each node.

### Access Matrix (who SHOULD have keys where)

| Node | Authorized keys | Purpose |
|------|----------------|---------|
| nsdockerhv | nsadmin (local), catSurface (dev) | Development, ops controller |
| CyberTruck | ghadmin (local), nsadmin@nsdockerhv (cron) | Backup verification, monitoring |
| cat9fin | ghadmin (local), nsadmin@nsdockerhv (cron) | hwpc-rp backup |
| slwin11ops (Win SSH :22) | ghadmin (local), nsadmin@nsdockerhv (cron) | Backup delivery, monitoring |
| slwin11ops (WSL :2020) | ghadmin (local), nsadmin@nsdockerhv (cron) | Docker management, site-ops |

### Key Audit Script

```bash
#!/bin/bash
# audit-ssh-keys.sh — compare deployed keys against authorized matrix
for target in "ghadmin@10.147.17.219" "ghadmin@10.147.17.94" "ghadmin@10.147.17.218"; do
  echo "=== $target ==="
  ssh -o ConnectTimeout=5 "$target" "type C:\ProgramData\ssh\administrators_authorized_keys 2>nul || type C:\Users\ghadmin\.ssh\authorized_keys 2>nul" 2>/dev/null
  echo ""
done

# WSL
echo "=== sl WSL (port 2020) ==="
ssh -p 2020 ghadmin@10.147.17.94 "cat ~/.ssh/authorized_keys" 2>/dev/null

# Linux
echo "=== nsdockerhv ==="
cat ~/.ssh/authorized_keys
```

**Detection:** Key in `authorized_keys` that isn't in the matrix → investigate.

---

## Layer 2: Authorization (What They Can Do)

**What it does:** Limits authenticated users to appropriate actions.

| Node | User | Sudoers | Docker | Purpose |
|------|------|:-------:|:------:|---------|
| nsdockerhv | nsadmin | full | yes | Ops controller — runs everything |
| slwin11ops WSL | ghadmin | full (NOPASSWD) | yes | site-ops deploy target |
| CyberTruck | ghadmin | admin (Windows) | n/a | Host management |
| cat9fin | ghadmin | admin (Windows) | n/a | hwpc-rp operations |

**Principle:** Automation users (`buadmin`, future) get minimal permissions. Interactive admin users get full access but are audited.

---

## Layer 3: Audit Trail (What They Did)

### Linux (nsdockerhv, sl WSL)

**Source:** `/var/log/auth.log`

```bash
# Recent SSH sessions
grep "Accepted" /var/log/auth.log | tail -20

# Failed attempts
grep "Failed" /var/log/auth.log | tail -20

# Session open/close
grep "session opened\|session closed" /var/log/auth.log | tail -20
```

**Key fields:** timestamp, username, source IP, key fingerprint (if `LogLevel VERBOSE` in sshd_config)

### Windows (CyberTruck, slwin11ops, cat9fin)

**Source:** Windows Security Event Log

| Event ID | Meaning |
|:--------:|---------|
| 4624 | Successful logon |
| 4625 | Failed logon |
| 4634 | Logoff |
| 4648 | Logon using explicit credentials |
| 4672 | Special privileges assigned (admin logon) |

```powershell
# Recent successful logins
Get-WinEvent -FilterHashtable @{LogName='Security'; ID=4624} -MaxEvents 20 |
  Select-Object TimeCreated, @{N='User';E={$_.Properties[5].Value}}, @{N='Source';E={$_.Properties[18].Value}}

# Failed logins
Get-WinEvent -FilterHashtable @{LogName='Security'; ID=4625} -MaxEvents 20 |
  Select-Object TimeCreated, @{N='User';E={$_.Properties[5].Value}}, @{N='Source';E={$_.Properties[19].Value}}
```

### Docker (container access)

```bash
# Who exec'd into a container
docker events --filter type=container --filter event=exec_start --since 24h
```

---

## Layer 4: Behavioral Baseline (Expected Patterns)

Define what normal looks like so anomalies are obvious:

### Expected Automated Access (cron-driven)

| Time | Source | Target | Purpose |
|------|--------|--------|---------|
| 02:00 daily | nsdockerhv (nsadmin) | CyberTruck (ghadmin) | Docker backup delivery to sl |
| 02:00 daily | cat9fin (scheduled task) | local | hwpc-rp tar creation |
| 03:00 weekly Sun | nsdockerhv (nsadmin) | CyberTruck + sl | wip-creds backup |
| 05:30 daily | nsdockerhv (nsadmin) | CyberTruck, sl, cat9fin | wip-daily-cron checks |
| Every 6h | sl WSL (ghadmin) | local | site-status.sh cron |

### Expected Interactive Access

| Who | When | Target | Purpose |
|-----|------|--------|---------|
| Chris (catSurface, catmini) | Business hours | nsdockerhv | Development |
| Chris | As needed | CyberTruck, sl, cat9fin | Maintenance |
| Wip (nsdockerhv) | Business hours | all nodes | Monitoring, verification |

### Anomaly Indicators

| Signal | What it means |
|--------|---------------|
| SSH from unknown IP (not in ZT inventory) | Shouldn't be possible (ZT boundary), but check |
| Login at 3 AM that isn't a cron job | Unexpected — was someone manually working? |
| Failed auth attempts > 5 in 1 hour | Brute force (unlikely via ZT, but possible) |
| `root` login on any node | Should never happen (use sudo) |
| SSH from a ZT IP that's a phone/tablet | Unusual — investigate |
| New `authorized_keys` entry appeared | Key was added — by whom? |

---

## Layer 5: Alerting (Flag the Unexpected)

### Integration with Daily Cron

Add to `wip-daily-cron.sh` or `site-status.sh`:

```bash
# --- Auth Monitor (Layer 5) ---
# Check for failed SSH attempts in last 24h
FAILED_SSH=$(grep "Failed" /var/log/auth.log 2>/dev/null | \
  grep "$(date -d yesterday +%b\ %d)\|$(date +%b\ %d)" | wc -l)

if [ "$FAILED_SSH" -gt 5 ]; then
  echo "  ⚠️  AUTH: $FAILED_SSH failed SSH attempts in 24h"
fi

# Check for unexpected sessions (not from known cron times)
UNEXPECTED=$(grep "Accepted" /var/log/auth.log 2>/dev/null | \
  grep "$(date +%b\ %d)" | \
  grep -v "02:00\|02:30\|03:00\|05:30" | wc -l)

if [ "$UNEXPECTED" -gt 0 ]; then
  echo "  📋 AUTH: $UNEXPECTED sessions outside cron schedule (review)"
fi
```

### Windows Auth Check (via SSH from ops controller)

```bash
# Check Windows nodes for failed logins
for node in "ghadmin@10.147.17.219" "ghadmin@10.147.17.94"; do
  FAILED=$(ssh -o ConnectTimeout=10 "$node" \
    "powershell -Command \"(Get-WinEvent -FilterHashtable @{LogName='Security'; ID=4625; StartTime=(Get-Date).AddDays(-1)} -ErrorAction SilentlyContinue).Count\"" 2>/dev/null)
  if [ "${FAILED:-0}" -gt 5 ]; then
    echo "  ⚠️  AUTH: $node — $FAILED failed logins in 24h"
  fi
done
```

---

## Layer 6: Response (What to Do)

| Severity | Trigger | Response |
|----------|---------|----------|
| **INFO** | Unexpected interactive session during business hours | Log it. Probably Chris working. |
| **WARNING** | > 5 failed attempts in 24h | Check source IP. If internal (ZT), check which device. |
| **CRITICAL** | Unknown key in authorized_keys | Investigate immediately. Who added it? |
| **CRITICAL** | Login from IP not in ZT inventory | Should be impossible. Check if ZT was bypassed. |
| **CRITICAL** | root login anywhere | Never expected. Investigate immediately. |

---

## Implementation Checklist

### Immediate (next deploy)
- [ ] Enable `LogLevel VERBOSE` in sshd_config on nsdockerhv (logs key fingerprints)
- [ ] Add auth check to sl `site-status.sh` (failed attempts counter)
- [ ] Document current authorized_keys on all nodes (baseline)

### Short-term
- [ ] Add auth monitoring section to `wip-daily-cron.sh`
- [ ] Install `fail2ban` on nsdockerhv and sl WSL (rate limit SSH)
- [ ] Create `audit-ssh-keys.sh` script (compare deployed vs. matrix)
- [ ] Add Windows event log check to `site-ops verify`

### Medium-term
- [ ] Generate access matrix from site-config.yml (who should have keys where)
- [ ] Periodic key rotation reminder (quarterly, per ops-token-management.md)
- [ ] Correlate ZeroTier member list with SSH access (detect orphaned keys)

---

## Connection to site-config.yml

```yaml
security:
  access_matrix:
    - node: slwin11ops
      authorized_users:
        - name: ghadmin
          key_source: "local"
          purpose: "admin"
        - name: nsadmin@nsdockerhv
          key_source: "ops controller"
          purpose: "cron (backup, monitoring)"
  monitoring:
    auth_log: true
    failed_attempt_threshold: 5
    alert_outside_cron_hours: true
    fail2ban: true
```

---

## Related Netstack Patterns

- [sensitive-data-pattern](https://github.com/2cld/netstack/blob/master/docs/ops/security/sensitive-data-pattern.md) — what to protect
- [cave-principles](https://github.com/2cld/netstack/blob/master/docs/ops/security/cave-principles.md) — minimal surface, immutability
- [ssh-rsync-pattern](https://github.com/2cld/netstack/blob/master/docs/ops/backup/ssh-rsync-pattern.md) — buadmin user, key-only auth
- [process-audit-pattern](https://github.com/2cld/netstack/blob/master/docs/ops/monitor/process-audit-pattern.md) — what's running (process layer)
- [monitoring-pattern](https://github.com/2cld/netstack/blob/master/docs/ops/monitor/monitoring-pattern.md) — ongoing health checks
- [ops-token-management.md](../../docs/ops-token-management.md) — token inventory and rotation
