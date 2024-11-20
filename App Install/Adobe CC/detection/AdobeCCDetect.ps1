# Check if the uninstall key exists
$appname = "Creative Cloud"
$uninstallReg = Get-ChildItem -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" | Get-ItemProperty | Where-Object {$_.DisplayName -like "$appName*"} -ErrorAction SilentlyContinue
$statusReg =    "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Intune_Win32\$appName"

# Check if status registry keys exist
$ops = @(
    "Installation",
    "Autostart Disabled"
)

$sRegCheck = Get-Item -Path $statusReg -ErrorAction SilentlyContinue | Foreach-Object {Get-ItemPropertyValue -Path $_.PSPath -Name $_.Property | Where-Object {$_ -eq "0"}} 

# Check if the correct number of operations are stored in the registry
$opsRegCheck = $ops.Count -eq $sRegCheck.Count

if ($($uninstallReg) -and ($opsRegCheck)) {
    Write-Host "$appname is installed"
    exit 0
}
else {
    Write-Host "$appname is not installed"
    exit 1
}