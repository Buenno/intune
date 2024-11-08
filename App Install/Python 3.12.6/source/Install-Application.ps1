$ErrorActionPreference = 'Stop'

## Install Python
$iString = "$PSScriptRoot\binary\python-3.12.6-amd64.exe"
$iParams = @(
    "/quiet",
    "InstallAllUsers=1",
    "PrependPath=1"
)

try {
    Start-Process $iString -ArgumentList "$($iParams -join " ")" -PassThru -Wait
}
catch {
    Write-Host "Installation failed. The following error was returned: $($_)"
}