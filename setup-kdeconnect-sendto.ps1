$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms

$appExe  = "C:\Program Files\WindowsApps\KDEe.V.KDEConnect_26.802.6845.0_x64__7vt06qxq7ptv8\bin\kdeconnect-app.exe"
$icoDir  = "$env:APPDATA\KDE Connect"
$icoPath = Join-Path $icoDir 'kdeconnect.ico'
if (-not (Test-Path $icoDir)) { New-Item -ItemType Directory -Path $icoDir | Out-Null }

if (Test-Path $appExe) {
    $icon = [System.Drawing.Icon]::ExtractAssociatedIcon($appExe)
    $stream = New-Object System.IO.FileStream($icoPath, [System.IO.FileMode]::Create)
    $icon.Save($stream)
    $stream.Close()
    $icon.Dispose()
    Write-Output "Icon extracted to $icoPath"
} else {
    Write-Output "WARNING: kdeconnect-app.exe not found at $appExe"
}

$ws = New-Object -ComObject WScript.Shell
$sendTo = [Environment]::GetFolderPath('SendTo')
$lnkPath = Join-Path $sendTo 'Send to Your Phone.lnk'

if (Test-Path $lnkPath) { Remove-Item $lnkPath -Force }
if (Test-Path (Join-Path $sendTo 'Send to Galaxy A25 5G.lnk')) { Remove-Item (Join-Path $sendTo 'Send to Galaxy A25 5G.lnk') -Force }
if (Test-Path (Join-Path $sendTo 'Send to My Phone.lnk')) { Remove-Item (Join-Path $sendTo 'Send to My Phone.lnk') -Force }

$lnk = $ws.CreateShortcut($lnkPath)
$lnk.TargetPath = 'powershell.exe'
$lnk.Arguments = '-WindowStyle Hidden -ExecutionPolicy Bypass -File "C:\Users\AlexNg\AppData\Roaming\KDE Connect\send-kdeconnect.ps1"'
$lnk.WorkingDirectory = '%USERPROFILE%'
$lnk.WindowStyle = 7
$lnk.Description = 'Send selected file(s) to your phone via KDE Connect (progress popup, no console window)'
$lnk.IconLocation = $icoPath
$lnk.Save()

Write-Output "Shortcut: $lnkPath"
Write-Output "Icon:     $icoPath"
if (Test-Path $lnkPath) { Write-Output 'OK' } else { Write-Output 'FAILED' }
