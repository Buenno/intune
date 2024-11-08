$ErrorActionPreference = 'Stop'

# Get the uninstall string from registry
$version = "1.0"
$displayName = "Application Name $version"
$uninstallReg = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object {$_.DisplayName -eq $displayName}

$uninstallParams = @(
    "/SILENT"
)

# Uninstall application
Start-Process $uninstallReg.UninstallString -ArgumentList $uninstallParams -PassThru -Wait