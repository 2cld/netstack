[edit]()

# Docker portal service workflow
Setting up a portal service in a docker container

- Identify new docker service
- Goto nsadmin@nsdockerhv [https://10.147.17.176:9090/system/terminal](https://10.147.17.176:9090/system/terminal)
  - ssh
  ```
  nsadmin@nsdockerhv:~/code/docker-compose$ pwd
  /home/nsadmin/code/docker-compose
  ```
- git commit docker-compose to repo [https://gitea.cat9.me/nsadmin/docker-compose](https://gitea.cat9.me/nsadmin/docker-compose)
- Add service to quicklinks [https://2cld.net/docs/quick](https://2cld.net/docs/quick)

## Example from [https://2cld.net/docs/quick](https://2cld.net/docs/quick)
| [cf-cat9me ct](https://one.dash.cloudflare.com/830c41d5976453f0c03f34d4f765b229/networks/tunnels) cf hv url | service [zt gh](https://my.zerotier.com/network/d5e5fb65371eb4a4) |
|---|---|
| [https://traefik.cat9.me](https://traefik.cat9.me) | [_traefik_](https://netstack.org/docs/lan/compute/docker/docker-portal-cloudflare-traefik-install) portal [cflare](https://dash.cloudflare.com/)->[ct-hv](10.147.17.219)->[cp.nsdockerhv](https://10.147.17.176:9090/)->[traefik](172.18.0.2) |
| [https://portainer.cat9.me](https://portainer.cat9.me) | portainer [cflare](https://dash.cloudflare.com/)->[ct-hv](10.147.17.219)->[cp.nsdockerhv](https://10.147.17.176:9090/)->[portainer](172.18.0.7) |
| [https://gitea.cat9.me](https://gitea.cat9.me) | gitea [cflare](https://dash.cloudflare.com/)->[ct-hv](10.147.17.219)->[cp.nsdockerhv](https://10.147.17.176:9090/)->[gitea](172.18.0.6) |
| [https://nginx.cat9.me](https://nginx.cat9.me) | nginx [cflare](https://dash.cloudflare.com/)->[ct-hv](10.147.17.219)->[cp.nsdockerhv](https://10.147.17.176:9090/)->[nginx](172.18.0.4) |
| newservice [https://newservice.cat9.me](https://newservice.cat9.me) | newservice [cflare](https://dash.cloudflare.com/)->[ct-hv](10.147.17.219)->[cp.nsdockerhv](https://10.147.17.176:9090/)->[newservice](172.18.0.x) |
