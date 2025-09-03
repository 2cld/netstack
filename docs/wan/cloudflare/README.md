[edit](https://github.com/2cld/netstack/edit/master/docs/wan/cloudflare/README.md)

# cloudflare
- dashboard https://dash.cloudflare.com/
  - Add domain in website
  - tbd
- dashboard zero-trust https://one.dash.cloudflare.com/
  - Network -> Tunnels (create site tunnel)
  - Access -> Applications (tunnel lockdowns)
- Crosstalk setup
  - https://www.crosstalksolutions.com/cloudflare-tunnel-easy-setup/ [youtube](https://www.youtube.com/watch?v=ZvIdFs3M5ic)
- Jim's Garage setup
  - https://github.com/JamesTurland/JimsGarage/tree/main/Cloudflare-HTTPS [youtube](https://www.youtube.com/watch?v=U8hUNw2E1ZM)
- tbd

## Linux install
- [Cloudflare Package Repo](https://pkg.cloudflare.com/)

## macOS
- [cloudflared install](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/downloads/)
```
brew install cloudflared
```

## windows install
- [cloudflared install](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/downloads/)
```
winget install --id Cloudflare.cloudflared
```

## wsl on windows install
- go to https://one.dash.cloudflare.com/
- search for tunnel and create new tunnel
- tbd
### connect as use
- edit ~/.ssh/config
- windows
```cmd
Host ssh.bradnordyke.com
ProxyCommand cloudflared access ssh --hostname %h
```
- linux
```bash
Host ssh.bradnordyke.com
ProxyCommand /usr/local/bin/cloudflared access ssh --hostname %h
```

# cf.2cld

| N | domain | cfip | description |
| - | ------ | ---- | ----------- |
| 1 | test.bradnordyke.com | http://192.168.6.2:30092 | homer running as truenas app see [tbd]() |
| 2 | chat.bradnordyke.com | http://192.168.6.30:8080 | open-webui running under wsl on cybertruck see [https://ai.2cld.net/docs/](https://ai.2cld.net/docs/) |
| 3 | casa.bradnordyke.com | http://192.168.6.30:20200 | casaos running under wsl on cybertruck see [tbd]() |

# docker install
- Jims Garage [Cloudflare Tunnels - Improving Security & Convenience](https://www.youtube.com/watch?v=U8hUNw2E1ZM)
- Jims Garage [cloudflare repo](https://github.com/JamesTurland/JimsGarage/blob/main/Cloudflare-HTTPS/cloudflared/docker-compose.yaml)
- Configure cloudflare tunnel
  - Networks -> Tunnels -> cloudflared
  - New tunnel (and name)
  - Get tunnel id and put into docker-compose
- Start tunnel
  - sudo docker compose up -d
  - should see tunnel in new tunnel config if
- configure traefik-demo dashboard [yt-tc05:46](https://youtu.be/U8hUNw2E1ZM?t=346)
  - public hosts *.domainurl -> https -> traefik-demo
  - Advanced -> TLS -> Origin Server Name -> *.domainurl
- DNS tunnel ID
  - copy tunnel ID
  - Add CNAME to DNS that points to tunnel ID
