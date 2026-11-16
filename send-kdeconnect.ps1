param([string[]]$FilePaths)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$device = 'YOUR_PHONE_NAME_HERE'  # <-- your phone's KDE Connect name
$kdeconnectCli = "$env:LOCALAPPDATA\Microsoft\WindowsApps\kdeconnect-cli.exe"
$iconPath  = "$env:APPDATA\KDE Connect\kdeconnect.ico"

$files = ($FilePaths | Where-Object { $_ -ne $null -and $_ -ne '' })

$form = New-Object System.Windows.Forms.Form
$form.Text = 'KDE Connect – Sending'
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
