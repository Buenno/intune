$ErrorActionPreference = 'Stop'

$regPath =      "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\AppModel\SystemAppData\MSTeams_8wekyb3d8bbwe"
$regKey =       "TeamsTfwStartupTask"
$fullPath =     Join-Path -Path $regPath -ChildPath $regKey
$regProp =      "State"
$desiredVal =   "1"

# Create the registry key if it doesn't exist
if (!(Test-Path -Path $fullPath)){
    New-Item -Path $regPath -Name $regKey
}

# Then set the state to disabled
Set-ItemProperty -Path $fullPath -Name $regProp -Value $desiredVal -Force