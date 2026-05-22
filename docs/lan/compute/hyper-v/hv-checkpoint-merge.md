[edit](https://github.com/2cld/netstack/edit/master/docs/lan/compute/hyper-v/hv-checkpoint-merge.md) or [./](./)

# Hyper-V Checkpoint Merge

Merge a differencing disk (.avhdx) back into its base (.vhdx) to reclaim space and improve I/O performance.

## Why

- Checkpoints create differencing disks that grow over time
- Every disk read checks the .avhdx first, then falls through to the base .vhdx (two lookups per read)
- As the diff grows, VM performance degrades
- Merging produces a single flat .vhdx — faster reads, less disk usage

## When to Do This

- Differencing disk exceeds 50% of base disk size
- VM I/O feels sluggish
- Before NVMe migration (merge first, then move the clean .vhdx)
- During planned maintenance windows

## Prerequisites

- VM must be **shut down** or in **Saved state** (merge cannot happen while running)
- Sufficient free disk space for the merge operation (temporary spike during merge)
- Plan for downtime: 10-30 minutes depending on diff size and disk speed

## Procedure

### 1. Check current state

```powershell
# List checkpoints for a VM
Get-VMCheckpoint -VMName "nsUb2404hv"

# Check disk chain
Get-VMHardDiskDrive -VMName "nsUb2404hv" | Select Path

# Check sizes
Get-ChildItem "C:\ProgramData\Microsoft\Windows\Virtual Hard Disks\nsUb2404hv*" |
  Select Name, @{N='Size(GB)';E={[math]::Round($_.Length/1GB,1)}}, LastWriteTime |
  Format-Table -AutoSize
```

### 2. Shut down the VM

```powershell
# Graceful shutdown (preferred — lets OS shut down cleanly)
Stop-VM -Name "nsUb2404hv" -Force

# Verify it's off
Get-VM -Name "nsUb2404hv" | Select Name, State
```

**Note:** All services on this VM will be unavailable during the merge (Docker, Gitea, Wip, etc.)

### 3. Delete the checkpoint (triggers merge)

```powershell
# Remove all checkpoints for the VM
Remove-VMCheckpoint -VMName "nsUb2404hv" -Name *

# Or remove a specific checkpoint by name
# Get-VMCheckpoint -VMName "nsUb2404hv"  ← list them first
# Remove-VMCheckpoint -VMName "nsUb2404hv" -Name "checkpoint-name"
```

### 4. Wait for merge to complete

The merge happens in the background. Monitor progress:

```powershell
# Watch disk activity (merge is happening when .avhdx is shrinking)
while (Test-Path "C:\ProgramData\Microsoft\Windows\Virtual Hard Disks\nsUb2404hv_*.avhdx") {
    $avhdx = Get-ChildItem "C:\ProgramData\Microsoft\Windows\Virtual Hard Disks\nsUb2404hv_*.avhdx" -ErrorAction SilentlyContinue
    if ($avhdx) {
        Write-Output ("{0:HH:mm:ss} - avhdx still exists: {1:N1} GB" -f (Get-Date), ($avhdx.Length/1GB))
    }
    Start-Sleep 30
}
Write-Output "Merge complete - avhdx is gone"
```

Or simply check periodically:

```powershell
Get-ChildItem "C:\ProgramData\Microsoft\Windows\Virtual Hard Disks\nsUb2404hv*" |
  Select Name, @{N='Size(GB)';E={[math]::Round($_.Length/1GB,1)}}
```

When only `nsUb2404hv.vhdx` remains (no .avhdx), the merge is done.

### 5. Verify and start VM

```powershell
# Check final disk size
Get-ChildItem "C:\ProgramData\Microsoft\Windows\Virtual Hard Disks\nsUb2404hv*" |
  Select Name, @{N='Size(GB)';E={[math]::Round($_.Length/1GB,1)}}

# Start the VM
Start-VM -Name "nsUb2404hv"

# Verify it's running
Get-VM -Name "nsUb2404hv" | Select Name, State, Uptime
```

### 6. Verify services (from another machine via SSH)

```bash
# Wait 60 seconds for boot, then test
ssh nsadmin@10.147.17.176 "hostname && docker ps --format 'table {{.Names}}\t{{.Status}}'"
```

## Expected Results

| Before | After (estimated) |
|--------|-------------------|
| Base: 119.9 GB + Diff: 78.6 GB = 198.5 GB | Single .vhdx: ~130-150 GB |
| Two-file lookup per read | Single-file lookup |
| ~50-70 GB reclaimed on C: | Faster I/O |

## Rollback

If something goes wrong during merge:
- The base .vhdx is not modified until merge completes
- If merge is interrupted (power loss), Hyper-V will retry on next start
- Worst case: restore from backup (catbu-sl has VM snapshots if backed up)

## Post-Merge: Prevent Future Checkpoint Growth

```powershell
# Set VM to not auto-checkpoint
Set-VM -Name "nsUb2404hv" -AutomaticCheckpointsEnabled $false
```

This prevents Windows from silently creating checkpoints during updates.

## Related

- [hv-vm-mac-remote-network.md](./hv-vm-mac-remote-network.md) — Hyper-V networking
- [netstack remote-desktop](../../ops/tools/remote-desktop.md) — remote access to VMs
- [netstack SSH + Kiro CLI](../../ops/users/dev-ssh-kiro-cli.md) — terminal access
