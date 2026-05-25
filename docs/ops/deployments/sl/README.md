[edit](https://github.com/2cld/netstack/edit/master/docs/ops/deployments/sl/README.md) or [../deployments](../) or [../../ops](../../)
# sl - St. Louis

| | |
|-|-|
| site docs | [sl.2cld.net](https://sl.2cld.net) |
| repo | [github.com/2cld/sl](https://github.com/2cld/sl) (private) |

## Overview

Primary ops site. Runs Windows 11 workstation with Hyper-V VM hosting Docker services (Traefik, Portainer, Gitea). Connected to federation via ZeroTier overlay VPN.

## Services (via Cloudflare Tunnel)

- traefik.2cld.com
- portainer.2cld.com
- gitea.2cld.com

## Details

Full device inventory, network topology, and service configuration in the private sl repo.
See [sl.2cld.net](https://sl.2cld.net) for site documentation.

## Patterns (from netstack)

- [Pattern Workflow](../../pattern-workflow.md) — how netstack drives ops
- [Ops Node Setup](../../users/ops-node-setup.md) — nsadmin environment setup
- [Federation Setup Guide](../federation-setup-guide.md) — full node standup procedure
- [Backup Cron Pattern](../../backup/backup-cron-pattern.md) — backup target configuration
