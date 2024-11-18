$appName =          "VC Redis 2015 - 14.0.24215"
$statusReg =        "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Intune_Win32\$appname"
$installOp =        "Installation"
$uninstallName =    "Microsoft Visual C++ 2015 x64 {0} - 14.0.24215"

$uninstallreg = @(
    "Minimum Runtime",
    "Additional Runtime"
)

# Check if status registry entries exists (created by installer)
if (Test-Path -Path $statusReg){
    $sRegCheck = Get-ItemPropertyValue -Path $statusReg -Name $installOp | Where-Object {$_ -eq "0"}
}
else {
    $sRegCheck = $false
}

# Check if both uninstall keys exist
$uCount = 0
foreach ($reg in $uninstallreg){
    $displayName = $uninstallName -f $reg
    if (Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object {$_.DisplayName -eq $displayName} -ErrorAction SilentlyContinue){
        $uCount++
    }
}

if (($uninstallReg.Count -eq $uCount) -and ($sRegCheck)) {
    Write-Host "$appName is installed"
    exit 0
}
else {
    Write-Host "$appName is not installed"
    exit 1
}