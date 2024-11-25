# Check if the uninstall key exists
$appName =      "Arduino"
$uninstallReg = Get-ChildItem -Path HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object {$_.DisplayName -eq $appName} -ErrorAction SilentlyContinue
$statusReg =    "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Intune_Win32\$appName"

# Operations which should be logged in the registry
$ops = @(
    "Installation",
    "Trusted Publisher Certificates Installed",
    "Added Java firewall rule",
    "Desktop shortcut removed"
)

# Check if status registry entries exists (created by installer)
$sRegCheck = Get-Item -Path $statusReg -ErrorAction SilentlyContinue | Foreach-Object {Get-ItemPropertyValue -Path $_.PSPath -Name $_.Property | Where-Object {$_ -eq "0"}} 

# Check if the correct number of operations are stored in the registry
$opsRegCheck = $ops.Count -eq $sRegCheck.Count

if (($uninstallReg) -and ($opsRegCheck)) {
    Write-Host "$displayName is installed"
    exit 0
}
else {
    Write-Host "$displayName is not installed"
    exit 1
}