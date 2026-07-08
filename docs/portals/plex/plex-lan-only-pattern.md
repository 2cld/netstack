# Pattern: Plex LAN-Only Configuration (Low-Resource)

**Location:** netstack `docs/portals/plex/plex-lan-only-pattern.md`
**Status:** Draft (validate against running instances at cf, sl)
**Related:** [netstack Plex README](https://github.com/2cld/netstack/blob/master/docs/portals/plex/README.md)

## Problem

Plex Media Server on federation nodes (especially i3-class hardware) can overwhelm the machine through:
- Continuous library scanning (file watchers, periodic scans)
- Video preview thumbnail generation (CPU + disk intensive)
- Remote access relay (bandwidth + CPU for transcoding)
- Intro/chapter detection (CPU intensive background processing)
- Automatic updates and phone-home activity

This impacts backup reception, federation services, and general responsiveness.

## Solution: LAN-Only, Scan-on-Demand Configuration

Configure Plex for local household media playback only:
- Direct play to LAN clients (no transcoding)
- No remote access (no relay, no external connections)
- No automatic scanning (manual scan only)
- No thumbnail/preview generation
- Minimal scheduled tasks

## Configuration (Preferences.xml / API)

### Key Settings

| Setting | Value | Why |
|---------|-------|-----|
| `PublishServerOnPlexOnlineKey` | `0` | Don't advertise to plex.tv |
| `RelayEnabled` | `0` | No relay for remote access |
| `customConnections` | (empty) | No custom remote URLs |
| `ManualPortMappingMode` | `1` | Don't try UPnP port mapping |
| `ScheduledLibraryUpdatesEnabled` | `0` | No periodic scans |
| `FSEventLibraryUpdatesEnabled` | `0` | No filesystem watcher scans |
| `ScannerLowPriority` | `1` | If scan runs, use low CPU priority |
| `GenerateBIFBehavior` | `never` | No video preview thumbnails |
| `GenerateChapterThumbBehavior` | `never` | No chapter thumbnails |
| `GenerateIntroMarkerBehavior` | `never` | No intro detection |
| `LoudnessAnalysisBehavior` | `never` | No audio analysis |
| `MusicAnalysisBehavior` | `never` | No sonic analysis |
| `TranscoderTempDirectory` | (default) | N/A — no transcoding expected |
| `TranscoderDefaultDuration` | `60` | Short transcode segments if needed |

### Per-Library Settings (via API or UI)

For each library:
- **Scan my library automatically:** OFF
- **Run a partial scan when changes are detected:** OFF  
- **Scan my library periodically:** Disabled
- **Include in dashboard:** ON (still shows in UI)

### Scheduled Tasks (Settings → Scheduled Tasks)

Uncheck all except:
- ✅ Backup database every three days (lightweight, protects metadata)
- ❌ Optimize database (can run manually if needed)
- ❌ Remove old bundles (run manually during maintenance)
- ❌ Refresh local metadata (manual)
- ❌ Upgrade media analysis (never)

Set maintenance window to low-traffic time (e.g., 3 AM, not during backup window).

## Applying Settings

### Via API (Plex running)

```bash
# Read current preferences
curl -s http://<plex-ip>:32400/:/prefs | xmllint --format -

# Set a preference
curl -X PUT "http://<plex-ip>:32400/:/prefs?PublishServerOnPlexOnlineKey=0"
curl -X PUT "http://<plex-ip>:32400/:/prefs?RelayEnabled=0"
curl -X PUT "http://<plex-ip>:32400/:/prefs?ScheduledLibraryUpdatesEnabled=0"
curl -X PUT "http://<plex-ip>:32400/:/prefs?FSEventLibraryUpdatesEnabled=0"
curl -X PUT "http://<plex-ip>:32400/:/prefs?GenerateBIFBehavior=never"
curl -X PUT "http://<plex-ip>:32400/:/prefs?GenerateChapterThumbBehavior=never"
curl -X PUT "http://<plex-ip>:32400/:/prefs?GenerateIntroMarkerBehavior=never"

# If Plex token needed (claimed server):
# Add ?X-Plex-Token=<token> to each request
# Token found in Preferences.xml: MachineIdentifier + Token fields
```

### Via Preferences.xml (Plex stopped)

Windows: `%LOCALAPPDATA%\Plex Media Server\Preferences.xml`
Linux: `/var/lib/plexmediaserver/Library/Application Support/Plex Media Server/Preferences.xml`
Docker: `<config-volume>/Preferences.xml`

Edit the XML attributes directly. Single-line format:
```xml
<Preferences ... PublishServerOnPlexOnlineKey="0" RelayEnabled="0" ScheduledLibraryUpdatesEnabled="0" ... />
```

### Validation (monitoring script can check)

```bash
# Check key settings via API
PREFS=$(curl -s http://<plex-ip>:32400/:/prefs)
echo "$PREFS" | grep -o 'RelayEnabled="[^"]*"'
echo "$PREFS" | grep -o 'ScheduledLibraryUpdatesEnabled="[^"]*"'
echo "$PREFS" | grep -o 'GenerateBIFBehavior="[^"]*"'
```

## Monitoring Integration

Add to site-status.sh or site-ops verify:

```bash
# Check Plex is running but not thrashing
PLEX_HTTP=$(curl -s -o /dev/null -w '%{http_code}' --max-time 3 http://<plex-ip>:32400/web)
# 200/302 = running and accessible
# 000 = not running
# Timeout = possibly thrashing/overloaded

# Optional: check transcoding not happening
PLEX_SESSIONS=$(curl -s http://<plex-ip>:32400/status/sessions | grep -c "transcode")
# Should be 0 for LAN-only direct play
```

## When to Scan

Manual scan triggers:
- After adding new media files
- After DVR recording completes (if Plex DVR is configured)
- During maintenance windows (Sunday evening, etc.)

Trigger via API:
```bash
# Scan all libraries
curl -X POST "http://<plex-ip>:32400/library/sections/all/refresh"

# Scan specific library (get section ID from /library/sections)
curl -X POST "http://<plex-ip>:32400/library/sections/1/refresh"
```

## Alternatives to Plex (evaluation criteria)

If Plex still causes issues even with this config:

| Server | Pros | Cons | Best for |
|--------|------|------|----------|
| **Jellyfin** | Open source, no phone-home, lighter on resources, no account required | Less polished UI, fewer client apps | LAN-only, low-power hardware |
| **Emby** | Good UI, moderate resources | Freemium (some features paid), still phones home | Middle ground |
| **Plex (current)** | Best client apps, DVR support, polished | Resource heavy, requires account, phones home | Feature-rich setups with good hardware |

**Migration path:** Jellyfin reads the same media folder structure. Point it at `F:\slMedia` and it indexes independently. Can run both during evaluation.

## Federation Considerations

- Each site runs its own Plex/media server independently
- No remote access means no cross-site streaming (intentional for bandwidth)
- DVR recordings stay local (not replicated — reproducible content)
- Plex config/database IS backed up (critical metadata, watch history)
- Media files are NOT backed up (reproducible, can re-record/re-obtain)

## Per-Site Configuration

| Site | Platform | Media Path | DVR | Notes |
|------|----------|-----------|:---:|-------|
| cf | Windows (CyberTruck) | cfbu:/volume1/plexnsds | No | GTX 660 available for transcode if needed |
| sl | Windows (slwin11ops) | F:\slMedia | Yes (HDHomeRun) | i3 CPU — direct play only, no transcode |
| wf | Proxmox LXC (cg2) | /MediaVolume/Media | No | Currently DOWN (wfMedia LXC stopped) |

## Related

- [netstack portals/plex/README.md](https://github.com/2cld/netstack/blob/master/docs/portals/plex/README.md) — general Plex docs
- [netstack#12](https://github.com/2cld/netstack/issues/12) — Unix monitoring node (Plex on Windows, monitoring from WSL)
- [sl-site-config.yml](../../.local/drafts/sl-site-config.yml) — sl Plex as Windows native service
- [cf-site-config.yml](../../.local/drafts/cf-site-config.yml) — cf Plex on CyberTruck
