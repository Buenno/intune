# Check if the uninstall key exists
$displayName = "Minecraft Education"
$uninstallReg = Get-ChildItem -Path HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object {$_.DisplayName -eq $displayName} -ErrorAction SilentlyContinue

if ($uninstallReg) {
    Write-Host "$displayName is installed"
    exit 0
}
else {
    Write-Host "$displayName is not installed"
    exit 1
}