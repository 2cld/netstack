[edit](https://github.com/2cld/xx/edit/master/docs/services.md) or [./](.)
# xx Services

## Network Services

| service | url | host | notes |
|---------|-----|------|-------|
| ng admin | [http://x.x.x.1/](http://x.x.x.1/) | router | network gateway |
| sg admin | [http://x.x.x.2/](http://x.x.x.2/) | NAS | storage admin |
| cg admin | [https://x.x.x.3:8006/](https://x.x.x.3:8006/) | proxmox | compute admin |
| portainer | [http://x.x.x.103:9000](http://x.x.x.103:9000) | docker ct | container mgmt |

## Plex Instances

| service | url | host |
|---------|-----|------|
| plex-main | [http://x.x.x.y:32400/](http://x.x.x.y:32400/) | - |

## Port Forwards (external)

| external port | internal | IP | service |
|---------------|----------|----|---------|
| 32400 | 32400 | x.x.x.y | plex |
