# Pattern: WSL Monitoring Node for Windows Sites

**Category:** `docs/ops/monitor/`  
**Purpose:** Use Windows Subsystem for Linux (WSL) as the Unix monitoring node on Windows-based federation sites, enabling standard bash monitoring scripts with LAN access.  
**Audience:** Any site running Windows as the primary OS that needs reliable monitoring via bash scripts.

---

## The Problem

Bash monitoring scripts don't work reliably on Windows:
- Git Bash + cmd.exe SSH: heredoc file writes fail, PowerShell not in PATH
- Commands are 10-30x slower via PowerShell shelling from bash
- SSH default shell issues (cmd.exe vs PowerShell vs Git Bash)

Meanwhile, the same scripts work perfectly on Linux (proven on cf/nsdockerhv).

## The Solution: WSL as Local Monitor

WSL provides a full Linux environment that:
- Has native bash, curl, standard Unix tools
- Can access the Windows host's LAN (reach local devices like HDHomeRun, NAS)
- Can call `powershell.exe` for Windows-specific queries (Get-Volume, Get-Service)
- Is accessible via SSH from the coordination layer (port-forwarded through Windows host)

```
Coordination Layer (Wip on nsdockerhv)
    ↓ SSH (port 2020)
Windows Host (port forward 2020 → WSL:22)
    ↓
WSL (Ubuntu) — runs site-status.sh
    ↓ checks
Local LAN devices (HDHomeRun, NAS, Plex on host)
    ↓ outputs
~/ops/site-status.json (read by Wip via SSH)
```

---

## Setup Procedure

### Prerequisites
- Windows 10/11 with WSL2 enabled
- Ubuntu installed in WSL (`wsl --install -d Ubuntu`)

### Step 1: Configure WSL SSH (port 2020)

In WSL:
```bash
sudo apt update && sudo apt install -y openssh-server cron
sudo service ssh start
sudo service cron start
```

### Step 2: Port Forward from Windows Host

In elevated PowerShell:
```powershell
# Get WSL IP
$wslIP = (wsl hostname -I).Trim()

# Port forward: host:2020 → WSL:22
netsh interface portproxy add v4tov4 listenport=2020 listenaddress=0.0.0.0 connectport=22 connectaddress=$wslIP

# Firewall rule
New-NetFirewallRule -DisplayName "WSL SSH 2020" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 2020
```

### Step 3: Deploy SSH Key (from coordination layer)

From nsdockerhv:
```bash
ssh-copy-id -p 2020 <user>@<site-zt-ip>
# Test:
ssh -p 2020 <user>@<site-zt-ip> "echo OK"
```

### Step 4: Deploy Status Script

```bash
scp -P 2020 site-status.sh <user>@<site-zt-ip>:~/ops/
ssh -p 2020 <user>@<site-zt-ip> "chmod +x ~/ops/site-status.sh && bash ~/ops/site-status.sh ~/ops"
```

### Step 5: Set Up Cron

Deploy setup script or manually:
```bash
(crontab -l 2>/dev/null; echo "0 */6 * * * /bin/bash ~/ops/site-status.sh ~/ops >> ~/ops/site-status.log 2>&1") | crontab -
```

Ensure cron auto-starts:
```bash
echo 'sudo service cron start 2>/dev/null' >> ~/.bashrc
echo "%sudo ALL=(ALL) NOPASSWD: /usr/sbin/service cron start" | sudo tee /etc/sudoers.d/cron
```

---

## Script Conventions for WSL on Windows

| Need | How |
|------|-----|
| Check Windows service | `powershell.exe -Command "(Get-Service sshd).Status"` |
| Check Windows disk | `powershell.exe -Command "[math]::Round((Get-Volume F).SizeRemaining/1GB)"` |
| Check LAN device | `curl -s http://192.168.x.x/endpoint` (WSL has LAN access) |
| Check host service | `curl http://192.168.x.x:port` (use LAN IP, not localhost) |
| Write output | Standard bash `cat > file << EOF` works in WSL |
| Timestamps | `date -u +%Y-%m-%dT%H:%M:%SZ` (standard Unix) |

**Key gotcha:** WSL `localhost` doesn't always reach Windows host services. Use the host's LAN IP instead.

---

## Known Limitations

| Issue | Workaround |
|-------|-----------|
| WSL IP changes on reboot | Re-run port proxy setup, or use `wsl hostname -I` in a startup script |
| Cron doesn't auto-start | Add to `.bashrc` + sudoers (see Step 5) |
| PowerShell.exe slow (2-5s per call) | Minimize PS calls; cache results for multiple checks |
| WSL filesystem ≠ Windows filesystem | Use `/mnt/c/` for Windows paths if needed |

---

## Coordination Layer Integration

Wip reads the site status via SSH:
```bash
# In wip-daily-cron.sh:
SL_JSON=$(ssh -o ConnectTimeout=10 -o BatchMode=yes -p 2020 user@site-zt-ip "cat ~/ops/site-status.json" 2>/dev/null)
```

Parse and report:
```bash
echo "$SL_JSON" | python3 -c "import json,sys; d=json.load(sys.stdin); ok=sum(1 for c in d['checks'] if c['status']=='ok'); print(f\"{d['site']}: {d['status']} ({ok}/{len(d['checks'])} passing)\")"
```

---

## Reference Implementation

- **sl site:** WSL Ubuntu 22.04 on slwin11ops, port 2020, cron every 6h
- **Script:** `sl-status.sh` checks Plex, HDHomeRun, sshd, storage, ZeroTier
- **Result:** 5/5 passing, JSON readable from nsdockerhv

---

## Related

- [cross-platform-monitoring-pattern](./cross-platform-monitoring-pattern.md) — general cross-platform approach
- [monitoring-pattern](./monitoring-pattern.md) — per-node health checks
- [netstack#12](https://github.com/2cld/netstack/issues/12) — architecture decision: Unix monitoring required
- [netstack#11](https://github.com/2cld/netstack/issues/11) — ng/sg/cg monitoring + site-status.json
- [site-tenant-contract-pattern](../deployments/site-tenant-contract-pattern.md) — defines monitoring scope
