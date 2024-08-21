[edit](https://github.com/2cld/netstack/edit/master/docs/ops/backup/README.md)

# backup proceedure for netstack ops
- [backup-catMediaShare](backup-catMediaShare.md) powershell
- [backup-diagram](backup-diagram.md)
- scripts
- [backup powershell script](https://netstack.org/docs/ops/backup/backup-powershell-script)
- [robocopy backup for powershell](https://netstack.org/docs/ops/backup/#robocopy)
- [vortexbox](./vortexbox/)


## rsync
Use rsync on windows via bash to move nstestShare (on c:) to network volume
```
rsync -avzP /mnt/c/nstestShare 'ssh -p22' buadmin@192.168.128.3:/volume1/bg/rsync
```
```
rsync -azrvP -e 'ssh -p 2020'  /mnt/d/cattvDVR/Hogan* buadmin@192.168.2.105:/volume1/pshare/tvOld/
```
- r recursive
- v verbose
- n or --dry-run do not sync, just list what it would do
- P or --partial --progress allow partial show progress
- e environment
- dir test/ - transfer file within the directory into target dir, just the files
- dir test  - transfer file directory into target dir, test and the files in test
- [sync-local-and-remote-directories](https://www.digitalocean.com/community/tutorials/how-to-use-rsync-to-sync-local-and-remote-directories)
rsync -avz -e "ssh -p 2232" SRC/ user@remote.host:/DEST/ 
```
df -lk  | grep D: | awk '{print "B0010B "$2" "$3" "$4}' >> /cygdrive/z/_backupLogs/B0010B.txt; du -sk --time * | awk '{print $4" "$1" "$2" B0010B"}' >> /cygdrive/z/_backupLogs/B0010B.txt
```
```
df -lk  | grep D: | awk '{print "B0010B "$2" "$3" "$4}' >> /cygdrive/z/_backupLogs/B0010B.txt
```
```
du -sk --time * | awk '{print $4" "$1" "$2" B0010B"}' >> /cygdrive/z/_backupLogs/B0010B.txt
```

## robocopy

```powershell
robocopy c:\source \\srv-vm2\share /v /log:c:\it\logs.txt
```

```powereshell
robocopy \\SG\CATMediaShare\11_CAT_Services D:\CATMediaShare\11_CAT_Services /s /e /z /log:D:\CATMediaShare\11_CAT_Services-log.txt
```
- /s - include empty dir
- /e - everything including sub dir
- /z - pick up where it left off on failure

```powereshell
robocopy \\SG\CATMediaShare\11_CAT_Services D:\CATMediaShare\11_CAT_Services /s /e /z /i 
```
- /i - test do not preform

### example check
- run on cybertruck to verify show transfer before removing
```powsershell
PS C:\WINDOWS\system32> robocopy "\\192.168.6.6\pshare\catShows\Family Ties (1982)\/" "C:\Video\Family Ties (1982)\/" /s /e /z /l /log:C:\Video\checkFamilyTieslog.txt

 Log File : C:\Video\checkFamilyTieslog.txt
PS C:\WINDOWS\system32> cat C:\Video\checkFamilyTieslog.txt

-------------------------------------------------------------------------------
   ROBOCOPY     ::     Robust File Copy for Windows
-------------------------------------------------------------------------------

  Started : Wednesday, August 21, 2024 8:29:22 AM
   Source : \\192.168.6.6\pshare\catShows\Family Ties (1982)\
     Dest : C:\Video\Family Ties (1982)\

    Files : *.*

  Options : *.* /L /S /E /DCOPY:DA /COPY:DAT /Z /R:1000000 /W:30

------------------------------------------------------------------------------

                           0    \\192.168.6.6\pshare\catShows\Family Ties (1982)\
                          22    \\192.168.6.6\pshare\catShows\Family Ties (1982)\Family Ties (1982) S01\
                          24    \\192.168.6.6\pshare\catShows\Family Ties (1982)\Family Ties (1982) S02\
                          25    \\192.168.6.6\pshare\catShows\Family Ties (1982)\Family Ties (1982) S03\
                          20    \\192.168.6.6\pshare\catShows\Family Ties (1982)\Family Ties (1982) S04\

------------------------------------------------------------------------------

               Total    Copied   Skipped  Mismatch    FAILED    Extras
    Dirs :         5         0         5         0         0         0
   Files :        91         0        91         0         0         0
   Bytes : 102.685 g         0 102.685 g         0         0         0
   Times :   0:00:00   0:00:00                       0:00:00   0:00:00
   Ended : Wednesday, August 21, 2024 8:29:22 AM

PS C:\WINDOWS\system32>
```
- run powershell
```powsershell
tbd
```

### Resources
- [rsync on synology](https://www.synology.com/en-global/knowledgebase/DSM/help/DSM/AdminCenter/application_backupserv_sharedfoldersync)
- [rsync from windows 10](https://www.linux.com/training-tutorials/most-useful-linux-commands-you-can-run-windows-10/)
- [Setup ssh access on windows 10](https://www.hanselman.com/blog/HowToSSHIntoAWindows10MachineFromLinuxORWindowsORAnywhere.aspx)
- [Could not chdir to home dir /var/services/homes/buadmin](https://www.linuxquestions.org/questions/linux-newbie-8/%27could-not-chdir-to-home-directory-home-%5Buser%5D-permission-denied%27-780328/)
