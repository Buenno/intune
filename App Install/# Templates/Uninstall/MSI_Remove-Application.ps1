$ErrorActionPreference = 'Stop'

$appName = ""
$installer = "msiexec.exe"

# Get uninstall string from registry
$uninstallReg = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object {$_.DisplayName -eq $appName}

$uninstallParams = @(
    "/x",
    $uninstallReg.PSChildName,
    "/qn"
)

# Uninstall application
$u = Start-Process $installer -ArgumentList "$($uninstallParams -join " ")" -PassThru -Wait

# Remove status registry key
if ($u.ExitCode -eq 0){
    Remove-StatusRegistryKey -Application $appName 
}