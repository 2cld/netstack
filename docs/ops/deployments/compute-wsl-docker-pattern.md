# Pattern: Docker on WSL for a Windows Host (the documented exception to the Proxmox default)

**Purpose:** Run a small Docker stack (tunnel, reverse proxy, status endpoint) inside WSL2 on a Windows host that cannot also be a Proxmox or Hyper-V Docker host.
**Audience:** A federation site whose only machine is a Windows PC, and the wip/human who maintains it.
**Reference implementation:** the sl site, rebuild tracked in [sl#15](https://github.com/2cld/sl/issues/15).
**Status:** Revised 2026-11-24 to match the sl#15 target design. The WSL start-up task (Step 7) has not been validated on a real rebuild yet; sl#15 is that test.
**Related:** [site-repo-flow-pattern](./site-repo-flow-pattern.md), [bmr-pattern](./bmr-pattern.md), [docker-service-subdomain-pattern](../../wan/cloudflare/docker-service-subdomain-pattern.md), [public-status-endpoint-pattern](../monitor/public-status-endpoint-pattern.md), [cloudflare-federation-access-pattern](../security/cloudflare-federation-access-pattern.md), [service-data-backup-restore-pattern](../backup/service-data-backup-restore-pattern.md), [service-backup-receiver-pattern](../backup/service-backup-receiver-pattern.md), [wsl-monitoring-node-pattern](../monitor/wsl-monitoring-node-pattern.md)
**Issues behind this pattern:** [netstack#37](https://github.com/2cld/netstack/issues/37) (host path), [#38](https://github.com/2cld/netstack/issues/38) (service layout), [#28](https://github.com/2cld/netstack/issues/28) (site-config schema), [#32](https://github.com/2cld/netstack/issues/32) (BMR to restore to monitor loop), [#43](https://github.com/2cld/netstack/issues/43) and [#45](https://github.com/2cld/netstack/issues/45) (receiver and backup agreements)

> Netstack holds patterns only. Site names, IPs, serials and domains below are placeholders (`<site>`, `<domain>`). The site's own repo holds the values.

---

## 1. When this pattern applies

Proxmox is the default host path for netstack services ([netstack#37](https://github.com/2cld/netstack/issues/37)): services run as LXC or VM, can move to another host during maintenance, and are reached the same way at every site. Use this WSL pattern only when **all** of these hold:

| Test | Why |
|------|-----|
| The site has one physical machine, and it runs Windows | No spare box for Proxmox |
| A Windows-bound application must stay on that machine (for example Plex native or GPU transcode) | Moving it is not worth the cost |
| The Docker stack is small and stateless (see Section 2) | A single-disk failure then costs a rebuild, not data |

If the stack needs data that cannot be recreated from git or a dashboard, do not put it here. Move it to a host with a backup path, or give that service its own backup per [service-data-backup-restore-pattern](../backup/service-data-backup-restore-pattern.md).

**The trade-off, stated plainly.** WSL on a single Windows host shares a failure domain with the drive that holds the WSL disk image. A failed drive takes down the tunnel and the status endpoint together. This pattern limits the damage in three ways: the stack holds no data, it rebuilds from git in one pass, and monitoring reads a public status endpoint, so the coordinator notices from outside the box.

## 2. Design rules

1. **Stack from config, minimal by default.** The services are the ones the site's `site-config.yml` lists. The usual minimum: `cloudflared`, `traefik`, a status checker, and an nginx site container. Anything else (Gitea, Portainer, Home Assistant) is added only when a site needs it and has a backup for it.
2. **No data volumes.** Container state is the compose file, the `.env`, and the git repo. A tunnel token can be re-extracted from the Cloudflare dashboard. If a service gains state, this rule is broken and the service needs a backup entry.
3. **Layout inside WSL** follows [docker-service-subdomain-pattern](../../wan/cloudflare/docker-service-subdomain-pattern.md): `/opt/appdata/<name>/{compose.yml,.env,config/,data/}`. Compose files are versioned in the site repo under `ops/services/<name>/`. `.env` files are never committed.
4. **Pin images.** No `:latest`. A rebuild reproduces the working versions; updates are a deliberate act ([site-repo-flow-pattern](./site-repo-flow-pattern.md)).
5. **Docker Engine, not Docker Desktop.** Desktop needs a commercial licence, runs its own distro and GUI, and is too heavy for a small node.
6. **Put the WSL disk where you decide.** Import the distro onto a named drive (`wsl --import`), not wherever the default installer puts it. Record that drive and its serial in the site's storage map, so a drive failure maps to this pattern's rebuild path.
7. **Tunnel only.** The `cloudflared` container connects outbound. Do not use `netsh portproxy`: the WSL IP changes on every host reboot, which breaks the rules.

## 3. Naming and routing

Two tiers of public hostname, one domain per site (sites do not share a domain):

| Hostname | Serves | Source |
|----------|--------|--------|
| `<site>.<domain>` | The site's own pages: `/status.json`, `/health`, `/docs` | Built from the site repo; served by the nginx site container |
| `<service>.<domain>` | One Docker service each, routed by Traefik on `Host()` | That service's compose file |

Rules:

- Every public hostname is a proxied CNAME to the tunnel, with an ingress entry that targets Traefik by service name (never a host IP).
- **Origin scheme.** `https://traefik:443` with a wildcard certificate (ACME DNS challenge) is the cf default. When the site has no wildcard certificate and no DNS API token, use `http://traefik:80`: Cloudflare terminates TLS to the public, and the tunnel is the only path to Traefik. State the choice in the site's `site-config.yml`.
- **Access.** Default-deny on Cloudflare Access for the site's hostnames, with bypass only for `/status.json` and `/health`, following [cloudflare-federation-access-pattern](../security/cloudflare-federation-access-pattern.md).
- ZeroTier clients may need local name overrides, as described in the service-subdomain pattern. Test both the public and the ZeroTier path.

## 4. Setup procedure

Run on the Windows host unless marked WSL.

1. **Install WSL2 and a base image** (PowerShell, elevated): `wsl --install --no-distribution`, then obtain the Ubuntu root filesystem for the version you pin (24.04 or later).
2. **Import the distro onto the chosen drive:**
   ```powershell
   wsl --import <DistroName> <D:\wsl\path> <ubuntu-rootfs.tar.gz>
   ```
   Record `<DistroName>`, the install path and the drive serial in the site repo.
3. **Enable systemd** in the distro's `/etc/wsl.conf`, then `wsl --shutdown` and relaunch:
   ```ini
   [boot]
   systemd=true

   [user]
   default=<admin-user>
   ```
4. **Install Docker Engine and the compose plugin** inside WSL from Docker's apt repository (`docker-ce`, `docker-ce-cli`, `containerd.io`, `docker-buildx-plugin`, `docker-compose-plugin`). Add the admin user to the `docker` group.
5. **Create the `proxy` network and the appdata directory:** `docker network create proxy`, `mkdir -p /opt/appdata`.
6. **Deploy from the site repo.** Clone the repo, copy each `ops/services/<name>/` to `/opt/appdata/<name>/`, put the `.env` files in place from the secret store, and `docker compose up -d` per service.
7. **Start WSL and Docker at boot** with a Windows scheduled task that launches the distro. WSL distros are registered **per Windows user**. A task that runs as `SYSTEM` may not see a distro imported by another user. Run the task as the user that owns the distro, and **test it with a reboot and nobody logged in**. If the task runs only at logon, enable automatic sign-in or switch trigger options. Record which option survived the reboot test. *(Untested as of this revision; sl#15 is the first validation.)*
8. **Configure the tunnel and Access** per Section 3.

## 5. Rebuild path (BMR, WSL variant)

Maps to the four-script path in [bmr-pattern](./bmr-pattern.md):

| BMR step | WSL variant |
|----------|-------------|
| `bootstrap` | Windows prerequisites, WSL import, systemd, Docker Engine, boot task (Section 4, steps 1 to 5, 7). Several steps are PowerShell and manual until scripted |
| `deploy` | `docker compose up -d` for each `ops/services/<name>/`. Hand-written compose in the repo; **do not depend on generating compose from `site-config.yml`** until the generator reads the nested schema ([netstack#28](https://github.com/2cld/netstack/issues/28)) |
| `restore` | Nothing, for a no-data stack. A service that has data follows its own restore procedure |
| `verify` | The checks in Section 7 |

**Rebuild proof.** For a stack with no data, "restore works" means: from a clean WSL import and the repo, the stack comes up and the public status endpoint reports every expected container. Record rebuild time and every runbook gap in the site's rebuild issue. This is the loop in [netstack#32](https://github.com/2cld/netstack/issues/32): BMR, restore, then monitor, written as one testable path.

## 6. Failure modes

| Failure | Effect | Recovery |
|---------|--------|----------|
| Drive holding the WSL image fails | Tunnel and status endpoint down; Windows apps and backup reception keep running | Replace drive, then Section 4 from step 2 |
| OS drive fails | Whole node down | Reinstall Windows, then Section 4 from step 1 |
| Host reboot (power, Windows update) | WSL stops until the boot task starts it | Boot task (step 7); verify with the reboot test |
| WSL IP changes | Breaks any `portproxy` rule | Tunnel-only design avoids it |
| Windows update changes WSL behaviour | Possible start-up change | Re-run the reboot test after major updates |

## 7. Verification checklist

- [ ] Reboot the host with nobody logged in: WSL and all containers start without intervention
- [ ] `docker ps` shows exactly the containers the site config lists, with pinned tags
- [ ] The tunnel has at least one connection
- [ ] `https://<site>.<domain>/status.json` and `/health` answer without login; `/` and `/docs` require Cloudflare Access
- [ ] The status checker's expected container count matches the site config
- [ ] Rebuild time and runbook gaps recorded on the rebuild issue

## 8. Monitoring

The coordinator reads the site's **public** `/status.json` ([public-status-endpoint-pattern](../monitor/public-status-endpoint-pattern.md)). Do not make SSH into WSL a requirement: it adds Windows OpenSSH key and port issues to every check. If the site also keeps a WSL SSH door for administration, treat it as a convenience path, not the monitor. To administer WSL from the coordinator, go through Windows SSH with `wsl -d <distro> -- ...`; see [Managing a Windows node over SSH](../backup/windows-openssh-setup.md#managing-a-windows-node-over-ssh-copy-a-ps1-file-and-run-it).

## 9. Backup reception on the same host

If the Windows host also receives federation backups (a Windows `sshd` writing to a data drive), that receiver is **not** part of the WSL stack and does not depend on it. Follow [service-backup-receiver-pattern](../backup/service-backup-receiver-pattern.md). Two cautions from [netstack#43](https://github.com/2cld/netstack/issues/43) and [#45](https://github.com/2cld/netstack/issues/45):

- A freshness marker written by the sender is sender-written evidence. It shows the sender thinks it finished, not that the receiver holds the bytes.
- Terms, reservations and permission to run operations are separate from a successful transfer. This pattern does not authorize any of them.

## 10. Host paths compared

| Aspect | Proxmox LXC or VM (default) | Hyper-V Ubuntu VM | WSL on Windows (this pattern) |
|--------|----------------------------|-------------------|-------------------------------|
| Fit | Sites with spare hardware | A Windows host with RAM to spare | One Windows box, limited RAM |
| Can move to another host | Yes | With effort | No |
| Start at boot | Proxmox | Hyper-V auto-start | Scheduled task (Section 4, step 7) |
| IP stability | Reserved | Reserved | Changes on every reboot |
| Failure domain | Per host, movable | The host | The drive holding the WSL image, plus the host OS |
| Overhead | Low | A few GB of RAM | About 300 MB |

## 11. Open items

- Validate the boot task user and trigger on a real reboot (sl#15).
- Decide how bootstrap becomes a script for a Windows host. Until then, the PowerShell steps stay manual.
- Reconcile with [netstack#28](https://github.com/2cld/netstack/issues/28) when the schema rewrite lands, so `deploy` can read the config.
