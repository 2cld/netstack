[edit](https://github.com/2cld/netstack/edit/master/docs/ops/deployments/sl/README.md) or [../deployments](../) or [../../ops](../../)
# sl - Silver Lake

| | |
|-|-|
| site docs | [sl.2cld.net/docs](https://sl.2cld.net/docs) |
| repo | [github.com/2cld/sl](https://github.com/2cld/sl) |
| ISP subnet | 192.168.0.0/24 |
| netstack subnet | 192.168.9.0/24 |
| PIP | 24.216.208.251 |

## Key Resources

| role | IP | what |
|------|----|------|
| ng | 192.168.9.1 | mikrotik |
| cg | 192.168.9.2 | proxmox |
| sg2 (QNAP) | 192.168.0.6 | QNAP TS-431 |
| slwin11 | 192.168.0.9 | ops workstation |
| dg | 192.168.9.9 | proxmox (documents) |
| gusGram | 192.168.0.28 | user workstation |

## Cloudflare Tunnels

| hostname | service |
|----------|---------|
| traefik.2cld.com | traefik via slwin11 Hyper-V |
| portainer.2cld.com | portainer via slwin11 Hyper-V |
| gitea.2cld.com | gitea via slwin11 Hyper-V |

## Remote Access
- zerotier: cat-ghadmin-grid (slwin11ops, slwin11)
- google remote desktop: gusGram, gusHPLaptop

Full device inventory, DHCP tables, and services: [sl.2cld.net/docs](https://sl.2cld.net/docs)
