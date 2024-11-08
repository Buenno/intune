# Check if the uninstall key exists
$displayName = "Safe Exam Browser (x64)"
$uninstallReg = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object {$_.DisplayName -eq $displayName} -ErrorAction SilentlyContinue

if ($uninstallReg) {
    Write-Host "$displayName is installed"
    exit 0
}
else {
    Write-Host "$displayName is not installed"
    exit 1
}