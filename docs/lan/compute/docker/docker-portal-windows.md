# docker portal windows
- Jim's Garage [yt](https://youtu.be/jOzk8QyAXwc)
  - Jim's [yaml github docker windows](https://github.com/JamesTurland/JimsGarage/blob/main/MacWindows/Windows/docker-compose.yaml)
  - yaml review [yt](https://youtu.be/jOzk8QyAXwc?t=345)
  - install [yt](https://youtu.be/jOzk8QyAXwc?t=575)
  - sudo docker compose up -d   [yt](https://youtu.be/jOzk8QyAXwc?t=5790
  - portainer - windows dockurr/windows running -> click on logs
  - should see it requesting windows 11 -> [yt](https://youtu.be/jOzk8QyAXwc?t=591)
  - go to the term portal and should see the windows install automatically running -> [yt](https://youtu.be/jOzk8QyAXwc?t=670)
  - Test by directly rpd into unit - [yt](https://youtu.be/jOzk8QyAXwc?t=789)
- Dockur [github repo Dockur](https://github.com/dockur)
  - Dockur [windows](https://github.com/dockur/windows)
  - Dockur [mac](https://github.com/dockur/macos)

## netstack nsadmin deployment
- repo [https://gitea.cat9.me/nsadmin/docker-compose](https://gitea.cat9.me/nsadmin/docker-compose)

## netstack nsadmin windows create docker-compose.md
- repo [https://gitea.cat9.me/nsadmin/docker-compose](https://gitea.cat9.me/nsadmin/docker-compose)
- rd/rdp/ssh - 10.147.17.176 - nsdockerhv-hv-ct-10.147.17.219
- repo /home/nsadmin/code/docker-compose
- mkdir catwin && cd catwin
- cp ../JimsGarage/MacWindows/Windows/docker-compose.yaml .
- vi docker-compose.yaml
- git commit
- catwin at [repo catwin](https://gitea.cat9.me/nsadmin/docker-compose/src/branch/master/catwin/docker-compose.yaml)
- sudo docker compose up -d
- portainer [docker containers](https://portainer.cat9.me/#!/3/docker/containers)
