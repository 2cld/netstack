# Cross-Platform Monitoring Pattern

**Applies to:** Monitoring mixed Linux/Windows federation nodes from a single ops controller.

## Principle

The ops controller (Linux) orchestrates all monitoring. Target nodes (Windows or Linux) answer queries via SSH. No monitoring agents needed on targets - just SSH + the target's native shell.

## Goal-Based Monitoring

**Monitor the goal outcome, not every piece of infrastructure.**

Don't ask "is every container up?" Ask "are my goals being served?"

### How to decide what to monitor:

1. Define the site's goals (what is this site FOR right now?)
2. Identify what serves each goal (which services/nodes)
3. Monitor ONLY those things
4. If a service doesn't serve a current goal, don't monitor it (less noise, less maintenance)

### Example (wf site):

| Goal | What serves it | Monitor check |
|------|---------------|---------------|
| hwpc-rp backup | D: drive receives from cf | "Did backup arrive today?" (.backup-state fresh) |
| Sort piles | devwin10 online, drives mountable | "Can I work when I'm at wf?" (ping + SSH) |
| Federation storage | cg2 ZFS + wfMedia | "Is storage and media serving?" (plex active, ZFS healthy) |

Things NOT monitored (don't serve a current goal):
- LXC 100 (docker) - stopped, no active use
- VM 102 (llscat) - Trink collab, not critical
- VM 501 (pfsense) - experiment, stopped

**When a new goal appears:** add the monitoring check. When a goal is retired, remove its checks. Keep the signal-to-noise ratio high.

## Architecture

```
nsdockerhv (Linux, bash)
    |
    |-- SSH --> Linux target (bash commands)
    |-- SSH --> Windows target (PowerShell commands)
    |
    v
.backup-state / status output / morning check-in
```

## Why This Works

- **One orchestrator, many targets** - scripts live in one place
- **No agents to install** - SSH is already required for backup
- **Native commands** - each target uses its own shell (bash or PowerShell)
- **Cross-platform** - the orchestrator doesn't care what the target runs

## Script Types

| Type | Runs on | Written in | Calls target via | Example |
|------|---------|-----------|-----------------|---------|
| Monitoring | ops controller | bash | SSH + target shell | `wf-status.sh` |
| Setup/admin | target node | target's native (PS1 or bash) | Run locally | `setup-buadmin-windows.ps1` |
| Backup push | ops controller | bash | SSH + scp/rsync | `backup-daily.sh` |

## Pattern: Bash Script Calling PowerShell via SSH

```bash
#!/bin/bash
SSH_KEY="/home/buadmin/.ssh/id_backup"
SSH="ssh -i $SSH_KEY -o BatchMode=yes -o ConnectTimeout=5"
TARGET="buadmin@10.147.17.x"

# Single command
$SSH $TARGET "Get-Service sshd | Select Name,Status"

# Multi-line (use semicolons, not &&)
$SSH $TARGET "Get-Volume | Where-Object DriveLetter | Format-Table -AutoSize"

# Boolean check
RESULT=$($SSH $TARGET "Test-Connection 192.168.9.3 -Count 1 -Quiet")
if echo "$RESULT" | grep -qi "true"; then
  echo "UP"
fi
```

## Windows PowerShell Gotchas

| Bash | PowerShell (via SSH) | Notes |
|------|---------------------|-------|
| `cmd1 && cmd2` | `cmd1; cmd2` | `&&` is not valid in PS |
| `echo "text"` | `Write-Host "text"` | Or just output objects |
| `$VAR` | `\$VAR` | Escape `$` in bash heredocs |
| `grep pattern` | `Select-String pattern` | Or pipe to `findstr` |
| `ls` | `Get-ChildItem` | Or `dir` (alias) |

## User Roles

| User | Purpose | Has sudo? | SSH key |
|------|---------|-----------|---------|
| buadmin | Backup + monitoring (automated) | No | id_backup (ed25519) |
| nsadmin/ghadmin | Admin actions (manual) | Yes | Personal key |

Monitoring scripts should run as `buadmin` (least privilege). Until buadmin is deployed on all targets, `nsadmin`/`ghadmin` with `id_backup` key works.

## Integration with Morning Check-in

Site status scripts are called by `wip-daily-cron.sh`:

```bash
# In wip-daily-cron.sh:
echo "## WF Site Status"
bash /home/nsadmin/code/wf/ops/scripts/wf-status.sh
```

Wip reads the output during morning standup and flags issues.

## Related

- [ssh-rsync-pattern](../backup/ssh-rsync-pattern.md) - backup transport (same SSH infrastructure)
- [ops-node-setup](../users/ops-node-setup.md) - user environment on each node
- [backup-cron-pattern](../backup/backup-cron-pattern.md) - automated cron jobs
- [pattern-workflow](../pattern-workflow.md) - document first, then implement
