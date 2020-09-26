# FreeNAS

The netstack storage infrastructure pattern uses ZFS storage mounted via NFS, SMB and iSCSI via a FreeNAS server.  Storage allocation, snapshots and recovery are determined via project / customer SLA and maintained through management of ZFS snapshot, replication and rsync tools via the FreeNAS server.

## Netstack Storage Infrastructure

1. [projects.ns.lan](https://192.168.2.6) - Production Project Storage
2. [backups.ns.lan](https://192.168.2.7) - Enterprise storage for ZFS volume replication
3. [offsite.ns.lan](https://192.168.8.8) - DeepStorage and Disaster Recovery

### Snapshot, Replication and Recover

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

### Reference
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
