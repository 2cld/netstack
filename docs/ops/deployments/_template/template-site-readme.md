[edit](https://github.com/2cld/xx/edit/master/docs/README.md)
# xx - SITENAME
- [https://xx.2cld.net](https://xx.2cld.net) and [https://github.com/2cld/xx](https://github.com/2cld/xx)
- PIP: x.x.x.x
- Architecture based on [netstack LAN model](https://netstack.org/docs/lan/)

## Site Summary

| role | IP | service | notes |
|------|----|---------|-------|
| ng | x.x.x.1 | - | network gateway |
| sg | x.x.x.2 | - | storage gateway |
| cg | x.x.x.3 | - | compute gateway |
| ng2 | x.x.x.5 | - | network gateway secondary |
| sg2 | x.x.x.6 | - | storage gateway secondary |
| cg2 | x.x.x.7 | - | compute gateway secondary |

## Docs

- [devices](./devices) - device inventory, DHCP, MACs
- [services](./services) - running services and URLs
- [tunnels](./tunnels) - cloudflare tunnel config
- [storage](./storage) - NAS mappings, plex libraries
- [ops/backup](./ops/backup) - site backup procedures
- [ops/notes](./ops/notes) - maintenance log
