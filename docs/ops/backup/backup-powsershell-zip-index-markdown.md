# PowerShell - Zip File Index to Markdown

Generate a text or markdown index of files inside a `.zip` archive using built-in Windows 11 PowerShell. Handy for leaving a manifest alongside your backup zips.

## Quick Text Index

```powershell
$zip = "MyBackup.zip"
[System.IO.Compression.ZipFile]::OpenRead($zip).Entries |
  Sort-Object FullName |
  Format-Table FullName, Length, @{N='LastModified';E={$_.LastWriteTime}} -AutoSize |
  Out-File "$zip.txt"
```

Produces `MyBackup.zip.txt` next to the archive.

## Markdown Table Index

```powershell
$zip = "MyBackup.zip"
$entries = [System.IO.Compression.ZipFile]::OpenRead($zip).Entries | Sort-Object FullName
$lines = @("# Index of $zip", "", "| File | Size (bytes) | Last Modified |", "|------|-------------|---------------|")
foreach ($e in $entries) {
    $lines += "| $($e.FullName) | $($e.Length) | $($e.LastWriteTime) |"
}
$lines | Out-File "$zip.md" -Encoding utf8
```

Produces `MyBackup.zip.md` with a nicely formatted table.

## Batch Process All Zips in a Folder

```powershell
Get-ChildItem *.zip | ForEach-Object {
    $zip = $_.FullName
    $entries = [System.IO.Compression.ZipFile]::OpenRead($zip).Entries | Sort-Object FullName
    $lines = @("# Index of $($_.Name)", "", "| File | Size (bytes) | Last Modified |", "|------|-------------|---------------|")
    foreach ($e in $entries) {
        $lines += "| $($e.FullName) | $($e.Length) | $($e.LastWriteTime) |"
    }
    $lines | Out-File "$zip.md" -Encoding utf8
}
```

## Notes

- Windows 11 PowerShell 5.1+ has `System.IO.Compression.FileSystem` loaded by default. On older versions add this first:
  ```powershell
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  ```
- For human-readable sizes swap `$e.Length` with:
  ```powershell
  "{0:N2} MB" -f ($e.Length / 1MB)
  ```
