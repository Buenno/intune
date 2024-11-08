$ErrorActionPreference = 'Stop'

# Get uninstall string from registry 
$installer = "msiexec.exe"
$displayName = "Safe Exam Browser (x64)"
$uninstallReg = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object {$_.DisplayName -eq $displayName}
$configDest = "C:\ProgramData\SafeExamBrowser\"

$uninstallParams = @(
    "/x",
    $uninstallReg.PSChildName,
    "/qn"
)

# Uninstall application
Start-Process $installer -ArgumentList "$($uninstallParams -join " ")" -PassThru -Wait

# Remove config directory
if (Test-Path $configDest){
    Remove-Item -Path $configDest -Recurse -Force
}