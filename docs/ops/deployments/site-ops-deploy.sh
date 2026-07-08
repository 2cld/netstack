#!/bin/bash
#
# site-ops deploy — Provision Docker on WSL + deploy compose services
#
# Usage: site-ops-deploy.sh <site-config.yml>
#
# What it does (idempotent — safe to run multiple times):
#   1. Reads site config for SSH target, services, storage mounts
#   2. SSHs into WSL and provisions Docker Engine
#   3. Creates directory layout
#   4. Generates docker-compose.yaml per service
#   5. Starts all services
#
# Prerequisites:
#   - Windows host with WSL Ubuntu installed
#   - SSH key-based access to WSL (port from config, default 2020)
#   - ZeroTier connected (host reachable on overlay IP)
#   - yq installed on ops controller (for YAML parsing)
#
# Pattern: ns-site-template/scripts/site-ops/
# Reference: compute-wsl-docker-pattern.md

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# --- Parse arguments ---
CONFIG="${1:-}"
if [[ -z "$CONFIG" || ! -f "$CONFIG" ]]; then
    echo -e "${RED}Usage: $0 <site-config.yml>${NC}"
    echo "  Deploys Docker services to a WSL target based on site config."
    exit 1
fi

echo "=== site-ops deploy ==="
echo "Config: $CONFIG"
echo ""

# --- Read config values (requires yq) ---
if ! command -v yq &>/dev/null; then
    echo -e "${RED}Error: yq not found. Install: sudo apt install yq OR snap install yq${NC}"
    exit 1
fi

SITE=$(yq '.site' "$CONFIG")
ZT_IP=$(yq '.primary_zt_ip' "$CONFIG")
SSH_PORT=$(yq '.cg.nodes[0].wsl.ssh_port // 2020' "$CONFIG")
SSH_USER=$(yq '.site_admin // "ghadmin"' "$CONFIG" | cut -d'@' -f1)
COMPOSE_PATH=$(yq '.cg.nodes[0].wsl.compose_path // "~/docker/docker-compose"' "$CONFIG")
DATA_PATH=$(yq '.cg.nodes[0].wsl.data_path // "~/docker/data"' "$CONFIG")

SSH_TARGET="${SSH_USER}@${ZT_IP}"
SSH_CMD="ssh -o ConnectTimeout=15 -o BatchMode=yes -p ${SSH_PORT} ${SSH_TARGET}"

echo "Site: ${SITE}"
echo "Target: ${SSH_TARGET}:${SSH_PORT} (WSL)"
echo "Compose path: ${COMPOSE_PATH}"
echo "Data path: ${DATA_PATH}"
echo ""

# --- Test connectivity ---
echo -e "${YELLOW}[1/6] Testing SSH connectivity...${NC}"
if ! $SSH_CMD "echo ok" >/dev/null 2>&1; then
    echo -e "${RED}Cannot reach ${SSH_TARGET}:${SSH_PORT}. Check:${NC}"
    echo "  - ZeroTier connected (host at ${ZT_IP})"
    echo "  - WSL SSH running on port ${SSH_PORT}"
    echo "  - SSH key deployed for ${SSH_USER}"
    exit 1
fi
echo -e "${GREEN}  ✅ SSH connected${NC}"
echo ""

# --- Validate remote environment ---
echo -e "${YELLOW}[1.5/6] Validating remote prerequisites...${NC}"
PREFLIGHT=$($SSH_CMD bash << 'PREFLIGHT_CHECK'
ERRORS=""

# Check we're on Linux (not cmd.exe or PowerShell)
if [[ ! -f /etc/os-release ]]; then
    ERRORS="${ERRORS}NOT_LINUX "
fi

# Check it's Ubuntu/Debian (apt-based)
if ! command -v apt-get &>/dev/null; then
    ERRORS="${ERRORS}NO_APT "
fi

# Check sudo access
if ! sudo -n true 2>/dev/null; then
    ERRORS="${ERRORS}NO_SUDO "
fi

# Check basic tools
for cmd in curl grep cut; do
    if ! command -v $cmd &>/dev/null; then
        ERRORS="${ERRORS}MISSING_${cmd} "
    fi
done

# Report
if [[ -z "$ERRORS" ]]; then
    # Print distro info for logging
    . /etc/os-release
    echo "OK $ID $VERSION_ID $(uname -m)"
else
    echo "FAIL $ERRORS"
fi
PREFLIGHT_CHECK
)

if [[ "$PREFLIGHT" == FAIL* ]]; then
    echo -e "${RED}  ❌ Remote prerequisites failed: ${PREFLIGHT}${NC}"
    echo ""
    echo "  The deploy target must be a Linux (WSL/Ubuntu) shell with:"
    echo "    - /etc/os-release present (Linux, not cmd.exe or PowerShell)"
    echo "    - apt-get available (Debian/Ubuntu)"
    echo "    - passwordless sudo for the SSH user"
    echo "    - curl, grep, cut installed"
    echo ""
    echo "  If SSH is landing in cmd.exe, fix the default shell:"
    echo "    On Windows (elevated): New-ItemProperty -Path 'HKLM:\\SOFTWARE\\OpenSSH' \\"
    echo "      -Name DefaultShell -Value 'C:\\Windows\\System32\\bash.exe' -PropertyType String -Force"
    echo "  Or use the WSL SSH on port 2020 (not the Windows SSH on port 22)."
    exit 1
fi

REMOTE_DISTRO=$(echo "$PREFLIGHT" | cut -d' ' -f2)
REMOTE_VERSION=$(echo "$PREFLIGHT" | cut -d' ' -f3)
REMOTE_ARCH=$(echo "$PREFLIGHT" | cut -d' ' -f4)
echo -e "${GREEN}  ✅ Remote is Linux: ${REMOTE_DISTRO} ${REMOTE_VERSION} (${REMOTE_ARCH})${NC}"
echo ""

# --- Install Docker Engine (idempotent) ---
echo -e "${YELLOW}[2/6] Ensuring Docker Engine installed...${NC}"
$SSH_CMD bash << 'DOCKER_INSTALL'
set -e

if command -v docker &>/dev/null && docker info >/dev/null 2>&1; then
    echo "  Docker already installed and running: $(docker --version)"
    exit 0
fi

echo "  Installing Docker Engine..."

# Prerequisites
sudo apt-get update -qq
sudo apt-get install -y -qq ca-certificates curl gnupg >/dev/null

# Docker GPG key
sudo install -m 0755 -d /etc/apt/keyrings
if [[ ! -f /etc/apt/keyrings/docker.gpg ]]; then
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
fi

# Docker repo (single line — no backslash breaks)
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install
sudo apt-get update -qq
sudo apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin >/dev/null

# Add user to docker group
sudo usermod -aG docker "$USER" || true

echo "  Docker installed: $(docker --version)"
DOCKER_INSTALL

echo -e "${GREEN}  ✅ Docker Engine ready${NC}"
echo ""

# --- Ensure Docker is running ---
echo -e "${YELLOW}[3/6] Ensuring Docker daemon running...${NC}"
$SSH_CMD bash << 'DOCKER_START'
set -e

# Check if systemd is available
if pidof systemd >/dev/null 2>&1; then
    sudo systemctl start docker 2>/dev/null || true
    sudo systemctl enable docker 2>/dev/null || true
    echo "  Docker started via systemd"
else
    # Fallback: start dockerd manually
    if ! pgrep -x dockerd >/dev/null; then
        sudo dockerd > /tmp/dockerd.log 2>&1 &
        sleep 3
        echo "  Docker started manually (no systemd)"
    else
        echo "  Docker daemon already running"
    fi
fi

# Verify
docker info >/dev/null 2>&1 && echo "  Docker daemon responding" || echo "  WARNING: Docker not responding"
DOCKER_START

echo -e "${GREEN}  ✅ Docker daemon running${NC}"
echo ""

# --- Create directory layout ---
echo -e "${YELLOW}[4/6] Creating directory layout...${NC}"

# Check storage mounts first
MEDIA_MOUNT=$($SSH_CMD "ls /mnt/f/slMedia 2>/dev/null && echo 'OK' || echo 'MISSING'" 2>/dev/null)
if [[ "$MEDIA_MOUNT" == *"MISSING"* ]]; then
    echo -e "${YELLOW}  ⚠️  /mnt/f/slMedia not accessible from WSL${NC}"
    echo "  Plex media mount will not work until F: drive is visible."
    echo "  Check: Windows drive automount in /etc/wsl.conf ([automount] enabled=true)"
    echo "  Continuing with deployment (non-fatal)..."
    echo ""
fi

$SSH_CMD bash << DIRS
set -e
mkdir -p ${COMPOSE_PATH}/{traefik,cloudflared,plex,portainer}
mkdir -p ${DATA_PATH}/{traefik/dynamic,plex,portainer}
mkdir -p ~/ops
echo "  Directories created"
DIRS

echo -e "${GREEN}  ✅ Directory layout ready${NC}"
echo ""

# --- Create Docker network ---
echo -e "${YELLOW}[5/6] Ensuring Docker network 'proxy' exists...${NC}"
$SSH_CMD bash << 'NETWORK'
set -e
if docker network inspect proxy >/dev/null 2>&1; then
    echo "  Network 'proxy' already exists"
else
    docker network create proxy
    echo "  Network 'proxy' created"
fi
NETWORK

echo -e "${GREEN}  ✅ Docker network ready${NC}"
echo ""

# --- Generate and deploy compose files ---
echo -e "${YELLOW}[6/6] Generating and deploying compose files...${NC}"

# Read services from config
SERVICES=$(yq -r '.cg.services[] | select(.layer == "docker") | .name' "$CONFIG")

for SERVICE in $SERVICES; do
    echo "  Deploying: ${SERVICE}"

    IMAGE=$(yq -r ".cg.services[] | select(.name == \"${SERVICE}\") | .image // \"\"" "$CONFIG")
    PORT=$(yq -r ".cg.services[] | select(.name == \"${SERVICE}\") | .port // \"\"" "$CONFIG")
    NET_MODE=$(yq -r ".cg.services[] | select(.name == \"${SERVICE}\") | .network_mode // \"\"" "$CONFIG")
    TUNNEL=$(yq -r ".cg.services[] | select(.name == \"${SERVICE}\") | .tunnel_name // \"\"" "$CONFIG")

    case "$SERVICE" in
        traefik)
            $SSH_CMD bash << 'TRAEFIK_COMPOSE'
cat > ~/docker/docker-compose/traefik/docker-compose.yaml << 'EOF'
services:
  traefik:
    image: traefik:v3
    container_name: traefik
    restart: unless-stopped
    networks:
      - proxy
    ports:
      - "80:80"
      - "443:443"
      - "8080:8080"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ~/docker/data/traefik/traefik.yaml:/traefik.yaml:ro
      - ~/docker/data/traefik/dynamic:/dynamic:ro
      - ~/docker/data/traefik/acme.json:/acme.json
    labels:
      - "traefik.enable=true"

networks:
  proxy:
    external: true
EOF
echo "    traefik compose written"
TRAEFIK_COMPOSE
            # Create minimal traefik static config if missing
            $SSH_CMD bash << 'TRAEFIK_CONFIG'
if [[ ! -f ~/docker/data/traefik/traefik.yaml ]]; then
cat > ~/docker/data/traefik/traefik.yaml << 'EOF'
api:
  dashboard: true
  insecure: true

entryPoints:
  http:
    address: ":80"
  https:
    address: ":443"

providers:
  docker:
    endpoint: "unix:///var/run/docker.sock"
    exposedByDefault: false
  file:
    directory: "/dynamic"
    watch: true
EOF
echo "    traefik config created"
fi
if [[ ! -f ~/docker/data/traefik/acme.json ]]; then
    touch ~/docker/data/traefik/acme.json
    chmod 600 ~/docker/data/traefik/acme.json
    echo "    acme.json created"
fi
TRAEFIK_CONFIG
            ;;

        cloudflared)
            # Read tunnel token from config (placeholder for now)
            TUNNEL_NAME=$(yq -r '.cloudflare.tunnels[0].name // "sl-2cld"' "$CONFIG")
            $SSH_CMD bash << CLOUDFLARED_COMPOSE
cat > ~/docker/docker-compose/cloudflared/docker-compose.yaml << 'EOF'
services:
  tunnel:
    container_name: sl-2cld
    image: cloudflare/cloudflared:latest
    restart: unless-stopped
    command: tunnel run
    networks:
      - proxy
    environment:
      - TUNNEL_TOKEN=\${CLOUDFLARE_TUNNEL_TOKEN}

networks:
  proxy:
    external: true
EOF
# Create .env placeholder if missing
if [[ ! -f ~/docker/docker-compose/cloudflared/.env ]]; then
    echo "CLOUDFLARE_TUNNEL_TOKEN=REPLACE_ME" > ~/docker/docker-compose/cloudflared/.env
    echo "    ⚠️  cloudflared .env created — SET TUNNEL_TOKEN before starting"
fi
echo "    cloudflared compose written"
CLOUDFLARED_COMPOSE
            ;;

        plex)
            $SSH_CMD bash << 'PLEX_COMPOSE'
cat > ~/docker/docker-compose/plex/docker-compose.yaml << 'EOF'
services:
  plex:
    image: linuxserver/plex:latest
    container_name: plex
    network_mode: host
    restart: unless-stopped
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=America/Chicago
      - VERSION=docker
      # - PLEX_CLAIM=claim-xxxx  # Uncomment for first run: https://plex.tv/claim
    volumes:
      - ~/docker/data/plex:/config
      - /mnt/f/slMedia:/data/media
      - /tmp/plex-transcode:/transcode
EOF
echo "    plex compose written"
PLEX_COMPOSE
            ;;

        portainer)
            $SSH_CMD bash << 'PORTAINER_COMPOSE'
cat > ~/docker/docker-compose/portainer/docker-compose.yaml << 'EOF'
services:
  portainer:
    image: portainer/portainer-ce:latest
    container_name: portainer
    restart: unless-stopped
    networks:
      - proxy
    ports:
      - "9000:9000"
      - "9443:9443"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ~/docker/data/portainer:/data
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.portainer.rule=Host(`portainer.2cld.com`)"
      - "traefik.http.services.portainer.loadbalancer.server.port=9000"

networks:
  proxy:
    external: true
EOF
echo "    portainer compose written"
PORTAINER_COMPOSE
            ;;

        *)
            echo "    ⚠️  Unknown service: ${SERVICE} (no template, skipping)"
            ;;
    esac
done

echo ""
echo -e "${GREEN}  ✅ All compose files generated${NC}"
echo ""

# --- Start services ---
echo -e "${YELLOW}Starting services...${NC}"
for SERVICE in $SERVICES; do
    echo -n "  Starting ${SERVICE}... "
    # Skip cloudflared if token not set
    if [[ "$SERVICE" == "cloudflared" ]]; then
        TOKEN_SET=$($SSH_CMD "grep -v REPLACE_ME ~/docker/docker-compose/cloudflared/.env 2>/dev/null | grep -c CLOUDFLARE_TUNNEL_TOKEN" 2>/dev/null || echo "0")
        if [[ "$TOKEN_SET" == "0" ]]; then
            echo -e "${YELLOW}SKIPPED (set CLOUDFLARE_TUNNEL_TOKEN in .env first)${NC}"
            continue
        fi
    fi
    $SSH_CMD "cd ~/docker/docker-compose/${SERVICE} && docker compose up -d" 2>/dev/null && \
        echo -e "${GREEN}OK${NC}" || \
        echo -e "${RED}FAILED${NC}"
done

echo ""
echo "=== site-ops deploy complete ==="
echo ""
echo "Next steps:"
echo "  1. Set Cloudflare tunnel token: ssh -p ${SSH_PORT} ${SSH_TARGET}"
echo "     Edit ~/docker/docker-compose/cloudflared/.env"
echo "  2. Set Plex claim token (first run only):"
echo "     Edit ~/docker/docker-compose/plex/docker-compose.yaml"
echo "  3. Verify: site-ops-verify.sh ${CONFIG}"
echo ""
echo "Run 'site-ops verify ${CONFIG}' to check all services."
