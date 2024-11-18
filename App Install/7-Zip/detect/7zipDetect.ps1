# Check if the uninstall key exists
$appName =      "7-Zip"
$uninstallReg = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object {$_.DisplayName -like "$appName*"} -ErrorAction SilentlyContinue
$statusReg =    "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Intune_Win32\$appname"
$installOp =    "Installation"

# Check if status registry entries exists (created by installer)
if (Test-Path -Path $statusReg){
    $sRegCheck = Get-ItemPropertyValue -Path $statusReg -Name $installOp | Where-Object {$_ -eq "0"}
}
else {
    $sRegCheck = $false
}

if (($uninstallReg -and ($sRegCheck))) {
    Write-Host "$appName is installed"
    exit 0
}
else {
    Write-Host "$appName is not installed"
    exit 1
}