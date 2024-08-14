[documents](../../) [lan](../)

### freenas index

- [gitlabPluginInstall](./gitlabPluginInstall)
- [ops-relocate](./ops-relocate)
- [plexPluginInstall](./plexPluginInstall)
- [setup](./setup)
- [sg-cf-2cld-config](./sg-cf-2cld-config)
- [ttuenas-virtualbox](./truenas-virtualbox)
- [tbd]()
  
# FreeNAS now TrueNAS

The netstack storage infrastructure pattern uses ZFS storage mounted via NFS, SMB and iSCSI via a FreeNAS server.  Storage allocation, snapshots and recovery are determined via project / customer SLA and maintained through management of ZFS snapshot, replication and rsync tools via the FreeNAS server.

[TrueNAS - Scale](https://www.truenas.com/truenas-scale/) [TrueNAS - Docs](https://www.truenas.com/docs/)

## Netstack Storage Infrastructure

1. [projects.ns.lan](https://192.168.2.6) - Production Project Storage
2. [backups.ns.lan](https://192.168.2.7) - Enterprise storage for ZFS volume replication
3. [offsite.ns.lan](https://192.168.8.8) - DeepStorage and Disaster Recovery

## Snapshot, Replication and Recover

1. [projects.ns.lan](https://192.168.2.6)
    1. ZFS Volumes
      - Projects
    2. ZFS Snapshot every 2hrs
    3. ZFS Replication to [backups.gh.lan](https://192.168.2.7) every night starting at 8PM CST
    4. Keep 28 snapshots (retention
2. [backups.ns.lan](https://192.168.2.7)
    1. ZFS Volumes
      - Projects to ProjectsBackup (target for ZFS replication)
    2. XFS Snapshot daily at 4pm 
2. [offsite.ns.lan](https://192.168.8.8) (this could be a physical rotation of ZFS drives
    1. ZFS Volumes
      - Projects

## Reference
Various information resources

### Best TrueNAS 12 Complete walkthrough
- [88TB TrueNAS CORE Build - Craft Computing](https://www.youtube.com/watch?v=nQiWP8T9R60)
- [TrueNAS CORE 12.0 Install Tutorial - Craft Computing](https://www.youtube.com/watch?v=nVRWpV2xyds)
    - [First Pool: Storage -> Pool](https://youtu.be/nVRWpV2xyds?t=323)
    - [SSD Cache to Pool: Storage -> Pool -> Add -> Add VDev -> Cache](https://youtu.be/nVRWpV2xyds?t=360)
    - [First SMB Share: Sharing -> SMB](https://youtu.be/nVRWpV2xyds?t=406)
    - [Add User for SMB Share: Accounts -> Users -> Add](https://youtu.be/nVRWpV2xyds?t=479)
    - [Set SMB User to Wheel Group for SMB](https://youtu.be/nVRWpV2xyds?t=501)
    - [Cleanup SMB Share permissions using shell](https://youtu.be/nVRWpV2xyds?t=555)
    - [Connect to SMB Share using Windows 10 client](https://youtu.be/nVRWpV2xyds?t=633)
- [TrueNAS Data Migration Tutorial - Craft Computing](https://www.youtube.com/watch?v=uVllnnozmFc)
    - [Push data from old FreeNAS to new TrueNAS using Replication](https://youtu.be/uVllnnozmFc?t=106)
    - [Verify Data Replication](https://youtu.be/uVllnnozmFc?t=447)
    - [Use dir and fc to verify file replication](https://youtu.be/uVllnnozmFc?t=471)
        1. Mount oldshare as Z drive on Windows client
        ```
        Z:\>dir /s > oldshare.txt
        ```
        2. Mount newshare as Z drive on Windows client
        ```
        Z:\>dir /s > newshare.txt
        ```
        3. Compare difference
        ```
        Z:\>fc newshare.txt oldshare.txt > newolddiffernces.txt
        ```
    - [Moving Physical Drives to new Server](https://youtu.be/uVllnnozmFc?t=614)
    - [Import old drives into new TrueNAS Server](https://youtu.be/uVllnnozmFc?t=664)
- [TrueNAS CORE 12.0 Tutorial - Datasets, Permissions, Snapshots - Craft Computing](https://www.youtube.com/watch?v=k0X0geU6NOA)
- [12-Bay, 1U Storage Server for $120 - Craft Computing](https://www.youtube.com/watch?v=F1xX3V_n0kw)
- [Three Server HomeLab for less than $1,000 - Craft Computing](https://www.youtube.com/watch?v=onMD8tvnLbs)
- [EPYC TrueNAS Scale Build and VM Install](https://www.youtube.com/watch?v=Vi-ZdJOenWc&t=799s)
    - [TrueNAS Scale new Install](https://youtu.be/Vi-ZdJOenWc?t=907)
- [Youtube Index - Craft Computing](https://www.youtube.com/c/CraftComputing/videos)
- [ - Craft Computing]()

### Other FreeNAS resources
- [ZFS Replication and Recovery with FreeNAS](http://storagegaga.com/zfs-replication-and-recovery-with-freenas/)
- [FreeNAS 11.2 - Datasets & Snapshots - iXsystems](https://www.youtube.com/watch?v=4hXjA5rNVSg)
- [Lawrence Systems - FreeNAS 11.2 Snapshots / Replication](https://www.youtube.com/watch?v=Ge8eLR2FvDU&list=PLjGQNuuUzvmug2-LMfh43ehP9nt8gmCSf&index=36)
- [Lawrence Systems - How To Backup Your FreeNAS 11.3 Using ZFS Replication](https://www.youtube.com/watch?v=et7JyacV_hA&list=PLjGQNuuUzvmug2-LMfh43ehP9nt8gmCSf&index=5)
    - [Lawrence Systems - How To Backup Your FreeNAS 11.3 Using ZFS Replication](https://www.youtube.com/watch?v=et7JyacV_hA)
    - [Zerotier vpn on Freebsd](https://gist.github.com/dch/b36dd170209e65677d23f77c44825b5a)
    - [Zerotier CLI](https://zerotier.atlassian.net/wiki/spaces/SD/pages/29065282/zerotier-cli)
    - [Lawrence Systems - ZeroTier on FreeNAS](https://forums.lawrencesystems.com/t/zerotier-on-freenas/1650)
    - [IXXyxtems - ZeroTier on FreeNAS](https://www.ixsystems.com/community/threads/zerotier-how-is-this-configured.56070/)
    - [FreeNAS - Zerotier Setup](https://techmaniac.in/freenasyt/freenasyt.html)
- [Lawrence Systems - FreeNAS VPN | Zerotier Setup | Remote Access FreeNAS Jail and Console](https://www.youtube.com/watch?v=fEkybngMcWk)
- [Fun with ZFS send and receive](https://128bit.io/2010/07/23/fun-with-zfs-send-and-receive/)
- [ZFS Snapshot to file as backup with rotation](https://unix.stackexchange.com/questions/113743/zfs-snapshot-to-file-as-backup-with-rotation)
- [ZFS Send to External Backup Drive](https://www.ixsystems.com/community/threads/zfs-send-to-external-backup-drive.17850/)
- [ZFS Send snapshot to remote machine](https://askubuntu.com/questions/764416/send-zfs-snapshot-to-remote-machine)
- [ZFS Send document oracle-sun](https://docs.oracle.com/cd/E19253-01/819-5461/gbinw/index.html)
- [How to migrate data from one pool to a bigger pool ZFS](https://www.ixsystems.com/community/threads/howto-migrate-data-from-one-pool-to-a-bigger-pool.40519/)
- [Combating WannaCry and Other Ransomware with OpenZFS Snapshots](https://www.ixsystems.com/blog/combating-ransomware/)
- [Iron Mountain - Backup Rotation](https://www.ironmountain.com/resources/general-articles/b/by-the-book-strategies-that-work-for-backup-tape-rotation)



- The config instructions for [cat9FreeNAS](./cat9FreeNAS.md) from original 2017-10-26 [cat9FreeNAS google doc](https://docs.google.com/document/d/1kE2nafGL4KOyLlbPjma4ittpz_pkTlQPhcBlV2qrHMU/edit)
