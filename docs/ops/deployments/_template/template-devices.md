[edit](https://github.com/2cld/xx/edit/master/docs/devices.md) or [./](.)
# xx Devices

## DHCP Reservations

| name | IP | mac | notes |
|------|----|-----|-------|
| ng (router) | x.x.x.1 | 00:00:00:00:00:00 | network gateway |
| sg (NAS) | x.x.x.2 | 00:00:00:00:00:00 | storage gateway |
| cg (hypervisor) | x.x.x.3 | 00:00:00:00:00:00 | compute gateway |
| workstation1 | x.x.x.10 | 00:00:00:00:00:00 | - |

## VMs / Containers

| name | IP | host | type | status |
|------|----|------|------|--------|
| vm-example | x.x.x.100 | cg | vm | active |
| ct-docker | x.x.x.103 | cg | lxc | active |
