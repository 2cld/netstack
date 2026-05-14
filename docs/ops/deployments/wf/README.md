[edit](https://github.com/2cld/netstack/edit/master/docs/ops/deployments/wf/README.md) or [../deployments](../) or [../../ops](../../)
# wf - Winfield

| | |
|-|-|
| site docs | [wf.2cld.net](https://wf.2cld.net) |
| repo | [github.com/2cld/wf](https://github.com/2cld/wf) |
| subnet | 192.168.9.0/24 |
| gateway | 192.168.9.1 (Mikrotik) |
| ISP | Starlink (via 192.168.4.1) |
| PIP | 98.97.4.249 |

## Key Resources

| role | IP | ZeroTier | what |
|------|----|----------|------|
| ng | 192.168.9.1 | — | Mikrotik router |
| sg (Synology) | 192.168.9.2 | 10.147.17.209 | NAS, Docker, CF tunnel endpoint |
| cg (Proxmox) | 192.168.9.3 | — | ASUS i5 hypervisor |
| 100-docker-vm | 192.168.9.11 | — | Proxmox VM (Gitea, Portainer, Cockpit) |
| cfbu (Synology) | 192.168.9.181 | — | Backup NAS |
| devwin10 | 192.168.9.195 | 10.147.17.165 | Workstation |

## Cloudflare Tunnels

| hostname | service |
|----------|---------|
| sg.klopfenstein.org | Synology admin portal |
| gitea.klopfenstein.org | Gitea on Synology |
| metube.klopfenstein.org | MeTube on Synology |
| jp.klopfenstein.org | WebDAV |

## Remote Access

- ZeroTier network: d5e5fb65371eb4a4
- SSH to sg: `ssh -p 2020 buadmin@10.147.17.209`
- SSH to cg: `wf.christrees.com:2020`
- WireGuard: 69.40.112.118:51821

Full device inventory, services, and network topology: [wf.2cld.net](https://wf.2cld.net)
