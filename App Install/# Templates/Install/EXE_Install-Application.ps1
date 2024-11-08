$ErrorActionPreference = 'Stop'

$binary = Get-ChildItem -Path "$PSScriptRoot\binary" -Filter *.exe
$installer = $binary.FullName

$installParams = @(
    "/silent"
)

# Install application
Start-Process $installer -ArgumentList "$($installParams -join " ")" -PassThru -Wait