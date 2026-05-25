[edit](https://github.com/2cld/netstack/edit/master/docs/ops/deployments/cf/README.md) or [../deployments](../) or [../../ops](../../)
# cf - Cedar Falls

| | |
|-|-|
| site docs | [cf.2cld.net](https://cf.2cld.net) |
| repo | [github.com/2cld/cf](https://github.com/2cld/cf) (private) |

## Overview

Media and compute site. Runs CyberTruck workstation (Win10 i7 GPU) with Hyper-V, WSL2 Docker, and isolated NAS storage. Connected to federation via ZeroTier overlay VPN.

## Services (via Cloudflare Tunnel)

- *.cat9.me (traefik, portainer, gitea, nginx, netbox)
- chat.bradnordyke.com (Open WebUI)

## Details

Full device inventory, network topology, storage mapping, and service configuration in the private cf repo.
See [cf.2cld.net](https://cf.2cld.net) for site documentation.

## Patterns (from netstack)

- [Pattern Workflow](../../pattern-workflow.md) — how netstack drives ops
- [Ops Node Setup](../../users/ops-node-setup.md) — nsadmin environment (nsdockerhv is the reference implementation)
- [CLI Helper Pattern](../../tools/cli-helper-pattern.md) — `wip` command and dispatcher scripts
- [Federation Setup Guide](../federation-setup-guide.md) — full node standup procedure
- [Backup Cron Pattern](../../backup/backup-cron-pattern.md) — daily backup automation
