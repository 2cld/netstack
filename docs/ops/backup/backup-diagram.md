# netstack filerepo data lifecycle

- repo tree active or creation of new repo tree
```mermaid
sequenceDiagram
    participant user
    participant buadmin
    participant fileserver
    participant buserver
    participant archserver
    participant archmediaUID
    buadmin->>fileserver: filerepo creation active
    user->>fileserver: filerepo changes
    fileserver->>fileserver: fileserver zfs snapshot 2hr
    fileserver->>buserver: fileserver zfs sync daily
    buserver->>buserver: buserver zfs snapshot weekly
    buserver->>archserver: buserver zfs sync weekly
    archserver->>archserver: archserver zfs snapshot monthly
```
- filerepo inactive and/or filerepo release to archive
```mermaid
sequenceDiagram
    participant user
    participant buadmin
    participant fileserver
    participant buserver
    participant archserver
    participant archmediaUID
    user->>fileserver: filerepo final changes
    buadmin->>fileserver: filerepo dailies / reviews / final
    user->>buadmin: filerepo final checkin
    buadmin->>fileserver: filerepo inactive
    fileserver->>buserver: fileserver zfs sync daily
    buserver->>archserver: buserver zfs sync weekly
    archserver->>archmediaUID: filerepo rsync archive
    archserver->>buadmin: filerepo archive archserver lot assignment logs
```
- filerepo request to offline (hide repo and mark to create offline archmedia_123 pack)
```mermaid
sequenceDiagram
    participant user
    participant buadmin
    participant fileserver
    participant buserver
    participant archserver
    participant archmediaUID
    buadmin->>fileserver: filerepo offline request process
    fileserver->>fileserver: filerepo directory log and pointer update
    fileserver->>buserver: active filerepo remove data process
    buserver->>buserver: filerepo directory log and pointer update
    buserver->>archserver: active filerepo remove data process
    archserver->>archserver: filerepo directory log and pointer update
    archserver->>archmediaUID: archive filerepo confirmation check
    archserver->>archserver: archive filerepo lot confirmation local
    archserver->>buadmin: filerepo hidden lot confirmation done
    archserver->>buadmin: filerepo archive archserver lot assignment logs
```
- filerepo archmedia offline and notify resource reclaim
```mermaid
sequenceDiagram 
    participant user
    participant buadmin
    participant fileserver
    participant buserver
    participant archserver
    participant archmediaUID
    buadmin->>fileserver: filerepo storage reclaim
    fileserver->>fileserver: filerepo storage reclaim process
    fileserver->>buserver: filerepo storage reclaim
    buserver->>buserver: filerepo storage reclaim process
    buserver->>archserver: filerepo storage reclaim
    archserver->>archmediaUID: filerepo archive archmedia3_123_UID write and log
    archserver->>archserver: archmedia2_123_UID and archmedia1_123_UID verify and log
    archserver->>buadmin: archmedia123UID location update
    archserver->>archserver: archmedia1_123_UID remove and scan
    archserver->>buadmin: filerepo hidden archmedia123UID offline done
```
