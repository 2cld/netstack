# Proxmox VM/CT Service Pattern

**Applies to:** Any VM or container managed by Proxmox VE at a federation site.

## Principle

A Proxmox VM/CT must be reproducible from its configuration + data backup. The VM description field is a **breadcrumb**, not the source of truth. Source of truth lives in the site repo.

## The Problem

Proxmox helper scripts (e.g., [tteck](https://tteck.github.io/Proxmox/)) create VMs/CTs with notes in the description field. Over time:
- Notes get outdated
- Config drifts from what was documented
- If the Proxmox host dies, the description is lost with it

## Correct Pattern

```
<site-repo>/ops/compute/
├── README.md                    # CG overview - what VMs exist and why
├── <vmid>-<name>.md             # Per-VM manifest (git = source of truth)
└── <vmid>-<name>.conf           # Copy of /etc/pve/qemu-server/<vmid>.conf
```

**Proxmox description field** contains only a breadcrumb:
```
Manifest: https://github.com/2cld/<site>/blob/main/ops/compute/<vmid>-<name>.md
Pattern: https://netstack.org/docs/lan/compute/proxmox/proxmox-service-pattern/
```

## VM Manifest (per-VM doc in site repo)

```markdown
# VM <id> - <name>

## Purpose
What this VM does and why it exists.

## Build Method
- [ ] Helper script: <URL to tteck or custom script>
- [ ] Manual install: <ISO + steps>
- [ ] Import: <source of VM image>

## Configuration
- VMID: <id>
- Node: <proxmox-host>
- OS: <os type + version>
- CPU: <cores>
- RAM: <MB>
- Disk: <storage>:<size>
- Network: <bridge>, IP: <static or DHCP>
- Start on boot: <yes/no>

## Services Running Inside
- <service>: <what it does, port>
- Docker: <yes/no> (if yes, follow docker-service-pattern)

## Access
- SSH: <user@ip:port>
- Web: <url>
- Console: Proxmox UI -> VM <id>

## Data (what needs backup)
- <path>: <what> (backed up by: <method>)

## Rebuild Steps
1. <step to recreate from scratch>
2. <or: restore from backup>

## History
- <date>: Created via <method>
- <date>: <changes>
```

## How to Extract from Existing VMs

For VMs that already exist (like VM 100 on cg2):

```bash
# Get the Proxmox config
cat /etc/pve/qemu-server/<vmid>.conf

# Get the description (often has the helper-script notes)
qm config <vmid> | grep description

# URL-decode the description (Proxmox URL-encodes it)
qm config <vmid> | grep description | python3 -c "import sys,urllib.parse; print(urllib.parse.unquote(sys.stdin.read()))"

# List what's running inside (if VM is on)
qm guest exec <vmid> -- cat /etc/os-release
qm guest exec <vmid> -- docker ps
```

Save output to site repo as `<vmid>-<name>-extract.txt`, then build the proper manifest from it.

## CG (Compute Gateway) Naming

The `cg` prefix in netstack means "compute gateway" - any hypervisor platform:

| Platform | Use Case | Site Examples |
|----------|----------|--------------|
| Proxmox VE | Full hypervisor (VMs + CTs + ZFS) | cg2 at wf, cg2 at cf |
| Hyper-V | Windows VMs | CyberTruck at cf |
| Docker | Containers only (no full VMs) | nsdockerhv at cf |
| VirtualBox | Dev/test VMs | legacy (old catmini, etc.) |

Same pattern applies regardless of platform - manifest in repo, breadcrumb on host.

## Proxmox Helper Scripts

[tteck helper scripts](https://tteck.github.io/Proxmox/) automate VM/CT creation. When using them:

1. **Record which script was used** in the manifest (URL + date)
2. **Record any modifications** you made after the script ran
3. **The script IS the build step** - if you can re-run it and get the same result, the VM is reproducible

## Monitoring

Add VMs to site status script:
```bash
# From the Proxmox host:
qm list | awk '{print $1, $2, $3}' # VMID, Name, Status
```

## Related

- [docker-service-pattern](./docker/docker-service-pattern.md) - for Docker services inside VMs
- [ops-node-setup](../../ops/users/ops-node-setup.md) - host environment
- [service-lifecycle-pattern](../../ops/tools/service-lifecycle-pattern.md) - migration gates
- [federation-setup-guide](../../ops/deployments/federation-setup-guide.md) - site standup
