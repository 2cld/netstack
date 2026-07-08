# site-config.yml — Physical Infrastructure Schema

**Purpose:** Capture format for physical infrastructure during site inventory.
**Pattern:** To be documented in netstack as `docs/ops/deployments/site-physical-inventory-pattern.md`
**Use case:** Walk through a site tagging boxes, tracing cables, labeling power — record it all here.

## Schema: `sg.drives` — Storage with Physical Identity + Purpose

Each drive entry captures physical identity (for tracing to hardware), purpose classification, and sub-roles:

```yaml
sg:
  drives:
    - letter: "F:"                         # Drive letter (Windows) or mount point (Linux)
      label: "slDriveF"                    # Filesystem label
      model: "WDC WD20EARX-00PASB0"       # Physical disk model
      serial: "WD-WCAZAC880243"            # Physical disk serial (unique ID)
      bus: "SATA"                          # Bus type: SATA, NVMe, USB, SAS
      size_gb: 1863                        # Total capacity
      free_gb: 884                         # Current free space
      purpose: "Media + Federation Backup" # Short classification (appears in tables)
      roles:                               # Detailed breakdown of what lives here
        - "Plex media libraries (Movies, TV, Music, DVR)"
        - "Federation backup reception from cf (catbu-sl/)"
        - "hwpc-rp backup archives"
      alert_below_pct: 10                  # Alert when free < this %
```

### Purpose Tag Convention

Standard purpose tags (pick one or combine with `+`):

| Tag | Meaning |
|-----|---------|
| `OS` | Operating system boot drive |
| `Workstation` | User apps, profiles, daily-use data |
| `WSL` | WSL root filesystem and Docker data |
| `Media` | Plex/Jellyfin media libraries (reproducible) |
| `Federation Backup` | Receives backups from other sites |
| `Local Backup` | Local backup staging or rotation |
| `Compute` | VM storage, container volumes |
| `Archive` | Long-term cold storage (glacial) |
| `Scratch` | Temporary, ephemeral (transcode cache, build artifacts) |

Examples:
- `"OS + Workstation"` — boot drive with apps
- `"Media + Federation Backup"` — shared media and backup target
- `"WSL + Local Backup"` — Docker data lives here, also staging area
- `"Archive"` — glacial storage (like wf L: drive)

### Why Serial Numbers Matter

- **DR:** Know exactly which physical disk to pull/replace
- **Backup tracing:** "This backup lives on disk serial X in bay Y"
- **Hardware failure:** Match SMART alerts to specific drive by serial
- **Inventory:** Cross-reference with `physical.equipment` tags

```yaml
# --- PHYSICAL INFRASTRUCTURE ---
# Captures: locations, switches, cable plant, power, rack/shelf positions
# Tag convention: <site><room-code><type><number> (e.g., sl-bm-sw3 = sl basement switch 3)

physical:

  # --- LOCATIONS (rooms/areas) ---
  locations:
    - code: sr        # Tag prefix for this room
      name: "Steve's Room"
      floor: main
      notes: "Front bedroom, router + modem + primary switch"
    - code: lr
      name: "Living Room"
      floor: main
      notes: "Switch 2, media devices, Roku, TiVo"
    - code: bm
      name: "Basement"
      floor: basement
      notes: "Switch 3, servers, NAS, compute"
    - code: at
      name: "Attic"
      floor: attic
      notes: "Antenna, coax amp"

  # --- SWITCHES (network switches, patch points) ---
  switches:
    - tag: sl-sr-sw1
      name: "Switch 1 (main)"
      location: sr
      model: "TP-Link 5-port"  # or whatever it actually is
      ports: 5
      uplink: "ISP modem (Spectrum)"
      connections:
        - port: 1
          to: "Steves320 TiVo"
          mac: "00-11-D9-35-02-A8"
          ip: "192.168.1.12"
          cable_tag: "sl-sr-eth01"
        - port: 2
          to: "Steves640 TiVo"
          mac: "00-11-D9-5F-47-82"
          ip: "192.168.1.11"
          cable_tag: "sl-sr-eth02"
        - port: 3
          to: "HDHomeRun tuner"
          mac: "00-18-DD-08-02-95"
          ip: "192.168.1.78"
          cable_tag: "sl-sr-eth03"
        - port: 4
          to: "sw2 (living room)"
          cable_tag: "sl-run-sw1-sw2"
          type: "uplink"
        - port: 5
          to: "unused"

    - tag: sl-lr-sw2
      name: "Switch 2 (living room)"
      location: lr
      model: "TBD"
      ports: 5
      uplink: "sw1 port 4"
      connections:
        - port: 1
          to: "KathysRokuUltra"
          mac: "84-EA-ED-A8-64-91"
          ip: "192.168.1.21"
        - port: 2
          to: "Kathys160 TiVo"
          mac: "00-11-D9-38-0B-FC"
          ip: "192.168.1.22"
        - port: 3
          to: "unused"
        - port: 4
          to: "sw3 (basement)"
          cable_tag: "sl-run-sw2-sw3"
          type: "uplink"
        - port: 5
          to: "sw1 (uplink)"
          type: "uplink"

    - tag: sl-bm-sw3
      name: "Switch 3 (basement)"
      location: bm
      model: "TBD"
      ports: 5
      uplink: "sw2 port 4"
      connections:
        - port: 1
          to: "sw2 (uplink)"
          type: "uplink"
        - port: 2
          to: "sg2 (QNAP NAS)"
          mac: "00-08-9B-E2-83-93"
          ip: "192.168.1.6"
          cable_tag: "sl-bm-eth01"
          status: "down"
        - port: 3
          to: "slwin11ops"
          mac: "B0-83-FE-65-80-80"
          ip: "192.168.1.194"
          cable_tag: "sl-bm-eth02"
        - port: 4
          to: "catSurface (when here)"
          cable_tag: "sl-bm-eth03"
          status: "occasional"
        - port: 5
          to: "unused"

  # --- CABLE RUNS (ethernet, between rooms) ---
  cable_runs:
    - tag: sl-run-sw1-sw2
      type: ethernet
      category: "cat5e"  # or cat6, etc.
      from: { location: sr, device: "sw1 port 4" }
      to: { location: lr, device: "sw2 port 5" }
      length_ft: 25
      route: "Through wall, sr → lr"
      verified: "2026-07-01"

    - tag: sl-run-sw2-sw3
      type: ethernet
      category: "cat5e"
      from: { location: lr, device: "sw2 port 4" }
      to: { location: bm, device: "sw3 port 1" }
      length_ft: 30
      route: "Through floor, lr → basement"
      verified: "2026-07-01"

  # --- COAX PLANT ---
  coax:
    antenna:
      source: "Main antenna (attic)"
      amp: { location: bm, tag: "sl-bm-coaxamp1" }
      splitters:
        - tag: sl-bm-spl01
          location: bm
          input: "coax amp output"
          outputs:
            - port: 1
              to: "sl-sr-spl02 (Steve's room)"
              cable_tag: "sl-run-coax-bm-sr"
            - port: 2
              to: "Kathys160 TiVo ant"
              cable_tag: "sl-run-coax-bm-lr"

        - tag: sl-sr-spl02
          location: sr
          input: "spl01 port 1"
          outputs:
            - port: 1
              to: "Steves320 TiVo ant"
            - port: 2
              to: "HDHomeRun tuner ant"

    cable:  # cable TV / ISP coax
      source: "Spectrum cable entry (sr)"
      splitters:
        - tag: sl-sr-spl03
          location: sr
          input: "Spectrum cable"
          outputs:
            - port: 1
              to: "Spectrum modem"
            - port: 2
              to: "sl-sr-spl04"

        - tag: sl-sr-spl04
          location: sr
          input: "spl03 port 2"
          outputs:
            - port: 1
              to: "Steves640 TiVo cable"
            - port: 2
              to: "Kathys160 cable"
            - port: 3
              to: "unused"
            - port: 4
              to: "unused"

  # --- POWER ---
  power:
    circuits:
      - tag: sl-bm-pwr1
        location: bm
        breaker: "Panel A, breaker 7"  # or however it's labeled
        outlets:
          - tag: sl-bm-pwr1-out1
            devices: ["slwin11ops", "sg2"]
            surge_protector: true
            ups: false
            notes: "Both servers on same circuit — no UPS"

      - tag: sl-sr-pwr1
        location: sr
        breaker: "Panel A, breaker 3"
        outlets:
          - tag: sl-sr-pwr1-out1
            devices: ["Spectrum modem", "TP-Link router", "sw1"]
            surge_protector: true
            ups: false
            notes: "Internet + networking on one strip"

    notes: |
      No UPS at sl site. Power loss = everything down.
      Recovery order: modem → router → switches → slwin11ops → verify ZeroTier + Docker auto-start.
      Plex starts on Windows login (auto-start app, not service).

  # --- EQUIPMENT TAGS ---
  # Master list of tagged physical items (cross-references switches, power, cable runs)
  equipment:
    - tag: sl-bm-srv1
      name: "slwin11ops"
      type: "server"
      location: bm
      make: "Dell"
      model: "TBD (1U rackmount)"
      serial: "TBD"
      mac: "B0-83-FE-65-80-80"
      ip: "192.168.1.194"
      zt_ip: "10.147.17.94"
      switch_port: "sl-bm-sw3 port 3"
      power: "sl-bm-pwr1-out1"
      os: "Windows 11"
      role: "Primary ops, backup receiver, Docker host (WSL)"
      notes: "Has WSL Ubuntu 22.04 with Docker. SSH port 2020 (WSL), port 22 (Windows)."

    - tag: sl-bm-nas1
      name: "sg2 (QNAP)"
      type: "NAS"
      location: bm
      make: "QNAP"
      model: "TBD"
      serial: "TBD"
      mac: "00-08-9B-E2-83-93"
      ip: "192.168.1.6"
      switch_port: "sl-bm-sw3 port 2"
      power: "sl-bm-pwr1-out1"
      status: "down"
      notes: "Not currently used. Old Plex host. Evaluate: keep or decommission."

    - tag: sl-sr-rtr1
      name: "Spectrum Router"
      type: "router"
      location: sr
      make: "Spectrum (ISP-provided)"
      model: "TBD"
      ip: "192.168.1.1"
      mac: "TBD"
      switch_port: "WAN"
      power: "sl-sr-pwr1-out1"
      notes: "ISP router. DHCP server. Gateway."

    - tag: sl-sr-sw1
      name: "Switch 1"
      type: "switch"
      location: sr
      make: "TP-Link"
      model: "TBD (5-port)"
      power: "sl-sr-pwr1-out1"
      notes: "Main switch, connects to modem/router"

    - tag: sl-sr-tuner1
      name: "HDHomeRun"
      type: "tuner"
      location: sr
      make: "SiliconDust"
      model: "HDHR5-4K-DEV (CONNECT 4K)"
      serial: "10802956"
      mac: "00-18-DD-08-02-95"
      ip: "192.168.1.78"
      switch_port: "sl-sr-sw1 port 3"
      power: "sl-sr-pwr1-out1"
      firmware: "20250815"
      notes: "4 tuners. Used by Plex DVR. Antenna input from sl-sr-spl02 port 2."
```

## Tagging Convention

Format: `<site>-<location>-<type><number>`

| Prefix | Meaning |
|--------|---------|
| `sl-sr-` | sl site, Steve's Room |
| `sl-lr-` | sl site, Living Room |
| `sl-bm-` | sl site, Basement |
| `sl-at-` | sl site, Attic |
| `sl-run-` | sl site, cable run between locations |

| Type suffix | Meaning |
|-------------|---------|
| `sw` | switch |
| `srv` | server |
| `nas` | NAS/storage |
| `rtr` | router |
| `eth` | ethernet cable/patch |
| `coax` | coaxial cable |
| `spl` | splitter |
| `pwr` | power circuit/outlet |
| `tuner` | TV tuner |
| `ups` | UPS/battery backup |

## How to Use During Inventory

1. Walk room by room
2. For each device: assign tag, record make/model/serial/MAC, note switch port + power outlet
3. For each cable: assign tag, record from/to/type/length
4. For each switch: document port-by-port connections
5. Update site-config.yml with findings
6. Run generator → updated docs appear on sl.2cld.com

## Generator Output (docs pages from this schema)

From the `physical:` block, generate:

### devices.html
Table of all equipment: tag, name, location, IP, MAC, status, switch port

### network.html
Switch port maps (visual table per switch), cable runs between rooms, coax plant diagram

### power.html
Circuits, outlet assignments, surge protectors, UPS status, recovery order

### status.html
Combines digital monitoring (site-status.json) with physical inventory alerts (down devices, unverified cables)
