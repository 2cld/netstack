# Pattern: Plex LAN-Only Configuration (Windows Host)

**Pattern type:** Service management (non-Docker, Windows-native)
**Applies to:** Federation sites running Plex on Windows host hardware
**Related:** [site-tenant-contract-pattern](../../../docs/ops/deployments/site-tenant-contract-pattern.md), [netstack#16](https://github.com/2cld/netstack/issues/16)

## Problem

Plex on federation nodes (especially i3/i5 class hardware) can overwhelm the machine:
- Continuous library scanning (file watchers, periodic scans)
- Video preview/chapter/intro generation (CPU + disk intensive)
- Remote access relay (bandwidth + CPU for transcoding)
- Phone-home activity to plex.tv (background network traffic)
- Loudness analysis (CPU intensive)

This impacts backup reception, federation Docker services (WSL), and responsiveness.

## Decision: Windows Host, Not Docker

Plex runs on the **Windows host** (not Docker in WSL) because:
- WSL `network_mode: host` binds to WSL's virtual network (172.31.x.x), not the Windows LAN
- LAN clients (TVs, phones) can't reach Docker Plex without port forwarding/mirrored networking
- HDHomeRun DVR requires LAN multicast discovery (doesn't traverse WSL network boundary)
- Windows Plex has direct access to LAN, GPU (if available), and storage drives

Docker in WSL handles: traefik, cloudflared, gitea, portainer (services that are accessed via Cloudflare tunnel or ZeroTier — not LAN).

## Configuration: LAN-Only, Scan-on-Demand

### Settings (applied via API or registry)

| Setting | Value | Why |
|---------|-------|-----|
| `PublishServerOnPlexOnlineKey` | `0` | Don't advertise to plex.tv |
| `RelayEnabled` | `0` | No relay for remote access |
| `ManualPortMappingMode` | `1` | No UPnP port mapping |
| `allowedNetworks` | `<site-subnet>/255.255.255.0` | Restrict to LAN only |
| `ScheduledLibraryUpdatesEnabled` | `0` | No periodic scans |
| `FSEventLibraryUpdatesEnabled` | `0` | No filesystem watcher |
| `FSEventLibraryPartialScanEnabled` | `0` | No partial scan on change |
| `GenerateBIFBehavior` | `never` | No video preview thumbnails |
| `GenerateIntroMarkerBehavior` | `never` | No intro detection |
| `GenerateChapterThumbBehavior` | `never` | No chapter thumbnails |
| `LoudnessAnalysisBehavior` | `never` | No audio analysis |
| `TranscoderCanOnlyRemuxVideo` | `1` | Remux only, no full transcode |
| `DlnaEnabled` | `0` | No DLNA (reduces network chatter) |
| `sendCrashReports` | `0` | No phone-home |
| `ButlerTaskDeepMediaAnalysis` | `0` | No deep analysis |
| `ButlerTaskUpgradeMediaAnalysis` | `0` | No upgrade analysis |
| `ButlerTaskRefreshPeriodicMetadata` | `0` | No periodic metadata refresh |

### Butler (Scheduled Tasks) Window

```
ButlerStartHour: 5  (maintenance window start)
ButlerEndHour: 8    (maintenance window end)
```

Keep this outside backup window (2 AM) and outside heavy usage times.

## Applying Configuration

### Via Plex API (Plex running, requires token)

Token location: Windows Registry `HKCU\Software\Plex, Inc.\Plex Media Server\PlexOnlineToken`

```bash
TOKEN="<PlexOnlineToken from registry>"
PLEX="http://<plex-lan-ip>:32400"

# Apply all LAN-only settings
curl -X PUT "$PLEX/:/prefs?RelayEnabled=0&X-Plex-Token=$TOKEN"
curl -X PUT "$PLEX/:/prefs?GenerateChapterThumbBehavior=never&X-Plex-Token=$TOKEN"
curl -X PUT "$PLEX/:/prefs?GenerateIntroMarkerBehavior=never&X-Plex-Token=$TOKEN"
curl -X PUT "$PLEX/:/prefs?LoudnessAnalysisBehavior=never&X-Plex-Token=$TOKEN"
curl -X PUT "$PLEX/:/prefs?allowedNetworks=192.168.1.0/255.255.255.0&X-Plex-Token=$TOKEN"
```

### Via Registry (Plex stopped, Windows SSH)

```powershell
Set-ItemProperty -Path 'HKCU:\Software\Plex, Inc.\Plex Media Server' -Name 'RelayEnabled' -Value 0
# ... etc for each setting
```

### Validation (read back and compare)

```bash
# Check critical settings via API
curl -s "$PLEX/:/prefs?X-Plex-Token=$TOKEN" | grep -oP '(RelayEnabled|ScheduledLibrary|GenerateBIF|GenerateIntro|GenerateChapter|Loudness|allowedNetworks).*?value="[^"]*"'
```

## site-config.yml Schema

In the site's `site-config.yml`, Plex is declared as a host-level service with managed configuration:

```yaml
goals:
  local:
    - name: "Media Playback + DVR"
      service:
        name: "Plex Media Server"
        layer: windows
        host: <hostname>
        port: 32400
        lan_ip: "<host-lan-ip>"
        check: "curl -s -o /dev/null -w '%{http_code}' http://<lan-ip>:32400/web"
        pattern: "plex-lan-only-pattern"
        config:
          remote_access: false
          transcoding: "remux-only"
          scanning: "manual"
          allowed_networks: "<site-subnet>/255.255.255.0"
          token_registry_path: "HKCU\\Software\\Plex, Inc.\\Plex Media Server\\PlexOnlineToken"
```

## Monitoring Integration

### From WSL (sl-status.sh)

```bash
# Check Plex via Windows host LAN IP
PLEX_CODE=$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 http://<lan-ip>:32400/web)
```

### From federation (via ZeroTier)

```bash
# Check Plex via ZeroTier overlay IP
PLEX_CODE=$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 http://<zt-ip>:32400/web)
```

### site-ops verify (config validation)

```bash
# Verify settings match pattern (requires token)
TOKEN=$(ssh ghadmin@<zt-ip> "powershell -Command \"(Get-ItemProperty 'HKCU:\\Software\\Plex, Inc.\\Plex Media Server').PlexOnlineToken\"")
PREFS=$(curl -s "http://<zt-ip>:32400/:/prefs?X-Plex-Token=$TOKEN")
# Check RelayEnabled=0, GenerateBIFBehavior=never, etc.
```

## Scanning: Manual Only

With all auto-scan disabled, trigger scans manually:

```bash
# Scan all libraries
curl -X POST "$PLEX/library/sections/all/refresh?X-Plex-Token=$TOKEN"

# Scan specific library (get section IDs from /library/sections)
curl -s "$PLEX/library/sections?X-Plex-Token=$TOKEN" | grep -oP 'key="\K[^"]+' 
curl -X POST "$PLEX/library/sections/<id>/refresh?X-Plex-Token=$TOKEN"
```

For DVR: Plex DVR auto-adds recordings to the DVR library section. With `FSEventLibraryUpdatesEnabled=0`, the recording appears in the filesystem but won't show in Plex until a manual scan. Option: keep FSEvent enabled ONLY for the DVR library if recordings need to appear immediately.

## Alternative: Jellyfin Migration Path

If Plex still causes issues (network choking, background activity):

| Factor | Plex | Jellyfin |
|--------|------|----------|
| Phone-home | Yes (plex.tv sync) | No |
| Account required | Yes | No |
| Background activity at idle | Moderate (metrics, updates) | Minimal |
| LAN discovery | Good | Good |
| HDHomeRun DVR | Yes (Plex Pass) | Yes (free) |
| Client apps | Best (all platforms) | Good (most platforms) |
| Resource usage | Higher | Lower |
| Media folder format | Standard | Standard (same folders work) |

Migration: Install Jellyfin, point at same media folders. Run both during evaluation. Decommission Plex if Jellyfin meets needs.

## Per-Site Reference

| Site | Plex Location | LAN IP | ZT IP | DVR | GPU |
|------|--------------|---------|-------|:---:|-----|
| cf | CyberTruck (Windows) | 192.168.6.30 | 10.147.17.219 | No | GTX 660 |
| sl | slwin11ops (Windows) | 192.168.1.194 | 10.147.17.94 | Yes (HDHomeRun) | Intel HD (i3) |
| wf | cg2 (Proxmox LXC) | 192.168.9.3 | N/A | No | None |

## Related

- [plex/README.md](./README.md) — general Plex federation notes
- [netstack#12](https://github.com/2cld/netstack/issues/12) — Unix monitoring node (why Plex is on Windows, monitoring from WSL)
- [netstack#16](https://github.com/2cld/netstack/issues/16) — federation dashboard (site-config.yml driven)
- [compute-wsl-docker-pattern](../../../docs/lan/compute/docker/) — Docker services alongside Windows Plex
