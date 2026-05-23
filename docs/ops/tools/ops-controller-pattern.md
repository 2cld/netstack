[edit](https://github.com/2cld/netstack/edit/master/docs/ops/tools/ops-controller-pattern.md) or [./](./)

# Ops Controller Pattern

One machine holds all code, runs all scripts, and reaches out to nodes via SSH. Target nodes don't need local clones or dev tools — they just need SSH enabled.

## Why

- **Split-brain prevention:** Two machines editing the same repo = merge conflicts, stale clones, confusion about "where did I leave this?"
- **Single source of truth:** All automation lives in one place, versioned in git
- **Minimal footprint on targets:** Production nodes stay clean — no git, no node.js, no dev tools needed
- **Audit trail:** All ops actions originate from one machine, logged in one place

## Architecture

```
┌─── Ops Controller (nsdockerhv) ───────────────────────┐
│                                                         │
│  All git repos cloned here:                            │
│    ~/code/wip, ~/code/netstack, ~/code/cf,             │
│    ~/code/sl, ~/code/docker-compose, etc.              │
│                                                         │
│  All scripts run from here:                            │
│    morning-checkin.js, netstack-status.js,              │
│    backup-docker-services.sh, perf-baseline.sh         │
│                                                         │
│  Reaches targets via SSH:                              │
│    ssh ghadmin@10.147.17.219  (CyberTruck)             │
│    ssh nsadmin@10.147.17.218  (cat9fin)                │
│    ssh ghadmin@10.147.17.94   (slwin11ops)             │
│    ssh nsadmin@192.168.10.2   (cfbu, via eth1)         │
│                                                         │
└─────────────────────────────────────────────────────────┘
         │ SSH          │ SSH          │ SSH
         ▼              ▼              ▼
   CyberTruck       cat9fin       slwin11ops
   (target)         (target)       (target)
   - no clones      - no clones    - no clones
   - no dev tools   - runs hwpc-rp - runs Plex
   - runs Hyper-V   - runs QB      - receives backups
   - runs Plex
```

## Rules

1. **All repos live on the controller** (nsdockerhv)
2. **Target nodes have SSH only** — no git clones, no editors, no dev tools
3. **Scripts execute remotely** via `ssh target "command"` from the controller
4. **Results come back** to the controller (stdout, scp, exit codes)
5. **Commits happen on the controller** — never from target nodes
6. **GitHub API pushes** (via ho-wip) are OK for repos Wip manages directly

## Remote Execution Patterns

### Run a command on a target

```bash
# Simple command
ssh ghadmin@10.147.17.219 "hostname && systemctl status sshd"

# PowerShell on Windows targets
ssh ghadmin@10.147.17.219 "powershell -Command \"Get-Process | Sort WS -Desc | Select -First 5\""

# Collect output for logging
ssh ghadmin@10.147.17.94 "netstat -an | findstr LISTENING" > /tmp/sl-ports.txt
```

### Push a script to run on a target

```bash
# Copy script, run it, get results back
scp /home/nsadmin/code/scripts/perf-baseline.ps1 ghadmin@10.147.17.219:C:/temp/
ssh ghadmin@10.147.17.219 "powershell -File C:/temp/perf-baseline.ps1"
```

### Pull data from a target

```bash
# Backup: pull data from target to controller
scp ghadmin@10.147.17.219:D:/cfops-share/current/cat9fin/hwpc-rp-latest.tar /home/nsadmin/backups/

# Monitoring: pull perf log
ssh ghadmin@10.147.17.94 "type C:\logs\perf-baseline.log" > /tmp/sl-perf.log
```

### Deploy config to a target

```bash
# Push updated config from repo to target
scp /home/nsadmin/code/cf/ops/scripts/backup-schedule.ps1 ghadmin@10.147.17.219:C:/scripts/
ssh ghadmin@10.147.17.219 "schtasks /create /tn BackupDaily /tr C:/scripts/backup-schedule.ps1 /sc daily /st 02:00"
```

## What Lives Where

| Machine | Role | Has Clones? | Has Dev Tools? | SSH Access |
|---------|------|:-----------:|:--------------:|:----------:|
| **nsdockerhv** | Ops Controller | ✅ All repos | ✅ Node.js, git, Docker | Inbound + Outbound |
| CyberTruck | VM Host | ❌ No | ❌ No (just PowerShell) | Inbound only |
| cat9fin | Production | ❌ No | ❌ No (just hwpc-rp runtime) | Inbound only |
| slwin11ops | Backup Target | ❌ No | ❌ No (just PowerShell) | Inbound only |
| devwin10 (wf) | Failover | ❌ No | ❌ No | Inbound only |

## Migration Plan (from current state)

Current state: ghadmin on CyberTruck has been editing cf/sl repos directly.

1. ✅ Clone cf and sl repos fresh on nsdockerhv (done 2026-05-23)
2. [ ] Remove any git clones from CyberTruck (or leave them stale — they won't be used)
3. [ ] Ensure all scripts in cf/sl repos can run remotely via SSH from nsdockerhv
4. [ ] Update any scripts that assume "running locally on CyberTruck" to use SSH instead
5. [ ] Document in each site repo: "This repo is managed from nsdockerhv. Do not edit locally."

## Exceptions

- **Emergency:** If nsdockerhv is down and you need to fix something on CyberTruck, edit directly. But commit with a note: "emergency edit from CyberTruck — sync to nsdockerhv when back up."
- **Site visits:** If physically at wf/sl with no network to nsdockerhv, edit locally. Sync when back.

## Related

- [dev-ssh-kiro-cli.md](../users/dev-ssh-kiro-cli.md) — SSH + Kiro CLI for dev sessions
- [session-logging.md](./session-logging.md) — logging ops actions
- [automation-pattern.md](./automation-pattern.md) — scheduling recurring tasks
- [../deployments/federation-setup-guide.md](../deployments/federation-setup-guide.md) — what each site needs
