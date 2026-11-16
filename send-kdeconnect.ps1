param([string[]]$FilePaths)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$kdeconnectCli = "$env:LOCALAPPDATA\Microsoft\WindowsApps\kdeconnect-cli.exe"
$iconPath  = "$env:APPDATA\KDE Connect\kdeconnect.ico"

# Auto-detect connected device name (paired and reachable only)
$deviceInfo = & $kdeconnectCli --list-available --id-name-only 2>&1
$cliExitCode = $LASTEXITCODE
if ($cliExitCode -ne 0 -or -not $deviceInfo -or $deviceInfo -match 'error|Error|not found|Couldn|devices found') {
    $msg = "No KDE Connect device found. Make sure your phone is paired and connected."
    [System.Windows.Forms.MessageBox]::Show($msg, "KDE Connect - Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    exit 1
}
# Parse "id name" format, take first line
$deviceLine = if ($deviceInfo -is [array]) { $deviceInfo[0] } else { $deviceInfo }
if (-not $deviceLine -or $deviceLine -notmatch '\s') {
    $msg = "No KDE Connect device found. Make sure your phone is paired and connected."
    [System.Windows.Forms.MessageBox]::Show($msg, "KDE Connect - Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    exit 1
}
$parts = $deviceLine -split ' ', 2
$deviceId = $parts[0]
$device = $parts[1]

$files = ($FilePaths | Where-Object { $_ -ne $null -and $_ -ne '' })

$form = New-Object System.Windows.Forms.Form
$form.Text = 'KDE Connect - Sending'
$form.Size = New-Object System.Drawing.Size(420, 150)
$form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false
$form.MinimizeBox = $false
$form.ShowInTaskbar = $true
$form.TopMost = $true
if (Test-Path $iconPath) { $form.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($iconPath) }

$label = New-Object System.Windows.Forms.Label
$label.Text = "Sending to $device"
$label.Location = New-Object System.Drawing.Size(20, 16)
$label.Size = New-Object System.Drawing.Size(370, 20)
$form.Controls.Add($label)

$fileLabel = New-Object System.Windows.Forms.Label
$fileLabel.Text = ($files -join ', ')
$fileLabel.Location = New-Object System.Drawing.Size(20, 38)
$fileLabel.Size = New-Object System.Drawing.Size(370, 36)
$form.Controls.Add($fileLabel)

$progress = New-Object System.Windows.Forms.ProgressBar
$progress.Location = New-Object System.Drawing.Size(20, 80)
$progress.Size = New-Object System.Drawing.Size(370, 22)
$progress.Style = [System.Windows.Forms.ProgressBarStyle]::Marquee
$progress.MarqueeAnimationSpeed = 30
$form.Controls.Add($progress)

# Actually show the window (without this no popup appeared)
$form.Show()

$errors = @()

# Run the CLI on a background runspace so the WinForms window stays responsive
$rs = [powershell]::Create()
$null = $rs.AddScript({
    param($cli, $dev, $paths)
    $errs = @()
    foreach ($p in $paths) {
        $out = & $cli -n $dev --share $p 2>&1
        if ($LASTEXITCODE -ne 0) { $errs += "$p`n$out" }
    }
    $errs
}).AddArgument($kdeconnectCli).AddArgument($device).AddArgument($files)
$async = $rs.BeginInvoke()

while (-not $async.IsCompleted) {
    [System.Windows.Forms.Application]::DoEvents()
    Start-Sleep -Milliseconds 100
}

$errors = $rs.EndInvoke($async)
$rs.Dispose()
$form.Close()

if ($errors) {
    $msg = ($errors -join "`n`n")
    [System.Windows.Forms.MessageBox]::Show($msg, "KDE Connect - Send failed", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    exit 1
}
