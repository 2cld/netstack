# Synology NAS SSH Setup for Federation Nodes

**Applies to:** Synology DiskStation devices (cfbu, etc.)
**Related:** [Windows OpenSSH Setup](windows-openssh-setup.md) | [SSH/rsync Pattern](ssh-rsync-pattern.md)

## Overview

Synology NAS devices run Linux (DSM) and support SSH natively. Key-based auth enables automated backup verification and health monitoring from the coordination layer.

## Known Gotchas

1. **SSH must be enabled in DSM UI** (disabled by default)
2. **Home directories** may be at `/var/services/homes/<user>/` (DSM 6.x) or `/volume1/homes/<user>/` instead of standard `/home/<user>/`
3. **Root login** is disabled by default — use `admin` user
4. **File permissions** must be correct (same as any Linux: 700 for .ssh, 600 for authorized_keys)
5. **DSM updates** can sometimes reset SSH settings — verify after updates

## Setup Procedure

### Step 1: Enable SSH in DSM Web UI

1. Open DSM: `https://<nas-ip>:5000`
2. Control Panel → Terminal & SNMP → Terminal tab
3. Check **"Enable SSH service"**
4. Port: 22 (default)
5. Apply

### Step 2: First-time SSH with password

From a machine that can reach the NAS on LAN:
```bash
ssh admin@192.168.x.x
# Enter admin password when prompted
```

### Step 3: Find the home directory

```bash
# Check where home is
echo $HOME
pwd
# Common locations:
#   /var/services/homes/admin   (DSM 6.x)
#   /volume1/homes/admin        (DSM 7.x)
#   /root                       (if logged in as root)
```

### Step 4: Deploy public key

```bash
mkdir -p ~/.ssh
chmod 700 ~/.ssh
echo "ssh-ed25519 AAAA...your_key_here... comment" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

**Or one-liner from remote (will prompt for password once):**
```bash
ssh admin@192.168.x.x "mkdir -p ~/.ssh && chmod 700 ~/.ssh && echo 'ssh-ed25519 AAAA...key...' >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
```

### Step 5: Verify key-based auth

```bash
# From the coordination node:
ssh -i ~/.ssh/id_backup -o BatchMode=yes admin@192.168.x.x "echo SSH_WORKS && uname -a"
```

Expected output:
```
SSH_WORKS
Linux <hostname> <kernel> ... synology_<model> GNU/Linux
```

## Troubleshooting

### Permission denied (key not accepted)

**Check permissions:**
```bash
ssh admin@nas "ls -la ~/.ssh/"
# authorized_keys must be 600
# .ssh directory must be 700
# Home directory must NOT be world-writable
```

**Check home directory ownership:**
```bash
ssh admin@nas "ls -la ~ | head -2"
# Must be owned by admin:users (or admin:admin)
```

**Check sshd config (DSM 7.x):**
```bash
ssh admin@nas "cat /etc/ssh/sshd_config | grep -i pubkey"
# Should show: PubkeyAuthentication yes
```

### SSH works locally but not over ZeroTier

Same as Windows — check if ZeroTier is running on the NAS:
```bash
ssh admin@nas "ps aux | grep zerotier"
# If not running:
ssh admin@nas "sudo /var/packages/zerotier/target/bin/zerotier-one -d"
```

Or restart via DSM Package Center → ZeroTier → Run.

### Home directory not found

On some DSM versions, user homes must be enabled:
- DSM → Control Panel → User & Group → Advanced → User Home
- Check "Enable user home service"

## Useful Commands (once SSH works)

```bash
# Disk health (SMART)
ssh admin@nas "cat /proc/mdstat"
ssh admin@nas "smartctl -a /dev/sda"  # per disk

# Storage usage
ssh admin@nas "df -h"
ssh admin@nas "du -sh /volume1/*"

# RAID status
ssh admin@nas "cat /proc/mdstat"
ssh admin@nas "mdadm --detail /dev/md2"

# ZeroTier status
ssh admin@nas "zerotier-cli status"
ssh admin@nas "zerotier-cli listnetworks"

# Restart ZeroTier
ssh admin@nas "sudo /var/packages/zerotier/target/bin/zerotier-one -d"

# Temperature
ssh admin@nas "cat /proc/synology_cpu_temperature/temperature"

# UPS status (if connected)
ssh admin@nas "upsc ups"
```

## Monitoring Integration

Once SSH is working, add to federation status checks:
```bash
# From coordination node:
ssh -i ~/.ssh/id_backup admin@nas "df -h /volume1 | tail -1 | awk '{print \$5}'"
# Returns: disk usage percentage

ssh -i ~/.ssh/id_backup admin@nas "cat /proc/mdstat | grep -c 'UU'"
# Returns: number of healthy RAID arrays
```

## Security Notes

- Synology admin account has sudo access — treat the SSH key as privileged
- Consider creating a dedicated `backup` user with limited access
- Restrict key with `command=` in authorized_keys if only used for monitoring
- Keep DSM updated (security patches)

## Related
- [Windows OpenSSH Setup](windows-openssh-setup.md) — for Windows nodes
- [SSH/rsync Backup Pattern](ssh-rsync-pattern.md) — backup transport
- [Federation Node Topology](../deployments/federation-node-topology.md) — node roles
- [Monitoring Pattern](../monitor/monitoring-pattern.md) — health checks
