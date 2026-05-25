# Site Template

Copy this folder into a new site repo (e.g. `xx.2cld.net`) and fill in the blanks. Replace `xx` with your site code, `SITENAME` with the location name, and update all placeholder values.

## Site repo structure

```
docs/
  README.md          # site overview (copy from template-site-readme.md)
  devices.md         # device inventory (copy from template-devices.md)
  services.md        # running services (copy from template-services.md)
  tunnels.md         # cloudflare tunnels (copy from template-tunnels.md)
  storage.md         # NAS and plex mappings (copy from template-storage.md)
  ops/
    backup.md        # site-specific backup (copy from template-ops-backup.md)
    notes.md         # maintenance log (copy from template-ops-notes.md)
```

## After creating the site repo

1. Set up `nsadmin` operator account per [ops-node-setup](https://netstack.org/docs/ops/users/ops-node-setup/)
2. Copy template files into `docs/` in the new repo
3. Fill in site-specific values (IPs, MACs, services)
4. Enable GitHub Pages on the repo
5. Add CNAME file with `xx.2cld.net`
6. Add DNS record pointing to GitHub Pages
7. Add the site to [netstack deployments](https://netstack.org/docs/ops/deployments/)

## Linking back to netstack

All work follows the [pattern-workflow](https://netstack.org/docs/ops/pattern-workflow/): netstack holds the Why/How/Where, site repos hold the What. Never duplicate explanations — link to netstack patterns instead.

Each site repo should reference netstack for architecture and install guides rather than duplicating them. Use links like:
- `Based on [netstack LAN model](https://netstack.org/docs/lan/)`
- `Installed per [netstack proxmox guide](https://netstack.org/docs/lan/compute/proxmox/)`
- `Backup procedures follow [netstack backup](https://netstack.org/docs/ops/backup/)`
- `Operator setup per [netstack ops-node-setup](https://netstack.org/docs/ops/users/ops-node-setup/)`
