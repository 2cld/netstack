[edit](https://github.com/2cld/netstack/edit/master/docs/lan/compute/docker/docker-compose-traefik.md) - [../docker](../) - [../../compute](../../)

# traefik
- reference [Jim's Garage](https://github.com/JamesTurland/JimsGarage)
- video [Traefik v3.3 - Secure Everything! Complete Tutorial](https://www.youtube.com/watch?v=CmUzMi5QLzI) also on [sg.klopfenstein.org](https://sg.klopfenstein.org/?launchApp=SYNO.SDS.VideoPlayer2.Application&SynoToken=aMXeceUJcyWJU&launchParam=ieMode%3D9%26is_drive%3Dfalse%26path%3D%252Fdocker%252FcatMetube%252FHomeLab%252FJimsGarage%252FTraefik%2520v3.3%2520-%2520Secure%2520Everything!%2520Complete%2520Tutorial.webm%26file_id%3D%252Fdocker%252FcatMetube%252FHomeLab%252FJimsGarage%252FTraefik%2520v3.3%2520-%2520Secure%2520Everything!%2520Complete%2520Tutorial.webm&ieMode=9)
- documents need to setup and commit to -> [gitea.2cld.com/nsops/docker-compose](https://gitea.2cld.com/nsops/docker-compose)

# Docker Comopose Folder Structure
- docker (changes here require docker restart)
  - traefik
    - config.yaml (copy from below then update used to tweak to get good rating)
    - traefik.yaml (copy from below then update)
- docker-compose (changes here traefik will pickup)
  - traefik
    - config
      - [acme.json](https://github.com/JamesTurland/JimsGarage/blob/main/Traefikv3/config/acme.json)
      - [config.yaml](https://github.com/JamesTurland/JimsGarage/blob/main/Traefikv3/config/config.yaml) (arch of docker/traefik/traefik.yaml)
      - [traefik.yaml](https://github.com/JamesTurland/JimsGarage/blob/main/Traefikv3/config/traefik.yaml) (arch of docker/traefik/traefik.yaml)
    - [docker-compose.yaml](https://github.com/JamesTurland/JimsGarage/blob/main/Traefikv3/docker-compose.yaml)
    - [.env](https://github.com/JamesTurland/JimsGarage/blob/main/Traefikv3/.env)
    - [cf-token](https://github.com/JamesTurland/JimsGarage/blob/main/Traefikv3/cf-token) (from cloudflare config)


The --force-recreate flag ensures that containers are recreated even if their configuration and image haven't changed, guaranteeing that the newly built images are used. If you want to run in detached mode, add the -d flag:

```bash
sudo docker compose up --force-recreate -d
```
