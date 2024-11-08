$ErrorActionPreference = 'Stop'

$binary = Get-ChildItem -Path "$PSScriptRoot\binary" -Filter *.exe
$installer = $binary.FullName

$installParams = @(
    "/SP-",
    "/VERYSILENT",
    "/SUPPRESSMSGBOXES",
    "/MERGETASKS=""!desktopicon"""
)

Start-Process $installer -ArgumentList "$($installParams -join " ")" -PassThru -Wait