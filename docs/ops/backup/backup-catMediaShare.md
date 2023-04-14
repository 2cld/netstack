```
#catrobocopy yyyy-mm-dd-hh
# \\SHARESERVER TrueNAS server with "SHARENAME" https://192.168.252.2/ zfs1
# CopyA - D: NASbu01  1.91 TB NFS
# CopyB - E: NASbu02  1.91 TB NFS
# CopyC - 

# CopyA \\SHARESERVER to D: catNASbu01
#$sourceDirPath = "\\SHARESERVER\SHARENAME\"
#$destinationPath =  "D:\SHARENAME\"
#$destinationPath =  "E:\SHARENAME\"

# TODO robocopy
#-status- -DirSize g- $sourceDirName = "SHAREDIR01-2-BACKUP-NAME"
#-status- -DirSize g- $sourceDirName = "SHAREDIR01-2-BACKUP-NAME"

#debug Write-Output "mkdir $destinationPath$sourceDirName"
#debug Write-Output "robocopy $sourceDirPath$sourceDirName $destinationPath$sourceDirName /s /e /z /log:D:\CATMediaShare\$sourceDirName-log.txt"

#mkdir $destinationPath$sourceDirName
#robocopy $sourceDirPath$sourceDirName $destinationPath$sourceDirName /s /e /z /TS /NP /TEE /log:D:\CATMediaShareLogs\$sourceDirName-B-log.txt

#####
# CopyB to D: to E: catNASbu01
#$sourceDirPath   =  "D:\SHARENAME\"
#$destinationPath =  "E:\SHARENAME\"

# Verify NASbu02 NASbu01
$sourceDirPath =  "D:\SHARENAME\"
$destinationPath =  "E:\SHARENAME\"

#-status- -DirSize g- $sourceDirName = "SHAREDIR-2-BACKUP-NAME"
#-status- -DirSize g- $sourceDirName = "SHAREDIR-2-BACKUP-NAME"
#Verifed 17.801 g 17.801 g $sourceDirName = "10_Downloads"
#Verifed 15.446 g 15.446 g $sourceDirName = "11_CAT_Services"

### check should detect no files should be transfered
#robocopy $sourceDirPath$sourceDirName $destinationPath$sourceDirName /e /ts /l /TEE /log:D:\CATMediaShareLogs\$sourceDirName-Verify-log.txt
### taget blank dir to get listing of source
#robocopy $sourceDirPath$sourceDirName $destinationPath\CATMediaShareLogs\_0blanktarget\ /e /ts /l /TEE /log+:D:\CATMediaShareLogs\$sourceDirName-Verify-log.txt

### copy logs
$sourceDirPath   =  "D:\SHARENAME\"
$destinationPath =  "E:\SHARENAME\"

#robocopy $sourceDirPath $destinationPath /s /e /z /TS /NP /TEE /log:D:\SHARELOGSDIR\$sourceDirName-B-log.txt
```

PowerShell Config Notes
```powershell
#############
#info robocopy man
#info https://social.technet.microsoft.com/Forums/ie/en-US/d9640b47-ca6a-42ff-a42c-b6f2db4455da/robocopy-logfile-help?forum=win10itprogeneral
#info https://technet.microsoft.com/en-us/library/cc733145(v=ws.11).aspx
# /s - copy subdirectories
# /e -
# /z - restartable on failure
# /TS - /ts timestamp of source
# /NP - /np no progress display
# /TEE - /tee print to log and terminal
# /l - list only, do not copy or timestamp (generate log)
#https://improvingsoftware.com/2013/09/09/how-to-diff-two-folders-from-a-windows-command-prompt/
#ROBOCOPY “\\FileShare\SourceFolder” “\\FileShare\ComparisonFolder” /e /l /ns /njs /njh /ndl /fp /log:reconcile.txt
#Explanation of the command switches used above:
#/e  Recurse through sub-directories (including empty ones)
#/l  Don’t modify or copy files, log differences only
#/fp  Include the full path of files in log (only necessary if you omit /ndl)
#/ns  Don’t include file sizes in log
#/ndl  Don’t include folders in log
#/njs   Don’t include Job Summary
#/njh   Don’t include Job Header
#/log:reconcile.txt   Write log to reconcile.txt (Recreate if exists)
#/log+: reconcile.txt   (Optional variant) Write log to reconcile.txt Append

```

Powershell for cat media share backup full example for catNADbu01 D:\CATMediaShareLogs\catrobocopyCATMediaShareBackup.ps1

```powershell
#catrobocopy 2023-03-18-20
# \\SG TrueNAS server with CATMediaShare Share https://192.168.252.2/ zfs1
# D: catNASbu01  0.931 TB NFS
# E: catNASbu02  1.007 TB NFS

# CopyA to D: catNASbu01
#$sourceDirPath = "\\SG\CATMediaShare\"
#$destinationPath =  "D:\CATMediaShare\"

#DONE 17.801 g $sourceDirName = "10_Downloads"
#DONE 15.446 g $sourceDirName = "11_CAT_Services"
#DONE 273.08 m $sourceDirName = "17_CAT_VOLURI"
#DONE 27.210 g $sourceDirName = "CAT_MS" 
#wait-catbuNAS02 763.360 g $sourceDirName = "CAT_WD1TB"
#DONE  9.28  g $sourceDirName = "CAT9_hostgator_201604_arch"
#DONE  1.734 g $sourceDirName = "CAT9_HWPC"
#DONE 12.348 g $sourceDirName = "cat9_tutorials"
#DONE 17.000 g $sourceDirName = "CAT9_VirtualMachines"
#DONE  2.252 g $sourceDirName = "catminiPROJECTS"
#DONE 12.893 g $sourceDirName = "catminiTOSORT"
#wait-----------est 0.395 t $sourceDirName = "CATMovies"
#DONE  1.762 g $sourceDirName = "CATMusic"
#DONE  113.8 k $sourceDirName = "CATPhotos"
#DONE  28.49 g $sourceDirName = "CATt1"
#wait-----------est 1.950 t $sourceDirName = "CATTVShows"
#DONE   44.8 k $sourceDirName = "cf-nginx"
#DONE      0 k $sourceDirName = "drtest"
#DONE      0 k $sourceDirName = "images"
#DONE  12.38 m $sourceDirName = "Udemy"
#DONE 263.00 g $sourceDirName = "WIP"


# CopyA to E: catNASbu02
#$sourceDirPath = "\\SG\CATMediaShare\"
#$destinationPath =  "E:\CATMediaShare\"
#DONE 763.360 g $sourceDirName = "CAT_WD1TB"

#############
# CopyB to E: catNASbu02
#$sourceDirPath =  "D:\CATMediaShare\"
#$destinationPath =  "E:\CATMediaShare\"

#DONE 17.801 g 17.801 g $sourceDirName = "10_Downloads"
#DONE 15.446 g 15.446 g $sourceDirName = "11_CAT_Services"
#DONE 273.08 m 273.08 m $sourceDirName = "17_CAT_VOLURI"
#DONE 27.210 g 27.210 g $sourceDirName = "CAT_MS" 
#wait-catbuNAS02 763.360 g $sourceDirName = "CAT_WD1TB"
#DONE  9.28  g 9.280 g $sourceDirName = "CAT9_hostgator_201604_arch"
#DONE  1.734 g 1.734 g $sourceDirName = "CAT9_HWPC"
#DONE 12.348 g 12.348 g $sourceDirName = "cat9_tutorials"
#DONE 17.098 g 17.098 g $sourceDirName = "CAT9_VirtualMachines"
#DONE  2.252 g $sourceDirName = "catminiPROJECTS"
#DONE 12.893 g 12.893 g $sourceDirName = "catminiTOSORT"
#wait-----------est 0.395 t $sourceDirName = "CATMovies"
#DONE  1.762 g 1.762 g $sourceDirName = "CATMusic"
#DONE  113.8 k 113.8 k $sourceDirName = "CATPhotos"
#DONE recheck  28.49 g 28.495 g $sourceDirName = "CATt1"
#wait-----------est 1.950 t $sourceDirName = "CATTVShows"
#todo   44.8 k $sourceDirName = "cf-nginx"
#todo      0 k $sourceDirName = "drtest"
#todo      0 k $sourceDirName = "images"
#DONE  12.38 m 12.38 m $sourceDirName = "Udemy"
#DONE 263.00 g 263.005 g $sourceDirName = "WIP"

#debug Write-Output "mkdir $destinationPath$sourceDirName"
#debut Write-Output "robocopy $sourceDirPath$sourceDirName $destinationPath$sourceDirName /s /e /z /log:D:\CATMediaShare\$sourceDirName-log.txt"

#mkdir $destinationPath$sourceDirName

#robocopy $sourceDirPath$sourceDirName $destinationPath$sourceDirName /s /e /z /TS /NP /TEE /log:D:\CATMediaShareLogs\$sourceDirName-B-log.txt

#############
#info robocopy man
#info https://social.technet.microsoft.com/Forums/ie/en-US/d9640b47-ca6a-42ff-a42c-b6f2db4455da/robocopy-logfile-help?forum=win10itprogeneral
#info https://technet.microsoft.com/en-us/library/cc733145(v=ws.11).aspx
# /s - copy subdirectories
# /e -
# /z - restartable on failure
# /TS - /ts timestamp of source
# /NP - /np no progress display
# /TEE - /tee print to log and terminal
# /l - list only, do not copy or timestamp (generate log)

#https://improvingsoftware.com/2013/09/09/how-to-diff-two-folders-from-a-windows-command-prompt/

#ROBOCOPY “\\FileShare\SourceFolder” “\\FileShare\ComparisonFolder” /e /l /ns /njs /njh /ndl /fp /log:reconcile.txt

#Explanation of the command switches used above:
#/e  Recurse through sub-directories (including empty ones)
#/l  Don’t modify or copy files, log differences only
#/fp  Include the full path of files in log (only necessary if you omit /ndl)
#/ns  Don’t include file sizes in log
#/ndl  Don’t include folders in log
#/njs   Don’t include Job Summary
#/njh   Don’t include Job Header
#/log:reconcile.txt   Write log to reconcile.txt (Recreate if exists)
#/log+: reconcile.txt   (Optional variant) Write log to reconcile.txt (Append if ex

#####
# Verify catNASbu02 catNASbu01
$sourceDirPath =  "D:\CATMediaShare\"
$destinationPath =  "E:\CATMediaShare\"

#Verifed 17.801 g 17.801 g $sourceDirName = "10_Downloads"
#Verifed 15.446 g 15.446 g $sourceDirName = "11_CAT_Services"
#Verifed 273.08 m 273.08 m  $sourceDirName = "17_CAT_VOLURI"
#Verifed 27.210 g 27.210 g $sourceDirName = "CAT_MS" 
###### onlyon-catbuNAS02 763.360 g $sourceDirName = "CAT_WD1TB"
#Verifed  9.28  g 9.280 g $sourceDirName = "CAT9_hostgator_201604_arch"
#Verifed  1.734 g 1.734 g $sourceDirName = "CAT9_HWPC"
#Verifed 12.348 g 12.348 g $sourceDirName = "cat9_tutorials"
#Verifed 17.098 g 17.098 g $sourceDirName = "CAT9_VirtualMachines"
#Verifed  2.252 g $sourceDirName = "catminiPROJECTS"
#DONE 12.893 g 12.893 g $sourceDirName = "catminiTOSORT"
###### PLEX-----------est 0.395 t $sourceDirName = "CATMovie
#Verifed  1.762 g 1.762 g $sourceDirName = "CATMusic"
#Verifed  113.8 k 113.8 k $sourceDirName = "CATPhotos"
#Verified------ recheck  28.49 g 28.495 g $sourceDirName = "CATt1"
###### PLEX-----------est 1.950 t $sourceDirName = "CATTVShows"
#todo   44.8 k $sourceDirName = "cf-nginx"
#todo      0 k $sourceDirName = "drtest"
#todo      0 k $sourceDirName = "images"
#Verified  12.38 m 12.38 m $sourceDirName = "Udemy"
#Verified 263.00 g 263.005 g $sourceDirName = "WIP"

### check should detect no files should be transfered
#robocopy $sourceDirPath$sourceDirName $destinationPath$sourceDirName /e /ts /l /TEE /log:D:\CATMediaShareLogs\$sourceDirName-Verify-log.txt
### taget blank dir to get listing of source
#robocopy $sourceDirPath$sourceDirName $destinationPath\CATMediaShareLogs\_0blanktarget\ /e /ts /l /TEE /log+:D:\CATMediaShareLogs\$sourceDirName-Verify-log.txt

### copy logs
$sourceDirPath   =  "D:\CATMediaShareLogs\"
$destinationPath =  "E:\CATMediaShareLogs\"

robocopy $sourceDirPath $destinationPath /s /e /z /TS /NP /TEE /log:D:\CATMediaShareLogs\$sourceDirName-B-log.txt

```
