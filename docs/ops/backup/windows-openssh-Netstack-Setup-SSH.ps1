# From
# https://github.com/2cld/netstack/blob/master/docs/ops/backup/windows-openssh-setup.md

# Install
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0

# Start and enable auto-start
Start-Service sshd
Set-Service -Name sshd -StartupType Automatic

# Verify
Get-Service sshd
# Should show: Running

# Key Deploy
## Admin
# Create the file with the public key
$key = "ssh-ed25519 AAAA... nsub2404hv-backup"
Set-Content C:\ProgramData\ssh\administrators_authorized_keys $key

# FIX PERMISSIONS (required - server rejects keys with wrong ACLs):
icacls "C:\ProgramData\ssh\administrators_authorized_keys" /inheritance:r /grant "SYSTEM:(F)" /grant "Administrators:(F)"

# Restart to pick up changes
Restart-Service sshd

## Normal Users
$user = "username"
mkdir "C:\Users\$user\.ssh" -Force
$key = "ssh-ed25519 AAAA...your_key_here... comment"
Set-Content "C:\Users\$user\.ssh\authorized_keys" $key

# Fix permissions:
icacls "C:\Users\$user\.ssh\authorized_keys" /inheritance:r /grant "$user:(F)" /grant "SYSTEM:(F)"


# Firewall
# Check if rule exists
Get-NetFirewallRule -Name *ssh*

# Create rule that works on ALL interfaces (including ZeroTier):
New-NetFirewallRule -Name "sshd-all" -DisplayName "OpenSSH Server (all interfaces)" -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22 -Profile Any

# If the default rule exists but only allows Domain/Private:
Remove-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue
Remove-NetFirewallRule -Name "sshd-all" -ErrorAction SilentlyContinue

New-NetFirewallRule -Name "sshd-all" -DisplayName "OpenSSH Server (all interfaces)" -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22 -Profile Any

