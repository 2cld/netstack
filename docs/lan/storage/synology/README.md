[edit]()

# DS411+II
- User interface on port 5000 [http://192.168.6.6:5000](http://192.168.6.6:5000)
- Control Panel -> Storage for Drive status

## Zerotier on DS411+II from [wan/zerotier](../../../wan/zerotier)
- Instructions [https://docs.zerotier.com/synology/](https://docs.zerotier.com/synology/)
  - [http://www.homeops.tech/2020/07/15/Zero-Tier-On-Synology/](http://www.homeops.tech/2020/07/15/Zero-Tier-On-Synology/)
  - [https://www.reddit.com/r/cordcutters/comments/5877jo/hdhomerun_connect_static_ip/?rdt=36595](https://www.reddit.com/r/cordcutters/comments/5877jo/hdhomerun_connect_static_ip/?rdt=36595)
  - [https://docs.zerotier.com/start/](https://docs.zerotier.com/start/)
  - [https://zerotier.atlassian.net/wiki/spaces/SD/pages/29065282/Command+Line+Interface+zerotier-cli](https://zerotier.atlassian.net/wiki/spaces/SD/pages/29065282/Command+Line+Interface+zerotier-cli)
  - [https://zerotier.atlassian.net/wiki/spaces/SD/pages/193134593/Bridge+your+ZeroTier+and+local+network+with+a+RaspberryPi](https://zerotier.atlassian.net/wiki/spaces/SD/pages/193134593/Bridge+your+ZeroTier+and+local+network+with+a+RaspberryPi)
  - [https://zerotier.atlassian.net/wiki/spaces/SD/pages/224395274/Route+between+ZeroTier+and+Physical+Networks](https://zerotier.atlassian.net/wiki/spaces/SD/pages/224395274/Route+between+ZeroTier+and+Physical+Networks)

- For DSM v 6.2 [zerotier package download](https://download.zerotier.com/dist/synology/)
- What package [https://kb.synology.com/en-nz/DSM/tutorial/What_kind_of_CPU_does_my_NAS_have](https://kb.synology.com/en-nz/DSM/tutorial/What_kind_of_CPU_does_my_NAS_have)
- DS411+II	Intel Atom D525	2	4	✓	X86	DDR2 1GB so [https://download.zerotier.com/dist/synology/zerotier_x86-6.2.4_1.8.7-1.spk](https://download.zerotier.com/dist/synology/zerotier_x86-6.2.4_1.8.7-1.spk)
- no GUI so ssh using buadmin
  ```
  ssh -p 2020 buadmin@192.168.6.6
  ```
- Zerotier cli [zerotier-cli docs](https://zerotier.atlassian.net/wiki/spaces/SD/pages/29065282/Command+Line+Interface+zerotier-cli)
- zerotier status
  ```
  sudo zerotier-cli status
  ```
- zerotier join
  ```
  sudo zerotier-cli join
  ```
- zerotier status
  ```
  sudo zerotier-cli status
  ```

# Docker Compose on Synology
- Reference [doc-synology-nas-docker-media-server-2022](https://www.simplehomelab.com/synology-nas-docker-media-server-2022/) of [https://www.simplehomelab.com/](https://www.simplehomelab.com/)
- Docker Compose [github repo](https://github.com/SimpleHomelab/Docker-Traefik) of [https://github.com/SimpleHomelab](https://github.com/SimpleHomelab)
- [ns DockerCompose Traefic](../../compute/docker/docker-compose-traefik.md) based on Jims Garage [github repo](https://github.com/JamesTurland/JimsGarage)
- ssh -p 2020 buadmin@192.168.9.2
- su
```bash
buadmin@sg:~$ sudo su
ash-4.3# cd /var/packages/Docker/target/usr/bin/
```
- move old to bak
```bash
ash-4.3# mv docker-compose docker-compose_bak
```
- pull down new
```bash
ash-4.3# curl -L https://github.com/docker/compose/releases/download/v2.39.2/docker-compose-`uname -s`-`uname -m` -o docker-compose
```
- check version
```bash
ash-4.3# docker-compose -v
Docker Compose version v2.39.2
```
