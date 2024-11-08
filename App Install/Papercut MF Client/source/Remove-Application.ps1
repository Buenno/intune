$ErrorActionPreference = 'Stop'

## Get the uninstall string
$application = "PaperCut MF Client"
$uReg = (Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object {$_.DisplayName -match $($application)})
$params = @(
    "/X $($uReg.PSChildName)",
    "/qn"
    )

try {
    Start-Process "msiexec" -ArgumentList $params -PassThru -Wait
}
catch {
    Write-Host "Uninstall failed. The following error was returned: $($_.Exception.Message)"
}