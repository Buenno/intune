$ErrorActionPreference = 'Stop'

## Install 7zip
$iString = ".\7z2408-x64.exe"
$iParams = @(
    "/S",
    "/D=`"C:\Program Files\7-Zip`""
)

try {
    Start-Process $iString -ArgumentList "$($iParams -join " ")" -PassThru -Wait
}
catch {
    Write-Host "Installation failed. The following error was returned: $($_)"
}

exit $LASTEXITCODE