# Security Notice

Some documentation in this repository contains internal network addresses and configuration details from development/lab environments. These are being migrated to private site repos per the [sensitive data pattern](./ops/security/sensitive-data-pattern.md).

## Status

| Area | Scrubbed | Notes |
|------|:--------:|-------|
| docs/ops/security/ | ✅ | Pattern docs, no real data |
| docs/ops/tools/ | ✅ | Methodology only |
| docs/ops/monitor/ | ✅ | Pattern only |
| docs/ops/backup/ | ✅ | Sanitized |
| docs/ops/storage-index/ | ✅ | Sanitized |
| docs/ops/deployments/ | ✅ | Sanitized (links to private repos) |
| docs/wan/zerotier/ | ⚠️ | bridge.md cleaned, README.md has old device list |
| docs/wan/cloudflare/ | ⚠️ | Has tunnel configs with IPs |
| docs/lan/ | ⚠️ | Install guides reference specific hosts |
| docs/portals/ | ⚠️ | Some reference internal URLs |
| docs/ops/users/ | ⚠️ | Dev setup docs reference hosts |

Files marked ⚠️ contain lab/internal addresses that are being cleaned up incrementally. The actual infrastructure details are in the private site repos (cf, sl, wf).

## What's safe to publish (per sensitive-data-pattern)

- Architecture patterns and methodology
- Tool names and usage instructions
- Template configurations with placeholder values
- Public service URLs (*.cat9.me, *.2cld.com, etc.)

## What should be in private repos only

- Internal IP addresses
- VPN overlay addresses and network IDs
- MAC addresses
- SSH connection strings with real hosts
- Cloudflare account/tunnel IDs
