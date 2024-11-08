$ErrorActionPreference = 'Stop'

# Get uninstall string from registry 
$installer = "msiexec.exe"
$displayName = "senso.cloud"
$uninstallReg = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object {$_.DisplayName -eq $displayName}

$uninstallParams = @(
    "/x",
    $uninstallReg.PSChildName,
    "/qn"
)

# Uninstall application
Start-Process $installer -ArgumentList "$($uninstallParams -join " ")" -PassThru -Wait