# Media Service Pattern

**Applies to:** Any site serving media content (video, music, photos) to local or remote users.

## Principle

The **service** is "media accessible to users." The **application** (Plex, Jellyfin, Emby, simple file share) is just the renderer. The application is replaceable; the media library and access pattern persist.

## Service Definition

Every media service documents:

```yaml
service_name: "<site>Media"        # e.g., wfMedia, cfMedia
application: "Plex|Jellyfin|SMB"   # current renderer
host: "<node>"                     # where it runs
media_path: "<path>"               # primary media storage location
media_tier: "Media"                # per federation-backup-plan tiers
access:
  local: "<url or path>"           # LAN access
  remote: "<url or tunnel>"        # external access (if any)
users: ["user1", "user2"]          # who accesses this
backup:
  primary: "<where>"               # the always-on copy
  offsite: "<where>"               # per tier: Media = 1 offsite copy
  backup_drives: ["bs11", "bs12"]  # offline backup references
```

## Components (separate concerns)

| Component | What it is | Can be replaced by |
|-----------|-----------|-------------------|
| **Media Library** | The files (movies, music, TV, photos) | Nothing - this is the data |
| **Application** | Software that indexes + serves | Plex, Jellyfin, Emby, basic SMB share |
| **Host** | Machine running the application | Any node with access to media path |
| **Access Method** | How users reach it | Cloudflare tunnel, ZeroTier, local LAN |
| **Backup Copies** | Offline/offsite copies of the library | Drives, rsync targets |

## Lifecycle (per service-lifecycle-pattern)

```
Media Library (the data - never loses this)
    |
    v
Host + Application (BUILD -> CONFIGURE -> DEPLOY -> MONITOR)
    |
    v
Access Method (tunnel, DNS, LAN)
    |
    v
Backup Copies (validate against primary per media-validation-pattern)
```

**To replace the application:** new app on same (or new) host, pointed at same media path. Users get new access URL. Old app shut down after validation.

**To replace the host:** new host with access to media path (mount, rsync, ZFS share). Application installed on new host. Old host retired per service-lifecycle-pattern gate.

## Data Classification

Media content should be classified within the library:

| Class | Description | Backup Tier | Examples |
|-------|-------------|-------------|----------|
| Irreplaceable | No physical source, can't re-obtain | Critical (3 copies) | Home video, personal recordings, unique rips |
| Replaceable-costly | Physical source exists (DVD/VHS/CD) | Media (2 copies) | DVD rips, CD rips, VHS captures |
| Replaceable-easy | Can re-download or re-record | Scratch (1 copy) | DVR recordings of broadcast TV, downloads |

**Key decision:** Before validating backup drives, classify the content. Replaceable media needs fewer copies than irreplaceable.

## Site Implementation

Each site with a media service creates:

```
<site>/docs/services/<service-name>.md   # service definition
<site>/ops/storage-index/<media-drive>.md # primary storage manifest
<site>/ops/scripts/validate-media.sh     # comparison script
```

## Template (for site service doc)

```markdown
# <site>Media Service

## Service
- Name: <site>Media
- Application: <current app>
- Host: <node> (<IP>)
- Port: <port>
- Status: <running|stopped|migrating>

## Media Library
- Primary path: <where the files live>
- Size: <total>
- Classification: <what tiers of content>

## Access
- LAN: <local URL>
- Remote: <tunnel URL or "none">
- Users: <who has access>

## Backup
- Primary: <always-on location> (tier: Media = 2 copies min)
- Offsite: <where> 
- Backup drives: <list of drive labels>

## History
- <date>: <changes, migrations, application swaps>
```

## Related

- [federation-backup-plan](./federation-backup-plan.md) - storage tiers (Critical, Media, Scratch)
- [media-validation-pattern](./media-validation-pattern.md) - compare backup against primary
- [service-lifecycle-pattern](../tools/service-lifecycle-pattern.md) - migration gates
- [storage-index](../storage-index/) - drive manifests
- [portals/plex](../../portals/plex/) - Plex-specific setup docs
