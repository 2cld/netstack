[edit](https://github.com/2cld/netstack/edit/master/docs/ops/deployments/sl/README.md) or [../deployments](../) or [../../ops](../../)
# sl - St. Louis

| | |
|-|-|
| site docs | [sl.2cld.net](https://sl.2cld.net) |
| repo | [github.com/2cld/sl](https://github.com/2cld/sl) |
| subnet | 192.168.0.0/24 |
| gateway | 192.168.0.1 (TP-Link AC1750 Archer C7) |
| PIP | 24.216.208.251 |

## Key Resources

| role | IP | ZeroTier | what |
|------|----|----------|------|
| ng | 192.168.0.1 | — | TP-Link Archer C7 router |
| slwin11ops | 192.168.0.143 | 10.147.17.94 | Dell i5 Win11 - primary ops |
| mg2 (Hyper-V) | 192.168.0.140 | 10.147.17.135 | Ubuntu 24.04 VM - Docker host |
| gusGram | 192.168.0.28 | 10.147.17.190 | User laptop |

## Cloudflare Tunnels

| hostname | service |
|----------|---------|
| traefik.2cld.com | traefik via mg2 |
| portainer.2cld.com | portainer via mg2 |
| gitea.2cld.com | gitea via mg2 |

## Remote Access

- ZeroTier network: d5e5fb65371eb4a4
- SSH to mg2: `ssh ghadmin@10.147.17.135`
- SSH to WSL: `ssh -p 2222 ghadmin@10.147.17.94`

Full device inventory, services, and storage: [sl.2cld.net](https://sl.2cld.net)
