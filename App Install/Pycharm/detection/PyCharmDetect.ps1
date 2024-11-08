$version =      "2024.2.3"
$appName =      "PyCharm Community Edition"
$displayName =  "$appname $version"
$statusReg =    "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Intune_Win32\$appname"

# Operations which should be logged in the registry
$ops = @(
    "Installation",
    "Platform Properties",
    "Plugins",
    "EULA",
    "Deny Data Sharing",
    "Options"
)

# Check uninstall string exists
$uRegCheck = Test-Path -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$displayName"

# Check if status registry entries exists (created by installer)
if (Test-Path -Path $statusReg){
    $sRegCheck = Get-Item -Path $statusReg | Foreach-Object {Get-ItemPropertyValue -Path $_.PSPath -Name $_.Property | Where-Object {$_ -eq "1"}} 
}
else {
    $sRegCheck = $false
}

# Check if the correct number of operations are stored in the registry
$opsRegCheck = $ops.Count -eq $sRegCheck.Count

# Return exit code based on checks
if (($uRegCheck) -and ($opsRegCheck)){
    Write-Host "$displayName is installed"
    exit 0
}
else {
    Write-Host "$displayName is not installed"
    exit 1
}