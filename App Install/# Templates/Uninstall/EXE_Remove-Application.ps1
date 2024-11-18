$ErrorActionPreference = 'Stop'

# Get the uninstall string from registry
$appName = ""
$uninstallReg = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object {$_.DisplayName -eq $appName}

$uninstallParams = @(
    "/SILENT"
)

# Uninstall application
$u = Start-Process $uninstallReg.UninstallString -ArgumentList $uninstallParams -PassThru -Wait

# Remove status registry key
if ($u.ExitCode -eq 0){
    Remove-StatusRegistryKey -Application $appName 
}