[edit](https://github.com/2cld/netstack/edit/master/docs/ops/backup/storage-cleanup-windows.md) --> [...](./)
# storage cleanup for windows

- youtube [Freeup Storage in Windows 10 11](https://youtu.be/kg055pAz9xA)
- RUN (ctrl c, ctrl v): and delete from
  - prefetch 
  - temp
  - %temp%
  - %appdata%
- Delete Windows.old if exists
- Right click C:, properties -> Tools -> Optimize (and turn on weekly optimize)
- C:\Windows\SoftwareDistribution - delete all
- run %appdata% -> Local -> Nivida glcache (and AMD) clear shaders cache
- DiskCleanup c: check everything you can
- Remove unused apps
- Local Disk search "SIZE:Gigantic" or Huge to see big files
- Settings -> System -> Storage shows storage useage

---

To reduce the size of the Windows folder, you can utilize built-in tools like Disk Cleanup and DISM, or manually remove unnecessary files. Additionally, compressing folders can help reduce their overall size. 
Here's a breakdown of methods:
1. Using Disk Cleanup:
- Open Disk Cleanup: Search for "Disk Cleanup" in the Windows search bar and select it. 
- Select the C: drive: If you have multiple drives, choose the one containing the Windows folder. 
- Clean up system files: Click "Clean up system files" to remove temporary files, old Windows Update files, and other unnecessary data. 
- Check all items: In the "Files to delete" list, check all the boxes to remove as much data as possible. 
- Confirm and wait: Click "OK" and confirm the deletion to free up space. 
2. Using DISM:
- Open Command Prompt as administrator: Search for "cmd", right-click, and select "Run as administrator". 
- Run the DISM command: This command removes superseded components from Windows updates.
  ```
  Dism.exe /online /Cleanup-Image /StartComponentCleanup /ResetBase
  ```
- Run the command for WinSxS cleanup: This command can reduce the size of the WinSxS folder. 
  ```
  Dism.exe /online /Cleanup-Image /StartComponentCleanup
  ```
3. Removing Unnecessary Files: 
- Uninstall unused applications:
.
Go to Settings > Apps > Apps & features to remove programs you no longer use. 
- Delete temporary files:
.
You can manually delete files from the Temp folder (C:\Windows\Temp and %temp%). 
- Clear your browser cache:
.
Clear the cache and browsing data of your web browsers (Chrome, Firefox, etc.). 
- Remove old drivers:
.
Use tools like DriverStore Explorer to remove outdated or unused device drivers. 
Delete downloaded installations:
.
- Delete files in C:\Windows\Downloaded Installations and C:\Windows\SoftwareDistribution\Download. 

4. Compressing Folders:
- Compress the entire Windows folder:
.
Right-click the Windows folder, select Properties, go to Advanced, and check "Compress contents to save disk space".
Compress individual folders:
.
- You can also compress specific folders within the Windows directory if you want to save space without affecting the entire folder. 

5. Additional Tips:
- Disable hibernation:
.
If you don't use hibernation mode, you can disable it to remove the large hiberfil.sys file from the root C: directory. 
- Move the page file:
.
If you have another drive, you can move the page file (swap file) to it to reduce the load on the C: drive. 
Use a disk space analyzer:
.
- Tools like WinDirStat can help visualize which folders and files are taking up the most space, allowing you to focus your cleanup efforts. 
