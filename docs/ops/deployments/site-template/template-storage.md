[edit](https://github.com/2cld/xx/edit/master/docs/storage.md) or [./](.)
# xx Storage

Storage architecture follows [netstack storage model](https://netstack.org/docs/lan/storage/).

## NAS Shares

| share | path | protocol | notes |
|-------|------|----------|-------|
| media | \\x.x.x.2\media | SMB | media files |
| backup | \\x.x.x.2\backup | SMB | backup target |

## Plex Library Mappings

| drive | path | library | location |
|-------|------|---------|----------|
| M: | \\x.x.x.2\media | Movies | local NAS |
