# Windows OpenSSH Setup for Federation Nodes

**Applies to:** Windows 10/11 machines in the federation (CyberTruck, slwin11ops, etc.)
**Related:** [SSH/rsync Backup Pattern](ssh-rsync-pattern.md)

## Overview

Windows 10/11 includes OpenSSH Server as an optional feature. This enables key-based SSH access for backup verification, remote monitoring, and rsync operations from Linux nodes.

## Known Gotchas

1. **Admin users need keys in a different file** than regular users
2. **File permissions (ACLs) must be exact** or the server silently rejects keys
3. **Firewall must allow SSH on ALL interfaces** (including ZeroTier overlay)
4. **Mapped network drives (S:, W:) are NOT accessible** in SSH sessions (per-login-session limitation)
5. **Use UNC paths or local drive letters** for file access via SSH

## Setup Procedure

### Step 1: Install OpenSSH Server

PowerShell as Administrator:
```powershell
# Install
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0

# Start and enable auto-start
Start-Service sshd
Set-Service -Name sshd -StartupType Automatic

# Verify
Get-Service sshd
# Should show: Running
```

### Step 2: Configure Firewall (CRITICAL for ZeroTier)

The default SSH firewall rule may only allow connections on the primary network interface. Federation nodes connect via ZeroTier overlay — you MUST allow SSH on ALL interfaces:

```powershell
# Check if rule exists
Get-NetFirewallRule -Name *ssh*

# Create rule that works on ALL interfaces (including ZeroTier):
New-NetFirewallRule -Name "sshd-all" -DisplayName "OpenSSH Server (all interfaces)" -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22 -Profile Any

# If the default rule exists but only allows Domain/Private:
Remove-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue
New-NetFirewallRule -Name "sshd-all" -DisplayName "OpenSSH Server (all interfaces)" -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22 -Profile Any
```

**Why this matters:** ZeroTier creates a virtual network adapter. Windows firewall treats it as a "Public" network by default. If your SSH rule only allows "Domain" or "Private" profiles, connections over ZeroTier will be silently dropped (timeout, not refused).

**Verify from another node:**
```bash
ssh -o ConnectTimeout=5 user@10.147.17.x "echo ok"
```
If you get "Connection timed out" instead of "Connection refused" or "Permission denied", it's a firewall issue.

### Step 3: Deploy Public Key

**CRITICAL: Admin users vs regular users have DIFFERENT key file locations.**

#### For admin users (Administrators group):

Keys go in `C:\ProgramData\ssh\administrators_authorized_keys` (NOT the user's .ssh folder):

```powershell
# Create the file with the public key
$key = "ssh-ed25519 AAAA...your_key_here... comment"
Set-Content C:\ProgramData\ssh\administrators_authorized_keys $key

# FIX PERMISSIONS (required - server rejects keys with wrong ACLs):
icacls "C:\ProgramData\ssh\administrators_authorized_keys" /inheritance:r /grant "SYSTEM:(F)" /grant "Administrators:(F)"

# Restart to pick up changes
Restart-Service sshd
```

#### For regular users:

Keys go in `C:\Users\<username>\.ssh\authorized_keys`:

```powershell
$user = "username"
mkdir "C:\Users\$user\.ssh" -Force
$key = "ssh-ed25519 AAAA...your_key_here... comment"
Set-Content "C:\Users\$user\.ssh\authorized_keys" $key

# Fix permissions:
icacls "C:\Users\$user\.ssh\authorized_keys" /inheritance:r /grant "$user:(F)" /grant "SYSTEM:(F)"
```

### Step 4: Verify sshd_config

Check `C:\ProgramData\ssh\sshd_config` for these settings:

```
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys

# For admin users, this line at the BOTTOM of the file overrides the above:
Match Group administrators
       AuthorizedKeysFile __PROGRAMDATA__/ssh/administrators_authorized_keys
```

If you modify sshd_config, restart the service:
```powershell
Restart-Service sshd
```

### Step 5: Test from Linux

```bash
# From the Linux node (e.g., nsdockerhv):
ssh -i ~/.ssh/id_backup -o BatchMode=yes user@windows-host "echo SSH_WORKS && hostname && whoami"
```

Expected output:
```
SSH_WORKS
HOSTNAME
hostname\username
```

## Troubleshooting

### Connection timed out (not refused)

**Cause:** Firewall blocking on the ZeroTier interface.

Fix:
```powershell
New-NetFirewallRule -Name "sshd-all" -DisplayName "OpenSSH Server (all interfaces)" -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22 -Profile Any
```

### Connection refused

**Cause:** sshd not running.

Fix:
```powershell
Start-Service sshd
Set-Service -Name sshd -StartupType Automatic
```

### Key is offered but rejected (Permission denied)

**Most common cause:** Wrong file permissions on authorized_keys.

Fix for admin users:
```powershell
icacls "C:\ProgramData\ssh\administrators_authorized_keys" /inheritance:r /grant "SYSTEM:(F)" /grant "Administrators:(F)"
Restart-Service sshd
```

### Verbose debugging from client side:
```bash
ssh -v -i ~/.ssh/id_backup -o BatchMode=yes user@host "echo ok" 2>&1 | grep -i "offer\|denied\|auth"
```

Look for:
- `Offering public key` — client is sending the key
- `Authentications that can continue` — server rejected it
- This means the key file exists but permissions are wrong

### Mapped drives not accessible via SSH

Windows maps network drives per-login-session. SSH sessions don't inherit them.

**Workaround:** Use UNC paths or local drive letters:
```bash
# Instead of S:\backup
ssh user@host "dir \\\\10.x.x.x\\share\\path"

# Or access local drives directly
ssh user@host "dir D:\\cfops-share\\current"
```

### SSH works but rsync doesn't

Windows doesn't have rsync natively. Options:
1. Install rsync via Cygwin (already on CyberTruck: `C:\cygwin64`)
2. Install rsync via WSL
3. Use `scp` instead (simpler, no delta sync)
4. Use PowerShell `Copy-Item` via SSH for simple copies

## Security Considerations

- Use dedicated backup keys (ed25519 preferred)
- No passphrase on automated keys (trade-off accepted for automation)
- Restrict key access via `command=` in authorized_keys if needed
- Only allow SSH from known ZeroTier IPs (firewall rule)
- Monitor SSH login events: Event Viewer > Applications and Services Logs > OpenSSH > Operational

## Integration with Federation Monitoring

Once SSH is working, the coordination layer can:
```bash
# Check disk space
ssh -i ~/.ssh/id_backup user@host "wmic logicaldisk get caption,freespace,size"

# Verify backup files exist
ssh -i ~/.ssh/id_backup user@host "dir D:\\backups\\*.tar"

# Check VM status (Hyper-V)
ssh -i ~/.ssh/id_backup user@host "powershell Get-VM | Select Name,State"

# Process audit
ssh -i ~/.ssh/id_backup user@host "tasklist /FI \"MEMUSAGE gt 500000\" /FO CSV /NH"
```

## Related
- [SSH/rsync Backup Pattern](ssh-rsync-pattern.md) — overall backup transport pattern
- [Federation Backup Plan](federation-backup-plan.md) — 3-2-1 strategy
- [Monitoring Pattern](../monitor/monitoring-pattern.md) — health check integration
- [Process Audit Pattern](../monitor/process-audit-pattern.md) — auditing what's running
- [Request Lifecycle](../monitor/request-lifecycle.md) — how SSH setup was requested and verified
