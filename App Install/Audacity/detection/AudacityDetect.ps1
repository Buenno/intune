# Check if the uninstall key exists
$version = "3.6.4"
$displayName = "Audacity $version"
$uninstallReg = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object {$_.DisplayName -eq $displayName} -ErrorAction SilentlyContinue

if ($uninstallReg) {
    Write-Host "$displayName is installed"
    exit 0
}
else {
    Write-Host "$displayName is not installed"
    exit 1
}