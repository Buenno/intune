# Get uninstall string from registry
$version = "3.6.4"
$displayName = "Audacity $version"
$uninstallReg = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object {$_.DisplayName -eq $displayName}

$uninstallParams = @(
    "/VERYSILENT"
)

# Uninstall application
Start-Process $uninstallReg.UninstallString -ArgumentList $uninstallParams -PassThru -Wait