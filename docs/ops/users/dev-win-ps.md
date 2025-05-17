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


## Bluetooth Devices

https://stackoverflow.com/questions/71736070/how-to-get-bluetooth-device-battery-percentage-using-powershell-on-windows

- catSurface - C:\Users\chris\Documents\WindowsPowerShell\BluetoothBattery.ps1

```powershell
  # https://stackoverflow.com/questions/71736070/how-to-get-bluetooth-device-battery-percentage-using-powershell-on-windows
  Get-PnpDevice -Class "Bluetooth" 
  
  Write-Host "... Netstack ... For more info got to:"
  Write-Host "https://netstack.org/docs/ops/users/dev-win-ps"
  <#
  Get-PnpDevice -FriendlyName "*<Device Name>*" | ForEach-Object {
      $local:test = $_ |
      Get-PnpDeviceProperty -KeyName '{104EA319-6EE2-4701-BD47-8DDBF425BBE5} 2' |
          Where Type -ne Empty;
      if ($test) {
          "To query battery for $($_.FriendlyName), run the following:"
          "    Get-PnpDeviceProperty -InstanceId '$($test.InstanceId)' -KeyName '{104EA319-6EE2-4701-BD47-8DDBF425BBE5} 2' | % Data"
          ""
          "The result will look like this:";
          Get-PnpDeviceProperty -InstanceId $($test.InstanceId) -KeyName '{104EA319-6EE2-4701-BD47-8DDBF425BBE5} 2' | % Data
      }
  }
  #>
```
