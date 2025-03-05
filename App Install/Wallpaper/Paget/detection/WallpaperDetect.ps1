$appName =      "Wallpaper"
$statusReg =    "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Intune_Win32\$appName"
$CSPReg =    "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP"

# Operations which should be logged in the registry
$ops = @(
    "Desktop CSP Set",
    "Lockscreen CSP Set",
    "Desktop Wallpaper DL",
    "Lockscreen Wallpaper DL",
    "Wallpaper Format",
    "Refresh Executed"
)

# Operations which should be logged in the PersonalizationCSP registry
$CSPs = @(
    "DesktopImagePath",
    "DesktopImageUrl",
    "DesktopImageStatus",
    "LockScreenImagePath",
    "LockScreenImageUrl",
    "LockScreenImageStatus"
)

# Check if status registry entries exists (created by installer)
$sRegCheck = Get-Item -Path $statusReg -ErrorAction SilentlyContinue | Foreach-Object {Get-ItemPropertyValue -Path $_.PSPath -Name $_.Property | Where-Object {$_ -eq "0"}} 

# Check if PersonalizeCSP registry entries exists
foreach ($CSP in $CSPs){
    if (Get-Item -Path $CSPReg -ErrorAction SilentlyContinue | Foreach-Object {Get-ItemPropertyValue -Path $_.PSPath -Name $CSP}){
        $CSPCount++
    }
}

# Check if the correct number of operations are stored in the registry
$opsRegCheck = $ops.Count -eq $sRegCheck.Count

# Check if the correct number of CSP operations are stored in the registry
$CSPRegCheck = $CSPs.Count -eq $CSPCount

# Return exit code based on checks
if ($opsRegCheck -and $CSPRegCheck){
    Write-Host "$appName is installed"
    exit 0
}
else {
    Write-Host "$appName is not installed"
    exit 1
}