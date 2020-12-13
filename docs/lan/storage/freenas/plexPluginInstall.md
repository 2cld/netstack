# Plex plugin install for TrueNAS 12

[TrueNAS Core 12 Plex Setup & ACL Permission Tutorial on a 144 TB Server - Lawrence Systems](https://www.youtube.com/watch?v=BGinwiHPllA)

1. Plugin Install via TrueNAS UI [youtube tc-2:20](https://youtu.be/BGinwiHPllA?t=140)
    - Choose pool in upper right 
    - Use Plex Beta if you have Plex Pass, otherwise the other
    - Click Install
2. Go MANAGE the Plex Server [youtube tc-4:33](https://youtu.be/BGinwiHPllA?t=273)
    - Login to server finish setup do not add libraries
    - Goto Pluggins and Stop Plex jail
3. Create Plex user on TrueNAS for ACL configuration [youtube tc-6:25](https://youtu.be/BGinwiHPllA?t=385)
    - Document Referenc [Plex Permissions in FreeNAS 11.3](https://www.ixsystems.com/blog/plex-permissions/)
    - Add user plex to TrueNAS Account User but give it SID 972 [youtube tc-7:17](https://youtu.be/BGinwiHPllA?t=437)
    - Add a normal user to the plex group [youtube tc-8:30](https://youtu.be/BGinwiHPllA?t=510)
4. Add plex user and group to ACL [youtube tc-8:57](https://youtu.be/BGinwiHPllA?t=537)
    - MediaVolume -> Media (DataSet) Edit ACL
    - Add ACL Item User
        - Who: User
        - User: plex
        - ACL Type: Allow
        - Permissions Type: Full Control
        - Flags Type: Basic
        - Flags: Inherit
    - Add ACL Item Group
        - Who: Group
        - User: plex
        - ACL Type: Allow
        - Permissions Type: Full Control
        - Flags Type: Basic
        - Flags: Inherit
    - Apply permissions recursively
5. Create Windows (SMB) Share [youtube tc-11:25](https://youtu.be/BGinwiHPllA?t=685)
    - Add Share /mnt/ghPool/synctest
    - Edit Share ACL
        - Domain: SG
        - Name: ghadmin
        - Permission: FULL
        - Type: ALLOWED
    - Test SMB share by connecting and writing some new folders and files
6. Add Share to plexServerCAT /mnt [youtube tc-13:14](https://youtu.be/BGinwiHPllA?t=794)
    - Stop Plex Plugin
    - Click on MOUNT POINTS
    - Add Mount Point
    - Source: /mnt/ghPool/synctest
    - Destination: /mnt/MediaVolume/iocage/jails/plexServerCAT/root/mnt/synctest
    - Save
    - Restsart Plex Plugin
7. Add new share as Lib in Plex [youtube tc-16:27](https://youtu.be/BGinwiHPllA?t=987)
    - Web browse to <plexserver>:32400 and sign-in
    - CLick on + next to PLEXSERVERCAT
    - Add Other name: ghlearn Videos
    - Add Folder /mnt/synctest/ghlearnVideos
8. Plex should auto scan and index [youtube tc-20:10](https://youtu.be/BGinwiHPllA?t=1210)
X. tbd [youtube tc-]()
X. tbd [youtube tc-]()
