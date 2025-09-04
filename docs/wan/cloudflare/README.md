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

| cftunnel | connector-id | network-id | origin ip | private ip | zt ip | hostname |
| -------- | ------------ | ---------- | --------- | ---------- | ----- | -------- |
| cf-2cld | [ab1a4538-3f8f-44e7-9b04-d9dff5fdd41c](https://one.dash.cloudflare.com/830c41d5976453f0c03f34d4f765b229/networks/tunnels/7145c9f1-c0a3-45e3-86f6-162eaf87ca42/connectors/ab1a4538-3f8f-44e7-9b04-d9dff5fdd41c?backTo=eyJ0ZXh0IjoiQmFjayB0byB0dW5uZWxzIiwidXJsIjoiLzgzMGM0MWQ1OTc2NDUzZjBjMDNmMzRkNGY3NjViMjI5L25ldHdvcmtzL3R1bm5lbHMifQ%3D%3D) | 7145c9f1-c0a3-45e3-86f6-162eaf87ca42 | 98.97.8.192 | 192.168.9.2 | 10.147.17.x | cf-cloudflared |
| cf-cat9me | [7fcb521a-3bbd-4c78-bc11-0e2d4acf4b5f](https://one.dash.cloudflare.com/830c41d5976453f0c03f34d4f765b229/networks/tunnels/9d5faaac-72b0-4bd1-be9b-238dca2db12e/connectors/7fcb521a-3bbd-4c78-bc11-0e2d4acf4b5f?backTo=eyJ0ZXh0IjoiQmFjayB0byB0dW5uZWxzIiwidXJsIjoiLzgzMGM0MWQ1OTc2NDUzZjBjMDNmMzRkNGY3NjViMjI5L25ldHdvcmtzL3R1bm5lbHMifQ%3D%3D) | 9d5faaac-72b0-4bd1-be9b-238dca2db12e | 192.111.21.62 | 172.18.0.3 | 10.147.17.176 | e6f22b61a96c |
| sl-2cld | [08386553-1fe5-45ae-87c8-400d8c7ae86d](https://one.dash.cloudflare.com/830c41d5976453f0c03f34d4f765b229/networks/tunnels/a19311a9-49a4-473d-a3fa-ea1cafc45331/connectors/08386553-1fe5-45ae-87c8-400d8c7ae86d?backTo=eyJ0ZXh0IjoiQmFjayB0byB0dW5uZWxzIiwidXJsIjoiLzgzMGM0MWQ1OTc2NDUzZjBjMDNmMzRkNGY3NjViMjI5L25ldHdvcmtzL3R1bm5lbHMifQ%3D%3D) | a19311a9-49a4-473d-a3fa-ea1cafc45331 | 174.86.8.20 | 192.168.0.143 | 10.147.17.94  | slwin11ops |

## cf-2cld

| n | dns url                 | x | service                  | x |
| - | ----------------------- | - | ------------------------ | - |
| 1 | gitea.klopfenstein.org  | * | http://192.168.9.2:3000  | 0 |
| 2 | metube.klopfenstein.org | * | http://192.168.9.2:8081  | 0 |
| 3 | sg.klopfenstein.org     | * | http://192.168.9.2:5000  | 0 |
| 4 | jp.klopfenstein.org     | * | http://192.168.9.2:5005  | 0 |
| 5 | chat.bradnordyke.com    | * | http://192.168.6.30:8080 | 0 |
| 6 | ssh.bradnordyke.com     | * | ssh://192.168.6.67:2020  | 0 |
| 7 | rt.bradnordyke.com      | * | http://192.168.6.30:3333 | 0 |

## cf-cat9me

| n | dns url                 | x | service                  | x |
| - | ----------------------- | - | ------------------------ | - |
| 1 | *.cat9.me               | * | https://192.168.6.106    | 1 originServerName |
| 2 | test.cat9.me            | * | https://192.168.6.106:88 | 0 |

## sl-2cld

| n | dns url                 | x | service                  | x |
| - | ----------------------- | - | ------------------------ | - |
| 1 | gitea.klopfenstein.org  | * | http://192.168.9.2:3000  | 0 |
| 2 | metube.klopfenstein.org | * | http://192.168.9.2:8081  | 0 |
| 3 | sg.klopfenstein.org     | * | http://192.168.9.2:5000  | 0 |
| 4 | jp.klopfenstein.org     | * | http://192.168.9.2:5005  | 0 |

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
