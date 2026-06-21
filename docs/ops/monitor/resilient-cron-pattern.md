# Resilient Cron Script Pattern

**Applies to:** Any cron-scheduled script that performs multiple independent checks.

## Problem

Using `set -euo pipefail` in monitoring scripts causes the entire script to abort if ANY single check fails. A timed-out ping kills the backup report, the calendar event, everything after it.

## Principle

**Monitoring checks are independent. One failure must not prevent the others from running.**

## Pattern

```bash
#!/bin/bash
# Pattern: https://netstack.org/docs/ops/monitor/resilient-cron-pattern/
#
# Use set -u (undefined vars are errors) but NOT set -e (don't exit on error).
# Each section handles its own errors.

set -uo pipefail  # WRONG for multi-check scripts
set -u            # RIGHT - catch undefined vars, but don't abort on check failures
```

### Section isolation

Each check section should catch its own errors:

```bash
# WRONG: one failed ping kills everything
for ip in "${IPS[@]}"; do
  ping -c1 -W2 "$ip" > /dev/null 2>&1  # if this exits non-zero, script dies
done

# RIGHT: capture result, continue regardless
for ip in "${IPS[@]}"; do
  if ping -c1 -W2 "$ip" > /dev/null 2>&1; then
    echo "  UP: $ip"
  else
    echo "  DOWN: $ip"
  fi
done
```

### External commands (SSH, node, curl)

Wrap external calls that might fail or hang:

```bash
# Add timeout + fallback
timeout 30 node script.js 2>&1 || echo "  script failed or timed out"

# SSH with timeout
ssh -o ConnectTimeout=5 -o BatchMode=yes user@host "cmd" 2>/dev/null || echo "  SSH failed"
```

### Critical vs non-critical sections

Mark sections as critical (script should abort) or non-critical (log and continue):

```bash
# CRITICAL - if backup fails, we want to know and stop
echo "[1/4] Backup..."
bash backup.sh || { echo "BACKUP FAILED"; exit 1; }

# NON-CRITICAL - if node ping fails, log it and keep going
echo "[2/4] Node checks..."
check_nodes || echo "  some nodes unreachable"

# NON-CRITICAL - if calendar event fails, not worth killing the report
echo "[3/4] Calendar event..."
create_calendar_event || echo "  calendar event failed (non-fatal)"
```

## Template

```bash
#!/bin/bash
# <script-name> - <description>
# Pattern: https://netstack.org/docs/ops/monitor/resilient-cron-pattern/
# Cron: <schedule>

set -u  # catch undefined vars, but don't abort on check failures

# --- Section 1: CRITICAL (abort if fails) ---
echo "[1/N] Critical thing..."
critical_command || { echo "CRITICAL FAILURE"; exit 1; }

# --- Section 2: NON-CRITICAL (log and continue) ---
echo "[2/N] Check thing..."
if check_command; then
  echo "  OK"
else
  echo "  FAILED (non-fatal)"
fi

# --- Section 3: EXTERNAL with timeout ---
echo "[3/N] External call..."
timeout 30 external_command 2>&1 || echo "  timed out or failed (non-fatal)"
```

## Related

- [backup-cron-pattern](../backup/backup-cron-pattern.md) - backup-specific cron
- [cross-platform-monitoring-pattern](./cross-platform-monitoring-pattern.md) - how checks run
