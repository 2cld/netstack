Powershell script

## robocopy Mirror a source directory to a destination, including subdirectories and empty ones
```
robocopy C:\SourcePath D:\DestinationPath /MIR /DCOPY:T /MT:8 /R:3 /W:1 /NP /LOG:C:\robocopy.log
```

## rsync via WSL to sync files from a Windows path to another
```
wsl rsync -av /mnt/c/SourcePath /mnt/d/DestinationPath
```

# Compare two folders
```
$folder1Items = Get-ChildItem -Path "C:\Folder1" -Recurse
$folder2Items = Get-ChildItem -Path "C:\Folder2" -Recurse
Compare-Object -ReferenceObject $folder1Items -DifferenceObject $folder2Items -Property Name, Length
```

# Check size force
```powershell
Compare-Object -ReferenceObject $folder1Items -DifferenceObject $folder2Items -Property Name, Length | Where-Object {$_.SideIndicator -eq "<="} | Copy-Item -Destination "C:\Folder3" -FromPath "C:\Folder2" -Force
```
    
# rsync
```powershell
function rsync  {
param ( $source,
        $target 
      )

$WorkDir=Get-Location
Write-Output "PATH PWD:   $WorkDir"
Write-Host "SOURCE: $source"
Write-Host "TARGET: $target"

$sourceFiles = Get-ChildItem -Path $source -Recurse
$targetFiles = Get-ChildItem -Path $target -Recurse

Write-Host "SOURCEFILES $sourceFiles"
Write-Host "TARGETFILES: $targetFiles"


if ($debug -eq $true) {
  Write-Output "Source=$source, Target=$target"
  Write-Output "sourcefiles = $sourceFiles TargetFiles = $targetFiles"
}
<#
1=1 way sync, 2=2 way sync, 3=1 way purging target files not equal with source files
#>
$syncMode = 3

#if ($sourceFiles -eq $null -or $targetFiles -eq $null) {
    if ($targetFiles -eq $null)
    {
        $targetFiles=""
    }

if ($sourceFiles -eq $null){
  Write-Host "Empty Directory encountered. Skipping file Copy."
} else
{
  $diff_command="Compare-Object -ReferenceObject $sourceFiles -DifferenceObject $targetFiles"
  Write-Host "diff command: $diff_command"

  $diff = Compare-Object -ReferenceObject $sourceFiles -DifferenceObject $targetFiles
  Write-Host "---> Different Files from SOURCE to TARGET: $diff"

  #$diff_target = Compare-Object -ReferenceObject $targetFiles  -DifferenceObject  $sourceFiles
  #Write-Host "---> Different Files from TARGET to SOURCE: $diff_target"

  foreach ($f in $diff) {
    Write-Host "--> Indicator: $f.SideIndicator "
    if ($f.SideIndicator -eq "<=") {
      $fullSourceObject = $f.InputObject.FullName
      $fullTargetObject = $f.InputObject.FullName.Replace($source,$target)

      Write-Host "Attempt to copy the following <= SourceTarget: " $fullSourceObject
      Copy-Item -Path $fullSourceObject -Destination $fullTargetObject
    }


    if ($f.SideIndicator -eq "=>" -and $syncMode -eq 2) {
      $fullSourceObject = $f.InputObject.FullName
      $fullTargetObject = $f.InputObject.FullName.Replace($target,$source)

      Write-Host "Attempt to copy the following => TargetSource: " $fullSourceObject
      Copy-Item -Path $fullSourceObject -Destination $fullTargetObject
    }

    if ($f.SideIndicator -eq "=>" -and $syncMode -eq 3 -and $targetFiles -ne "") {
        $fullSourceObject = $f.InputObject.FullName
        $fullTargetObject = $f.InputObject.FullName.Replace($target,$source)

        Write-Host "Removing files from Target that are not present in Source=> TargetSource: " $fullSourceObject
        Write-Host "FIles that are not in source: $fullSourceObject"
        Remove-Item  $fullSourceObject 
      }

  }
}
```
