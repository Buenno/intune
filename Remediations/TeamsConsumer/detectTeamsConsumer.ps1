$package = "MicrosoftTeams"
$appxPackage = Get-AppxPackage -Name $package -AllUsers
try {
    $reg = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Communications" -Name "ConfigureChatAutoInstall"
}
catch {Write-Output "Registry key doesn't exist"}

if (($appxPackage) -and !($reg)){
    Write-Output "$($package) is installed"
    exit 1
}
else {
    Write-Output "$($package) is not installed"
    exit 0
}