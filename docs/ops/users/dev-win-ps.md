# Powershell 

## Map network drive

```powershell
$username = "domain\username"
$password = ConvertTo-SecureString "password" -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($username, $password)
New-PSDrive -Name "DriveLetter" -PSProvider FileSystem -Root "\\server\share" -Credential $credential -Persist
```

- Replace "DriveLetter" with the desired drive letter
- Networkpath "\\server\share" with the actual network path
- User "domain\username" with the appropriate username
- Password "password" with the corresponding password.
- The -Persist parameter ensures the mapping persists after reboot.
  
Alternatively, Get-Credential can be used to prompt for credentials:

```powershell
$credential = Get-Credential
New-PSDrive -Name "DriveLetter" -PSProvider FileSystem -Root "\\server\share" -Credential $credential -Persist
```
