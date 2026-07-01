# Pattern: Media Equipment Inventory (Room-Based Stations)

**Pattern type:** Physical infrastructure documentation
**Applies to:** Federation sites with media equipment (TVs, streaming devices, DVRs, audio)
**Related:** [site-physical-inventory-pattern](../deployments/site-physical-inventory-pattern.md), [plex-lan-only-pattern](../../portals/plex/plex-lan-only-pattern.md)

## Problem

Home sites have media equipment spread across rooms — TVs with multiple HDMI inputs, streaming boxes, DVRs, game consoles, audio receivers. Each device has multiple cable types connecting it to different infrastructure:
- HDMI to display
- Coax from antenna/cable splitter
- Ethernet to network switch (or wifi)
- Power to a specific outlet/strip
- Sometimes optical audio, USB, component video

Without a connection map, troubleshooting a dead input or tracing a cable run is guesswork.

## Solution: Room-Based Media Stations

Model each room as a **media station** centered on a display (TV), with attached devices and their connections documented.

## site-config.yml Schema

```yaml
physical:
  media:
    stations:
      - tag: "<site>-<room>-tv<n>"
        name: "<Room> Media"
        location: <room-code>
        display:
          name: "<TV description>"
          make: "<manufacturer>"
          model: "<model>"
          size: "<screen size>"
          inputs:
            - { port: "HDMI1", label: "<what's plugged in>" }
            - { port: "HDMI2", label: "<what's plugged in>" }
            - { port: "HDMI3", label: "<what's plugged in>" }
            - { port: "ARC/eARC", label: "<soundbar or receiver>" }
          audio_out: "<optical, ARC, 3.5mm, none>"
        devices:
          - tag: "<site>-<room>-<type><n>"
            name: "<device name>"
            type: "<roku|tivo|firetv|appletv|bluray|game|soundbar|receiver>"
            make: "<manufacturer>"
            model: "<model>"
            mac: "<MAC if network-connected>"
            ip: "<IP if static/reserved>"
            connections:
              - { type: "hdmi", to: "<display input or receiver input>" }
              - { type: "coax_ant", from: "<splitter tag + port>" }
              - { type: "coax_cable", from: "<splitter tag + port>" }
              - { type: "ethernet", to: "<switch tag + port OR wifi>" }
              - { type: "optical", to: "<soundbar/receiver>" }
              - { type: "usb", to: "<what>" }
              - { type: "power", to: "<power tag or strip name>" }
            status: "active|standby|unused|decommissioned"
            notes: "<any special config, firmware version, account>"
```

## Connection Types

| Type | Direction | Description |
|------|-----------|-------------|
| `hdmi` | → (out to display/receiver) | Video + audio to TV or AV receiver |
| `coax_ant` | ← (in from antenna) | Over-the-air signal from splitter |
| `coax_cable` | ← (in from cable) | Cable TV signal from splitter |
| `ethernet` | ↔ (network) | Wired LAN to switch port |
| `wifi` | ↔ (network) | Wireless (note SSID if relevant) |
| `optical` | → (audio out) | Toslink optical audio to soundbar/receiver |
| `arc` | ↔ (audio return) | HDMI ARC/eARC to soundbar |
| `usb` | → | USB to hub, storage, or power |
| `power` | ← | Power source (outlet/strip/UPS) |
| `component` | → | Legacy component video (rare) |
| `composite` | → | Legacy RCA composite (rare) |

## Generated Output: Connection Table

From the schema, generate a per-room connection table:

### Steve's Room Media

**Display:** Samsung 55" (TV)
| Input | Device | Notes |
|-------|--------|-------|
| HDMI1 | StevesRokuUltra | Primary streaming |
| HDMI2 | Steves320 TiVo | DVR (antenna) |
| HDMI3 | Steves640 TiVo | DVR (cable) |

**Device Connections:**
| Device | HDMI | Coax | Network | Power |
|--------|------|------|---------|-------|
| StevesRokuUltra | → TV HDMI1 | — | wifi | sr-strip |
| Steves320 TiVo | → TV HDMI2 | ← spl02 p1 (ant) | sw1 p1 (eth) | sr-strip |
| Steves640 TiVo | → TV HDMI3 | ← spl04 p1 (cable) | sw1 p2 (eth) | sr-strip |
| HDHomeRun | — | ← spl02 p2 (ant) | sw1 p3 (eth) | sr-strip |

## Relationship to Other Sections

The media section cross-references:
- **Network switches** (`physical.switches`) — which port each device uses
- **Coax plant** (`physical.coax`) — which splitter port feeds which device
- **Power** (`physical.power`) — which circuit/strip powers which device
- **Services** (`cg.services`) — Plex serves content to these devices

```
site-config.yml
├── physical.switches    ← ethernet connections
├── physical.coax        ← antenna/cable feeds
├── physical.power       ← power sources
├── physical.media       ← THIS: ties devices to all of the above
└── cg.services (Plex)   ← what serves content to these devices
```

## Tagging Convention

Media device tags: `<site>-<room>-<type><n>`

| Type code | Device type |
|-----------|-------------|
| `tv` | Television/display |
| `roku` | Roku streaming device |
| `tivo` | TiVo DVR |
| `ftv` | Amazon Fire TV |
| `atv` | Apple TV |
| `sbar` | Soundbar |
| `rcvr` | AV Receiver |
| `game` | Game console |
| `dvd` | DVD/Blu-ray player |
| `tuner` | Network tuner (HDHomeRun) |

## Monitoring Integration

Media devices are generally NOT monitored by Wip (they're consumer electronics, not federation infrastructure). Exceptions:
- **HDHomeRun** — monitored (DVR dependency, has HTTP API)
- **Network-connected streamers** — optional ping check if they have static IP

The monitoring boundary: if it has an IP and serves a federation goal (like DVR), monitor it. If it's a TV or Roku, don't.

## Example: Full Room Documentation

```yaml
- tag: sl-sr-tv1
  name: "Steve's Room Media"
  location: sr
  display:
    name: "Samsung 55 inch"
    make: Samsung
    model: "TBD"
    size: "55in"
    inputs:
      - { port: "HDMI1", label: "Roku Ultra" }
      - { port: "HDMI2", label: "TiVo 320 (antenna)" }
      - { port: "HDMI3", label: "TiVo 640 (cable)" }
    audio_out: "TV speakers"
  devices:
    - tag: sl-sr-roku1
      name: "StevesRokuUltra"
      type: roku
      make: Roku
      model: "Ultra"
      mac: "8C-49-62-0B-69-8D"
      connections:
        - { type: hdmi, to: "TV HDMI1" }
        - { type: wifi, ssid: "TP-LINK_24" }
        - { type: power, to: "sl-sr-pwr1" }
      status: active
      notes: "Primary streaming device. Plex, Netflix, etc."

    - tag: sl-sr-tivo1
      name: "Steves320"
      type: tivo
      make: TiVo
      model: "Roamio (320GB)"
      mac: "00-11-D9-35-02-A8"
      connections:
        - { type: hdmi, to: "TV HDMI2" }
        - { type: coax_ant, from: "sl-sr-spl02 port 1" }
        - { type: ethernet, to: "sl-sr-sw1 port 1" }
        - { type: power, to: "sl-sr-pwr1" }
      status: active
      notes: "Antenna DVR. TiVo service active."
```

## Related

- [plex-lan-only-pattern](../../portals/plex/plex-lan-only-pattern.md) — media server config
- [site-physical-inventory-pattern](../deployments/site-physical-inventory-pattern.md) — overall physical infra
- [netstack portals/plex/README.md](../../portals/plex/README.md) — Plex federation notes
- [netstack#16](https://github.com/2cld/netstack/issues/16) — federation dashboard (config-driven docs)
