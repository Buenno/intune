$appName =      "IntelliJ IDEA Community Edition"
$statusReg =    "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Intune_Win32\$appName"
$uninstallReg = Get-ChildItem -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall" | Get-ItemProperty | Where-Object {$_.DisplayName -like "$appName*"} -ErrorAction SilentlyContinue


# Operations which should be logged in the registry
$ops = @(
    "Installation",
    "Platform Properties",
    "Plugins",
    "EULA",
    "Deny Data Sharing",
    "Options",
    "Start Menu Tidied"
)

# Check if status registry entries exists (created by installer)
$sRegCheck = Get-Item -Path $statusReg -ErrorAction SilentlyContinue | Foreach-Object {Get-ItemPropertyValue -Path $_.PSPath -Name $_.Property | Where-Object {$_ -eq "0"}} 

# Check if the correct number of operations are stored in the registry
$opsRegCheck = $ops.Count -eq $sRegCheck.Count

# Return exit code based on checks
if (($uninstallReg) -and ($opsRegCheck)){
    Write-Host "$appName is installed"
    exit 0
}
else {
    Write-Host "$appName is not installed"
    exit 1
}