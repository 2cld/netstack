# Plex
[edit this](https://github.com/2cld/netstack/edit/master/docs/portals/plex/README.md)

### quick
---
- [cattvwin10 http://test.christrees.com:32400/](http://test.christrees.com:32400/)
- [dockerplex http://test.christrees.com:32500/](http://test.christrees.com:32500/)
- [tnasplex   http://test.christrees.com:32600/](http://test.christrees.com:32600/)

### WIP Portals
- [https://cf.christrees.com/](https://cf.christrees.com/)
- [https://cf.christrees.com/ns/](https://cf.christrees.com/ns)
- [http://test.christrees.com/](http://test.christrees.com/) 
- [https://whatismyipaddress.com/ip/24.149.22.11](https://whatismyipaddress.com/ip/24.149.22.11) - 24.149.22.11
- [https://whatismyipaddress.com/](https://whatismyipaddress.com/)
- [https://www.plex.tv/](https://www.plex.tv/)
- [https://www.plex.tv/claim/](https://www.plex.tv/claim/)
- [https://www.cfu.net/tv-internet/tv-service-info/channel-guide](https://www.cfu.net/tv-internet/tv-service-info/channel-guide)
- [cattvwin10 channel map](https://docs.google.com/spreadsheets/d/1wjN1_N5Vjji6NQgE3DXi4D-S76sAHppQrdXsqh5qX2E/edit#gid=0) 
- [tbd]()


---
---
### Reference
- [Plex downloads](https://www.plex.tv/media-server-downloads/)
  - Plex 1.28.2 for OSX 10.9
  - [Plex remote client network issue](https://www.devwithimagination.com/2019/08/21/plex-docker-and-the-problem-of-always-appearing-as-remote/)
  - [Plex remote access pfsense configs](https://www.thesmarthomebook.com/2020/04/16/fixing-remote-access-for-plex-in-pfsense/)
  - [Plex-Reverse-Proxy-for-Docker](https://github.com/fmillion/docs/blob/master/Plex-Reverse-Proxy-for-Docker.md)
  - [firetv recast file transfer](https://www.aftvnews.com/how-and-why-to-pull-video-recording-files-off-of-the-amazon-fire-tv-recast-dvr/)
  - [plex on synology and docker compose](https://www.wundertech.net/how-to-install-plex-on-a-synology-nas/)
  - [comskip github https://github.com/erikkaashoek/Comskip](https://github.com/erikkaashoek/Comskip)
  - [http://unixetc.co.uk/2020/03/16/how-to-install-comskip-on-a-raspberry-pi/](http://unixetc.co.uk/2020/03/16/how-to-install-comskip-on-a-raspberry-pi/)

- cat: verify trinkdvr and trinktnas
  - CattvWin10:trinktnas plexlib on CattvWin10 N: SMB mount \\192.168.2.2\plexmedia which is \mnt\zpool-01\plexmedia\plexdvr\trinkdvr
  - CattvWin10:trinktvDVR  plexlib on CattvWin10 D:\trinktvDVR  - physical harddrive
  - CattvWin10:trinktvDVR recordings and future recordings are now on CattvWin10:trinknas
  - I don't see libs on Tri484 plex server
  - moved "Ghosts" and "So Help Me Todd" shows to Tnasplex:catdvr
  - Added both shows to Tnasplex ran into issue
  - When I added Ghost, I did one eps, went back to change it to all and it would not let me, deleted and attempted to re-add and it gave me an error
  - basically after I deleted it was still showing up in LiveTV guide when I attempted to add... probably cache issue ?
  - log out and back in on plex server... and I was able to re-add
  - had issue with tnasplex plex.tv connection can get to it fine on local subnet
  - firewall issues with plex in .2 subnet probably plex working on other ports on a session being blocked
  - not going to mess with much more figure the only issue would be remote view of tuner... use cattvwin10 for that for now
  - tbd

---
New stuff
- [SatIP Protocal](https://www.satip.info/sites/satip/files/resource/satip_specification_version_1_2_2.pdf)
- [plex iptv](https://www.videoconverterfactory.com/tips/plex-iptv.html)
- [iptv sw tuner for plex - github xteve-project](https://github.com/xteve-project/xTeVe)
- [xteve install documentation](https://github.com/xteve-project/xTeVe-Documentation/blob/master/en/configuration.md)
- [plex hdhomerun-api-use-udp-for-saving-streams](https://forums.plex.tv/t/hdhomerun-api-use-udp-for-saving-streams/162703)
- [Plex HDHomeRun Tuner API](https://forums.plex.tv/t/wrapping-other-video-cards-with-hdhomerun-apis/157792/6) helped me sort out how channel streams are managed
- [truenas cannot deploy plex](https://www.truenas.com/community/threads/truenas-scale-cannot-deploy-plex.100397/)
- half the time I cant get channel matching ui to save
- It's like certian channels will not save 074.10 075.1
- [plex docker on synology - good dockercompose file](https://www.wundertech.net/how-to-install-plex-on-a-synology-nas/)
- tbd

### 2023.02.02 3pm PST 5pm CST
- [brave talk](https://talk.brave.com/eiIGZbj5QJ7Z60sw10spTjwNghZjsXqeMrc2U7zb7Dk)
- Review trink helix testbench progress
- Chris: ~~finish USDA Survey,~~ look at 1099 tax stuff
- Chris: ~~fix tnasplex permissions issue~~
- Chris: ~~test tnasplex dvr~~
- Chris: Document docker volume mappings with ~~tnasplex app~~ and dockerplex
  - added pshare user UID 1000 and pshare group GID 1000
  - Use pshare user for smb login
  - Add apps (UID 568) to pshare group (this alone did not do it for plex app)
  - Changed plexmedia share to pshare owner and group 
  - Added User apps (UID 568) Allow | Special to plexmedia Dataset Permissions (this seemed to do it)
- Chris: review ns, gs and cf documents and merge
- Chris: document theory of plex.tv ip port / server stuff - netflix doing 30 day IP 'sign-on' per public IP
  - Seems servers are not unique, it is the public IP and port response
  - syncing info on each server to cloud and client... I think
- Chris: maybe [setup win11](https://youtu.be/2Ja_e6CMkNY) and ubuntu 22.04 on proxmox for gus remote testing
- Chris: update [https://gus.conversehouse.com/](https://gus.conversehouse.com/) on HD mappings and 5G backup route

### 2023.02.01 3pm PST 5pm CST
- [brave talk](https://talk.brave.com/eiIGZbj5QJ7Z60sw10spTjwNghZjsXqeMrc2U7zb7Dk)
- distroyed old nas setup true nas
- setup ssh to nas 24.149.22.11:2020 for rsync
- plex on truenas via k3s name: tnasplex
- plex volume issue on truenas [config access truenas-scale-cannot-deploy-plex](https://www.truenas.com/community/threads/truenas-scale-cannot-deploy-plex.100397/)
- review current [pr review request helix](https://github.com/helix-editor/helix/pull/5751#pullrequestreview-1277856760)
- review this doc and move to gitea.trink.com ??
- DanK band _HKH and the Imponderables_ [https://losaltosfirstfriday.org/](https://losaltosfirstfriday.org/)
- share tuner mapping with HD indication
- TrueNAS, Portainer, Tailscale example - [document](https://forum.level1techs.com/t/truenas-scale-ultimate-home-setup-incl-tailscale/186444) - [youtube](https://www.youtube.com/watch?v=R7BXEuKjJ0k)
- tbd

### 2023.01.30 3pm PST 5pm CST
- [brave talk](https://talk.brave.com/eiIGZbj5QJ7Z60sw10spTjwNghZjsXqeMrc2U7zb7Dk)
- setup ssh to nas 24.149.22.11:2020
- review [pr helix](https://github.com/helix-editor/helix/pull/5738)
- tbd

## Trink think things to review

- [Nestack for homelab](https://netstack.org/docs/)
   - Document trinktv home media model
   - Document storage sharing model
   - Docuemtn security storage model
- [Home Assistant](https://www.home-assistant.io/)
- [Home Assistant Release Review](https://www.youtube.com/watch?v=Ts-_BdFsvxI)
- [Home Assist Dashboard](https://www.youtube.com/watch?v=yy_GBQ5dhKw)
- [OpenSource security AI - frigate ai](https://github.com/blakeblackshear/frigate)
- [https://frigate.video/](https://frigate.video/)
- [Amazon Dash Button Rescure](https://blog.christophermullins.com/2019/12/20/rescue-your-amazon-dash-buttons/)
- [Amazon Dash Button Hack repo](https://github.com/Nekmo/amazon-dash)
- Setup Test network model on eve that models cf.lan and gh.lan
- Setup Test ipv6 network on eve

### TrinkCat Remote DataCenter
- It seem with robot simulation, plex dvr and transcode, OpenCI object recon ML and general AI having a DC with gpu is worth the effort.
- ProxMox server with shared GPU machine is my suggestion. [Proxmox vGPU Gaming Tutorial](https://www.youtube.com/watch?v=cPrOoeMxzu0)
    - Plex DVR and Transcoding.  There was about 30 stations
    - Private network extensions to Trink and Cat home TV networks using pfSense.
    - Remote rendering for robot simulations
    - Remote GPU and stoarge for AI/ML
- Grasshorse has lots of robot and robot kits.  
    - They had a grant for protomotion - stop motion animation robots
    - They have multiple robot kits: gantry robonova old school factory robot proto arms
- We chat about [https://www.coridium.us/coridium/shop](https://www.coridium.us/coridium/shop) 
    - BruceE company to integrate sensors into co.bot ?
    - MikeR did a lot of the embedded networking and they also did custom compilers for arm

## TrinkTV
Goal: Stable Plex server running in CF maintainable by mdt and cat.

### Plex Rebuilds 2022.08.12-14
Synopsys --
Use Window 10/11 with i5+ gen 10+ machine and map storage over network.

One of the ongoing issues is plex clients asking for transcode when its not required. 

[Avoid Plex transcoding](https://www.plexopedia.com/plex-media-server/general/avoid-transcoding/)

[Using GPU accelerated streaming](https://support.plex.tv/articles/115002178853-using-hardware-accelerated-streaming/)

Notes:
DVR recording takes very little cpu, but transcoding basically requries a gpu or lots of cores.
- macci - trink's old mini after rebuild would only playback to portals (aka portal client can take original format)
- trintv - old admin2cld-win10 Intel(R) Core(TM)2 Duo CPU E8400  @ 3.00GHz added trinks old video card and it could almost handle transcode to one web client
- HPi5 - Intel(R) Core(TM) i5-1035G1 CPU @ 1.00GHz - laptop I've been using could almost handle 4 recording and playback HD streams to web clinets NOTE gen 10 so has GPU built in.
- catmini - i7 
