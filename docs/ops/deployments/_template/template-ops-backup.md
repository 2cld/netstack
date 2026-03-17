[edit](https://github.com/2cld/xx/edit/master/docs/ops/backup.md) or [../](../.)
# xx Backup

Backup procedures follow [netstack backup guide](https://netstack.org/docs/ops/backup/).

## Backup Targets

| source | destination | method | schedule |
|--------|-------------|--------|----------|
| sg data | sg2 | ZFS replication | nightly |
| workstation | sg | robocopy | manual |

## Scripts

```powershell
# example backup script
robocopy \\source\share D:\backup /s /e /z /log:D:\backup-log.txt
```

## Restore Notes
- tbd
