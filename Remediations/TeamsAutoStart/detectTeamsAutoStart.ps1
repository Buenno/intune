$ErrorActionPreference = 'Stop'

$regPath =      "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\AppModel\SystemAppData\MSTeams_8wekyb3d8bbwe"
$regKey =       "TeamsTfwStartupTask"
$fullPath =     Join-Path -Path $regPath -ChildPath $regKey
$regProp =      "State"
$desiredVal =   "1"

if (Test-Path -Path $fullPath){
    $curValue = Get-ItemPropertyValue -Path $fullPath -Name $regProp
    if ($curValue -ne $desiredVal){
        # Remediation required
        Write-Host "Auto-start is currently enabled"
        exit 1
    }
    else {
        # Remediation not required
        Write-Host "Auto-start is currently disabled"
        exit 0
    }
}
else {
    # Remediation required
    Write-Host "No auto-start value found, Teams is likely not install or has not been run. Let's create the key."
    exit 1
}