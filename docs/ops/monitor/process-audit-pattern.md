# Process Audit Pattern for Federation Nodes

**Applies to:** All Windows federation nodes (CyberTruck, slwin11ops, etc.)
**Related:** [Monitoring Pattern](monitoring-pattern.md) | [Windows OpenSSH Setup](../backup/windows-openssh-setup.md)

## Purpose

Identify what's running on a node, categorize it, and eliminate bloat. Federation nodes should run minimal processes — every unnecessary process steals RAM from VMs and services.

## The Audit Process

### Step 1: Pull Process List (via SSH)

```bash
ssh -i ~/.ssh/id_backup user@node "tasklist /FO CSV /NH"
```

### Step 2: Categorize

Group processes into categories:

| Category | Examples | Verdict |
|----------|---------|---------|
| **SYSTEM** | svchost, csrss, dwm, lsass, Registry | Keep (Windows core) |
| **HYPERVISOR** | vmms, vmcompute, vmwp | Keep (runs VMs) |
| **SECURITY** | MsMpEng (Defender), NisSrv | Keep (protection) |
| **NETWORK** | ZeroTier, SSH | Keep (federation connectivity) |
| **SERVICES** | Plex, Docker, app servers | Keep (intended workload) |
| **BROWSER** | chrome.exe, msedge.exe | Question — why on a server? |
| **IDE** | Kiro, VS Code, etc. | Question — should dev be in a VM? |
| **BLOAT** | PhoneExperienceHost, SearchApp, Cortana | Nuke |

### Step 3: Calculate Impact

```
Total host memory used by processes: X GB
- System (unavoidable): Y GB
- Services (intended): Z GB
- Bloat (removable): W GB
= Recoverable memory: W GB
```

### Step 4: Act

| Action | How |
|--------|-----|
| Close browser | Close Chrome/Edge, or reduce to essential tabs only |
| Move IDE to VM | Do dev work inside the VM, not on the host |
| Disable Edge | Settings → Apps → Default Apps → disable Edge auto-start |
| Disable Phone Link | Settings → Apps → Phone Link → disable |
| Disable Search indexing | `services.msc` → Windows Search → Disabled |
| Remove startup items | Task Manager → Startup tab → disable unnecessary |

### Step 5: Document Baseline

After cleanup, document what SHOULD be running:

```markdown
## Expected Processes (node: HOSTNAME)

### Must Run (system + hypervisor)
- Windows core (svchost, csrss, dwm, lsass)
- Hyper-V services (vmms, vmcompute, vmwp per VM)
- Windows Defender (MsMpEng)

### Must Run (services)
- ZeroTier (federation network)
- OpenSSH (remote management)
- Plex Media Server (if media node)

### Should NOT Run (on a VM host)
- Chrome/Edge (use browser inside VM instead)
- IDE (Kiro, VS Code — use inside dev VM)
- Phone Link, Cortana, Search indexing
- Any app that's not a server service
```

### Step 6: Monitor for Drift

Add a periodic check that flags when unexpected processes appear:

```bash
# Compare current processes against baseline
ssh user@node "tasklist /FO CSV /NH" | compare_to_baseline.py
```

Alert if:
- New process not in baseline appears
- Any single process using > 1GB RAM
- Total host process memory exceeds threshold (e.g., 10GB for a 128GB host)

## Automation Script

```bash
#!/bin/bash
# process-audit.sh — run against any Windows node via SSH
NODE=$1
KEY=~/.ssh/id_backup

echo "=== Process Audit: $NODE ==="
ssh -i $KEY $NODE "tasklist /FO CSV /NH" | sort_and_categorize.py

# Flag high memory consumers
ssh -i $KEY $NODE "tasklist /FI \"MEMUSAGE gt 500000\" /FO CSV /NH"
```

## Thresholds

| Metric | Healthy | Warning | Critical |
|--------|:-------:|:-------:|:--------:|
| Host process memory (128GB system) | < 10 GB | 10-15 GB | > 15 GB |
| Single process memory | < 500 MB | 500MB-1GB | > 1 GB |
| Chrome/browser total | 0 (not running) | < 1 GB | > 1 GB |
| Process count | < 200 | 200-300 | > 300 |

## The "Headless Server" Goal

A VM host should be treated as a headless server, not a workstation:
- No browser on the host (use browser inside VMs)
- No IDE on the host (develop inside VMs)
- No desktop apps on the host
- Only: OS + hypervisor + network + monitoring + intended services

This maximizes RAM available for VMs and reduces attack surface.

## Related
- [Monitoring Pattern](monitoring-pattern.md) — ongoing health checks
- [Request Lifecycle](request-lifecycle.md) — how to request cleanup from admin
- [Windows OpenSSH Setup](../backup/windows-openssh-setup.md) — SSH access for auditing
- [CAVE Principles](../security/cave-principles.md) — minimal surface
