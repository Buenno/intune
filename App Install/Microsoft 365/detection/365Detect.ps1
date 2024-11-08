# Check if the uninstall key exists
# There is one key for each proof language we have installed, we need to check all of them
# We will also check to see if the status registry key (added by the installer) exists

$appName =      "Microsoft 365"
$statusReg =    "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Intune_Win32\$appname"
$installOp =    "Installation"

$app = "O365ProPlusRetail - en-gb"

$proof = @(
    "fr-fr",
    "de-de",
    "it-it",
    "es-es"
)

$proofCount = 0

$appInstall = Test-Path -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$app"

foreach ($language in $proof){
    $keyName = "O365ProPlusRetail - {0}.proof" -f $language
    if (Test-Path -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$keyName"){
        $proofCount++
    }
}

# Check if status registry entries exists (created by installer)
if (Test-Path -Path $statusReg){
    $sRegCheck = Get-ItemPropertyValue -Path $statusReg -Name $installOp | Where-Object {$_ -eq "0"}
}
else {
    $sRegCheck = $false
}

if (($proofCount -eq $proof.Count) -and ($sRegCheck) -and ($appInstall)) {
    Write-Host "$appName is installed"
    exit 0
}
else {
    Write-Host "$appName is not installed"
    exit 1
}