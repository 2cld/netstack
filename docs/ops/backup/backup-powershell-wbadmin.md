# windows backup admin

To perform a backup of Windows 11 Pro using PowerShell, you can utilize the wbadmin command. A specific example is below , which creates a full backup of the C: drive (including all critical components) and saves it to the E: drive. This command is equivalent to using the "Create a system image" option in the Control Panel's Backup and Restore (Windows 7) feature.
```
wbadmin start backup -backupTarget:E: -include:C: -quiet -allCritical
```

Here's a breakdown of the command:
wbadmin start backup: This initiates a backup operation. 
-backupTarget:E:: Specifies the drive (E:) where the backup will be stored. 
-include:C:: Indicates that the C: drive (including all its contents) should be included in the backup. 
-quiet: This switch suppresses any confirmation prompts or status messages, making the backup run silently. 
-allCritical: Ensures that all critical components of the system are included in the backup, guaranteeing a complete system image, according to Microsoft Community. 

Important Considerations:

Administrative Privileges:
You need to run PowerShell with administrator rights to execute the wbadmin command. 

Storage Location:
Ensure the backup target drive (e.g., E:) has enough free space to accommodate the backup. 

Alternative Cmdlets:
If you need more granular control over backup items, you can explore other cmdlets like New-WBPolicy, Add-WBFileSpec, and Add-WBVolume. 

Windows Server Backup Feature:
While the wbadmin command is built-in, the Windows Server Backup feature itself needs to be installed for it to work optimally. 

You can install it using 
```
Install-WindowsFeature -Name Windows-Server-Backup
```

# Review
Windows backup / image
https://www.hirensbootcd.org/download/
https://www.youtube.com/watch?v=KcFANbzgyoo

Setup Windows 11 perfectly
https://www.youtube.com/watch?v=wAUjrvGTvMs

https://www.youtube.com/@CyberCPU/videos

