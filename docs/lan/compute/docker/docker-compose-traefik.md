[edit]()

# traefik
- reference [Jim's Garage](https://github.com/JamesTurland/JimsGarage)
- documents [gitea.2cld.com/nsops/docker-compose](https://gitea.2cld.com/nsops/docker-compose)

The --force-recreate flag ensures that containers are recreated even if their configuration and image haven't changed, guaranteeing that the newly built images are used. If you want to run in detached mode, add the -d flag:

```bash
sudo docker compose up --force-recreate -d
```
