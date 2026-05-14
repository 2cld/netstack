[edit](https://github.com/2cld/netstack/edit/master/docs/ops/deployments/cf/README.md) or [../deployments](../) or [../../ops](../../)
# cf - Cedar Falls

| | |
|-|-|
| site docs | [cf.2cld.net](https://cf.2cld.net) |
| repo | [github.com/2cld/cf](https://github.com/2cld/cf) |
| subnet | 192.168.6.0/24 |
| gateway | 192.168.6.1 (CFU 854G-1) |
| PIP | 192.111.21.62 |

## Key Resources

| role | IP | ZeroTier | what |
|------|----|----------|------|
| ng | 192.168.6.1 | — | CFU router |
| CyberTruck | 192.168.6.30 | 10.147.17.219 | Win10 i7 128G GPU (Plex, Docker/WSL, Hyper-V) |
| nsdockerhb | — | 10.147.17.176 | Docker host (Traefik, Portainer, Gitea, Nginx, Netbox) |
| cats-mac-mini | — | 10.147.17.59 | Mac Mini |
| HDHR-1080AD03 | 192.168.6.48 | — | SiliconDust TV tuner |
| cfbu (Synology) | 192.168.6.10 | — | Backup NAS (plexnsds) |

## Cloudflare Tunnels

| hostname | service |
|----------|---------|
| traefik.cat9.me | Traefik reverse proxy |
| portainer.cat9.me | Portainer |
| gitea.cat9.me | Gitea |
| nginx.cat9.me | Nginx |
| netbox.cat9.me | Netbox |
| chat.bradnordyke.com | Open WebUI (Ollama) |
| rt.bradnordyke.com | Rust test |
| ssh.bradnordyke.com | SSH |

## Remote Access

- ZeroTier network: d5e5fb65371eb4a4
- SSH to WSL: `ssh -p 2020 ghadmin@10.147.17.219`
- SSH to Mac Mini: `ssh trink@10.147.17.59`

Full device inventory, services, storage mappings: [cf.2cld.net](https://cf.2cld.net)
