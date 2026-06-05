# Setup buadmin on Windows targets
# Run as: Administrator on each Windows node
# Pattern: https://netstack.org/docs/ops/backup/ssh-rsync-pattern/
#
# Usage: Run in PowerShell as Admin on target node

# 1. Create buadmin user (key-auth only, strong random password)
$password = [System.Guid]::NewGuid().ToString()
net user buadmin $password /add /active:yes
net localgroup Administrators buadmin /add
Write-Host "Created buadmin user"

# 2. Create .ssh directory
$sshDir = "C:\Users\buadmin\.ssh"
New-Item -ItemType Directory -Path $sshDir -Force | Out-Null
Write-Host "Created $sshDir"

# 3. Add the nsdockerhv buadmin public key
# This is the key from nsdockerhv:/home/buadmin/.ssh/id_backup.pub
$pubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE2VwROHwIrRdrD4nCNMMPuCrO98llSUijt18RAjTUn2 buadmin@nsdockerhv"

# For admin users, key goes in ProgramData
$adminKeyFile = "C:\ProgramData\ssh\administrators_authorized_keys"
Add-Content -Path $adminKeyFile -Value $pubKey
Write-Host "Added public key to $adminKeyFile"

# For admin users, key goes in ProgramData
#$userKeyFile = "C:\Users\buadmin\.ssh\authorized_keys"
#Add-Content -Path $userKeyFile -Value $pubKey
#Write-Host "Added public key to $userKeyFile"
#icacls C:\Users\buadmin\.ssh\authorized_keys /inheritance:r /grant "buadmin:(R)" /grant "SYSTEM:(R)"

# Fix permissions on admin key file (required by Windows OpenSSH)
icacls $adminKeyFile /inheritance:r /grant "SYSTEM:(F)" /grant "Administrators:(F)"
Write-Host "Fixed permissions on authorized_keys"

# 4. Verify OpenSSH is running
$sshStatus = Get-Service sshd -ErrorAction SilentlyContinue
if ($sshStatus.Status -ne "Running") {
    Start-Service sshd
    Set-Service sshd -StartupType Automatic
    Write-Host "Started and enabled sshd"
} else {
    Write-Host "sshd already running"
}

Write-Host ""
Write-Host "=== buadmin setup complete ==="
Write-Host ""
Write-Host "Test from nsdockerhv:"
Write-Host "  sudo -u buadmin ssh -i /home/buadmin/.ssh/id_backup buadmin@<this-node-zt-ip> 'echo ok'"
Write-Host ""
Write-Host "Nodes to test:"
Write-Host "  sl:      sudo -u buadmin ssh -i /home/buadmin/.ssh/id_backup buadmin@10.147.17.94 'echo ok'"
Write-Host "  cat9fin: sudo -u buadmin ssh -i /home/buadmin/.ssh/id_backup buadmin@10.147.17.218 'echo ok'"
Write-Host "  wf:      sudo -u buadmin ssh -i /home/buadmin/.ssh/id_backup buadmin@10.147.17.165 'echo ok'"
