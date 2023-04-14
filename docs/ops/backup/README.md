# backup proceedure for netstack ops
- [backup-catMediaShare](backup-catMediaShare.md) powershell
- [backup-diagram](backup-diagram.md)

## rsync
Use rsync on windows via bash to move nstestShare (on c:) to network volume
```
rsync -avzP /mnt/c/nstestShare 'ssh -p22' buadmin@192.168.128.3:/volume1/bg/rsync
```
```
rsync -rv -e 'ssh -p 2020'  /mnt/d/cattvDVR/Hogan* buadmin@192.168.2.105:/volume1/pshare/tvOld/
```

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

### Resources
- [rsync on synology](https://www.synology.com/en-global/knowledgebase/DSM/help/DSM/AdminCenter/application_backupserv_sharedfoldersync)
- [rsync from windows 10](https://www.linux.com/training-tutorials/most-useful-linux-commands-you-can-run-windows-10/)
- [Setup ssh access on windows 10](https://www.hanselman.com/blog/HowToSSHIntoAWindows10MachineFromLinuxORWindowsORAnywhere.aspx)
- [Could not chdir to home dir /var/services/homes/buadmin](https://www.linuxquestions.org/questions/linux-newbie-8/%27could-not-chdir-to-home-directory-home-%5Buser%5D-permission-denied%27-780328/)
