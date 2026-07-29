# Pattern: Access Monitoring & Authentication Audit (Security Layers 3-5)

**Category:** `docs/ops/security/`
**Purpose:** Detective security — who accessed what, when, and was it expected? Catch unauthorized access, stale keys, and anomalous behavior.
**Prerequisite patterns:**
- [federation-user-model-pattern](../deployments/federation-user-model-pattern.md) — defines roles and boundaries
- [ssh-rsync-pattern](../backup/ssh-rsync-pattern.md) — buadmin key-only transport
- [credential-backup-pattern](./credential-backup-pattern.md) — secrets DR

---

## Security Onion Model

```
Layer 0: Network boundary    (ZeroTier membership — who CAN reach)
Layer 1: Authentication      (SSH keys — who IS on the node)
Layer 2: Authorization       (sudoers — what they CAN do)
Layer 3: Audit trail         (logs — what they DID do)           ← THIS DOC
Layer 4: Behavioral baseline (patterns — was this EXPECTED)      ← THIS DOC
Layer 5: Alerting            (deviation — flag the UNEXPECTED)   ← THIS DOC
```

---

## Part 1: Access Matrix

This table defines the AUTHORIZED access paths. Anything not listed here is unexpected.

### SSH Keys (outbound from nsdockerhv)

| Key | Fingerprint | Identity | Targets | Purpose | Schedule |
|-----|-------------|----------|---------|---------|----------|
| id_backup | `SHA256:KDGH24XN...` | nsub2404hv-backup | CT, sl, wf, cat9fin | Backup cron (SCP) | Daily 2 AM |
| id_rsa | `SHA256:UqoEjZmH...` | nsadmin@horseoff.com | github.com (as horseoffcom) | Interactive git push | On-demand |

### SSH Keys (inbound to nsdockerhv)

| Source | Key comment | Authorized for user | Purpose |
|--------|-------------|--------------------:|---------|
| CyberTruck | cfbu-backup@cybertruck | nsadmin | (legacy — review if still needed) |

### SSH Targets (per site contract)

| Target | IP (ZT) | Port | User | Key | Access from nsdockerhv |
|--------|---------|------|------|-----|----------------------|
| CyberTruck | 10.147.17.219 | 22 | ghadmin | id_backup | Yes (backup-daily.sh) |
| cat9fin | 10.147.17.218 | 22 | ghadmin | id_backup | Yes (backup-daily.sh) |
| slwin11ops | 10.147.17.94 | 22 | ghadmin | id_backup | Yes (backup + monitoring) |
| slwin11ops WSL | 10.147.17.94 | 2020 | ghadmin | id_backup | Yes (sl-status) |
| devwin10 | 10.147.17.165 | 22 | ghadmin | default | Yes (wf monitoring) |

---

## Part 2: Expected Automated Access (Behavioral Baseline)

These SSH connections are EXPECTED at specific times. Anything outside this pattern is a deviation.

| Time | Source | Target | User | Purpose | Script |
|------|--------|--------|------|---------|--------|
| 02:00 daily | nsdockerhv | CyberTruck :22 | ghadmin | Pull hwpc-rp sync | backup-daily.sh |
| 02:00 daily | nsdockerhv | slwin11ops :22 | ghadmin | Push Docker backups | backup-daily.sh |
| 02:00 daily | nsdockerhv | devwin10 :22 | buadmin | Push Docker backups (wf leg) | backup-daily.sh |
| 03:00 Sun | nsdockerhv | CyberTruck :22 | ghadmin | Push wip-creds backup | backup-wip-credentials.sh |
| 03:00 Sun | nsdockerhv | slwin11ops :22 | ghadmin | Push wip-creds backup | backup-wip-credentials.sh |
| 05:30 daily | nsdockerhv | slwin11ops :22 | ghadmin | sl disk check (wip-daily-cron) | wip-daily-cron.sh |
| 05:30 daily | nsdockerhv | devwin10 :22 | ghadmin | wf status check | wip-daily-cron.sh |
| 05:30 daily | nsdockerhv | devwin10 :22 | ghadmin | site-server proxy (192.168.9.9) | netstack-status.js |
| On-demand | nsdockerhv | any ZT node | ghadmin | Interactive troubleshooting | Manual (site-admin) |

### What "unexpected" looks like:

- SSH at 3 AM on a Tuesday to a target that's only accessed at 2 AM daily
- SSH from an IP not in the ZeroTier network
- SSH as root (never expected — no root SSH allowed)
- SSH with an unknown key fingerprint
- Failed auth attempts > 3 in 5 minutes (brute force)

---

## Part 3: Auth Log Collection

### Linux (nsdockerhv, LXCs)

```bash
# Recent auth events
grep "sshd" /var/log/auth.log | tail -20

# Failed attempts (Layer 5 signal)
grep "Failed password\|Invalid user\|Connection closed by.*preauth" /var/log/auth.log | tail -10

# Accepted keys (Layer 3 audit trail)
grep "Accepted publickey" /var/log/auth.log | tail -10

# Enable key fingerprint logging (one-time):
# /etc/ssh/sshd_config: LogLevel VERBOSE
# systemctl restart sshd
```

### Windows (slwin11ops, devwin10, CyberTruck)

```powershell
# Failed logons (Event 4625) — last 24h
Get-WinEvent -FilterHashtable @{LogName='Security';Id=4625;StartTime=(Get-Date).AddDays(-1)} | Select TimeCreated,Message | Format-List

# Successful logons (Event 4624) — last 24h
Get-WinEvent -FilterHashtable @{LogName='Security';Id=4624;StartTime=(Get-Date).AddDays(-1)} | Where-Object { $_.Message -match "Logon Type:\s+10|Logon Type:\s+3" } | Select TimeCreated

# OpenSSH log (if sshd logging configured)
Get-Content C:\ProgramData\ssh\logs\sshd.log -Tail 20
```

---

## Part 4: Audit Script (audit-ssh-keys.sh)

Run periodically to detect stale or unauthorized keys:

```bash
#!/bin/bash
# audit-ssh-keys.sh — Compare deployed authorized_keys against expected list
# Run: manually during weekly review, or add to wip-daily-cron.sh

# Expected keys (from this pattern doc — source of truth)
declare -A EXPECTED_KEYS
EXPECTED_KEYS["nsadmin@nsdockerhv"]="cfbu-backup@cybertruck"
EXPECTED_KEYS["wip@nsdockerhv"]=""  # no inbound expected

echo "=== SSH Key Audit ==="

for user_host in "${!EXPECTED_KEYS[@]}"; do
  user="${user_host%%@*}"
  host="${user_host##*@}"
  auth_file="/home/$user/.ssh/authorized_keys"
  
  if [ -f "$auth_file" ]; then
    actual=$(awk '{print $NF}' "$auth_file" | sort | tr '\n' ',' | sed 's/,$//')
    expected="${EXPECTED_KEYS[$user_host]}"
    
    if [ "$actual" = "$expected" ]; then
      echo "  OK $user@$host: $actual"
    else
      echo "  ⚠️  $user@$host: MISMATCH"
      echo "    Expected: $expected"
      echo "    Actual:   $actual"
    fi
  else
    echo "  -- $user@$host: no authorized_keys file"
  fi
done

# Check for unexpected users with .ssh directories
echo ""
echo "=== Users with .ssh dirs ==="
find /home -maxdepth 2 -name ".ssh" -type d 2>/dev/null | while read dir; do
  user=$(echo "$dir" | cut -d/ -f3)
  keys=$(wc -l < "$dir/authorized_keys" 2>/dev/null || echo 0)
  echo "  $user: $keys authorized key(s)"
done
```

---

## Part 5: Integration with wip-daily-cron.sh

Add to the daily cron report (quick check, not full audit):

```bash
# --- Auth Health Check ---
echo "## Auth Health"

# Failed SSH attempts in last 24h
FAILED=$(grep -c "Failed\|Invalid user" /var/log/auth.log 2>/dev/null || echo 0)
if [ "$FAILED" -gt 10 ]; then
  echo "  ❌ $FAILED failed SSH attempts (last 24h) — investigate"
elif [ "$FAILED" -gt 0 ]; then
  echo "  ⚠️ $FAILED failed SSH attempts (last 24h)"
else
  echo "  ✅ No failed SSH attempts"
fi

# Check if any unexpected keys were added
EXPECTED_KEY_COUNT=1  # nsadmin should have 1 key
ACTUAL=$(wc -l < /home/nsadmin/.ssh/authorized_keys 2>/dev/null || echo 0)
if [ "$ACTUAL" -ne "$EXPECTED_KEY_COUNT" ]; then
  echo "  ⚠️ nsadmin authorized_keys: $ACTUAL keys (expected $EXPECTED_KEY_COUNT)"
else
  echo "  ✅ authorized_keys: $ACTUAL key(s) (expected)"
fi
```

---

## Part 6: Response Playbook

| Signal | Severity | Action |
|--------|----------|--------|
| Failed attempts < 5/day | INFO | Log, no action (noise from port scanners) |
| Failed attempts > 10/day | WARNING | Check source IPs, verify ZT boundary intact |
| Failed attempts > 50/day | CRITICAL | Enable fail2ban, investigate source, alert site-admin |
| Unknown key in authorized_keys | CRITICAL | Identify owner immediately, revoke if unknown |
| SSH at unexpected time | WARNING | Correlate with cron schedule, verify if manual admin work |
| Root login attempt | CRITICAL | Root SSH should be disabled — if attempt succeeded, incident response |
| Key fingerprint mismatch on target | WARNING | Target node may have been rebuilt without updating known_hosts |

---

## Part 7: Key Rotation Schedule

| Key | Rotation trigger | Procedure |
|-----|-----------------|-----------|
| id_backup (backup-agent) | On compromise, or annually | Generate new ed25519, deploy pub to all targets, update DR USB |
| id_rsa (nsadmin interactive) | On compromise | Generate new, register on GitHub (horseoffcom) |
| GitHub PAT (GITHUB_HOWIP_API) | On expiry or compromise | `gh auth login` device flow, update .env |
| Gitea token | On compromise | Regenerate at gitea.cat9.me/user/settings/applications |
| ZeroTier API token | On compromise | Regenerate at my.zerotier.com |

**Quarterly check (Sunday weekly review, once per quarter):**
- Run `audit-ssh-keys.sh` on nsdockerhv
- SSH to each site node, verify authorized_keys matches expected
- Check GitHub token expiry (ops-token-management.md)
- Verify fail2ban active (if installed)

---

## Implementation Phases

### Phase 1: Immediate (today)

- [x] Document access matrix (this file)
- [x] Document expected cron schedule
- [ ] Enable `LogLevel VERBOSE` in sshd_config on nsdockerhv
- [ ] Add auth health check to wip-daily-cron.sh

### Phase 2: Short-term (next month)

- [ ] Install fail2ban on nsdockerhv
- [ ] Create `audit-ssh-keys.sh` and run first audit
- [ ] Add Windows event check to site-status scripts (sl, wf)
- [ ] Document known_hosts baseline

### Phase 3: Medium-term (quarterly)

- [ ] Generate access matrix from site-config.yml (per-site)
- [ ] Correlate ZeroTier member list with SSH access
- [ ] Periodic key rotation reminder in weekly review
- [ ] fail2ban on sl WSL node

---

## Related

- [federation-user-model-pattern](../deployments/federation-user-model-pattern.md) — role definitions
- [ssh-rsync-pattern](../backup/ssh-rsync-pattern.md) — buadmin transport security
- [credential-backup-pattern](./credential-backup-pattern.md) — secrets DR
- [sensitive-data-pattern](./sensitive-data-pattern.md) — what to protect
- [cave-principles](./cave-principles.md) — minimal attack surface
- [wip ops-federation-identity](https://github.com/2cld/wip/blob/main/docs/ops-federation-identity.md) — concrete identity map
- [wip ops-token-management](https://github.com/2cld/wip/blob/main/docs/ops-token-management.md) — token expiry + escalation
