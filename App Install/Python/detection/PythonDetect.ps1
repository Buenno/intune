$ErrorActionPreference = 'Stop'

## Get the uninstall strings
$appName = "Python"
$version = "3.13.150.0"
$uninstallReg = Get-ChildItem -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" | Get-ItemProperty | Where-Object {($_.DisplayName -like "$appName*") -and ($_.DisplayVersion -eq $version)}
$statusReg =    "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Intune_Win32\$appName"

# Check if status registry keys exist
$installOp =    "Installation"

if (Test-Path -Path $statusReg){
    $sRegCheck = Get-ItemPropertyValue -Path $statusReg -Name $installOp | Where-Object {$_ -eq "0"}
}
else {
    $sRegCheck = $false
}

if (($sRegCheck) -and ($uninstallReg.Count -eq '5')){
    Write-Host "$appName is installed."
    exit 0
}
else {
    Write-Host "$appName is not installed."
    exit 1
}