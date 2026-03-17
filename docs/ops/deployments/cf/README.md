[edit](https://github.com/2cld/netstack/edit/master/docs/ops/deployments/cf/README.md) or [../deployments](../) or [../../ops](../../)
# cf - Cedar Falls (Fletch)

| | |
|-|-|
| site docs | [cf.2cld.net/docs](https://cf.2cld.net/docs) |
| repo | [github.com/2cld/cf](https://github.com/2cld/cf) |
| subnet | 192.168.6.0/24 |
| gateway | 192.168.6.1 (cfu 854G-1) |
| PIP | 192.111.21.62 |

## Key Resources

| role | IP | what |
|------|----|------|
| ng | 192.168.6.1 | cfu pop router |
| sg | 192.168.6.2 | TrueNAS i3 (apps: homer, gitea, jellyfin) |
| cg | 192.168.6.3 | cfPlex win11 i7 (Hyper-V: pfSense, win11vm, ubuntu) |
| sg2 | 192.168.6.67 | Synology DS411 (cfDVR: gitea, metube, plex) |
| Cybertruck | 192.168.6.30 | win10 i7 GPU (plex, ollama, portainer, open-webui, HAOS) |
| cfbu | 192.168.6.51 | Synology backup NAS |

## Cloudflare Tunnels

| hostname | service |
|----------|---------|
| chat.bradnordyke.com | Open WebUI on Cybertruck |
| ssh.bradnordyke.com | SSH to cfDVR |
| gitea.klopfenstein.org | Gitea on cfDVR |
| metube.klopfenstein.org | MeTube on cfDVR |
| sg.klopfenstein.org | cfDVR portal |
| *.cat9.me | traefik via Hyper-V |

Full device inventory, services, storage mappings, and port forwards: [cf.2cld.net/docs](https://cf.2cld.net/docs)
