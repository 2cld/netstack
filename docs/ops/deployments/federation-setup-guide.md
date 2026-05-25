[edit](https://github.com/2cld/netstack/edit/master/docs/ops/deployments/federation-setup-guide.md) or [./](./)

# Federation Site Setup Guide

How to stand up a new cf, wf, or sl federation node from scratch. Covers network, services, storage, backup, and verification.

## Architecture Overview

Three geographic sites connected by encrypted overlay (ZeroTier). Each site has a role:

| Site | Role | Critical Services | Storage Role |
|------|------|-------------------|--------------|
| **cf** (Cedar Falls) | Production + Dev | hwpc-rp, Gitea, Traefik, Plex | Primary (source of backups) |
| **sl** (O'Fallon) | Off-site Backup + Media | Plex DVR, SMB backup target | Backup target #1 |
| **wf** (Winfield) | Failover + Archive | Proxmox, ZFS archive | Backup target #2 + failover |

```
        cf (primary)
       /            \
      /   ZeroTier   \
     /   10.147.17.x  \
    sl ──────────────── wf
  (backup)          (failover)
```

## Layer 0: Ops User Environment

Before touching network or services, set up the operator account. This is the foundation everything else builds on.

**Follow:** [ops-node-setup.md](../users/ops-node-setup.md)

Checklist:
1. `nsadmin` user exists with sudo + docker group
2. `~/code/` directory with netstack clone (minimum)
3. `~/.local/bin/` on PATH
4. Node.js 22+ installed
5. Git configured

Once the operator environment is ready, proceed to network setup.

**Pattern note:** All work on this node follows the [pattern-workflow](../pattern-workflow.md) — if you can't find a netstack doc for what you're doing, write one first.

---

## Layer 1: Network Setup

Every federation node needs these network components:

### 1.1 Base OS + SSH

```bash
# Ubuntu
sudo apt update && sudo apt install -y openssh-server
sudo systemctl enable ssh

# Windows (PowerShell as admin)
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
Set-Service sshd -StartupType Automatic
Start-Service sshd
```

See: [windows-openssh-setup.md](../backup/windows-openssh-setup.md)

### 1.2 ZeroTier (overlay network)

```bash
# Linux
curl -s https://install.zerotier.com | sudo bash
sudo zerotier-cli join d5e5fb65371eb4a4

# Windows (download from zerotier.com, then)
zerotier-cli join d5e5fb65371eb4a4
```

Authorize the new node at: https://my.zerotier.com/network/d5e5fb65371eb4a4

After authorization, node gets a 10.147.17.x IP. All federation traffic flows over this overlay.

### 1.3 Firewall Rules

Allow through ZeroTier interface:
- SSH (22)
- SMB (445) — for backup shares
- Service-specific ports (see per-site sections below)

### 1.4 Remote Access (optional but recommended)

See: [remote-desktop.md](../tools/remote-desktop.md)
- RDP (3389) — for GUI access
- RustDesk (21118) — for NAT traversal
- SSH is primary (see [dev-ssh-kiro-cli.md](../users/dev-ssh-kiro-cli.md))

---

## Layer 2: Storage Setup

### 2.1 Backup Share (required on sl and wf)

Each backup target needs an SMB share accessible over ZeroTier:

```powershell
# Windows — create share
New-Item -ItemType Directory -Path "F:\backup-share" -Force
New-SmbShare -Name "backup-share" -Path "F:\backup-share" -FullAccess "Everyone"
```

```bash
# Linux — create share (samba)
sudo apt install -y samba
# Add to /etc/samba/smb.conf:
# [backup-share]
#   path = /srv/backup
#   writable = yes
#   guest ok = no
#   valid users = nsadmin
```

### 2.2 Backup Source (required on cf)

cf pushes backups to sl and wf. Needs:
- SSH key-based auth to target nodes
- rsync or scp for transfer
- Scheduled script (cron or Task Scheduler)

```bash
# Test connectivity
ssh ghadmin@10.147.17.94 "echo sl reachable"
ssh ghadmin@10.147.17.165 "echo wf reachable"
```

### 2.3 Storage Layout Convention

```
[backup-drive]:\
├── catbu-[site]\           ← backups received from cf
│   ├── hwpc-rp-*.tar      ← production data snapshots
│   ├── gitea-db-*.sql     ← Gitea database dumps
│   ├── docker-backup-*\   ← full Docker service backup
│   └── .backup-state      ← timestamp of last successful backup
├── media\                  ← Plex/media content (if applicable)
└── archive\                ← cold storage (old projects, VMs)
```

---

## Layer 3: Services (per site)

### CF Node Setup

CF is the production site. It runs:

| Service | Where | Port | Setup |
|---------|-------|:----:|-------|
| Hyper-V | CyberTruck host | — | Windows feature, hosts VMs |
| hwpc-rp | cat9fin VM | 5005 | Node.js app + SQLite |
| Gitea | nsdockerhv (Docker) | 3000 | docker-compose |
| Traefik | nsdockerhv (Docker) | 80/443 | docker-compose |
| Cloudflare tunnel | nsdockerhv (Docker) | — | docker-compose |
| Plex | CyberTruck host | 32400 | Windows installer + GPU |
| UPS monitor | CyberTruck host | 31111 | CyberPower PowerPanel |

**CF rebuild order:**
1. Install Windows 10 on host
2. Enable Hyper-V
3. Install ZeroTier + SSH
4. Create nsdockerhv VM (Ubuntu 24.04)
5. Deploy Docker services (gitea, traefik, cloudflared)
6. Create cat9fin VM (Windows 11)
7. Restore hwpc-rp data from backup
8. Install Plex + point to cfbu media
9. Verify all services

### SL Node Setup

SL is the backup target + Plex DVR:

| Service | Port | Setup |
|---------|:----:|-------|
| SMB (slMedia share) | 445 | Windows share on F: drive |
| Plex DVR | 32400 | Windows installer (records, transfers to cf) |
| SSH | 22 | OpenSSH server |
| ZeroTier | 9993 | Overlay network |

**SL rebuild order:**
1. Install Windows 11
2. Install ZeroTier + SSH
3. Create SMB share (slMedia on F:)
4. Install Plex (DVR recording role)
5. Verify backup reception from cf

### WF Node Setup

WF is failover + archive storage:

| Service | Port | Setup |
|---------|:----:|-------|
| SMB (cat9bu-wf-share) | 445 | Windows share |
| Proxmox (cg2) | 8006 | Separate hardware, ZFS pool |
| SSH | 22 | OpenSSH server |
| ZeroTier | 9993 | Overlay network |

**WF rebuild order:**
1. Repair storm damage (power, network)
2. Install OS on devwin10 (or repurpose for Proxmox)
3. Install ZeroTier + SSH
4. Create SMB share (cat9bu-wf-share)
5. Verify backup reception from cf
6. (Future) Test hwpc-rp failover

---

## Layer 4: Backup Automation

### What Gets Backed Up

| Data | Source | Size | Frequency | Method |
|------|--------|:----:|:---------:|--------|
| hwpc-rp (route_tickets.db + Account/) | cat9fin | ~90 MB | Daily | tar + scp |
| Gitea DB (PostgreSQL dump) | nsdockerhv | ~600 KB | Daily | pg_dump + scp |
| Gitea data (repos, avatars) | nsdockerhv | ~50 MB | Weekly | docker exec tar + scp |
| Traefik certs (acme.json) | nsdockerhv | ~120 MB | Weekly | tar + scp |
| Cloudflare token | nsdockerhv | <1 KB | On change | copy |
| Docker compose files | nsdockerhv | <1 MB | In git | git push (automatic) |

### Backup Flow

```
cf (source) ──── daily ────→ sl (off-site backup #1)
     │
     └─────── daily ────→ wf (off-site backup #2, when online)
```

### Scripts

- **Docker services:** `docker-compose/backup/backup-docker-services.sh`
- **hwpc-rp:** tar from cat9fin → D:\cfops-share → scp to sl/wf
- **Transfer:** `scp -r /backup/dir ghadmin@10.147.17.94:F:/slMedia/catbu-sl/`

### Cron Schedule (target state)

```bash
# On nsdockerhv — daily at 2 AM
0 2 * * * bash ~/code/docker-compose/backup/backup-docker-services.sh ~/backups/docker-daily
0 3 * * * scp -r ~/backups/docker-daily ghadmin@10.147.17.94:F:/slMedia/catbu-sl/docker/

# On cat9fin — daily at 2 AM (Task Scheduler)
# tar hwpc-rp data → D:\cfops-share\current\cat9fin\
# robocopy to \\10.147.17.94\slMedia\catbu-sl\
```

---

## Layer 5: Verification

### Daily Health Check

```bash
# From nsdockerhv (or any ZT node)
# Check all nodes reachable
for ip in 10.147.17.219 10.147.17.218 10.147.17.94 10.147.17.165; do
  ping -c1 -W2 $ip > /dev/null 2>&1 && echo "$ip UP" || echo "$ip DOWN"
done

# Check critical services
curl -s https://gitea.cat9.me > /dev/null && echo "Gitea OK" || echo "Gitea DOWN"
ssh nsadmin@10.147.17.218 "netstat -an | findstr 5005 | findstr LISTENING" && echo "hwpc-rp OK"
```

### Backup Freshness Check

```bash
# Check .backup-state on sl
ssh ghadmin@10.147.17.94 "type F:\slMedia\catbu-sl\.backup-state"
# Should show today's date
```

### Full Restore Test (monthly)

1. Spin up a test VM (or use win11vm on CyberTruck)
2. Run restore script with latest backup
3. Verify hwpc-rp starts and serves data
4. Verify Gitea starts and repos are accessible
5. Document results + time taken

---

## Quick Reference: Federation IPs

| Node | ZeroTier IP | LAN IP | Site | Role |
|------|:-----------:|:------:|:----:|------|
| CyberTruck | 10.147.17.219 | 192.168.6.30 | cf | Host (Hyper-V, Plex) |
| cat9fin | 10.147.17.218 | 192.168.6.127 | cf | Production (hwpc-rp) |
| nsdockerhv | 10.147.17.176 | 192.168.6.106 | cf | Dev (Docker, Gitea, Wip) |
| cfbu | — | 192.168.10.2 | cf | Storage (Plex media, LAN-only) |
| slwin11ops | 10.147.17.94 | 192.168.1.194 | sl | Backup target + Plex DVR |
| devwin10 | 10.147.17.165 | 192.168.9.x | wf | Backup target (DOWN) |
| cg2 | — | 192.168.9.3 | wf | Proxmox/ZFS archive |

## Related

- [federation-node-topology.md](./federation-node-topology.md) — node roles and relationships
- [status.md](./status.md) — current deployment status
- [../backup/federation-backup-plan.md](../backup/federation-backup-plan.md) — 3-2-1 backup details
- [../backup/ssh-rsync-pattern.md](../backup/ssh-rsync-pattern.md) — backup transport
- [../tools/remote-desktop.md](../tools/remote-desktop.md) — remote access methods
- [../users/dev-ssh-kiro-cli.md](../users/dev-ssh-kiro-cli.md) — SSH + Kiro CLI workflow
