# Pattern: Docker on WSL for Windows Federation Sites

**Category:** `ns-site-template/templates/`  
**Purpose:** Deploy Docker Compose services inside WSL on Windows hosts that lack resources for a full Hyper-V Ubuntu VM.  
**Audience:** Federation sites running Windows as primary OS that need containerized services (reverse proxy, tunnel, monitoring).  
**Reference implementation:** sl site (slwin11ops)

---

## The Problem

Federation sites need to run Docker services (Traefik, Cloudflare tunnel, Portainer, site-specific apps), but not every site can afford a dedicated Hyper-V VM:

| Site | Compute Model | Why |
|------|---------------|-----|
| **cf** | Full Hyper-V Ubuntu VM (nsdockerhv) | CyberTruck has 128 GB RAM, plenty of headroom |
| **sl** | WSL on primary Windows host | slwin11ops is i3 / limited RAM — can't spare 8 GB for a VM |
| **wf** | Proxmox (cg2) — separate hardware | Has dedicated compute box |

WSL gives us a Linux Docker environment on the existing Windows host with minimal overhead (~300 MB RAM idle vs 4-8 GB for a VM).

## The Solution: Docker Engine in WSL

```
┌─────────────────────────────────────────────────────┐
│  Windows 11 Host (slwin11ops)                       │
│                                                     │
│  ┌──────────────────────────────────────────────┐   │
│  │  WSL2 (Ubuntu 22.04)                         │   │
│  │                                              │   │
│  │  Docker Engine (not Docker Desktop)          │   │
│  │  ┌────────────────────────────────────────┐  │   │
│  │  │  docker-compose stack                  │  │   │
│  │  │  ├─ traefik (reverse proxy)            │  │   │
│  │  │  ├─ cloudflared (CF tunnel)            │  │   │
│  │  │  ├─ portainer (management)             │  │   │
│  │  │  └─ [site-specific services]           │  │   │
│  │  └────────────────────────────────────────┘  │   │
│  │                                              │   │
│  │  ~/ops/site-status.sh (monitoring cron)      │   │
│  │  ~/docker/ (compose files + data)            │   │
│  └──────────────────────────────────────────────┘   │
│                                                     │
│  Port forwards: host:80 → WSL:80, host:443 → WSL   │
│  SSH: host:2020 → WSL:22                            │
│  ZeroTier: 10.147.17.x (host-level, WSL inherits)  │
└─────────────────────────────────────────────────────┘
         │
         │ Cloudflare Tunnel (encrypted)
         ▼
    *.2cld.com (public endpoints)
```

## Why Not Docker Desktop?

- **License:** Docker Desktop requires a paid license for commercial use
- **Overhead:** Runs its own WSL distro + GUI + Kubernetes — too heavy for a backup node
- **Control:** We want direct Docker Engine matching the cf pattern (compose files, volumes, networks)
- **Consistency:** Same `docker compose` commands as nsdockerhv

---

## Prerequisites

- Windows 10/11 with WSL2 enabled
- Ubuntu 22.04+ installed in WSL (`wsl --install -d Ubuntu`)
- WSL SSH already working (per [wsl-monitoring-node-pattern](https://github.com/2cld/netstack/blob/master/docs/ops/monitor/wsl-monitoring-node-pattern.md))
- ZeroTier on the Windows host (WSL inherits network access)
- Cloudflare account with tunnel token for this site's domain

## Setup Procedure

### Step 1: Install Docker Engine in WSL

```bash
# In WSL (Ubuntu)
sudo apt update
sudo apt install -y ca-certificates curl gnupg

# Add Docker's official GPG key
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add the repository (single line — do not break with backslash)
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine + Compose plugin
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add user to docker group (no sudo needed for docker commands)
sudo usermod -aG docker $USER
```

### Step 2: Auto-start Docker on WSL Launch

WSL doesn't run systemd by default (older installs). Two options:

**Option A: Enable systemd (Ubuntu 22.04+ with WSL 2.0+)**

Edit `/etc/wsl.conf`:
```ini
[boot]
systemd=true

[user]
default=ghadmin
```

Then restart WSL: `wsl --shutdown` from PowerShell, relaunch.

**Option B: Manual start in .bashrc (legacy fallback)**

```bash
# Add to ~/.bashrc
if ! pgrep -x dockerd > /dev/null; then
    sudo dockerd > /dev/null 2>&1 &
    sleep 2
fi
```

With corresponding sudoers entry:
```bash
echo "%docker ALL=(ALL) NOPASSWD: /usr/bin/dockerd" | sudo tee /etc/sudoers.d/docker
```

**Prefer Option A** (systemd) — it's cleaner and also gives you `systemctl` for cron, ssh, etc.

### Step 3: Create Docker Network

```bash
# Create the shared network (same as cf pattern)
docker network create proxy
```

### Step 4: Directory Layout

```bash
mkdir -p ~/docker/docker-compose/{traefik,cloudflared,portainer}
mkdir -p ~/docker/traefik/{dynamic,certs}
mkdir -p ~/docker/data
```

Convention (matches cf):
```
~/docker/
├── docker-compose/          ← compose files per service
│   ├── traefik/
│   │   ├── docker-compose.yaml
│   │   ├── .env
│   │   └── cf-token
│   ├── cloudflared/
│   │   └── docker-compose.yaml
│   └── portainer/
│       └── docker-compose.yaml
├── traefik/                 ← traefik runtime data
│   ├── traefik.yaml         ← static config
│   ├── acme.json            ← TLS certs
│   └── dynamic/             ← dynamic config
└── data/                    ← service volumes
    └── portainer/
```

### Step 5: Deploy Services

Each service gets its own compose file (same structure as `gitea.cat9.me/nsadmin/docker-compose`). The service selection comes from `site-config.yml`.

**Minimal sl stack:**

| Service | Purpose | Public URL | Required? |
|---------|---------|-----------|:---------:|
| traefik | Reverse proxy + TLS | — (internal) | ✅ |
| cloudflared | Tunnel to Cloudflare | *.2cld.com | ✅ |
| portainer | Container management UI | portainer.2cld.com | ✅ |
| [future] | Site-specific apps | — | Optional |

### Step 6: Port Forwarding (Windows → WSL)

For services that need direct LAN/ZeroTier access (not tunneled):

```powershell
# PowerShell (elevated) — forward 80/443 from host to WSL
$wslIP = (wsl hostname -I).Trim()

netsh interface portproxy add v4tov4 listenport=80 listenaddress=0.0.0.0 connectport=80 connectaddress=$wslIP
netsh interface portproxy add v4tov4 listenport=443 listenaddress=0.0.0.0 connectport=443 connectaddress=$wslIP

# Firewall rules
New-NetFirewallRule -DisplayName "Docker HTTP" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 80
New-NetFirewallRule -DisplayName "Docker HTTPS" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 443
```

**Note:** If everything goes through the Cloudflare tunnel (no direct ingress needed), port forwarding for 80/443 is optional. The tunnel container connects outbound — no inbound ports required.

### Step 7: Auto-start WSL + Docker on Windows Boot

Create a Windows Scheduled Task:

```powershell
# PowerShell (elevated)
$action = New-ScheduledTaskAction -Execute "wsl.exe" -Argument "-d Ubuntu -u root -- bash -c 'service docker start; service ssh start; service cron start'"
$trigger = New-ScheduledTaskTrigger -AtStartup
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
Register-ScheduledTask -TaskName "WSL-Docker-AutoStart" -Action $action -Trigger $trigger -Settings $settings -User "SYSTEM" -RunLevel Highest
```

**Verify after reboot:**
```bash
# From coordination layer (nsdockerhv)
ssh -p 2020 ghadmin@10.147.17.94 "docker ps"
```

---

## Networking Model

### How Traffic Flows

```
Internet → Cloudflare Edge → Tunnel (outbound from WSL) → traefik → container

                                    No inbound ports needed!
                                    Tunnel connects OUT to Cloudflare.
```

The Cloudflare tunnel model means:
- No port forwarding required on the ISP router
- No firewall holes for HTTP/HTTPS
- Cloudflare handles TLS termination and DDoS protection
- Each site gets its own tunnel with its own domain(s)

### ZeroTier Access

WSL inherits the host's ZeroTier connection. Services running in Docker containers can be reached from other federation nodes via the host's ZeroTier IP:

```bash
# From nsdockerhv (coordination layer)
curl http://10.147.17.94:9000   # → portainer (if port-forwarded)
```

### DNS for Internal Services

Internal services (not public) can be accessed via:
- ZeroTier IP + port (e.g., `10.147.17.94:9000`)
- Traefik with Host header (if running locally)

---

## Differences from CF Model

| Aspect | cf (nsdockerhv) | sl (WSL) |
|--------|-----------------|----------|
| Compute layer | Hyper-V Ubuntu VM | WSL2 Ubuntu |
| Docker install | Native on VM | Docker Engine in WSL |
| Startup | VM auto-starts with host | Scheduled Task starts WSL |
| IP stability | VM gets DHCP reservation | WSL IP changes on reboot |
| Port access | Direct (VM has own IP) | Port-forward from host OR tunnel only |
| RAM overhead | 8 GB allocated to VM | ~300 MB for WSL + containers |
| Tunnel domain | *.cat9.me | *.2cld.com |
| Compose repo | gitea.cat9.me/nsadmin/docker-compose | local ~/docker/docker-compose (git push to gitea) |

### The WSL IP Problem

WSL gets a new IP on every host reboot. This breaks `netsh portproxy` rules.

**Solutions (pick one):**
1. **Tunnel-only mode** — no port forwarding needed, everything goes through Cloudflare tunnel. Internal access via `docker exec` or SSH into WSL. **Recommended for sl.**
2. **Startup script** — re-run portproxy with fresh WSL IP on every boot (fragile but works).
3. **Bridge mode** — configure WSL networking in bridged mode (gives WSL a stable LAN IP). More complex setup.

---

## Connection to site-config.yml

The `services` and `cloudflare` sections in site-config.yml define what gets deployed:

```yaml
# In sl-site-config.yml
services:
  - name: "Traefik"
    type: "reverse-proxy"
    host: "slwin11ops-wsl"
    port: 8080
    enabled: true

  - name: "Cloudflared"
    type: "tunnel"
    host: "slwin11ops-wsl"
    tunnel_name: "sl-2cld"
    enabled: true

  - name: "Portainer"
    type: "container-management"
    url: "https://portainer.2cld.com"
    host: "slwin11ops-wsl"
    port: 9000
    enabled: true

cloudflare:
  enabled: true
  tunnels:
    - name: "sl-2cld"
      tunnel_id: "TUNNEL_ID_HERE"
      domain: "2cld.com"
      services:
        - hostname: "portainer.2cld.com"
          local_url: "http://localhost:9000"
        - hostname: "traefik.2cld.com"
          local_url: "http://localhost:8080"
```

**Future:** `generate-docker-compose.sh` reads this config and produces the compose files + traefik dynamic config automatically.

---

## Backup Integration

Docker data in WSL needs to be included in the site backup:

```yaml
# In sl-site-config.yml — storage.backups section
storage:
  backups:
    - name: "sl-docker"
      source: "wsl://~/docker/data"
      description: "Docker volumes (portainer, future app data)"
      schedule: "daily"
      method: "tar from WSL → scp to cf"
      retention:
        daily: 7
        weekly: 4
```

Backup script (runs inside WSL via cron):
```bash
#!/bin/bash
# backup-sl-docker.sh — tar Docker data, push to cf
DATE=$(date +%Y%m%d-%H%M)
DEST="/tmp/sl-docker-backup-${DATE}.tar.gz"

tar -czf "$DEST" -C ~/docker data/ docker-compose/
scp "$DEST" nsadmin@10.147.17.176:/home/nsadmin/backups/sl-docker/
rm "$DEST"

echo "${DATE} OK $(du -sh "$DEST" 2>/dev/null | cut -f1)" > ~/docker/.backup-state
```

---

## Monitoring Integration

The existing WSL monitoring node (site-status.sh) adds Docker health checks:

```bash
# Additional checks for site-status.sh
CHECK_DOCKER_STATUS="unknown"
CHECK_DOCKER_MSG=""

if command -v docker &>/dev/null; then
  RUNNING=$(docker ps -q | wc -l)
  EXPECTED=3  # traefik + cloudflared + portainer
  if [ "$RUNNING" -ge "$EXPECTED" ]; then
    CHECK_DOCKER_STATUS="ok"
    CHECK_DOCKER_MSG="${RUNNING} containers running"
  else
    CHECK_DOCKER_STATUS="warning"
    CHECK_DOCKER_MSG="${RUNNING}/${EXPECTED} containers (expected ${EXPECTED})"
  fi
else
  CHECK_DOCKER_STATUS="error"
  CHECK_DOCKER_MSG="Docker not installed"
fi
```

---

## Deployment Checklist

### One-Time Setup
- [ ] Docker Engine installed in WSL (Step 1)
- [ ] systemd enabled in /etc/wsl.conf (Step 2)
- [ ] Docker network `proxy` created (Step 3)
- [ ] Directory layout created (Step 4)
- [ ] Windows Scheduled Task for auto-start (Step 7)
- [ ] Cloudflare tunnel token obtained for sl domain

### Per-Service Deployment
- [ ] Create docker-compose.yaml in ~/docker/docker-compose/SERVICE/
- [ ] Test: `docker compose up -d`
- [ ] Verify via tunnel or direct access
- [ ] Add to site-config.yml
- [ ] Update site-status.sh expected container count

### Verification
- [ ] Reboot Windows host → WSL + Docker auto-start
- [ ] `docker ps` shows all expected containers
- [ ] Tunnel endpoints respond (curl from external)
- [ ] Wip daily cron reads docker health from site-status.json
- [ ] Backup script runs and produces .backup-state

---

## Evolution Path

| Stage | What | Status |
|:-----:|------|:------:|
| 1 | WSL monitoring node (site-status.sh, SSH, cron) | ✅ DONE |
| 2 | Docker Engine in WSL + manual compose deploy | ← NEXT |
| 3 | Cloudflare tunnel live (*.2cld.com restored) | NEXT |
| 4 | site-config.yml drives service selection | FUTURE |
| 5 | generate-docker-compose.sh produces compose files from config | FUTURE |
| 6 | Full site generation: docs + compose + monitoring + backup | FUTURE |

---

## Related

- [wsl-monitoring-node-pattern](https://github.com/2cld/netstack/blob/master/docs/ops/monitor/wsl-monitoring-node-pattern.md) — prerequisite (WSL + SSH + cron)
- [federation-setup-guide](https://github.com/2cld/netstack/blob/master/docs/ops/deployments/federation-setup-guide.md) — full site standup
- [backup-cron-pattern](https://github.com/2cld/netstack/blob/master/docs/ops/backup/backup-cron-pattern.md) — daily backup integration
- [docker-compose repo](https://gitea.cat9.me/nsadmin/docker-compose) — cf reference implementation
- [site-config-template.yml](../site-config-template.yml) — config schema that drives generation
- [netstack#11](https://github.com/2cld/netstack/issues/11) — monitoring + site-status.json generation
