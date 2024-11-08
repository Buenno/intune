$ErrorActionPreference = 'Stop'

## Get the uninstall string
$installer = "msiexec.exe"
$displayName = "Java(TM) SE Development Kit 23.0.1 (64-bit)"
$uninstallReg = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object {$_.DisplayName -eq $displayName}

$uninstallParams = @(
    "/x",
    $uninstallReg.PSChildName,
    "/qn"
)

## Uninstall application
Start-Process $installer -ArgumentList "$($uninstallParams -join " ")" -PassThru -Wait