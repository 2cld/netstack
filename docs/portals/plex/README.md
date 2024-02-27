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

# Plex Document links
- Plex playback [setup and testing](#plex-playback)
- Plex dvr [setup and testing](#plex-dvr)
- Plex library [setup and updates](#plex-library) and [shared media library](https://docs.google.com/spreadsheets/d/1QtCblfwwH6PWYOKnIw2m4DKLni8KrVynXM6Xslb7mGg/edit#gid=0)
- Plex [server settings](#plex-server)
- Plex [client settings](#plex-client)
- Plex [remote ssh](#remote-ssh-management)
-
# DVD to Plex
- [MakeMKV Key](https://forum.makemkv.com/forum/viewtopic.php?t=1053)
  - Go to MakeMKV application
  - Help -> Registration -> Paste Key
- [MakeMKV download](https://www.makemkv.com/download/)
## DVD-RIP
- Insert DVD
- Click on DVD icon (read the DVD)
- Verify Output folder and Title then click MakeMVK
- Verify output file... may need to name for Plex
- Repeat

# cfPlex
<!--
[plex.tv --- ghwin11.test.christrees 32800](http://test.christrees.com:32800/) cf->32800->6.3 cfPlex
  - cfPlex ghadmin windows 11
  - i5 Intel
  - Nividia GTX 660
  - Primary plex server
-->

# cfDVR plex
<!--
[plex.tv - bs01ds411.test.christrees 32700](http://test.christrees.com:32700/) cf->32700->6.103pf->2.105 bs01ds411
  - bs01ds411 Synology DS411 NAS
  - pshare \\192.168.2.105
  - storage and DVR for cf
  - Used as plexDVR
-->

## Plex dvr
- Login to [app.plex.tv](https://app.plex.tv/desktop/#!/) 
- goto wrench icon in upper right
- on left, select the server you want to manage
- select "Manage" -  "Live TV & DVR" near bottom of list
- add new tuners
- click on existing tuner channels "xx enabled" to access channel mapping function

## Plex library
- Update [shared media library](https://docs.google.com/spreadsheets/d/1QtCblfwwH6PWYOKnIw2m4DKLni8KrVynXM6Xslb7mGg/edit#gid=0) as you modify plex libs
- Login to [app.plex.tv](https://app.plex.tv/desktop/#!/) 
- goto wrench icon in upper right
- on left, select the server you want to manage
- select "Manage" -  "Library" near bottom of list
- add, delete or edit the library
- edit will allow you to add additional directories local to that plex server

## Plex client
- Login to [app.plex.tv](https://app.plex.tv/desktop/#!/) and client link [plex.tv/link](https://www.plex.tv/link/)
- use cfDVR for recordings
- use cfPlex for viewing and LiveTV
- Verify client settings location varies on each client
  - Quality MAX
  - Play at original quality
  - may want to mess with beta stuff as they are adjusting for various player updates

## Plex server
- see [https://github.com/2cld/netstack/tree/master/docs/portals/plex](https://github.com/2cld/netstack/tree/master/docs/portals/plex)

## Remote ssh management
ssh shell access for user data management
- [christrees.com/dns](https://domains.google.com/registrar/christrees.com/dns)
- cfPlex test.christrees.com -> 24.149.22.11:2020 -> 192.168.6.2:21
- cfDVR test.christrees.com -> 24.149.22.11:2021 -> 192.168.6.6:2020
- [port forward](http://192.168.6.1/#/html/advanced/security/advanced_security_advancedportforwarding.html)
- cfDVR ssh -p 2021 trink@test.christrees.com
- trink@cfDVR:~$ ls /volume1/pshare/trinkDVR/
- sg-cfPlex ssh -p 2020 trink@test.christrees.com
- trink@cf-sg2:~$ ls /mnt/catpool/trink/trinkDVR/

---
---
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
- [https://www.oliviertravers.com/plex-complex-libraries-ultimate-media-server/](https://www.oliviertravers.com/plex-complex-libraries-ultimate-media-server/)
- tbd
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
