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

## Windows 11 permissions

```
Remove "Everyone", then add it back like this:
Right click the Folder containing your media.
Click Properties
Click "Security" tab
Click ADVANCED
Click ADD
Click "select a principal"
Enter Everyone, click "Check Names" to ensure correct spelling
Click OK
Click "Full Control"
Click OK
Tick "Replace all child object permission entries with inheritable permission entries from this object"
Click OK
Click OK to close the properties window.
Restart Plex Media Server, or better yet, restart windows entirely because sometimes it's a little bitch with file permissions.

Retest
```
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
- [definitive_plex_pfsense_config_post](https://www.reddit.com/r/PleX/comments/10ud1q9/definitive_plex_pfsense_config_post/)
- [2_dvr_tuners_hdhr_antenna_iptv_xteve_with_xml_epg](https://www.reddit.com/r/PleX/comments/nqb67e/2_dvr_tuners_hdhr_antenna_iptv_xteve_with_xml_epg/)
- [integrate_youtubetv_or_plutotv_into_plex_as_livetv](https://www.reddit.com/r/PleX/comments/fc3qod/integrate_youtubetv_or_plutotv_into_plex_as_livetv/)
- [4-things-to-know-before-you-sign-up-for-youtube-tv](https://clark.com/technology/tvsatellite-cable/4-things-to-know-before-you-sign-up-for-youtube-tv/)
- Added plexapp to bs01ds411 synology NAS on 192.168.2.105
- plex volume issue on truenas [config access truenas-scale-cannot-deploy-plex](https://www.truenas.com/community/threads/truenas-scale-cannot-deploy-plex.100397/)
- [tbd]()

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
